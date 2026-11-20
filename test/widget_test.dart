import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/features/about/licenses_page.dart';
import 'package:klos/features/favorites_screen/favorites_screen.dart';
import 'package:klos/features/home_screen/components/addresses_card.dart';
import 'package:klos/main.dart';
import 'package:klos/platform/app_info.dart';
import 'package:klos/platform/screen_wakelock.dart';
import 'package:klos/theme/app_theme.dart';

import 'helpers/test_locator.dart';

Future<FakeObjectBoxService> _pumpApp(
  WidgetTester tester, {
  AppSettings? settings,
}) async {
  final storage = await setUpTestLocator(settings: settings);
  addTearDown(tearDownTestLocator);
  await tester.pumpWidget(const KlosApp());
  await tester.pumpAndSettle();
  return storage;
}

/// Scrolls the home list until [finder] is built and visible.
///
/// The home screen is a [ListView], so cards below the fold are not built
/// until the list actually scrolls.
Future<void> _scrollHome(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(ListView),
    const Offset(0, -120),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // The version plugin has no implementation in tests, so give every test a
    // stable app version unless it asks for another one.
    AppInfo.useLoader(
      () async => const AppInfo(
        version: '1.0.0',
        buildNumber: '1',
        packageName: 'com.example.klos',
      ),
    );
  });

  testWidgets('shows the server state and app settings in English', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Server is stopped'), findsOneWidget);
    expect(find.text('Start server'), findsOneWidget);
    expect(find.text('Kindle address'), findsOneWidget);

    await _scrollHome(tester, find.text('Server settings'));
    expect(find.text('Server settings'), findsOneWidget);
    expect(find.text('No address added yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Keep the screen on'), findsOneWidget);
    expect(find.text('Changes are saved automatically.'), findsOneWidget);

    // The note sits below the cards, so scroll it into view first.
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The catalog, port, folder and Kindle delivery are set up on '
        'the main screen.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens the server settings in a bottom sheet', (tester) async {
    await _pumpApp(tester);

    final catalogTile = find.text('OPDS catalog');
    await _scrollHome(tester, catalogTile);
    await tester.tap(catalogTile);
    await tester.pumpAndSettle();

    expect(find.text('Catalog address'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Check'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Catalog address'), findsNothing);
  });

  testWidgets('saves the catalog address typed in the sheet', (tester) async {
    final storage = await _pumpApp(tester);

    final catalogTile = find.text('OPDS catalog');
    await _scrollHome(tester, catalogTile);
    await tester.tap(catalogTile);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      '192.168.1.20:8080/opds',
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(
      storage.settings.catalogUrl,
      Uri.parse('http://192.168.1.20:8080/opds'),
    );

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('http://192.168.1.20:8080/opds'), findsOneWidget);
  });

  testWidgets('shows the Ukrainian translation for a uk locale', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('uk')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await _pumpApp(tester);

    expect(find.text('Сервер зупинено'), findsOneWidget);
    expect(find.text('Запустити сервер'), findsOneWidget);
    expect(find.text('Адреса для Kindle'), findsOneWidget);

    await _scrollHome(tester, find.text('Налаштування сервера'));
    expect(find.text('Налаштування сервера'), findsOneWidget);
    expect(find.text('Адресу ще не додано'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Мова'), findsOneWidget);
    expect(find.text('Тема'), findsOneWidget);
    expect(find.text('Зміни зберігаються автоматично.'), findsOneWidget);
  });

  testWidgets('overrides the system locale with a language setting', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await _pumpApp(
      tester,
      settings: const AppSettings(
        catalogUrl: null,
        language: AppLanguage.ukrainian,
      ),
    );

    expect(find.text('Сервер зупинено'), findsOneWidget);
    expect(find.text('Server is stopped'), findsNothing);
  });

  testWidgets('builds the dark theme when the setting is on', (tester) async {
    await _pumpApp(
      tester,
      settings: const AppSettings(
        catalogUrl: null,
        themeMode: AppThemeMode.dark,
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, AppTheme.brand);
    expect(theme.appBarTheme.backgroundColor, AppTheme.brand);
    expect(theme.appBarTheme.foregroundColor, Colors.white);
  });

  testWidgets('uses the brand colour in the light theme', (tester) async {
    await _pumpApp(
      tester,
      settings: const AppSettings(
        catalogUrl: null,
        themeMode: AppThemeMode.light,
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);

    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppTheme.brand);
    expect(theme.appBarTheme.backgroundColor, AppTheme.brand);
  });

  testWidgets('follows the system theme by default', (tester) async {
    await _pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('uses the dark theme on auto when the system is dark', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await _pumpApp(tester);

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('keeps the wake lock off while the server is stopped', (
    tester,
  ) async {
    final calls = <bool>[];
    ScreenWakelock.useDriver((enabled) async => calls.add(enabled));
    addTearDown(ScreenWakelock.reset);

    await _pumpApp(
      tester,
      settings: const AppSettings(catalogUrl: null, keepAwake: true),
    );

    expect(ScreenWakelock.isEnabled, isFalse);
    expect(calls, isEmpty);
  });

  testWidgets('saves the wake lock switch in the app settings', (tester) async {
    final calls = <bool>[];
    ScreenWakelock.useDriver((enabled) async => calls.add(enabled));
    addTearDown(ScreenWakelock.reset);

    final storage = await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(storage.settings.keepAwake, isTrue);
    // The wake lock only turns on while the server runs, so it stays off here.
    expect(calls, isEmpty);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(storage.settings.keepAwake, isFalse);
  });

  testWidgets('saves the PIN switch and explains where the code appears', (
    tester,
  ) async {
    final storage = await _pumpApp(tester);

    final serverTile = find.text('Local server');
    await _scrollHome(tester, serverTile);
    await tester.tap(serverTile);
    await tester.pumpAndSettle();

    final switchTitle = find.text('PIN protection');
    await tester.ensureVisible(switchTitle);
    await tester.pumpAndSettle();

    await tester.tap(switchTitle);
    await tester.pumpAndSettle();
    expect(storage.settings.requirePin, isTrue);
    expect(
      find.text('The code appears here after the server starts.'),
      findsOneWidget,
    );

    await tester.tap(switchTitle);
    await tester.pumpAndSettle();
    expect(storage.settings.requirePin, isFalse);
    expect(find.text('PIN code'), findsNothing);
  });

  testWidgets('asks for the catalog address from the library card', (
    tester,
  ) async {
    await _pumpApp(tester);

    final browseTile = find.text('Browse catalog');
    await _scrollHome(tester, browseTile);
    await tester.tap(browseTile);
    await tester.pumpAndSettle();

    expect(find.text('Catalog address'), findsOneWidget);
  });

  testWidgets('opens the favorites from the library card', (tester) async {
    await _pumpApp(tester);

    final favoritesTile = find.text('Favorites');
    await _scrollHome(tester, favoritesTile);
    await tester.tap(favoritesTile);
    await tester.pumpAndSettle();

    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(
      find.text(
        'No saved books yet. Open the catalog and tap the bookmark next to '
        'a book you want.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps the refresh button in the Kindle address card', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.refresh),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(AddressesCard),
        matching: find.byIcon(Icons.refresh),
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens the help in a bottom sheet', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('How to connect a Kindle'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.textContaining('Favorites are the books'), findsOneWidget);

    await tester.ensureVisible(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('How to connect a Kindle'), findsNothing);
  });

  testWidgets('shows the app version and opens the licences', (tester) async {
    AppInfo.useLoader(
      () async => const AppInfo(
        version: '9.9.9',
        buildNumber: '42',
        packageName: 'com.example.klos',
      ),
    );
    addTearDown(AppInfo.reset);
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks([
        'klos_sample',
      ], 'Sample licence.');
    });

    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    final aboutTile = find.text('About the app');
    await tester.scrollUntilVisible(
      aboutTile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Version 9.9.9 (42)'), findsOneWidget);

    await tester.tap(aboutTile);
    await tester.pumpAndSettle();

    expect(find.text('9.9.9'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('com.example.klos'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('klos_sample'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Full licence texts'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensesPage), findsOneWidget);
    final sample = find.descendant(
      of: find.byType(LicensesPage),
      matching: find.text('klos_sample'),
    );
    expect(sample, findsOneWidget);

    await tester.tap(sample);
    await tester.pumpAndSettle();
    expect(find.text('Sample licence.'), findsOneWidget);
  });
}
