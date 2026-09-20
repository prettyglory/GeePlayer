import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/data/playback/playback_database.dart';

void main() {
  late PlaybackDatabase database;

  setUp(() => database = PlaybackDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('restores progress after saving and clears it at completion', () async {
    const duration = Duration(minutes: 10);
    expect(await database.positionFor('video:1'), isNull);

    await database.savePosition(
      'video:1',
      const Duration(minutes: 3),
      duration,
    );
    expect(await database.positionFor('video:1'), const Duration(minutes: 3));

    await database.savePosition(
      'video:1',
      const Duration(minutes: 9, seconds: 58),
      duration,
    );
    expect(await database.positionFor('video:1'), isNull);
  });

  test('does not offer a resume position for a brief preview', () async {
    await database.savePosition(
      'audio:1',
      const Duration(seconds: 3),
      const Duration(minutes: 3),
    );
    expect(await database.positionFor('audio:1'), isNull);
  });
}
