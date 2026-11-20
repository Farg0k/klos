import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/platform/screen_wakelock.dart';
import 'package:klos/services/server_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(ScreenWakelock.reset);

  /// Service that binds the local server to loopback on a free port.
  ServerService buildService() => ServerService(
    addressLoader: () async => const [
      LocalAddress(interfaceName: 'wlan0', address: '127.0.0.1'),
    ],
  );

  test('holds the wake lock only while the server runs', () async {
    final calls = <bool>[];
    ScreenWakelock.useDriver((enabled) async => calls.add(enabled));

    final service = buildService();
    addTearDown(service.dispose);
    await service.init(
      AppSettings(
        catalogUrl: Uri.parse('http://127.0.0.1:9/opds'),
        port: 0,
        keepAwake: true,
      ),
    );
    expect(ScreenWakelock.isEnabled, isFalse);

    await service.startServer();
    expect(service.isRunning, isTrue);
    expect(ScreenWakelock.isEnabled, isTrue);

    await service.stopServer();
    expect(service.isRunning, isFalse);
    expect(ScreenWakelock.isEnabled, isFalse);
    expect(calls, [true, false]);
  });

  test('does not lock the screen when the setting is off', () async {
    final calls = <bool>[];
    ScreenWakelock.useDriver((enabled) async => calls.add(enabled));

    final service = buildService();
    addTearDown(service.dispose);
    await service.init(
      AppSettings(catalogUrl: Uri.parse('http://127.0.0.1:9/opds'), port: 0),
    );

    await service.startServer();
    expect(service.isRunning, isTrue);
    expect(calls, isEmpty);

    await service.stopServer();
  });

  test(
    'releases the wake lock when the setting is turned off while running',
    () async {
      ScreenWakelock.useDriver((enabled) async {});

      final service = buildService();
      addTearDown(service.dispose);
      await service.init(
        AppSettings(
          catalogUrl: Uri.parse('http://127.0.0.1:9/opds'),
          port: 0,
          keepAwake: true,
        ),
      );

      await service.startServer();
      expect(ScreenWakelock.isEnabled, isTrue);

      await service.applySettings(
        AppSettings(
          catalogUrl: Uri.parse('http://127.0.0.1:9/opds'),
          port: 0,
          keepAwake: false,
        ),
      );
      expect(service.isRunning, isTrue);
      expect(ScreenWakelock.isEnabled, isFalse);

      await service.stopServer();
    },
  );
}
