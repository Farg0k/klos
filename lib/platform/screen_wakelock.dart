import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Turns the wake lock on or off.
typedef WakelockDriver = Future<void> Function(bool enabled);

/// Keeps the screen awake while the local server should stay reachable.
///
/// Some phones stop the local server as soon as the screen turns off, and the
/// Kindle then loses the catalog. The wake lock keeps the screen on; it is a
/// setting because the screen never turns off and the battery drains faster.
class ScreenWakelock {
  ScreenWakelock._();

  static bool _enabled = false;
  static WakelockDriver _driver = _applyToPlugin;

  /// Whether the app currently asked for the wake lock.
  static bool get isEnabled => _enabled;

  /// Applies the choice made in the settings.
  ///
  /// Repeated calls with the same value do nothing, so every settings update
  /// can call it.
  static Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    await _apply();
  }

  /// Applies the last requested state again.
  ///
  /// Android can drop the screen flag while the app is in the background, so
  /// the app repeats the call when it comes back.
  static Future<void> reapply() => _enabled ? _apply() : Future<void>.value();

  /// Replaces the plugin call in tests.
  @visibleForTesting
  static void useDriver(WakelockDriver? driver) {
    _driver = driver ?? _applyToPlugin;
  }

  /// Returns to the initial state; used between tests.
  @visibleForTesting
  static void reset() {
    _enabled = false;
    _driver = _applyToPlugin;
  }

  static Future<void> _apply() async {
    try {
      await _driver(_enabled);
    } catch (error) {
      // A platform without the plugin still works, just without the lock.
      debugPrint('Wake lock change failed: $error');
    }
  }

  static Future<void> _applyToPlugin(bool enabled) =>
      enabled ? WakelockPlus.enable() : WakelockPlus.disable();
}
