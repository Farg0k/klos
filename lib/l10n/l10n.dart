import 'package:flutter/widgets.dart';

import '../entity/app_settings.dart';
import '../generated/l10n.dart';

/// Locale for [AppLanguage], or null when the system locale should be used.
Locale? localeFor(AppLanguage language) {
  switch (language) {
    case AppLanguage.system:
      return null;
    case AppLanguage.english:
      return const Locale('en');
    case AppLanguage.ukrainian:
      return const Locale('uk');
  }
}

/// Localized messages for code that runs outside the widget tree.
///
/// The HTTP server, background mail jobs and pure-Dart helpers have no
/// `BuildContext`, so they read [messages] (or the [l10n] shorthand) instead.
/// Until [apply] loads a translation the main-locale literals are returned,
/// which keeps unit tests working without any setup.
class L10n {
  L10n._();

  static S _messages = S();
  static Locale _locale = const Locale('en');

  static S get messages => _messages;

  /// Language code of the loaded messages (`en`, `uk`, ...).
  static String get languageCode => _locale.languageCode;

  /// Loads the translation for [locale], falling back to the main locale.
  static Future<void> use(Locale locale) async {
    final resolved = basicLocaleListResolution([
      locale,
    ], S.delegate.supportedLocales);
    _locale = resolved;
    _messages = await S.load(resolved);
  }

  /// Applies the language selected in the settings.
  static Future<void> apply(AppLanguage language) async {
    await use(localeFor(language) ?? _systemLocale);
  }

  static Locale get _systemLocale {
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    return locales.isEmpty ? const Locale('en') : locales.first;
  }
}

/// Shorthand for [L10n.messages].
S get l10n => L10n.messages;
