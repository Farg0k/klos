import 'package:objectbox/objectbox.dart';

import 'app_settings.dart';

/// ObjectBox representation of [AppSettings].
///
/// [AppSettings] keeps a [Uri] and enums, which ObjectBox cannot store
/// directly, so this entity flattens them into text. It is the only class that
/// knows about the database layout; the rest of the app keeps using
/// [AppSettings].
@Entity()
class SettingsEntity {
  SettingsEntity({
    this.id = 0,
    this.catalogUrl = '',
    this.username = '',
    this.password = '',
    this.port = AppSettings.defaultPort,
    this.autoStart = false,
    this.autoStopMinutes = AppSettings.defaultAutoStopMinutes,
    this.keepAwake = false,
    this.requirePin = false,
    this.showCovers = true,
    this.language = '',
    this.themeMode = 'system',
    this.kindleEmail = '',
    this.smtpHost = '',
    this.smtpPort = AppSettings.defaultSmtpPort,
    this.smtpUsername = '',
    this.smtpPassword = '',
    this.senderEmail = '',
    this.smtpSsl = false,
    this.localFolderUri = '',
    this.localFolderName = '',
  });

  @Id()
  int id;

  /// Catalog address as text; empty when the catalog is not configured.
  String catalogUrl;

  String username;
  String password;
  int port;
  bool autoStart;

  /// [AppSettings.autoStopMinutes]: minutes, 0 turns the stop off.
  int autoStopMinutes;
  bool keepAwake;
  bool requirePin;
  bool showCovers;

  /// [AppLanguage.code].
  String language;

  /// [AppThemeMode.code].
  String themeMode;

  String kindleEmail;

  String smtpHost;
  int smtpPort;
  String smtpUsername;
  String smtpPassword;
  String senderEmail;
  bool smtpSsl;
  String localFolderUri;
  String localFolderName;

  factory SettingsEntity.fromSettings(AppSettings settings) {
    return SettingsEntity(
      catalogUrl: settings.catalogUrl?.toString() ?? '',
      username: settings.username,
      password: settings.password,
      port: settings.port,
      autoStart: settings.autoStart,
      autoStopMinutes: settings.autoStopMinutes,
      keepAwake: settings.keepAwake,
      requirePin: settings.requirePin,
      showCovers: settings.showCovers,
      language: settings.language.code,
      themeMode: settings.themeMode.code,
      kindleEmail: settings.kindleEmail,
      smtpHost: settings.smtpHost,
      smtpPort: settings.smtpPort,
      smtpUsername: settings.smtpUsername,
      smtpPassword: settings.smtpPassword,
      senderEmail: settings.senderEmail,
      smtpSsl: settings.smtpSsl,
      localFolderUri: settings.localFolderUri,
      localFolderName: settings.localFolderName,
    );
  }

  AppSettings toSettings() {
    return AppSettings(
      catalogUrl: AppSettings.parseCatalogUrl(catalogUrl),
      username: username,
      password: password,
      port: port >= 1024 && port <= 65535 ? port : AppSettings.defaultPort,
      autoStart: autoStart,
      autoStopMinutes:
          AppSettings.autoStopMinutesOptions.contains(autoStopMinutes)
          ? autoStopMinutes
          : AppSettings.defaultAutoStopMinutes,
      keepAwake: keepAwake,
      requirePin: requirePin,
      showCovers: showCovers,
      language: AppLanguage.fromCode(language),
      themeMode: AppThemeMode.fromCode(themeMode),
      kindleEmail: kindleEmail,
      smtpHost: smtpHost,
      smtpPort: smtpPort >= 1 && smtpPort <= 65535
          ? smtpPort
          : AppSettings.defaultSmtpPort,
      smtpUsername: smtpUsername,
      smtpPassword: smtpPassword,
      senderEmail: senderEmail,
      smtpSsl: smtpSsl,
      localFolderUri: localFolderUri,
      localFolderName: localFolderName,
    );
  }
}
