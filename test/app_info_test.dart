import 'package:flutter_test/flutter_test.dart';
import 'package:klos/platform/app_info.dart';

void main() {
  tearDown(AppInfo.reset);

  test('formats the version with the build number', () {
    expect(
      const AppInfo(version: '1.0.0', buildNumber: '1').versionLabel,
      '1.0.0 (1)',
    );
    expect(const AppInfo(version: '1.0.0').versionLabel, '1.0.0');
    expect(
      const AppInfo(version: '1.0.0', buildNumber: '').versionLabel,
      '1.0.0',
    );
  });

  test('reads the version once and reuses the result', () async {
    var calls = 0;
    AppInfo.useLoader(() async {
      calls++;
      return const AppInfo(version: '2.3.4', buildNumber: '7');
    });

    final first = await AppInfo.load();
    final second = await AppInfo.load();

    expect(first.versionLabel, '2.3.4 (7)');
    expect(second.versionLabel, '2.3.4 (7)');
    expect(calls, 1);
  });

  test('falls back to an empty version when the platform fails', () async {
    AppInfo.useLoader(() async => throw StateError('no plugin'));

    final info = await AppInfo.load();

    expect(info.version, isEmpty);
    expect(info.versionLabel, isEmpty);
  });
}
