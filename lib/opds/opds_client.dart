import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../l10n/l10n.dart';
import 'opds_feed.dart';
import 'opds2_feed.dart';

class OpdsException implements Exception {
  OpdsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Text response together with the effective URL (after redirects).
class FetchedText {
  const FetchedText({required this.url, required this.body});

  final Uri url;
  final String body;
}

class RemoteDownload {
  const RemoteDownload({required this.response, required this.url});

  final HttpClientResponse response;
  final Uri url;
}

/// Small OPDS client with optional HTTP Basic authentication.
class OpdsClient {
  OpdsClient({this.username = '', this.password = ''}) {
    _feedClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..userAgent = 'klos/1.0';
    _downloadClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 60)
      ..autoUncompress = false
      ..userAgent = 'klos/1.0';
  }

  static const int _maxFeedBytes = 32 * 1024 * 1024;

  final String username;
  final String password;

  late final HttpClient _feedClient;
  late final HttpClient _downloadClient;

  void close() {
    _feedClient.close(force: true);
    _downloadClient.close(force: true);
  }

  Future<OpdsFeed> fetchFeed(Uri url) async {
    final text = await fetchText(url);
    try {
      if (_looksLikeJson(text.body)) {
        return parseOpds2(text.body, text.url);
      }
      return OpdsFeed.parse(text.body, text.url);
    } on FormatException catch (error) {
      throw OpdsException(l10n.opdsParseFailed(error.message));
    }
  }

  /// OPDS 2.0 serves JSON (`application/opds+json`). Sniffing the body is more
  /// reliable than the content type, because some servers send `text/plain`.
  static bool _looksLikeJson(String body) {
    final trimmed = body.replaceFirst(RegExp(r'^\uFEFF'), '').trimLeft();
    return trimmed.startsWith('{');
  }

  Future<FetchedText> fetchText(Uri url) async {
    final response = await _get(
      _feedClient,
      url,
      accept: 'application/atom+xml,application/xml;q=0.9,*/*;q=0.5',
      timeout: const Duration(seconds: 45),
    );
    final effectiveUrl = _effectiveUrl(url, response.redirects);

    final builder = BytesBuilder(copy: false);
    try {
      await for (final chunk in response) {
        builder.add(chunk);
        if (builder.length > _maxFeedBytes) {
          throw OpdsException(l10n.opdsResponseTooLarge);
        }
      }
    } on IOException catch (error) {
      throw OpdsException(l10n.opdsReadFailed('$error'));
    }

    final bytes = builder.takeBytes();
    final charset = response.headers.contentType?.charset?.toLowerCase();
    String body;
    final encoding = charset == null ? null : Encoding.getByName(charset);
    try {
      body = (encoding ?? utf8).decode(bytes);
    } on FormatException {
      body = utf8.decode(bytes, allowMalformed: true);
    }

    return FetchedText(url: effectiveUrl, body: body);
  }

  Future<RemoteDownload> openDownload(Uri url) async {
    final response = await _get(
      _downloadClient,
      url,
      accept: '*/*',
      timeout: const Duration(seconds: 60),
    );
    return RemoteDownload(
      response: response,
      url: _effectiveUrl(url, response.redirects),
    );
  }

  /// Downloads a small binary resource, such as a cover thumbnail.
  ///
  /// The client keeps the HTTP Basic credentials, so covers behind a login
  /// work exactly like the feed itself.
  Future<Uint8List> fetchBytes(
    Uri url, {
    int maxBytes = 8 * 1024 * 1024,
  }) async {
    final response = await _get(
      _feedClient,
      url,
      accept: 'image/*,*/*;q=0.5',
      timeout: const Duration(seconds: 30),
    );

    final builder = BytesBuilder(copy: false);
    try {
      await for (final chunk in response) {
        builder.add(chunk);
        if (builder.length > maxBytes) {
          throw OpdsException(l10n.opdsResponseTooLarge);
        }
      }
    } on IOException catch (error) {
      throw OpdsException(l10n.opdsReadFailed('$error'));
    }
    return builder.takeBytes();
  }

  Future<HttpClientResponse> _get(
    HttpClient client,
    Uri url, {
    required String accept,
    required Duration timeout,
  }) async {
    if (url.scheme != 'http' && url.scheme != 'https') {
      throw OpdsException(l10n.onlyHttpAddresses);
    }

    HttpClientRequest request;
    try {
      request = await client.getUrl(url).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw OpdsException(l10n.opdsTimeout);
    } on HandshakeException catch (error) {
      throw OpdsException(l10n.tlsError(error.message));
    } on SocketException catch (error) {
      throw OpdsException(l10n.opdsConnectFailed(error.message));
    } on IOException catch (error) {
      throw OpdsException(l10n.connectionError('$error'));
    }

    request.headers.set(HttpHeaders.acceptHeader, accept);
    _authorize(request);

    HttpClientResponse response;
    try {
      response = await request.close().timeout(timeout);
    } on TimeoutException {
      request.abort();
      throw OpdsException(l10n.opdsTimeout);
    } on IOException catch (error) {
      throw OpdsException(l10n.connectionError('$error'));
    }

    final status = response.statusCode;
    if (status == HttpStatus.unauthorized || status == HttpStatus.forbidden) {
      await _drain(response);
      throw OpdsException(l10n.opdsAccessDenied(status));
    }
    if (status < 200 || status >= 300) {
      await _drain(response);
      throw OpdsException(l10n.opdsHttpStatus(status));
    }
    return response;
  }

  void _authorize(HttpClientRequest request) {
    if (username.isEmpty && password.isEmpty) return;
    final token = base64.encode(utf8.encode('$username:$password'));
    request.headers.set(HttpHeaders.authorizationHeader, 'Basic $token');
  }

  static Future<void> _drain(HttpClientResponse response) async {
    try {
      await response.drain<void>();
    } catch (_) {
      // The response may already be aborted; nothing else to do.
    }
  }

  static Uri _effectiveUrl(Uri original, List<RedirectInfo> redirects) {
    var current = original;
    for (final redirect in redirects) {
      current = current.resolveUri(redirect.location);
    }
    return current;
  }
}
