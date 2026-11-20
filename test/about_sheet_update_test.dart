import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/features/about/about_sheet.dart';
import 'package:klos/generated/l10n.dart';
import 'package:klos/platform/app_info.dart';
import 'package:klos/platform/app_update.dart';

Map<String, dynamic> _release(String tag) => {
  'tag_name': tag,
  'body': 'Notes for $tag',
  'assets': [
    {
      'name': 'app-release.apk',
      'browser_download_url':
          'https://github.com/Farg0k/klos/releases/download/$tag/app-release.apk',
    },
  ],
};

Future<void> _pumpSheet(WidgetTester tester, AppUpdateService updates) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: AboutSheet(updateService: updates)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AppInfo.useLoader(
      () async => const AppInfo(version: '1.0.0', buildNumber: '1'),
    );
  });

  tearDown(AppInfo.reset);

  testWidgets('reports that the installed version is current', (tester) async {
    await _pumpSheet(
      tester,
      AppUpdateService(
        fetchRelease: () async => _release('v1.0.0'),
        abisProvider: () async => const ['arm64-v8a'],
      ),
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('You have the latest version.'), findsOneWidget);
  });

  testWidgets('offers the newer release with its notes', (tester) async {
    await _pumpSheet(
      tester,
      AppUpdateService(
        fetchRelease: () async => _release('v1.2.0'),
        abisProvider: () async => const ['arm64-v8a'],
      ),
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.0 is available'), findsOneWidget);
    expect(find.text('Notes for v1.2.0'), findsOneWidget);
    expect(find.text('Download and install'), findsOneWidget);
    expect(find.text('Check for updates'), findsNothing);
  });

  testWidgets('explains a failed GitHub request', (tester) async {
    await _pumpSheet(
      tester,
      AppUpdateService(
        fetchRelease: () async =>
            throw UpdateException(UpdateProblem.github, '404'),
        abisProvider: () async => const ['arm64-v8a'],
      ),
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('GitHub answered 404.'), findsOneWidget);
  });

  testWidgets('explains a release without a suitable APK', (tester) async {
    await _pumpSheet(
      tester,
      AppUpdateService(
        fetchRelease: () async => {
          'tag_name': 'v2.0.0',
          'assets': [
            {'name': 'source.zip', 'browser_download_url': 'https://x/y.zip'},
          ],
        },
        abisProvider: () async => const ['arm64-v8a'],
      ),
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('The release has no APK for this phone.'), findsOneWidget);
  });
}
