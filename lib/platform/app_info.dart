import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Version data of the installed app, shown in «About».
@immutable
class AppInfo {
  const AppInfo({
    this.appName = 'klos',
    this.packageName = '',
    this.version = '',
    this.buildNumber = '',
  });

  /// App label as it appears on the phone.
  final String appName;

  /// Android application id, for example `com.example.klos`.
  final String packageName;

  /// Version name from `pubspec.yaml`, for example `1.0.0`.
  final String version;

  /// Version code (the `+1` in `pubspec.yaml`).
  final String buildNumber;

  /// `1.0.0 (1)`, or only the version when there is no build number.
  String get versionLabel =>
      buildNumber.isEmpty ? version : '$version ($buildNumber)';

  /// Reads the version from the platform.
  ///
  /// The result is cached, so the settings screen and the sheet do not ask the
  /// platform twice. A platform without the plugin falls back to an empty
  /// [AppInfo] instead of failing.
  static Future<AppInfo> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      return _cached = await _loader();
    } catch (error) {
      debugPrint('App info lookup failed: $error');
      return _cached = const AppInfo();
    }
  }

  /// Replaces the plugin call in tests.
  @visibleForTesting
  static void useLoader(AppInfoLoader? loader) {
    _loader = loader ?? _readPlatform;
    _cached = null;
  }

  /// Returns to the initial state; used between tests.
  @visibleForTesting
  static void reset() {
    _loader = _readPlatform;
    _cached = null;
  }

  static AppInfoLoader _loader = _readPlatform;
  static AppInfo? _cached;

  static Future<AppInfo> _readPlatform() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppInfo(
        appName: info.appName,
        packageName: info.packageName,
        version: info.version,
        buildNumber: info.buildNumber,
      );
    } on MissingPluginException {
      // Desktop and tests have no plugin; the caller shows empty fields.
      return const AppInfo();
    }
  }
}

/// Reads the app version from the running platform.
typedef AppInfoLoader = Future<AppInfo> Function();
