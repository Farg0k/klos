import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/features/about/about_sheet.dart';
import 'package:klos/features/update/bloc/update_bloc.dart';
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

/// Builds the sheet with a bloc that answers from [release] instead of GitHub.
///
/// [startAutomatically] runs the launch check before the sheet is pumped, the
/// way the app does it, so the sheet opens on an already known release.
Future<void> _pumpSheet(
  WidgetTester tester,
  Future<Map<String, dynamic>?> Function() release, {
  String installed = '1.0.0',
  bool startAutomatically = false,
}) async {
  final bloc = UpdateBloc(
    service: AppUpdateService(
      fetchRelease: release,
      abisProvider: () async => const ['arm64-v8a'],
    ),
    infoLoader: () async => AppInfo(version: installed),
  );
  addTearDown(bloc.close);
  if (startAutomatically) bloc.add(const UpdateStarted());

  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(body: AboutSheet()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(AppInfo.reset);

  testWidgets('reports that the installed version is current', (tester) async {
    await _pumpSheet(tester, () async => _release('v1.0.0'));

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('You have the latest version.'), findsOneWidget);
  });

  testWidgets('offers the newer release with its notes', (tester) async {
    await _pumpSheet(tester, () async => _release('v1.2.0'));

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.0 is available'), findsOneWidget);
    expect(find.text('Notes for v1.2.0'), findsOneWidget);
    expect(find.text('Download and install'), findsOneWidget);
    expect(find.text('Check for updates'), findsNothing);
  });

  testWidgets('shows the release the launch check already found', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      () async => _release('v3.0.0'),
      installed: '1.0.0',
      startAutomatically: true,
    );

    expect(find.text('Version 3.0.0 is available'), findsOneWidget);
    expect(find.text('Download and install'), findsOneWidget);
  });

  testWidgets('shows the release notes as a list, not as Markdown', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      () async => {
        'tag_name': 'v4.0.0',
        'body':
            '## 4.0.0\n\n- Checks for updates at launch\n- **Faster** startup\n\n'
            '**Full Changelog**: https://github.com/Farg0k/klos/compare/x...y',
        'assets': [
          {
            'name': 'app-arm64-v8a-release.apk',
            'browser_download_url': 'https://x/app.apk',
          },
        ],
      },
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('Checks for updates at launch'), findsOneWidget);
    expect(find.text('Faster startup'), findsOneWidget);
    expect(find.text('4.0.0'), findsOneWidget);
    // The raw Markdown never reaches the screen.
    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('Full Changelog'), findsNothing);
  });

  testWidgets('explains a failed GitHub request', (tester) async {
    await _pumpSheet(
      tester,
      () async => throw UpdateException(UpdateProblem.github, '404'),
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('GitHub answered 404.'), findsOneWidget);
  });

  testWidgets('explains a release without a suitable APK', (tester) async {
    await _pumpSheet(
      tester,
      () async => {
        'tag_name': 'v2.0.0',
        'assets': [
          {'name': 'source.zip', 'browser_download_url': 'https://x/y.zip'},
        ],
      },
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(find.text('The release has no APK for this phone.'), findsOneWidget);
  });
}
