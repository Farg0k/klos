import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'entity/app_settings.dart';
import 'features/favorites_screen/bloc/favorites_bloc.dart';
import 'features/home_screen/bloc/home_bloc.dart';
import 'features/home_screen/home_screen.dart';
import 'features/settings_screen/bloc/settings_bloc.dart';
import 'features/update/bloc/update_bloc.dart';
import 'generated/l10n.dart';
import 'l10n/l10n.dart';
import 'platform/app_info.dart';
import 'platform/app_update.dart';
import 'platform/foreground_service.dart';
import 'platform/screen_wakelock.dart';
import 'theme/app_theme.dart';
import 'utils/locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const KlosApp());
}

class KlosApp extends StatelessWidget {
  const KlosApp({super.key, this.updateService, this.updateInfoLoader});

  /// Replaces the GitHub check; tests use it to stay offline and to avoid the
  /// platform ABI channel, which has no implementation outside Android.
  final AppUpdateService? updateService;

  /// Replaces the installed-version lookup in the update check.
  final AppInfoLoader? updateInfoLoader;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsBloc()..add(const SettingsStarted()),
        ),
        BlocProvider(create: (_) => HomeBloc()..add(const HomeStarted())),
        BlocProvider(create: (_) => FavoritesBloc()),
        BlocProvider(
          create: (_) =>
              UpdateBloc(service: updateService, infoLoader: updateInfoLoader)
                ..add(const UpdateStarted()),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> with WidgetsBindingObserver {
  /// Settings already forwarded to [HomeBloc].
  ///
  /// [HomeBloc] reads the stored settings itself on start, so this only
  /// reacts to later edits made on the settings screen.
  AppSettings? _appliedSettings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final bloc = context.read<HomeBloc>();
    bloc.add(HomeResumedChanged(state == AppLifecycleState.resumed));
    if (state == AppLifecycleState.resumed) {
      unawaited(ScreenWakelock.reapply());
    }
    if (state == AppLifecycleState.detached) {
      ForegroundService.stop();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final settings = context.read<SettingsBloc>().state.settings;
    if (settings.language == AppLanguage.system) {
      L10n.apply(AppLanguage.system);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) => previous.settings != current.settings,
      listener: (context, state) {
        if (_appliedSettings == state.settings) return;
        _appliedSettings = state.settings;
        context.read<HomeBloc>().add(HomeSettingsChanged(state.settings));
      },
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (previous, current) =>
            previous.settings.language != current.settings.language ||
            previous.settings.themeMode != current.settings.themeMode,
        builder: (context, state) {
          final settings = state.settings;
          return MaterialApp(
            title: 'klos',
            debugShowCheckedModeBanner: false,
            locale: localeFor(settings.language),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _flutterThemeMode(settings.themeMode),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  /// Maps the saved theme choice to Flutter's [ThemeMode].
  static ThemeMode _flutterThemeMode(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
