import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../entity/app_settings.dart';
import '../convert/book_converter.dart';
import '../books/ebook_archive.dart';
import '../books/kindle_file.dart';
import '../entity/favorite.dart';
import '../l10n/l10n.dart';
import '../local/local_files.dart';
import '../local/local_storage.dart';
import '../mail/kindle_mailer.dart';
import '../opds/opds_client.dart';
import '../opds/opds_feed.dart';
import '../opds/opensearch.dart';
import '../share/share_service.dart';
import 'file_names.dart';
import 'favicon.dart';
import 'html_pages.dart';
import 'mail_jobs.dart';
import 'server_auth.dart';
import 'url_codec.dart';

typedef SettingsProvider = AppSettings Function();
typedef LogSink = void Function(String message);
typedef VoidCallback = void Function();
typedef ShareFile = Future<void> Function(
  File file,
  String title,
  String mime,
  String to,
);
typedef CanShare = bool Function();
typedef ShareDirectoryProvider = Future<Directory> Function();
typedef FavoritesProvider = List<Favorite> Function();

/// A small HTTP server that renders the remote OPDS catalog as plain HTML
/// for the Kindle Experimental Browser.
class OpdsProxyServer {
  OpdsProxyServer({
    required this.settingsProvider,
    required this.log,
    KindleMailer? mailer,
    ShareFile? shareFile,
    CanShare? canShare,
    ShareDirectoryProvider? shareDirectoryProvider,
    FavoritesProvider? favoritesProvider,
    LocalStorage? localStorage,
    ServerAuth? auth,
    this.onPinChanged,
    this.onAutoStopped,
    Duration Function()? idleTimeout,
  }) : _mailer = mailer ?? KindleMailer(),
       _shareDirectory = shareDirectoryProvider ?? shareCacheDirectory,
       _localStorage = localStorage ?? const SafLocalStorage(),
       _favoritesProvider = favoritesProvider ?? _emptyFavorites,
       _idleTimeoutOverride = idleTimeout,
       _auth = auth ?? ServerAuth() {
    _shareFile = shareFile;
    _canShare = canShare;
    _mailQueue = MailJobQueue(run: _runMailJob);
  }

  static const int _maxShareBytes = 100 * 1024 * 1024;

  static List<Favorite> _emptyFavorites() => const [];

  /// Name of the cookie that keeps a Kindle signed in after it typed the PIN.
  static const String sessionCookie = 'klos_session';

  /// Largest accepted `/unlock` body. The form has two short fields.
  static const int _maxFormBytes = 4096;

  final SettingsProvider settingsProvider;
  final LogSink log;
  final KindleMailer _mailer;
  late final ShareFile? _shareFile;
  late final CanShare? _canShare;
  final ShareDirectoryProvider _shareDirectory;
  final LocalStorage _localStorage;
  final FavoritesProvider _favoritesProvider;
  final ServerAuth _auth;

  /// Called when the PIN changes outside the server (automatic rotation after
  /// failed attempts), so the app can log it and repaint the code.
  final VoidCallback? onPinChanged;

  /// Called when the server stopped itself after being idle for too long.
  final VoidCallback? onAutoStopped;

  /// How long the server waits before stopping itself.
  ///
  /// Tests pass a short duration; the app reads the value from the settings
  /// through [settingsProvider].
  final Duration Function()? _idleTimeoutOverride;

  /// Pending automatic-stop timer, or null when the stop is off.
  Timer? _idleTimer;

  /// Requests being served right now. A long download keeps the server busy,
  /// so the idle timer waits instead of stopping in the middle of it.
  int _activeRequests = 0;

  late final MailJobQueue _mailQueue;

  /// OpenSearch templates resolved from description documents, keyed by the
  /// document URL. Failed lookups are not cached, so they can be retried.
  final Map<String, String> _searchTemplates = {};

  /// Catalog pages visited by each Kindle, newest last.
  ///
  /// Some OPDS servers link only "next" and omit "previous". Keeping a short
  /// history lets klos render a working "Back" button in that case.
  final Map<String, List<Uri>> _feedHistory = {};
  static const int _maxFeedHistory = 50;

  /// Downloads and conversions that are already running, keyed by the
  /// requested link.
  ///
  /// The Kindle browser is slow and often sends the same request twice. While
  /// a request is in progress, later requests for the same link wait for its
  /// result instead of downloading or converting the book again.
  final Map<String, Future<Object?>> _runningRequests = {};

  /// Sockets the server listens on, one per bound address.
  ///
  /// klos binds every Wi-Fi address the phone has, so the Kindle can reach it
  /// on whichever network it is connected to, while mobile data stays closed.
  /// Loopback is bound as well, so the phone itself (and `adb forward` on an
  /// emulator) can open the catalog too.
  final List<HttpServer> _servers = [];

  bool get isRunning => _servers.isNotEmpty;

  int? get port => _servers.isEmpty ? null : _servers.first.port;

  /// Addresses the server answers on, empty while it is stopped.
  ///
  /// Includes loopback; used to show only the links that really answer.
  Set<String> get boundAddresses => {
    for (final server in _servers) server.address.address,
  };

  /// Whether the Kindle must enter the PIN before it sees anything.
  bool get pinRequired => settingsProvider().requirePin;

  /// PIN the Kindle has to enter, or null when protection is off or the
  /// server is stopped.
  String? get currentPin {
    if (!pinRequired) return null;
    final pin = _auth.pin;
    return pin.isEmpty ? null : pin;
  }

  /// Replaces the PIN and signs every device out.
  void refreshPin() {
    if (!pinRequired) return;
    _auth.rotate();
    onPinChanged?.call();
  }

  /// Restarts the idle countdown, so a changed timeout applies right away.
  void refreshIdleTimer() {
    if (isRunning) _armIdleTimer();
  }

  /// Waits this long before the server stops itself; zero turns it off.
  Duration get _idleTimeout {
    final override = _idleTimeoutOverride;
    if (override != null) return override();
    final minutes = settingsProvider().autoStopMinutes;
    return minutes > 0 ? Duration(minutes: minutes) : Duration.zero;
  }

