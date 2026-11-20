import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/l10n/l10n.dart';
import 'package:klos/server/proxy_server.dart';
import 'package:klos/services/server_service.dart';

void main() {
  setUpAll(() async {
    await L10n.use(const Locale('uk'));
  });

  late List<String> logs;
  late OpdsProxyServer proxy;
  late HttpClient client;

  setUp(() {
    logs = [];
    proxy = OpdsProxyServer(
      settingsProvider: () => const AppSettings(catalogUrl: null),
      log: logs.add,
    );
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await proxy.stop();
  });

  Future<int> get(String host, int port) async {
    final request = await client.getUrl(Uri.parse('http://$host:$port/'));
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  }

  group('loopback', () {
    test(
      'is always bound, so adb forward and the phone itself can connect',
      () async {
        await proxy.start(port: 0);

        expect(proxy.isRunning, isTrue);
        expect(proxy.boundAddresses, contains('127.0.0.1'));
        expect(await get('127.0.0.1', proxy.port!), HttpStatus.ok);
      },
    );

    test('is kept when the phone also has network addresses', () async {
      await proxy.start(port: 0, addresses: const ['127.0.0.2']);

      expect(proxy.boundAddresses, containsAll(['127.0.0.2', '127.0.0.1']));
      expect(await get('127.0.0.2', proxy.port!), HttpStatus.ok);
      expect(await get('127.0.0.1', proxy.port!), HttpStatus.ok);
    });
  });

  test('keeps serving when one address cannot be bound', () async {
    // TEST-NET-1 is never assigned to a local interface.
    await proxy.start(port: 0, addresses: const ['192.0.2.1']);

    expect(proxy.isRunning, isTrue);
    expect(proxy.boundAddresses, {'127.0.0.1'});
    expect(await get('127.0.0.1', proxy.port!), HttpStatus.ok);
    expect(logs, isNotEmpty);
  });

  test('does not listen twice', () async {
    await proxy.start(port: 0);
    final port = proxy.port;

    await proxy.start(port: 0);

    expect(proxy.port, port);
    expect(proxy.boundAddresses, hasLength(1));
  });

  group('ServerService', () {
    test('starts with only a local folder', () async {
      // The foreground service talks to Android; without this override the
      // test platform tries to reach a method channel that has no binding.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final service = ServerService(
        addressLoader: () async => const [
          LocalAddress(interfaceName: 'wlan0', address: '127.0.0.2'),
        ],
      );
      addTearDown(service.dispose);
      await service.init(
        const AppSettings(
          catalogUrl: null,
          localFolderUri: 'content://com.android.externalstorage.documents/tree/primary%3ABooks',
          localFolderName: 'Books',
          port: 0,
        ),
      );

      expect(service.canServe, isTrue);

      await service.startServer();

      expect(service.lastError, isNull);
      expect(service.isRunning, isTrue);

      await service.stopServer();
    });

    test('binds every address the app offers', () async {
      final service = ServerService(
        addressLoader: () async => const [
          LocalAddress(interfaceName: 'wlan0', address: '127.0.0.2'),
          LocalAddress(interfaceName: 'wlan1', address: '127.0.0.3'),
        ],
      );
      addTearDown(service.dispose);
      await service.init(
        AppSettings(catalogUrl: Uri.parse('http://127.0.0.1:9/opds'), port: 0),
      );

      await service.startServer();

      expect(service.isRunning, isTrue);
      expect(
        service.addresses.map((item) => item.address),
        containsAll(<String>['127.0.0.2', '127.0.0.3']),
      );

      await service.stopServer();
    });
  });
}
