import 'package:equatable/equatable.dart';

/// Interface language selected in the settings.
///
/// [system] follows the phone locale; the other values force a language.
enum AppLanguage {
  system(''),
  english('en'),
  ukrainian('uk');

  const AppLanguage(this.code);

  /// Language code stored in ObjectBox; empty for [system].
  final String code;

  static AppLanguage fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return system;
  }
}

/// Theme selected in the settings.
///
/// [system] follows the phone's light or dark mode; the other values force
/// one theme regardless of the system setting.
enum AppThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.code);

  /// Value stored in ObjectBox.
  final String code;

  static AppThemeMode fromCode(String? code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return system;
  }
}

/// Immutable app configuration.
class AppSettings extends Equatable {
  const AppSettings({
    required this.catalogUrl,
    this.username = '',
    this.password = '',
    this.port = defaultPort,
    this.autoStart = false,
    this.autoStopMinutes = defaultAutoStopMinutes,
    this.keepAwake = false,
    this.requirePin = false,
    this.showCovers = true,
    this.language = AppLanguage.system,
    this.themeMode = AppThemeMode.system,
    this.kindleEmail = '',
    this.smtpHost = '',
    this.smtpPort = defaultSmtpPort,
    this.smtpUsername = '',
    this.smtpPassword = '',
    this.senderEmail = '',
    this.smtpSsl = false,
    this.localFolderUri = '',
    this.localFolderName = '',
  });

  static const int defaultPort = 8080;
  static const int defaultSmtpPort = 587;

  /// Minutes without a request after which the server stops on its own.
  ///
  /// 0 turns the automatic stop off and keeps the server on until it is
  /// stopped by hand.
  static const int defaultAutoStopMinutes = 10;

  /// Values offered in the settings for the automatic stop.
  static const List<int> autoStopMinutesOptions = [0, 5, 10, 30, 60];

  static const AppSettings initial = AppSettings(catalogUrl: null);

  /// Send to Kindle domain used when the address has none.
  ///
  /// Amazon uses `@kindle.com` in most regions, but a few keep a local Kindle
  /// domain such as `@kindle.co.uk` or `@kindle.de`.
  static const String defaultKindleDomain = '@kindle.com';

  static final RegExp _kindleDomain = RegExp(
    r'^@kindle\.[a-z]+(\.[a-z]+)*$',
    caseSensitive: false,
  );

  /// Whether [domain] (including the leading `@`) is an Amazon Kindle domain.
  static bool isKindleDomain(String domain) {
    final value = domain.trim();
    return value == defaultKindleDomain || _kindleDomain.hasMatch(value);
  }

  /// Rewrites a Kindle address so its domain is always an Amazon one.
  ///
  /// The part before the `@` is kept as the name, but any other domain (a
  /// typo or a value left from an older entry) is replaced with
  /// [defaultKindleDomain], so the saved address can never point at a
  /// non-Kindle domain.
  static String normalizeKindleEmail(String value) {
    final text = value.trim();
    final at = text.indexOf('@');
    if (at <= 0) return text;
    final name = text.substring(0, at).trim();
    if (name.isEmpty) return text;
    final domain = text.substring(at).trim();
    return name + (isKindleDomain(domain) ? domain : defaultKindleDomain);
  }

  /// Remote OPDS catalog address, or null when it was not configured yet.
  final Uri? catalogUrl;

  /// Optional HTTP Basic credentials for the remote OPDS server.
  final String username;
  final String password;

  /// Port of the local server that Kindle connects to.
  final int port;

  /// Start the local server automatically when the app opens.
  final bool autoStart;

  /// Stop the local server after this many minutes without a request.
  ///
  /// Keeps a forgotten server from sitting on the Wi-Fi network. 0 means the
  /// server keeps running until it is stopped by hand.
  final int autoStopMinutes;

  /// Keep the screen on while the local server runs.
  ///
  /// Some Android phones stop the local server when the screen turns off.
  /// The wake lock prevents that at the cost of a faster battery drain; it is
  /// released as soon as the server stops.
  final bool keepAwake;

  /// Ask the Kindle for a PIN before it can open the catalog.
  ///
  /// The PIN is generated on every server start and shown in the app; the
  /// Kindle keeps a session cookie after typing it once.
  final bool requirePin;

  /// Show book cover thumbnails in the catalog (when the OPDS feed has them).
  final bool showCovers;

  /// Language of the app interface.
  final AppLanguage language;

  /// Theme selected for the app: automatic, light or dark.
  final AppThemeMode themeMode;

  /// Kindle Send to Kindle address (for example `name@kindle.com`).
  final String kindleEmail;

  /// Outgoing SMTP server used to send books to Kindle.
  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String smtpPassword;

  /// Sender address. Amazon requires it to be in the approved list.
  final String senderEmail;

  /// Connect with implicit SSL (usually port 465). Otherwise STARTTLS.
  final bool smtpSsl;

  /// Persisted `content://` URI of the folder picked through SAF.
  ///
  /// Empty means no permission was granted yet. The settings still offer
  /// Downloads as the default folder, but Android requires an explicit
  /// confirmation before an app may read it.
  final String localFolderUri;

  /// Display name of [localFolderUri], shown in the app and on the server.
  final String localFolderName;

  bool get isConfigured => catalogUrl != null;

