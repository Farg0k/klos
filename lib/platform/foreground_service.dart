import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

/// Keeps the process alive while the local server is running.
///
/// The actual foreground service is implemented in Kotlin
/// (`ServerService`), because a Dart HTTP server would otherwise be
/// suspended when the screen turns off.
class ForegroundService {
  static const MethodChannel _channel = MethodChannel('klos/foreground');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> start({required int port}) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('start', {
        'port': port,
        'channelName': l10n.notificationChannelName,
        'channelDescription': l10n.notificationChannelDescription,
        'text': port > 0
            ? l10n.notificationRunningPort(port)
            : l10n.notificationRunning,
      });
    } on MissingPluginException {
      // Running on a platform without the native implementation.
    } on PlatformException catch (error) {
      debugPrint('Foreground service start failed: ${error.message}');
    }
  }

  static Future<void> stop() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // Running on a platform without the native implementation.
    } on PlatformException catch (error) {
      debugPrint('Foreground service stop failed: ${error.message}');
    }
  }
}
