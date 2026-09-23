import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/app/playback_controller.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/data/playback/playback_source_resolver.dart';
import 'package:gee_player/domain/media/local_media.dart';

import '../support/fake_application_preferences.dart';

void main() {
  test('queue edits preserve the current track and its index', () async {
    final database = PlaybackDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = PlaybackController(
      database,
      const PlaybackSourceResolver(),
      applicationPreferences: FakeApplicationPreferences(),
    );
    addTearDown(() {
      controller.current = null;
      controller.dispose();
    });
    const one = LocalMedia(
      id: 'audio:one',
      kind: MediaKind.audio,
      uri: 'content://audio/one',
      fileName: 'One.mp3',
      folderPath: 'Music',
    );
    const two = LocalMedia(
      id: 'audio:two',
      kind: MediaKind.audio,
      uri: 'content://audio/two',
      fileName: 'Two.mp3',
      folderPath: 'Music',
    );
    const three = LocalMedia(
      id: 'audio:three',
      kind: MediaKind.audio,
      uri: 'content://audio/three',
      fileName: 'Three.mp3',
      folderPath: 'Music',
    );
    controller.queue = const [one, two, three];
    controller.index = 1;
    controller.current = two;

    expect(controller.reorderQueue(0, 2), isTrue);
    expect(controller.queue.map((item) => item.id), [two.id, three.id, one.id]);
    expect(controller.index, 0);
    expect(controller.current, same(two));

    expect(controller.removeQueueItem(2), isTrue);
    expect(controller.queue.map((item) => item.id), [two.id, three.id]);
    expect(controller.removeQueueItem(0), isFalse);

    expect(controller.reorderQueue(0, 1), isTrue);
    expect(controller.queue.map((item) => item.id), [three.id, two.id]);
    expect(controller.index, 1);
  });
}