  /// Whether the local server has something the Kindle can open.
  ///
  /// The OPDS catalog and the local folder are independent sources. A folder
  /// with books is enough to start the server and browse it on the Kindle,
  /// even when no catalog address is set.
  bool get canServe => isConfigured || hasLocalFolder;

  /// Whether the server should stop by itself after being idle.
  bool get autoStopEnabled => autoStopMinutes > 0;

  /// Whether a local folder was connected and can be shown to the Kindle.
  bool get hasLocalFolder => localFolderUri.trim().isNotEmpty;

  /// Whether a valid Kindle address is known.
  ///
  /// The Send to Kindle action is shown when this is true. Without SMTP the
  /// phone's mail app is opened instead, so the address is all it needs.
  bool get hasKindleEmail => AppSettings.isValidEmail(kindleEmail);

  /// Whether a real SMTP server is ready to send letters automatically.
  bool get smtpConfigured =>
      smtpHost.trim().isNotEmpty && senderEmail.trim().isNotEmpty;

  /// Whether a letter can be sent automatically (SMTP + Kindle address).
  bool get emailConfigured => smtpConfigured && hasKindleEmail;

  /// Copy of these settings that points at another local folder.
  ///
  /// Used when the folder picker returns, so the choice takes effect
  /// immediately without saving unrelated fields.
  AppSettings withLocalFolder({required String uri, required String name}) {
    final cleanUri = uri.trim();
    return copyWith(
      localFolderUri: cleanUri,
      localFolderName: cleanUri.isEmpty ? '' : name.trim(),
    );
  }

  /// Copy of these settings with the given values replaced.
  ///
  /// [catalogUrl] is null when the catalog is not configured, so a plain
  /// nullable argument cannot mean "remove the address"; use
  /// [clearCatalogUrl] for that.
  AppSettings copyWith({
    Uri? catalogUrl,
    bool clearCatalogUrl = false,
    String? username,
    String? password,
    int? port,
    bool? autoStart,
    int? autoStopMinutes,
    bool? keepAwake,
    bool? requirePin,
    bool? showCovers,
    AppLanguage? language,
    AppThemeMode? themeMode,
    String? kindleEmail,
    String? smtpHost,
    int? smtpPort,
    String? smtpUsername,
    String? smtpPassword,
    String? senderEmail,
    bool? smtpSsl,
    String? localFolderUri,
    String? localFolderName,
  }) {
    return AppSettings(
      catalogUrl: clearCatalogUrl ? null : (catalogUrl ?? this.catalogUrl),
      username: username ?? this.username,
      password: password ?? this.password,
      port: port ?? this.port,
      autoStart: autoStart ?? this.autoStart,
      autoStopMinutes: autoStopMinutes ?? this.autoStopMinutes,
      keepAwake: keepAwake ?? this.keepAwake,
      requirePin: requirePin ?? this.requirePin,
      showCovers: showCovers ?? this.showCovers,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      kindleEmail: kindleEmail ?? this.kindleEmail,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      senderEmail: senderEmail ?? this.senderEmail,
      smtpSsl: smtpSsl ?? this.smtpSsl,
      localFolderUri: localFolderUri ?? this.localFolderUri,
      localFolderName: localFolderName ?? this.localFolderName,
    );
  }

  /// Normalizes user-provided input before it is stored.
  AppSettings normalized() {
    return AppSettings(
      catalogUrl: catalogUrl,
      username: username.trim(),
      password: password,
      port: port,
      autoStart: autoStart,
      autoStopMinutes: autoStopMinutesOptions.contains(autoStopMinutes)
          ? autoStopMinutes
          : defaultAutoStopMinutes,
      keepAwake: keepAwake,
      requirePin: requirePin,
      showCovers: showCovers,
      language: language,
      themeMode: themeMode,
      kindleEmail: normalizeKindleEmail(kindleEmail),
      smtpHost: smtpHost.trim(),
      smtpPort: smtpPort,
      smtpUsername: smtpUsername.trim(),
      smtpPassword: smtpPassword,
      senderEmail: senderEmail.trim(),
      smtpSsl: smtpSsl,
      localFolderUri: localFolderUri.trim(),
      localFolderName: localFolderUri.trim().isEmpty
          ? ''
          : localFolderName.trim(),
    );
  }

  static Uri? parseCatalogUrl(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;
    if (!text.contains('://')) {
      text = 'http://$text';
    }
    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.host.isEmpty) return null;
    return uri;
  }

  static bool isValidEmail(String input) {
    final value = input.trim();
    if (value.isEmpty) return false;
    if (value.contains(' ')) return false;
    final at = value.indexOf('@');
    if (at <= 0 || at != value.lastIndexOf('@')) return false;
    final domain = value.substring(at + 1);
    if (!domain.contains('.')) return false;
    if (domain.startsWith('.') || domain.endsWith('.')) return false;
    return true;
  }

  @override
  List<Object?> get props => [
    catalogUrl,
    username,
    password,
    port,
    autoStart,
    autoStopMinutes,
    keepAwake,
    requirePin,
    showCovers,
    language,
    themeMode,
    kindleEmail,
    smtpHost,
    smtpPort,
    smtpUsername,
    smtpPassword,
    senderEmail,
    smtpSsl,
    localFolderUri,
    localFolderName,
  ];
}
