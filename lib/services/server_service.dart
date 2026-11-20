import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../entity/app_settings.dart';
import '../entity/favorite.dart';
import '../l10n/l10n.dart';
import '../local/local_files.dart';
import '../local/local_storage.dart';
import '../mail/kindle_mailer.dart';
import '../opds/opds_client.dart';
import '../platform/foreground_service.dart';
import '../platform/screen_wakelock.dart';
import '../server/proxy_server.dart';
import '../share/share_service.dart';

class LocalAddress {
  const LocalAddress({required this.interfaceName, required this.address});

  final String interfaceName;
  final String address;

  String urlFor(int port) => 'http://$address:$port/';
}

class OpdsPreview {
  const OpdsPreview({
    required this.title,
    required this.entryCount,
    required this.hasNextPage,
  });

  final String title;
  final int entryCount;
  final bool hasNextPage;
}

/// Owns the HTTP server, the Android foreground service and the helpers the
/// settings screen calls (connection test, test letter, folder picker).
///
/// [HomeBloc] wraps this service and exposes it to the widget tree as BLoC
/// state. Settings themselves live in ObjectBox and are applied here through
/// [applySettings].
class ServerService extends ChangeNotifier {
  ServerService({
    LocalStorage? localStorage,
    Future<List<LocalAddress>> Function()? addressLoader,
    List<Favorite> Function()? favoritesProvider,
  }) : _localStorage = localStorage ?? const SafLocalStorage(),
       _addressLoader = addressLoader ?? _listLocalAddresses {
    _server = OpdsProxyServer(
      settingsProvider: () => settings,
      log: _addLog,
      shareFile: _shareToPhone,
      canShare: () => _resumed,
      localStorage: _localStorage,
      favoritesProvider: favoritesProvider,
      onPinChanged: _onPinChanged,
      onAutoStopped: _onAutoStopped,
    );
  }

  final LocalStorage _localStorage;
  final Future<List<LocalAddress>> Function() _addressLoader;
  late final OpdsProxyServer _server;
  final KindleMailer _mailer = KindleMailer();
  final ShareService _shareService = const ShareService();

  /// Interface names used by mobile data. The server must never listen there,
  /// otherwise the catalog would be reachable from the internet.
  static const List<String> _cellularInterfaces = [
    'rmnet',
    'ccmni',
    'pdp',
    'wwan',
    'cell',
  ];

  AppSettings settings = AppSettings.initial;
  List<LocalAddress> addresses = const [];

  final List<String> _logs = [];
  String? lastError;

  bool _busy = false;
  bool _disposed = false;
  bool _autoStartAttempted = false;
  bool _resumed = true;

  bool get busy => _busy;
  bool get isRunning => _server.isRunning;

  /// Whether the server has a catalog or a local folder to show.
  bool get canServe => settings.canServe;
  List<String> get logs => List.unmodifiable(_logs);

  /// PIN the Kindle has to type, or null when protection is off.
  String? get currentPin => _server.currentPin;

  /// Replaces the PIN and signs every Kindle out.
  void refreshPin() {
    _server.refreshPin();
  }

  /// Applies the settings loaded at startup.
  Future<void> init(AppSettings initialSettings) async {
    settings = initialSettings.normalized();
    await _refreshAddresses();
    await cleanupOldShares();
    _addLog(l10n.logAppStarted);
  }

  /// Called by the root widget when Android changes the app lifecycle state.
  void setResumed(bool value) {
    _resumed = value;
  }

  Future<void> maybeAutoStart() async {
    if (_autoStartAttempted) return;
    _autoStartAttempted = true;
    if (settings.autoStart && settings.canServe) {
      await startServer();
    }
  }

