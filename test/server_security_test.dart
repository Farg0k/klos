import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/l10n/l10n.dart';
import 'package:klos/server/proxy_server.dart';
import 'package:klos/server/server_auth.dart';

typedef _Reply = ({int status, String body, HttpHeaders headers});

void main() {
  setUpAll(() async {
    await L10n.use(const Locale('uk'));
  });

  late List<String> logs;
  late HttpClient client;
  late OpdsProxyServer proxy;
  var requirePin = true;
  var pinChanges = 0;

  setUp(() async {
    logs = [];
    pinChanges = 0;
    requirePin = true;
    proxy = OpdsProxyServer(
      settingsProvider: () =>
          AppSettings(catalogUrl: null, requirePin: requirePin),
      log: logs.add,
      onPinChanged: () => pinChanges++,
    );
    await proxy.start(port: 0, addresses: const ['127.0.0.1']);
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await proxy.stop();
  });

  Future<_Reply> get(String path, {String? cookie}) async {
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${proxy.port}$path'),
    );
    if (cookie != null) {
      request.headers.set(HttpHeaders.cookieHeader, cookie);
    }
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    return (status: response.statusCode, body: body, headers: response.headers);
  }

  Future<_Reply> post(String path, Map<String, String> fields) async {
    final request = await client.postUrl(
      Uri.parse('http://127.0.0.1:${proxy.port}$path'),
    );
    request.followRedirects = false;
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    request.write(
      fields.entries
          .map(
            (entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}',
          )
          .join('&'),
    );
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    return (status: response.statusCode, body: body, headers: response.headers);
  }

  /// A PIN that is guaranteed to be wrong (the real code never starts with 0).
  String wrongPin(String pin) => pin == '0000' ? '1111' : '0000';

  /// Signs a device in and returns its cookie header.
  Future<String> unlock() async {
    final reply = await post('/unlock', {'pin': proxy.currentPin!});
    expect(reply.status, HttpStatus.seeOther);
    final raw = reply.headers.value(HttpHeaders.setCookieHeader) ?? '';
    final token = RegExp(r'klos_session=([^;]+)').firstMatch(raw)?.group(1);
    expect(token, isNotNull);
    return 'klos_session=$token';
  }

  test('asks for the PIN before showing anything', () async {
    final reply = await get('/');

    expect(reply.status, HttpStatus.ok);
    expect(reply.body, contains(l10n.pinPageTitle));
    expect(reply.body, contains('action="/unlock"'));
    expect(reply.body, isNot(contains(l10n.notConfiguredBody)));
    expect(reply.headers.value('x-frame-options'), 'DENY');
    expect(reply.headers.value('x-content-type-options'), 'nosniff');
  });

  test('serves the favicon without the PIN', () async {
    final reply = await get('/icon.svg');

    expect(reply.status, HttpStatus.ok);
    expect(reply.headers.contentType?.mimeType, 'image/svg+xml');
  });

  test('rejects a wrong PIN and accepts the right one', () async {
    final oldPin = proxy.currentPin!;

    final wrong = await post('/unlock', {'pin': wrongPin(oldPin)});
    expect(wrong.status, HttpStatus.ok);
    expect(wrong.body, contains(l10n.pinWrong));
    expect(wrong.headers.value(HttpHeaders.setCookieHeader), isNull);

    final ok = await post('/unlock', {'pin': oldPin});
    expect(ok.status, HttpStatus.seeOther);
    expect(ok.headers.value(HttpHeaders.locationHeader), '/');
    expect(ok.headers.value(HttpHeaders.setCookieHeader), contains('HttpOnly'));

    final raw = ok.headers.value(HttpHeaders.setCookieHeader) ?? '';
    final token = RegExp(r'klos_session=([^;]+)').firstMatch(raw)?.group(1);
    expect(token, isNotNull);

    final home = await get('/', cookie: 'klos_session=$token');
    expect(home.status, HttpStatus.ok);
    expect(home.body, contains(l10n.notConfiguredBody));
    expect(home.body, isNot(contains(l10n.pinPageTitle)));
  });

  test('returns to the requested page after unlocking', () async {
    final login = await get('/help');
    expect(login.body, contains('value="/help"'));

    final ok = await post('/unlock', {
      'pin': proxy.currentPin!,
      'next': '/help',
    });

    expect(ok.status, HttpStatus.seeOther);
    expect(ok.headers.value(HttpHeaders.locationHeader), '/help');
  });

  test('never redirects to another host', () async {
    for (final target in ['http://evil.example', '//evil.example']) {
      final ok = await post('/unlock', {
        'pin': proxy.currentPin!,
        'next': target,
      });
      expect(ok.status, HttpStatus.seeOther);
      expect(ok.headers.value(HttpHeaders.locationHeader), '/');
    }
  });

  test('blocks a device after repeated wrong PINs', () async {
    final wrong = wrongPin(proxy.currentPin!);

    for (var attempt = 0; attempt < 5; attempt++) {
      final reply = await post('/unlock', {'pin': wrong});
      expect(reply.status, HttpStatus.ok);
      expect(reply.body, contains(l10n.pinWrong));
    }

    final blocked = await post('/unlock', {'pin': wrong});
    expect(blocked.status, HttpStatus.tooManyRequests);
    expect(blocked.body, contains(l10n.pinBlocked));
    expect(blocked.headers.value(HttpHeaders.retryAfterHeader), isNotNull);
  });

  test('replaces the PIN after too many failures', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () =>
          const AppSettings(catalogUrl: null, requirePin: true),
      log: logs.add,
      auth: ServerAuth(maxFailures: 3),
      onPinChanged: () => pinChanges++,
    );
    await proxy.start(port: 0, addresses: const ['127.0.0.1']);

    final oldPin = proxy.currentPin!;
    final wrong = wrongPin(oldPin);
    for (var attempt = 0; attempt < 3; attempt++) {
      await post('/unlock', {'pin': wrong});
    }

    expect(proxy.currentPin, isNot(oldPin));
    expect(pinChanges, 1);
  });

  test('signs devices out when the PIN is replaced', () async {
    final cookie = await unlock();
    expect(
      (await get('/', cookie: cookie)).body,
      contains(l10n.notConfiguredBody),
    );

    proxy.refreshPin();

    final after = await get('/', cookie: cookie);
    expect(after.body, contains(l10n.pinPageTitle));
    expect(after.body, isNot(contains(l10n.notConfiguredBody)));
  });

  test('has no PIN while protection is off', () async {
    requirePin = false;

    expect(proxy.currentPin, isNull);
    final reply = await get('/');
    expect(reply.body, contains(l10n.notConfiguredBody));
    expect(reply.body, isNot(contains(l10n.pinPageTitle)));
  });

  test('treats a forged cookie as signed out', () async {
    final reply = await get('/', cookie: 'klos_session=not-a-real-token');

    expect(reply.body, contains(l10n.pinPageTitle));
  });
}
