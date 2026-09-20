import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/data/media/android_media_repository.dart';
import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.gee.player/media_library');

  test('maps Android MediaStore rows and limited access', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'scan');
          return {
            'videoAccess': 'limited',
            'audioAccess': 'granted',
            'items': [
              {
                'id': 'video:42',
                'kind': 'video',
                'uri': 'content://media/external/video/media/42',
                'fileName': 'Trip.mp4',
                'folderPath': 'Movies/Trips',
                'durationMs': 125000,
                'sizeBytes': 3000000,
                'dateAddedMs': 1760000000000,
                'mimeType': 'video/mp4',
                'artist': null,
              },
              {
                'id': 'audio:7',
                'kind': 'audio',
                'uri': 'content://media/external/audio/media/7',
                'fileName': 'Song.mp3',
                'folderPath': 'Music/Album',
                'durationMs': 210000,
                'sizeBytes': 4000000,
                'dateAddedMs': null,
                'mimeType': 'audio/mpeg',
                'artist': 'Artist',
              },
            ],
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final snapshot = await AndroidMediaRepository(channel: channel)
        .loadLibrary();

    expect(snapshot.access.videos, MediaAccessLevel.limited);
    expect(snapshot.access.canReadVideos, isTrue);
    expect(snapshot.videos.single.title, 'Trip');
    expect(snapshot.videos.single.duration, const Duration(seconds: 125));
    expect(snapshot.music.single.artist, 'Artist');
    expect(snapshot.folders.map((folder) => folder.name), ['Album', 'Trips']);
  });

  test(
    'permission request preserves separate video and audio results',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'requestAccess');
            expect(call.arguments, {'kind': 'audio'});
            return {'videoAccess': 'denied', 'audioAccess': 'granted'};
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final access = await AndroidMediaRepository(channel: channel)
          .requestAccess(kind: MediaKind.audio);

      expect(access.canReadVideos, isFalse);
      expect(access.canReadAudio, isTrue);
    },
  );
}