  Future<void> startServer() async {
    if (_busy || isRunning) return;
    if (!settings.canServe) {
      lastError = l10n.addCatalogFirst;
      _notify();
      return;
    }

    _busy = true;
    lastError = null;
    _notify();

    try {
      await _refreshAddresses();
      final binds = [for (final address in addresses) address.address];
      if (binds.isEmpty) {
        lastError = l10n.noIpAddress;
        _addLog(lastError!);
        return;
      }
      await _server.start(port: settings.port, addresses: binds);
      await ForegroundService.start(port: settings.port);
      await ScreenWakelock.setEnabled(settings.keepAwake);
      await _refreshAddresses();
      _addLog(l10n.logServerStarted(settings.port));
      final listening = _server.boundAddresses.toList()..sort();
      _addLog(l10n.logServerListening(listening.join(', ')));
    } on SocketException catch (error) {
      lastError = _portError(error, settings.port);
      _addLog(lastError!);
    } catch (error) {
      lastError = l10n.serverStartFailed('$error');
      _addLog(lastError!);
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> stopServer() async {
    if (_busy || !isRunning) return;

    _busy = true;
    _notify();

    try {
      await _server.stop();
      await ForegroundService.stop();
      await ScreenWakelock.setEnabled(false);
      _addLog(l10n.logServerStopped);
    } catch (error) {
      lastError = l10n.serverStopFailed('$error');
      _addLog(lastError!);
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// Applies settings saved by [SettingsBloc].
  ///
  /// Called on every settings change, so it only stops and starts the server
  /// when the port actually changed. This keeps auto-save from flickering the
  /// server on every toggle.
  Future<void> applySettings(AppSettings next) async {
    final normalized = next.normalized();
    final portChanged = settings.port != normalized.port;
    final restart = portChanged && isRunning;
    if (restart) await stopServer();

    settings = normalized;
    lastError = null;
    _server.refreshIdleTimer();
    await ScreenWakelock.setEnabled(isRunning && settings.keepAwake);
    await _refreshAddresses();
    _notify();

    if (restart) await startServer();
  }

  /// Sends a short test letter to verify the Kindle mail settings.
  Future<void> sendTestEmail(AppSettings draft) async {
    await _mailer.sendTest(draft.normalized());
    _addLog(l10n.logTestMailSent(draft.kindleEmail));
  }

  /// Opens Android's folder picker. Returns null when the user cancels.
  Future<LocalFolder?> pickLocalFolder() => _localStorage.pickFolder();

  /// Whether the persisted permission for [uri] is still usable.
  Future<bool> checkLocalFolder(String uri) => _localStorage.checkAccess(uri);

  /// Display name of a folder that was picked earlier.
  Future<String?> localFolderName(String uri) => _localStorage.folderName(uri);

  Future<void> _shareToPhone(
    File file,
    String title,
    String mime,
    String to,
  ) async {
    if (!_resumed) {
      throw ShareException(l10n.appNotOpen);
    }
    await _shareService.shareFile(file: file, title: title, mime: mime, to: to);
    _addLog(l10n.logMailApp(title));
  }

  Future<void> refreshAddresses() async {
    await _refreshAddresses();
    _notify();
  }

  Future<OpdsPreview> preview(AppSettings draft) async {
    final url = draft.catalogUrl;
    if (url == null) {
      throw OpdsException(l10n.catalogAddressRequired);
    }
    final client = OpdsClient(
      username: draft.username,
      password: draft.password,
    );
    try {
      final feed = await client.fetchFeed(url);
      return OpdsPreview(
        title: feed.title,
        entryCount: feed.entries.length,
        hasNextPage: feed.nextPage != null,
      );
    } finally {
      client.close();
    }
  }

  void clearLogs() {
    _logs.clear();
    _notify();
  }

  /// Called by the server when it replaces the PIN by itself.
  void _onPinChanged() {
    _addLog(l10n.logPinChanged);
  }

  /// Called by the server when it stopped itself after being idle.
  void _onAutoStopped() {
    unawaited(ForegroundService.stop());
    unawaited(ScreenWakelock.setEnabled(false));
    _addLog(l10n.logServerAutoStopped);
    unawaited(_refreshAddresses().then((_) => _notify()));
  }

  Future<void> _refreshAddresses() async {
    final found = <LocalAddress>[];
    try {
      found.addAll(await _addressLoader());
    } catch (error) {
      _addLog(l10n.ipLookupFailed('$error'));
    }

    found.sort((a, b) => _addressRank(b).compareTo(_addressRank(a)));

    // While the server runs it answers on the addresses it bound only, so
    // showing the others would offer links that cannot answer.
    final bound = _server.boundAddresses;
    if (bound.isNotEmpty) {
      found.removeWhere((item) => !bound.contains(item.address));
    }

    addresses = List.unmodifiable(found);
  }

  /// Reads the phone's IPv4 interfaces, skipping loopback and APIPA ones.
  static Future<List<LocalAddress>> _listLocalAddresses() async {
    final found = <LocalAddress>[];
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      if (_cellularInterfaces.any(name.contains)) continue;
      for (final address in interface.addresses) {
        if (address.address.startsWith('169.254.')) continue;
        found.add(
          LocalAddress(interfaceName: interface.name, address: address.address),
        );
      }
    }
    return found;
  }

  void _addLog(String message) {
    if (_disposed) return;
    final now = DateTime.now();
    final stamp = '${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}';
    _logs.insert(0, '[$stamp] $message');
    if (_logs.length > 80) _logs.removeLast();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static String _portError(SocketException error, int port) {
    final message = error.message.toLowerCase();
    final code = error.osError?.errorCode;
    if (message.contains('in use') || code == 98 || code == 10048) {
      return l10n.portInUse(port);
    }
    return l10n.serverStartFailed(error.message);
  }

  static int _addressRank(LocalAddress address) {
    final name = address.interfaceName.toLowerCase();
    var rank = 0;
    if (name.contains('wlan') || name.contains('wifi')) rank += 4;
    if (name.startsWith('en') || name.contains('eth')) rank += 2;
    if (address.address.startsWith('192.168.') ||
        address.address.startsWith('10.')) {
      rank += 1;
    }
    return rank;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    _disposed = true;
    _server.stop();
    super.dispose();
  }
}