  /// Starts the countdown again; called on start and on every request.
  void _armIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
    final timeout = _idleTimeout;
    if (timeout <= Duration.zero) return;
    _idleTimer = Timer(timeout, () => unawaited(_stopIfIdle()));
  }

  /// Stops the server when nothing used it for [_idleTimeout].
  Future<void> _stopIfIdle() async {
    if (_activeRequests > 0) {
      // A request is still running; check again later.
      _armIdleTimer();
      return;
    }
    if (!isRunning) return;
    await stop();
    onAutoStopped?.call();
  }

  /// Starts the server on [port] and on every address in [addresses].
  ///
  /// Loopback is always bound as well, so the phone itself and `adb forward`
  /// on an emulator can reach the catalog. Mobile-data addresses are never
  /// passed in, so the catalog stays off the internet.
  ///
  /// One address failing to bind (it went away, or another app holds the
  /// port) does not stop the others. Throws when nothing could be bound.
  Future<void> start({required int port, List<String>? addresses}) async {
    if (_servers.isNotEmpty) return;

    final targets = <InternetAddress>[];
    void add(InternetAddress? address) {
      if (address == null) return;
      if (targets.any((item) => item.address == address.address)) return;
      targets.add(address);
    }

    for (final value in addresses ?? const <String>[]) {
      add(InternetAddress.tryParse(value.trim()));
    }
    // anyIPv4 already covers loopback.
    if (!targets.any((item) => item.address == '0.0.0.0')) {
      add(InternetAddress.loopbackIPv4);
    }
    // Loopback goes last, so a network address stays the primary one.
    targets.sort((a, b) => _isLoopback(a).compareTo(_isLoopback(b)));

    Object? failure;
    var boundPort = port;
    for (final target in targets) {
      try {
        final server = await HttpServer.bind(target, boundPort, shared: false);
        boundPort = server.port;
        _servers.add(server);
      } catch (error) {
        failure = error;
        log(l10n.serverErrorLog('$error'));
      }
    }

    if (_servers.isEmpty) {
      throw failure is SocketException
          ? failure
          : SocketException('Could not listen on port $boundPort: $failure');
    }

    _auth.start();
    _armIdleTimer();
    for (final server in _servers) {
      server.listen(
        _handle,
        onError: (Object error) => log(l10n.serverErrorLog('$error')),
        cancelOnError: false,
      );
    }
  }

  Future<void> stop() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final servers = List<HttpServer>.of(_servers);
    _servers.clear();
    _auth.stop();
    for (final server in servers) {
      await server.close(force: true);
    }
  }

  static int _isLoopback(InternetAddress address) => address.isLoopback ? 1 : 0;

  Future<void> _handle(HttpRequest request) async {
    final headOnly = request.method == 'HEAD';
    _activeRequests++;
    _armIdleTimer();
    try {
      _applySecurityHeaders(request.response);

      final path = request.uri.path;
      if (_isIcon(path)) {
        await _icon(request, path, headOnly: headOnly);
        return;
      }

      if (pinRequired && !_hasSession(request)) {
        await _challenge(request);
        return;
      }

      if (request.method != 'GET' && !headOnly) {
        await _page(
          request,
          HttpStatus.methodNotAllowed,
          renderErrorPage(l10n.methodNotSupported(request.method)),
        );
        return;
      }

      if (path == '/download' || path.startsWith('/download/')) {
        await _download(request, headOnly: headOnly);
        return;
      }
      if (path == '/send' || path.startsWith('/send/')) {
        await _sendToKindle(request, headOnly: headOnly);
        return;
      }
      if (path == '/image' || path.startsWith('/image/')) {
        await _image(request, headOnly: headOnly);
        return;
      }
      if (path.startsWith('/mail/')) {
        await _mailStatus(request, headOnly: headOnly);
        return;
      }
      if (path == '/local' || path.startsWith('/local/')) {
        await _local(request, headOnly: headOnly);
        return;
      }

      switch (path) {
        case '/':
          await _root(request, headOnly: headOnly);
          break;
        case '/browse':
          await _browse(request, headOnly: headOnly);
          break;
        case '/search':
          await _search(request, headOnly: headOnly);
          break;
        case '/opds':
          await _rawFeed(request, headOnly: headOnly);
          break;
        case '/help':
          await _help(request, headOnly: headOnly);
          break;
        case '/favorites':
        case '/favorites/':
          await _favorites(request, headOnly: headOnly);
          break;
        default:
          await _page(
            request,
            HttpStatus.notFound,
            renderNotFoundPage(),
            headOnly: headOnly,
          );
      }
    } catch (error) {
      log(l10n.requestErrorLog(request.uri.toString(), '$error'));
      try {
        await _page(
          request,
          HttpStatus.internalServerError,
          renderErrorPage(l10n.internalServerError('$error')),
        );
      } catch (_) {
        // The response is already started or closed.
      }
    } finally {
      _activeRequests--;
    }
  }

  /// Headers that keep browsers from sniffing types or framing the pages.
  ///
  /// The Kindle browser ignores most of them, but they cost nothing and make
  /// the server safer when it is opened from a modern device on the network.
  static void _applySecurityHeaders(HttpResponse response) {
    response.headers
      ..set('x-content-type-options', 'nosniff')
      ..set('x-frame-options', 'DENY')
      ..set('referrer-policy', 'no-referrer');
  }

  /// Icons are served without the PIN: the login page needs its favicon too.
  static bool _isIcon(String path) =>
      path == '/icon.svg' || path == '/favicon.svg' || path == '/favicon.ico';

  Future<void> _icon(
    HttpRequest request,
    String path, {
    required bool headOnly,
  }) async {
    if (path == '/favicon.ico') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }
    await _favicon(request, headOnly: headOnly);
  }

  /// Whether the request carries a cookie of a signed-in Kindle.
  bool _hasSession(HttpRequest request) {
    final token = _sessionToken(request);
    return token != null && _auth.isSessionValid(token);
  }

  String? _sessionToken(HttpRequest request) {
    try {
      for (final cookie in request.cookies) {
        if (cookie.name == sessionCookie) return cookie.value;
      }
    } catch (_) {
      // A malformed Cookie header simply means "not signed in".
    }
    return null;
  }

  /// Answers a request that is not signed in yet.
  ///
  /// `POST /unlock` checks the typed PIN; everything else shows the login
  /// form. The form has no JavaScript, so the old Kindle browser can use it.
  Future<void> _challenge(HttpRequest request) async {
    if (request.method == 'POST' && request.uri.path == '/unlock') {
      await _unlock(request);
      return;
    }
    final next = request.method == 'GET' || request.method == 'HEAD'
        ? request.uri.toString()
        : null;
    await _page(
      request,
      HttpStatus.ok,
      renderPinPage(next: next),
      headOnly: request.method == 'HEAD',
    );
  }

  /// Checks the PIN, blocks repeated guesses and signs the Kindle in.
  Future<void> _unlock(HttpRequest request) async {
    final client = _clientIp(request);
    if (_auth.isBlocked(client)) {
      request.response.headers.set(
        HttpHeaders.retryAfterHeader,
        '${_auth.retryAfter(client).inSeconds}',
      );
      log(l10n.logPinBlocked(client));
      await _page(
        request,
        HttpStatus.tooManyRequests,
        renderPinPage(error: l10n.pinBlocked),
      );
      return;
    }

    final fields = await _readForm(request);
    if (!_auth.matchesPin((fields['pin'] ?? '').trim())) {
      final rotated = _auth.noteFailure(client);
      log(l10n.logPinFailed(client));
      if (rotated) {
        log(l10n.logPinRotated);
        onPinChanged?.call();
      }
      await _page(
        request,
        HttpStatus.ok,
        renderPinPage(error: l10n.pinWrong, next: fields['next']),
      );
      return;
    }

    _auth.noteSuccess(client);
    final response = request.response;
    response.cookies.add(
      Cookie(sessionCookie, _auth.createSession())
        ..path = '/'
        ..httpOnly = true
        ..maxAge = _auth.sessionLifetime.inSeconds,
    );
    log(l10n.logPinGranted(client));
    response.statusCode = HttpStatus.seeOther;
    response.headers.set(HttpHeaders.locationHeader, _safeNext(fields['next']));
    await response.close();
  }

  /// Reads a small URL-encoded form body.
  Future<Map<String, String>> _readForm(HttpRequest request) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request) {
      builder.add(chunk);
      if (builder.length > _maxFormBytes) return const {};
    }
    final body = utf8.decode(builder.takeBytes(), allowMalformed: true);
    return Uri.splitQueryString(body);
  }

  /// Only local paths may be used as the post-login redirect.
  static String _safeNext(String? value) {
    final text = (value ?? '').trim();
    if (!text.startsWith('/') || text.startsWith('//')) return '/';
    return text;
  }

  Future<void> _root(HttpRequest request, {required bool headOnly}) async {
    final settings = settingsProvider();
    final url = settings.catalogUrl;
    if (url == null) {
      // Without a catalog the chosen folder is the whole library. Showing it
      // at the root means the Kindle can start from the same address as usual.
      if (settings.hasLocalFolder) {
        await _localBrowse(request, headOnly: headOnly);
        return;
      }
      await _page(
        request,
        HttpStatus.ok,
        renderNotConfiguredPage(),
        headOnly: headOnly,
      );
      return;
    }
    await _serveFeed(request, url, settings, headOnly: headOnly);
  }

  Future<void> _favicon(HttpRequest request, {required bool headOnly}) async {
    final bytes = utf8.encode(klosFaviconSvg);
    final response = request.response;
    response.statusCode = HttpStatus.ok;
    response.headers.set(
      HttpHeaders.contentTypeHeader,
      'image/svg+xml; charset=utf-8',
    );
    response.headers.contentLength = bytes.length;
    response.headers.set(
      HttpHeaders.cacheControlHeader,
      'public, max-age=86400',
    );
    if (!headOnly) response.add(bytes);
    await response.close();
  }

  Future<void> _image(HttpRequest request, {required bool headOnly}) async {
    final target = _target(request);
    if (target == null) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.badImageAddress),
        headOnly: headOnly,
      );
      return;
    }

    final declared = _requestedImageMime(request);

    // A HEAD probe must not download the image.
    if (headOnly) {
      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers
        ..set(HttpHeaders.contentTypeHeader, declared)
        ..set(HttpHeaders.cacheControlHeader, 'public, max-age=86400');
      await response.close();
      return;
    }

    final settings = settingsProvider();
    final client = OpdsClient(
      username: settings.username,
      password: settings.password,
    );

    var streaming = false;
    try {
      final remote = await client.openDownload(target);
      final remoteMime = remote.response.headers.contentType?.mimeType;
      if (remoteMime != null && !remoteMime.startsWith('image/')) {
        await remote.response.drain<void>();
        throw OpdsException(l10n.notAnImage);
      }
      final mime = remoteMime ?? declared;

      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers
        ..set(HttpHeaders.contentTypeHeader, mime)
        ..set(HttpHeaders.cacheControlHeader, 'public, max-age=86400');
      final length = remote.response.contentLength;
      if (length > 0) response.contentLength = length;

      streaming = true;
      await response.addStream(remote.response);
      await response.close();
    } on OpdsException catch (error) {
      log(l10n.coverLog(error.message));
      if (!streaming) {
        await _page(
          request,
          HttpStatus.badGateway,
          renderErrorPage(error.message),
          headOnly: headOnly,
        );
      } else {
        await _closeQuietly(request.response);
      }
    } catch (error) {
      log(l10n.coverLog('$error'));
      if (!streaming) {
        await _page(
          request,
          HttpStatus.badGateway,
          renderErrorPage(l10n.imageFetchFailed('$error')),
          headOnly: headOnly,
        );
      } else {
        await _closeQuietly(request.response);
      }
    } finally {
      client.close();
    }
  }

  static String _requestedImageMime(HttpRequest request) {
    final value = (request.uri.queryParameters['t'] ?? '').trim().toLowerCase();
    return value.startsWith('image/') ? value : 'image/jpeg';
  }

  Future<void> _browse(HttpRequest request, {required bool headOnly}) async {
    final target = _target(request);
    if (target == null) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.badCatalogAddress),
        headOnly: headOnly,
      );
      return;
    }
    await _serveFeed(request, target, settingsProvider(), headOnly: headOnly);
  }

  Future<void> _serveFeed(
    HttpRequest request,
    Uri url,
    AppSettings settings, {
    required bool headOnly,
    String? searchTemplate,
    String? searchQuery,
  }) async {
    final client = OpdsClient(
      username: settings.username,
      password: settings.password,
    );
    try {
      final feed = await client.fetchFeed(url);
      final template = searchTemplate ?? await _searchTemplate(feed, client);
      final previousPage = headOnly
          ? null
          : _rememberFeed(request, feed.url, settings.catalogUrl);
      log(l10n.catalogLog(feed.title, feed.entries.length, _clientIp(request)));
      await _page(
        request,
        HttpStatus.ok,
        renderCatalogPage(
          feed,
          previousPage: previousPage,
          kindleMailReady: settings.hasKindleEmail,
          showCovers: settings.showCovers,
          searchTemplate: template,
          searchQuery: searchQuery,
        ),
        headOnly: headOnly,
      );
    } on OpdsException catch (error) {
      log(l10n.catalogErrorLog(url.toString(), error.message));
      await _page(
        request,
        HttpStatus.badGateway,
        renderErrorPage(
          error.message,
          retryHref: searchQuery == null
              ? null
              : searchHref(searchTemplate ?? '', searchQuery),
          retryUrl: searchQuery == null ? url : null,
        ),
        headOnly: headOnly,
      );
    } finally {
      client.close();
    }
  }

  /// Records a visited catalog page and returns the page before it.
  ///
  /// Revisiting a page already in the history (Back or a refresh) trims
  /// everything after it, so the pager stays consistent with where the reader
  /// actually is.
  Uri? _rememberFeed(HttpRequest request, Uri url, Uri? catalogUrl) {
    final key = '${_clientIp(request)}|${catalogUrl ?? ''}';
    final history = _feedHistory.putIfAbsent(key, () => <Uri>[]);
    final index = history.lastIndexOf(url);
    if (index >= 0) {
      history.removeRange(index + 1, history.length);
    } else {
      history.add(url);
      if (history.length > _maxFeedHistory) history.removeAt(0);
    }
    return history.length > 1 ? history[history.length - 2] : null;
  }

  Future<void> _search(HttpRequest request, {required bool headOnly}) async {
    final template = (request.uri.queryParameters['u'] ?? '').trim();
    final query = (request.uri.queryParameters['q'] ?? '').trim();

    if (!isSearchTemplate(template)) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.badSearchTemplate),
        headOnly: headOnly,
      );
      return;
    }

    if (query.isEmpty) {
      // An empty form submission goes back to the catalog, which still shows
      // the search field.
      final response = request.response;
      response.statusCode = HttpStatus.found;
      response.headers.set(HttpHeaders.locationHeader, '/');
      await response.close();
      return;
    }

    final target = buildSearchUrl(template, query);
    if (target == null) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.searchUrlFailed),
        headOnly: headOnly,
      );
      return;
    }

    await _serveFeed(
      request,
      target,
      settingsProvider(),
      headOnly: headOnly,
      searchTemplate: template,
      searchQuery: query,
    );
  }

  /// Finds the search template for [feed], fetching its OpenSearch description
  /// document when the feed only links to one.
  Future<String?> _searchTemplate(OpdsFeed feed, OpdsClient client) async {
    if (feed.searchTemplate != null) return feed.searchTemplate;

    final description = feed.searchDescription;
    if (description == null) return null;

    final key = description.toString();
    final cached = _searchTemplates[key];
    if (cached != null) return cached;

    try {
      final text = await client.fetchText(description);
      final template = parseSearchDescription(text.body, text.url);
      if (template != null) _searchTemplates[key] = template;
      return template;
    } catch (error) {
      log(l10n.openSearchLog('$error'));
      return null;
    }
  }

  Future<void> _rawFeed(HttpRequest request, {required bool headOnly}) async {
    final target = _target(request);
    if (target == null) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.badCatalogAddress),
        headOnly: headOnly,
      );
      return;
    }

    final settings = settingsProvider();
    final client = OpdsClient(
      username: settings.username,
      password: settings.password,
    );
    try {
      final text = await client.fetchText(target);
      final bytes = utf8.encode(text.body);
      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/atom+xml; charset=utf-8',
      );
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      response.contentLength = bytes.length;
      if (!headOnly) response.add(bytes);
      await response.close();
    } on OpdsException catch (error) {
      log(l10n.requestErrorLog(request.uri.toString(), error.message));
      await _page(
        request,
        HttpStatus.badGateway,
        renderErrorPage(error.message, retryUrl: target),
        headOnly: headOnly,
      );
    } finally {
      client.close();
    }
  }

  Future<void> _favorites(HttpRequest request, {required bool headOnly}) async {
    final settings = settingsProvider();
    final favorites = _favoritesProvider();
    log(l10n.favoritesLog(favorites.length, _clientIp(request)));
    await _page(
      request,
      HttpStatus.ok,
      renderFavoritesPage(
        favorites: favorites,
        kindleMailReady: settings.hasKindleEmail,
        showCovers: settings.showCovers,
      ),
      headOnly: headOnly,
    );
  }

  Future<void> _local(HttpRequest request, {required bool headOnly}) async {
    final path = request.uri.path;
    if (path == '/local') {
      await _localBrowse(request, headOnly: headOnly);
      return;
    }
    if (path == '/local/download' || path.startsWith('/local/download/')) {
      await _localDownload(request, headOnly: headOnly);
      return;
    }
    if (path == '/local/send' || path.startsWith('/local/send/')) {
      await _localSend(request, headOnly: headOnly);
      return;
    }
    await _page(
      request,
      HttpStatus.notFound,
      renderNotFoundPage(),
      headOnly: headOnly,
    );
  }

  Future<void> _localBrowse(
    HttpRequest request, {
    required bool headOnly,
  }) async {
    final settings = settingsProvider();
    final rootUri = settings.localFolderUri.trim();
    if (rootUri.isEmpty) {
      await _page(
        request,
        HttpStatus.ok,
        renderLocalUnavailablePage(),
        headOnly: headOnly,
      );
      return;
    }

    var folderUri = rootUri;
    final token = request.uri.queryParameters['d'];
    if (token != null && token.isNotEmpty) {
      final decoded = decodeTarget(token)?.toString();
      if (decoded == null || !LocalStorage.isUnder(rootUri, decoded)) {
        await _page(
          request,
          HttpStatus.badRequest,
          renderErrorPage(l10n.localFolderBadLink),
          headOnly: headOnly,
        );
        return;
      }
      folderUri = decoded;
    }

    try {
      if (!await _localStorage.checkAccess(rootUri)) {
        await _page(
          request,
          HttpStatus.forbidden,
          renderLocalUnavailablePage(message: l10n.localFolderAccessLost),
          headOnly: headOnly,
        );
        return;
      }

      final all = await _localStorage.list(folderUri);
      final entries =
          all
              .where(
                (entry) =>
                    entry.isDirectory ||
                    isLocalBookName(entry.name, mime: entry.mime),
              )
              .toList()
            ..sort(compareLocalEntries);

      LocalParent? parent;
      var title = settings.localFolderName.trim();
      if (folderUri == rootUri) {
        if (title.isEmpty) title = l10n.localFolderDefaultName;
      } else {
        parent = await _localStorage.parentOf(treeUri: rootUri, uri: folderUri);
        final name = parent?.name.trim() ?? '';
        title = name.isEmpty ? l10n.localFiles : name;
      }

      log(l10n.localCatalogLog(title, entries.length, _clientIp(request)));
      await _page(
        request,
        HttpStatus.ok,
        renderLocalPage(
          title: title,
          folderUri: folderUri,
          entries: entries,
          parent: parent,
          kindleMailReady: settings.hasKindleEmail,
        ),
        headOnly: headOnly,
      );
    } on LocalStorageException catch (error) {
      log(l10n.localFolderErrorLog(error.message));
      await _page(
        request,
        HttpStatus.badGateway,
        renderErrorPage(error.message),
        headOnly: headOnly,
      );
    }
  }

  /// Validates a `content://` file link against the chosen folder.
  ({Uri uri, String? title, String? type})? _localFile(HttpRequest request) {
    final uri = _target(request);
    if (uri == null || uri.scheme != 'content') return null;
    final root = settingsProvider().localFolderUri;
    if (root.isEmpty || !LocalStorage.isUnder(root, uri.toString())) {
      return null;
    }
    return (
      uri: uri,
      title: request.uri.queryParameters['n'],
      type: request.uri.queryParameters['t'],
    );
  }

  Future<void> _localDownload(
    HttpRequest request, {
    required bool headOnly,
  }) async {
    final file = _localFile(request);
    if (file == null) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.localFolderBadLink),
        headOnly: headOnly,
      );
      return;
    }

    final declared = downloadMime(remoteType: null, linkType: file.type);
    if (headOnly) {
      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.set(HttpHeaders.contentTypeHeader, declared);
      response.headers.set(
        'content-disposition',
        contentDispositionFor(title: file.title, url: file.uri, mime: declared),
      );
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      await response.close();
      return;
    }

    try {
      final downloaded = await _once(
        'local-download:${request.uri}',
        () => _fetchLocalDownload(
          uri: file.uri,
          title: file.title,
          declared: declared,
          ip: _clientIp(request),
        ),
      );

      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.set(HttpHeaders.contentTypeHeader, downloaded.mime);
      response.headers.set(
        'content-disposition',
        contentDispositionFor(
          title: file.title,
          url: downloaded.url,
          mime: downloaded.mime,
        ),
      );
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      response.contentLength = downloaded.bytes.length;
      response.add(downloaded.bytes);
      await response.close();
    } on LocalStorageException catch (error) {
      log(l10n.localFolderErrorLog(error.message));
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(error.message, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
    } on BookArchiveException catch (error) {
      log(l10n.localFolderErrorLog(error.message));
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(error.message, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
    } on EpubConversionException catch (error) {
      log(l10n.localFolderErrorLog(error.message));
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(error.message, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
    } catch (error) {
      log(l10n.localFolderErrorLog('$error'));
      await _page(
        request,
        HttpStatus.badGateway,
        renderErrorPage(
          l10n.fileTransferFailed('$error'),
          retryHref: _retryHref(request),
        ),
        headOnly: headOnly,
      );
    }
  }

  /// Shares one download or conversion between identical requests.
  ///
  /// While [run] is in progress, later requests for the same [key] wait for
  /// its result instead of starting a second download or conversion. The
  /// entry is removed as soon as the request finishes or fails, so the next
  /// press still starts a fresh attempt.
  Future<T> _once<T>(String key, Future<T> Function() run) {
    final running = _runningRequests[key];
    if (running != null) return running as Future<T>;
    final future = run();
    _runningRequests[key] = future;
    return future.whenComplete(() {
      if (identical(_runningRequests[key], future)) {
        _runningRequests.remove(key);
      }
    });
  }

  /// Fetches a book for a download and resolves what to send back.
  ///
  /// Archives with no Kindle format are converted into MOBI by
  /// [deliverDownloadedBook], the same helper the in-app download uses, so both
  /// paths save exactly the same file.
  Future<_DownloadedFile> _fetchForDownload({
    required Uri target,
    required String? title,
    required String? linkType,
    required String ip,
  }) async {
    final settings = settingsProvider();
    final client = OpdsClient(
      username: settings.username,
      password: settings.password,
    );
    try {
      final remote = await readRemoteBook(
        client: client,
        link: OpdsLink(href: target, type: linkType),
      );
      final book = await deliverDownloadedBook(
        bytes: remote.bytes,
        url: remote.url,
        title: title,
        mime: remote.mime,
        contentEncoding: remote.contentEncoding,
        ip: ip,
        log: log,
        languageCode: L10n.languageCode,
      );
      return _DownloadedFile(
        bytes: book.bytes,
        url: book.url,
        mime: book.mime,
        contentEncoding: book.contentEncoding,
      );
    } finally {
      client.close();
    }
  }

  /// Reads a local file for a download and resolves what to send back.
  Future<_DownloadedFile> _fetchLocalDownload({
    required Uri uri,
    required String? title,
    required String declared,
    required String ip,
  }) async {
    final bytes = await _localStorage.read(
      uri.toString(),
      maxBytes: maxDeliveryBytes,
    );
    if (bytes.isEmpty) throw LocalStorageException(l10n.opdsEmptyFile);

    final book = await deliverDownloadedBook(
      bytes: bytes,
      url: uri,
      title: title,
      mime: declared,
      ip: ip,
      log: log,
      languageCode: L10n.languageCode,
    );
    return _DownloadedFile(
      bytes: book.bytes,
      url: book.url,
      mime: book.mime,
      contentEncoding: book.contentEncoding,
    );
  }

  Future<void> _localSend(HttpRequest request, {required bool headOnly}) async {
    final file = _localFile(request);
    if (file == null) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.localFolderBadLink),
        headOnly: headOnly,
      );
      return;
    }

    final settings = settingsProvider();
    if (!settings.hasKindleEmail) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.kindleAddressMissing),
        headOnly: headOnly,
      );
      return;
    }

    if (headOnly) {
      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.html;
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      await response.close();
      return;
    }

    if (!settings.smtpConfigured) {
      await _openLocalMailApp(
        request,
        settings: settings,
        file: file,
        headOnly: headOnly,
      );
      return;
    }

    final job = _mailQueue.enqueueLocal(
      localUri: file.uri.toString(),
      title: file.title,
      mime: file.type,
      retryHref: _retryHref(request),
    );
    log(l10n.mailQueuedLog(job.displayTitle, _clientIp(request)));
    await _page(
      request,
      HttpStatus.ok,
      renderMailPage(job, kindleEmail: settings.kindleEmail),
      headOnly: headOnly,
    );
  }

  /// Writes a local book into the share cache and opens the mail app.
  Future<void> _openLocalMailApp(
    HttpRequest request, {
    required AppSettings settings,
    required ({Uri uri, String? title, String? type}) file,
    required bool headOnly,
  }) async {
    final share = _shareFile;
    if (share == null) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.sendUnavailable, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
      return;
    }
    if (_canShare != null && !_canShare()) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.appNotOpenMailApp, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
      return;
    }

    Directory? requestDir;
    var keepFile = false;
    try {
      final bytes = await _localStorage.read(
        file.uri.toString(),
        maxBytes: _maxShareBytes,
      );
      if (bytes.isEmpty) throw LocalStorageException(l10n.opdsEmptyFile);
      final book = resolveBook(
        bytes,
        purpose: BookPurpose.email,
        maxBytes: KindleMailer.maxAttachmentBytes,
      );
      final mime = book.mime ?? _effectiveMime(null, file.type);
      final fileName = fileNameFor(
        url: file.uri,
        title: file.title,
        mime: mime,
      );
      final base = await _shareDirectory();
      final dirName = DateTime.now().microsecondsSinceEpoch.toString();
      requestDir = Directory('${base.path}${Platform.pathSeparator}$dirName');
      await requestDir.create(recursive: true);
      final target = File(
        '${requestDir.path}${Platform.pathSeparator}$fileName',
      );
      await target.writeAsBytes(book.bytes, flush: true);

      final displayTitle = (file.title ?? '').trim().isEmpty
          ? fileName
          : file.title!.trim();
      log(
        book.extracted
            ? l10n.mailAppFromZipLog(displayTitle, _clientIp(request))
            : l10n.mailAppLog(displayTitle, _clientIp(request)),
      );
      await share(target, displayTitle, mime, settings.kindleEmail);
      keepFile = true;
      await _page(
        request,
        HttpStatus.ok,
        renderSharePage(title: displayTitle, kindleEmail: settings.kindleEmail),
        headOnly: headOnly,
      );
    } on ShareException catch (error) {
      if (!keepFile) await _deleteDirectoryQuietly(requestDir);
      log(l10n.mailPrepareErrorLog(error.message));
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(error.message, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
    } on BookArchiveException catch (error) {
      if (!keepFile) await _deleteDirectoryQuietly(requestDir);
      log(l10n.mailPrepareErrorLog(error.message));
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(error.message, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
    } on LocalStorageException catch (error) {
      if (!keepFile) await _deleteDirectoryQuietly(requestDir);
      log(l10n.mailPrepareErrorLog(error.message));
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(error.message, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
    } catch (error) {
      if (!keepFile) await _deleteDirectoryQuietly(requestDir);
      log(l10n.mailPrepareErrorLog('$error'));
      await _page(
        request,
        HttpStatus.badGateway,
        renderErrorPage(
          l10n.prepareFileFailed('$error'),
          retryHref: _retryHref(request),
        ),
        headOnly: headOnly,
      );
    }
  }

  Future<void> _download(HttpRequest request, {required bool headOnly}) async {
    final target = _target(request);
    if (target == null) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.badFileAddress),
        headOnly: headOnly,
      );
      return;
    }

    final title = request.uri.queryParameters['n'];
    final linkType = request.uri.queryParameters['t'];

    // Do not download the whole book just to answer a HEAD probe.
    if (headOnly) {
      final mime = downloadMime(remoteType: null, linkType: linkType);
      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.set(HttpHeaders.contentTypeHeader, mime);
      response.headers.set(
        'content-disposition',
        contentDispositionFor(title: title, url: target, mime: mime),
      );
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      await response.close();
      return;
    }

    var streaming = false;
    try {
      final downloaded = await _once(
        'download:${request.uri}',
        () => _fetchForDownload(
          target: target,
          title: title,
          linkType: linkType,
          ip: _clientIp(request),
        ),
      );

      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.set(HttpHeaders.contentTypeHeader, downloaded.mime);
      response.headers.set(
        'content-disposition',
        contentDispositionFor(
          title: title,
          url: downloaded.url,
          mime: downloaded.mime,
        ),
      );
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      response.contentLength = downloaded.bytes.length;
      final encoding = downloaded.contentEncoding;
      if (encoding != null) {
        response.headers.set(HttpHeaders.contentEncodingHeader, encoding);
      }
      streaming = true;
      response.add(downloaded.bytes);
      await response.close();
      return;
    } on BookArchiveException catch (error) {
      log(l10n.requestErrorLog(request.uri.toString(), error.message));
      if (!streaming) {
        await _page(
          request,
          HttpStatus.badRequest,
          renderErrorPage(error.message, retryHref: _retryHref(request)),
          headOnly: headOnly,
        );
      } else {
        await _closeQuietly(request.response);
      }
    } on EpubConversionException catch (error) {
      log(l10n.requestErrorLog(request.uri.toString(), error.message));
      if (!streaming) {
        await _page(
          request,
          HttpStatus.badRequest,
          renderErrorPage(error.message, retryHref: _retryHref(request)),
          headOnly: headOnly,
        );
      } else {
        await _closeQuietly(request.response);
      }
    } on OpdsException catch (error) {
      log(l10n.requestErrorLog(request.uri.toString(), error.message));
      if (!streaming) {
        await _page(
          request,
          HttpStatus.badGateway,
          renderErrorPage(error.message, retryUrl: target),
          headOnly: headOnly,
        );
      } else {
        await _closeQuietly(request.response);
      }
    } catch (error) {
      if (!streaming) {
        log(l10n.requestErrorLog(request.uri.toString(), '$error'));
        await _page(
          request,
          HttpStatus.badGateway,
          renderErrorPage(l10n.fileTransferFailed('$error')),
          headOnly: headOnly,
        );
      } else {
        log(l10n.fileTransferInterrupted('$error'));
        await _closeQuietly(request.response);
      }
    }
  }

  /// Downloads a book and opens the phone's mail app with it attached.
  ///
  /// Used when a Kindle address is configured but SMTP is not: the address is
  /// prefilled in the mail app and the user only has to send the letter.
  Future<void> _openMailApp(
    HttpRequest request, {
    required AppSettings settings,
    required Uri target,
    required String? title,
    required String? linkType,
    required bool headOnly,
  }) async {
    final share = _shareFile;
    if (share == null) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.sendUnavailable, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
      return;
    }

    if (_canShare != null && !_canShare()) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.appNotOpenMailApp, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
      return;
    }

    // A HEAD probe must not download the book or open a mail app.
    if (headOnly) {
      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.html;
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      await response.close();
      return;
    }

    final client = OpdsClient(
      username: settings.username,
      password: settings.password,
    );

    Directory? requestDir;
    var keepFile = false;
    try {
      final remote = await client.openDownload(target);
      final remoteMime = remote.response.headers.contentType?.mimeType;
      if (remoteMime == 'text/html' &&
          (linkType == null || !linkType.contains('html'))) {
        await remote.response.drain<void>();
        throw OpdsException(l10n.opdsHtmlInsteadOfFile);
      }

      final contentEncoding = remote.response.headers.value(
        HttpHeaders.contentEncodingHeader,
      );
      final encoded = contentEncoding != null && contentEncoding.isNotEmpty;

      final iterator = StreamIterator<List<int>>(remote.response);
      try {
        // Some servers send a ZIP archive even when the link says EPUB/FB2.
        // Peek first, then either unpack it or stream it to a temp file.
        final head = BytesBuilder(copy: false);
        while (head.length < 4 && await iterator.moveNext()) {
          head.add(iterator.current);
        }
        final headBytes = head.takeBytes();

        BookContent? resolved;
        if (!encoded && looksLikeZip(headBytes)) {
          final builder = BytesBuilder(copy: false)..add(headBytes);
          while (await iterator.moveNext()) {
            builder.add(iterator.current);
            if (builder.length > _maxShareBytes) {
              throw OpdsException(l10n.tooLargeToEmail);
            }
          }
          resolved = resolveBook(
            builder.takeBytes(),
            purpose: BookPurpose.email,
            maxBytes: KindleMailer.maxAttachmentBytes,
          );
        }

        final effectiveMime =
            resolved?.mime ?? _effectiveMime(remoteMime, linkType);
        final fileName = fileNameFor(
          url: remote.url,
          title: title,
          mime: effectiveMime,
        );
        final base = await _shareDirectory();
        final dirName = DateTime.now().microsecondsSinceEpoch.toString();
        requestDir = Directory('${base.path}${Platform.pathSeparator}$dirName');
        await requestDir.create(recursive: true);
        final file = File(
          '${requestDir.path}${Platform.pathSeparator}$fileName',
        );

        var written = 0;
        if (resolved != null) {
          written = resolved.bytes.length;
          await file.writeAsBytes(resolved.bytes, flush: true);
        } else {
          final sink = file.openWrite();
          try {
            if (headBytes.isNotEmpty) {
              written += headBytes.length;
              sink.add(headBytes);
            }
            while (await iterator.moveNext()) {
              written += iterator.current.length;
              if (written > _maxShareBytes) {
                throw OpdsException(l10n.tooLargeToEmail);
              }
              sink.add(iterator.current);
            }
            await sink.flush();
          } finally {
            await sink.close();
          }
        }
        if (written == 0) {
          throw OpdsException(l10n.opdsEmptyFile);
        }

        final displayTitle = (title ?? '').trim().isEmpty
            ? fileName
            : title!.trim();
        log(
          resolved?.extracted == true
              ? l10n.mailAppFromZipLog(displayTitle, _clientIp(request))
              : l10n.mailAppLog(displayTitle, _clientIp(request)),
        );
        await share(file, displayTitle, effectiveMime, settings.kindleEmail);
        keepFile = true;
        await _page(
          request,
          HttpStatus.ok,
          renderSharePage(
            title: displayTitle,
            kindleEmail: settings.kindleEmail,
          ),
          headOnly: headOnly,
        );
      } finally {
        await iterator.cancel();
      }
    } on ShareException catch (error) {
      if (!keepFile) await _deleteDirectoryQuietly(requestDir);
      log(l10n.mailPrepareErrorLog(error.message));
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(error.message, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
    } on BookArchiveException catch (error) {
      if (!keepFile) await _deleteDirectoryQuietly(requestDir);
      log(l10n.mailPrepareErrorLog(error.message));
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(error.message, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
    } on OpdsException catch (error) {
      if (!keepFile) await _deleteDirectoryQuietly(requestDir);
      log(l10n.mailPrepareErrorLog(error.message));
      await _page(
        request,
        HttpStatus.badGateway,
        renderErrorPage(error.message, retryHref: _retryHref(request)),
        headOnly: headOnly,
      );
    } catch (error) {
      if (!keepFile) await _deleteDirectoryQuietly(requestDir);
      log(l10n.mailPrepareErrorLog('$error'));
      await _page(
        request,
        HttpStatus.badGateway,
        renderErrorPage(
          l10n.prepareFileFailed('$error'),
          retryHref: _retryHref(request),
        ),
        headOnly: headOnly,
      );
    } finally {
      client.close();
    }
  }

  Future<void> _sendToKindle(
    HttpRequest request, {
    required bool headOnly,
  }) async {
    final target = _target(request);
    if (target == null) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.badBookAddress),
        headOnly: headOnly,
      );
      return;
    }

    final settings = settingsProvider();
    if (!settings.hasKindleEmail) {
      await _page(
        request,
        HttpStatus.badRequest,
        renderErrorPage(l10n.kindleAddressMissing),
        headOnly: headOnly,
      );
      return;
    }

    final title = request.uri.queryParameters['n'];
    final linkType = request.uri.queryParameters['t'];

    // A HEAD probe must not send a real letter.
    if (headOnly) {
      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.html;
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      await response.close();
      return;
    }

    // Without SMTP klos cannot send the letter itself, so it prepares the file
    // and hands it to the phone's mail app with the Kindle address filled in.
    if (!settings.smtpConfigured) {
      await _openMailApp(
        request,
        settings: settings,
        target: target,
        title: title,
        linkType: linkType,
        headOnly: headOnly,
      );
      return;
    }

    final job = _mailQueue.enqueue(url: target, title: title, mime: linkType);
    log(l10n.mailQueuedLog(job.displayTitle, _clientIp(request)));
    await _page(
      request,
      HttpStatus.ok,
      renderMailPage(job, kindleEmail: settings.kindleEmail),
      headOnly: headOnly,
    );
  }

  Future<void> _mailStatus(
    HttpRequest request, {
    required bool headOnly,
  }) async {
    final segments = request.uri.pathSegments;
    final id = segments.length >= 2 ? segments[1] : '';
    final job = _mailQueue.byId(id);
    if (job == null) {
      await _page(
        request,
        HttpStatus.notFound,
        renderNotFoundPage(),
        headOnly: headOnly,
      );
      return;
    }
    await _page(
      request,
      HttpStatus.ok,
      renderMailPage(job, kindleEmail: settingsProvider().kindleEmail),
      headOnly: headOnly,
    );
  }

  Future<void> _runMailJob(MailJob job) async {
    final settings = settingsProvider();
    if (!settings.emailConfigured) {
      job.fail(l10n.mailNotConfiguredShort);
      log(l10n.mailSkippedLog);
      return;
    }

    job.startDownloading();
    log(l10n.mailDownloadLog(job.displayTitle));

    if (job.source == MailJobSource.local) {
      final uri = job.localUri;
      final root = settings.localFolderUri;
      if (uri == null || !LocalStorage.isUnder(root, uri)) {
        job.fail(l10n.localFolderBadLink);
        log(l10n.mailErrorLog(l10n.localFolderBadLink));
        return;
      }
      try {
        final bytes = await _localStorage.read(uri, maxBytes: maxDeliveryBytes);
        if (bytes.isEmpty) throw LocalStorageException(l10n.opdsEmptyFile);
        final book = resolveBook(
          bytes,
          purpose: BookPurpose.email,
          maxBytes: KindleMailer.maxAttachmentBytes,
        );
        final mime = book.mime ?? _effectiveMime(null, job.mime);
        await _mailer.sendBookBytes(
          settings: settings,
          bytes: book.bytes,
          title: job.title,
          mime: mime,
          onSending: job.startSending,
        );
        job.succeed();
        log(l10n.mailSentLog(job.displayTitle, settings.kindleEmail));
      } catch (error) {
        final message = KindleMailer.describeError(error);
        job.fail(message);
        log(l10n.mailErrorLog(message));
      }
      return;
    }

    try {
      final url = job.url;
      if (url == null) {
        job.fail(l10n.mailNotConfiguredShort);
        log(l10n.mailSkippedLog);
        return;
      }
      await _mailer.sendBook(
        settings: settings,
        url: url,
        title: job.title,
        mime: job.mime,
        onSending: job.startSending,
      );
      job.succeed();
      log(l10n.mailSentLog(job.displayTitle, settings.kindleEmail));
    } catch (error) {
      final message = KindleMailer.describeError(error);
      job.fail(message);
      log(l10n.mailErrorLog(message));
    }
  }

  Future<void> _help(HttpRequest request, {required bool headOnly}) async {
    final host = request.headers.value(HttpHeaders.hostHeader);
    final address = host == null || host.isEmpty ? null : 'http://$host/';
    await _page(
      request,
      HttpStatus.ok,
      renderHelpPage(serverAddress: address),
      headOnly: headOnly,
    );
  }

  Uri? _target(HttpRequest request) {
    final raw = request.uri.queryParameters['u'];
    if (raw == null) return null;
    return decodeTarget(raw);
  }

  Future<void> _page(
    HttpRequest request,
    int status,
    String html, {
    bool headOnly = false,
  }) async {
    final bytes = utf8.encode(html);
    final response = request.response;
    response.statusCode = status;
    response.headers.contentType = ContentType.html;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.contentLength = bytes.length;
    if (!headOnly) response.add(bytes);
    await response.close();
  }

  static Future<void> _closeQuietly(HttpResponse response) async {
    try {
      await response.close();
    } catch (_) {
      // The response may already be closed.
    }
  }

  static String _clientIp(HttpRequest request) {
    return request.connectionInfo?.remoteAddress.address ?? '?';
  }

  static String? _retryHref(HttpRequest request) {
    final value = request.uri.toString();
    return value.isEmpty ? null : value;
  }

  static String _effectiveMime(String? remoteMime, String? declared) {
    final remote = remoteMime?.split(';').first.trim();
    if (remote != null &&
        remote.isNotEmpty &&
        remote != 'application/octet-stream') {
      return remote;
    }
    final declaredType = declared?.split(';').first.trim();
    if (declaredType != null && declaredType.isNotEmpty) {
      return declaredType;
    }
    return 'application/octet-stream';
  }

  static Future<void> _deleteDirectoryQuietly(Directory? directory) async {
    if (directory == null) return;
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (_) {
      // A leftover cache directory is harmless.
    }
  }
}

/// A file ready to be written as a download response.
class _DownloadedFile {
  const _DownloadedFile({
    required this.bytes,
    required this.url,
    required this.mime,
    this.contentEncoding,
  });

  final Uint8List bytes;
  final Uri url;
  final String mime;
  final String? contentEncoding;
}
