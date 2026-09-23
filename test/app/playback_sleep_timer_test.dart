import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/app/playback_sleep_timer.dart';

void main() {
  test('sleep timer reports remaining time and invokes its callback', () async {
    final elapsed = Completer<void>();
    var callbackCount = 0;
    final timer = PlaybackSleepTimer(() async {
      callbackCount++;
      elapsed.complete();
    });
    addTearDown(timer.dispose);

    timer.schedule(const Duration(milliseconds: 20));

    expect(timer.active, isTrue);
    expect(timer.remaining, greaterThan(Duration.zero));
    await elapsed.future.timeout(const Duration(seconds: 1));
    expect(timer.active, isFalse);
    expect(callbackCount, 1);
  });

  test('cancel prevents the sleep callback', () async {
    var callbackCount = 0;
    final timer = PlaybackSleepTimer(() async => callbackCount++);
    addTearDown(timer.dispose);

    timer.schedule(const Duration(milliseconds: 20));
    timer.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(timer.active, isFalse);
    expect(callbackCount, 0);
  });
}
