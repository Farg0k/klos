import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/l10n/l10n.dart';
import 'package:klos/server/proxy_server.dart';

void main() {
  setUpAll(() async {
    await L10n.use(const Locale('uk'));
  });

  late List<String> logs;
  late HttpClient client;

  setUp(() {
    logs = [];
    client = HttpClient();
  });

  tearDown(() => client.close(force: true));

  Future<void> get(OpdsProxyServer proxy, String path) async {
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${proxy.port}$path'),
    );
    final response = await request.close();
    await response.drain<void>();
  }

  /// Server that stops after [timeout] without a request.
  OpdsProxyServer build(Duration timeout, {required void Function() onStop}) {
    final proxy = OpdsProxyServer(
      settingsProvider: () => const AppSettings(catalogUrl: null),
      log: logs.add,
      idleTimeout: () => timeout,
      onAutoStopped: onStop,
    );
    addTearDown(proxy.stop);
    return proxy;
  }

  test('stops itself when no request arrives before the timeout', () async {
    var stopped = 0;
    final proxy = build(
      const Duration(milliseconds: 100),
      onStop: () => stopped++,
    );
    await proxy.start(port: 0, addresses: const ['127.0.0.1']);

    await get(proxy, '/');
    expect(proxy.isRunning, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(proxy.isRunning, isFalse);
    expect(stopped, 1);
  });

  test('keeps running while requests keep coming', () async {
    var stopped = 0;
    final proxy = build(
      const Duration(milliseconds: 300),
      onStop: () => stopped++,
    );
    await proxy.start(port: 0, addresses: const ['127.0.0.1']);

    for (var i = 0; i < 3; i++) {
      await get(proxy, '/');
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    expect(proxy.isRunning, isTrue);
    expect(stopped, 0);
  });

  test('never stops while the timeout is off', () async {
    var stopped = 0;
    final proxy = OpdsProxyServer(
      settingsProvider: () =>
          const AppSettings(catalogUrl: null, autoStopMinutes: 0),
      log: logs.add,
      onAutoStopped: () => stopped++,
    );
    addTearDown(proxy.stop);
    await proxy.start(port: 0, addresses: const ['127.0.0.1']);

    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(proxy.isRunning, isTrue);
    expect(stopped, 0);
  });

  test('a changed timeout applies without a restart', () async {
    var stopped = 0;
    final proxy = build(
      const Duration(milliseconds: 100),
      onStop: () => stopped++,
    );
    await proxy.start(port: 0, addresses: const ['127.0.0.1']);

    await get(proxy, '/');
    proxy.refreshIdleTimer();

    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(proxy.isRunning, isFalse);
    expect(stopped, 1);
  });
}
