import 'package:flutter_test/flutter_test.dart';
import 'package:klos/platform/screen_wakelock.dart';

void main() {
  tearDown(ScreenWakelock.reset);

  test('is off by default', () {
    expect(ScreenWakelock.isEnabled, isFalse);
  });

  test('turns the lock on and off once per change', () async {
    final calls = <bool>[];
    ScreenWakelock.useDriver((enabled) async => calls.add(enabled));

    await ScreenWakelock.setEnabled(true);
    await ScreenWakelock.setEnabled(true);
    await ScreenWakelock.setEnabled(false);
    await ScreenWakelock.setEnabled(false);

    expect(calls, [true, false]);
    expect(ScreenWakelock.isEnabled, isFalse);
  });

  test('reapplies the lock only while it is requested', () async {
    final calls = <bool>[];
    ScreenWakelock.useDriver((enabled) async => calls.add(enabled));

    await ScreenWakelock.reapply();
    await ScreenWakelock.setEnabled(true);
    await ScreenWakelock.reapply();

    expect(calls, [true, true]);
    expect(ScreenWakelock.isEnabled, isTrue);
  });

  test('survives a platform without the plugin', () async {
    ScreenWakelock.useDriver((enabled) async => throw StateError('no plugin'));

    await ScreenWakelock.setEnabled(true);

    expect(ScreenWakelock.isEnabled, isTrue);
  });
}
