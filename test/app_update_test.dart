import 'package:flutter_test/flutter_test.dart';
import 'package:klos/platform/app_update.dart';

Map<String, dynamic> _asset(String name) => {
  'name': name,
  'browser_download_url':
      'https://github.com/Farg0k/klos/releases/download/'
      'v1.0.1/$name',
};

Map<String, dynamic> _release({
  String tag = 'v1.0.1',
  String body = 'Fixed the release build',
  List<String> assets = const [
    'app-arm64-v8a-release.apk',
    'app-armeabi-v7a-release.apk',
    'app-x86_64-release.apk',
    'app-release.apk',
  ],
}) => {
  'tag_name': tag,
  'body': body,
  'assets': [for (final name in assets) _asset(name)],
};

void main() {
  group('parseRelease', () {
    test('reports a newer release with its notes', () {
      final update = AppUpdateService.parseRelease(
        _release(),
        abis: const ['arm64-v8a'],
        currentVersion: '1.0.0',
      );

      expect(update, isNotNull);
      expect(update!.version, '1.0.1');
      expect(update.assetName, 'app-arm64-v8a-release.apk');
      expect(update.downloadUrl, contains('v1.0.1/app-arm64-v8a-release.apk'));
      expect(update.notes, 'Fixed the release build');
    });

    test('returns null when the installed version is current or newer', () {
      expect(
        AppUpdateService.parseRelease(
          _release(tag: 'v1.0.0'),
          abis: const ['arm64-v8a'],
          currentVersion: '1.0.0',
        ),
        isNull,
      );
      expect(
        AppUpdateService.parseRelease(
          _release(tag: 'v1.0.0'),
          abis: const ['arm64-v8a'],
          currentVersion: '1.0.1',
        ),
        isNull,
      );
      // 1.0.10 is newer than 1.0.9; a plain string compare would be wrong.
      expect(
        AppUpdateService.parseRelease(
          _release(tag: 'v1.0.10'),
          abis: const ['arm64-v8a'],
          currentVersion: '1.0.9',
        ),
        isNotNull,
      );
    });

    test('strips the v prefix and keeps releases without notes', () {
      final update = AppUpdateService.parseRelease(
        _release(tag: 'v2.0.0', body: '  '),
        abis: const ['arm64-v8a'],
        currentVersion: '1.9.9',
      );

      expect(update!.version, '2.0.0');
      expect(update.notes, isEmpty);
    });

    test('returns null when the repository has no release yet', () {
      expect(
        AppUpdateService.parseRelease(
          null,
          abis: const [],
          currentVersion: '1.0.0',
        ),
        isNull,
      );
    });

    test('picks the split APK of the phone', () {
      for (final entry in {
        'arm64-v8a': 'app-arm64-v8a-release.apk',
        'armeabi-v7a': 'app-armeabi-v7a-release.apk',
        'x86_64': 'app-x86_64-release.apk',
      }.entries) {
        final update = AppUpdateService.parseRelease(
          _release(),
          abis: [entry.key],
          currentVersion: '1.0.0',
        );
        expect(update!.assetName, entry.value);
      }
    });

    test('uses the universal APK for an unknown ABI', () {
      final update = AppUpdateService.parseRelease(
        _release(),
        abis: const ['riscv64'],
        currentVersion: '1.0.0',
      );

      expect(update!.assetName, 'app-release.apk');
    });

    test('prefers the first ABI the platform reports', () {
      final update = AppUpdateService.parseRelease(
        _release(),
        abis: const ['x86_64', 'arm64-v8a'],
        currentVersion: '1.0.0',
      );

      expect(update!.assetName, 'app-x86_64-release.apk');
    });

    test('ignores non-APK assets', () {
      final json = _release(assets: const ['app-arm64-v8a-release.apk']);
      (json['assets'] as List<dynamic>).insert(0, _asset('notes.txt'));

      final update = AppUpdateService.parseRelease(
        json,
        abis: const ['arm64-v8a'],
        currentVersion: '1.0.0',
      );

      expect(update!.assetName, 'app-arm64-v8a-release.apk');
    });

    test('fails when the release has no APK at all', () {
      expect(
        () => AppUpdateService.parseRelease(
          _release(assets: const ['notes.txt']),
          abis: const ['arm64-v8a'],
          currentVersion: '1.0.0',
        ),
        throwsA(
          isA<UpdateException>().having(
            (error) => error.problem,
            'problem',
            UpdateProblem.noApk,
          ),
        ),
      );
    });
  });

  group('check', () {
    test('skips the network when the installed version is unknown', () async {
      var calls = 0;
      final service = AppUpdateService(
        fetchRelease: () async {
          calls++;
          return _release();
        },
      );

      await expectLater(
        service.check(currentVersion: ' '),
        throwsA(
          isA<UpdateException>().having(
            (error) => error.problem,
            'problem',
            UpdateProblem.unknownVersion,
          ),
        ),
      );
      expect(calls, 0);
    });

    test('asks GitHub once and compares the tag', () async {
      var calls = 0;
      final service = AppUpdateService(
        fetchRelease: () async {
          calls++;
          return _release(tag: 'v1.2.3');
        },
      );

      final update = await service.check(
        currentVersion: '1.2.2',
        abis: const ['arm64-v8a'],
      );

      expect(calls, 1);
      expect(update!.version, '1.2.3');
    });
  });

  test('normalizeAbis keeps the order and drops duplicates', () {
    expect(
      AppUpdateService.normalizeAbis(const [
        'arm64-v8a',
        ' arm64-v8a ',
        '',
        'armeabi-v7a',
      ]),
      ['arm64-v8a', 'armeabi-v7a'],
    );
  });
}
