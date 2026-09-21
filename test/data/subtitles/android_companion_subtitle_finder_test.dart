import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/data/subtitles/android_companion_subtitle_finder.dart';
import 'package:gee_player/domain/media/local_media.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.gee.player/media_library');
  const media = LocalMedia(
    id: 'video:12',
    kind: MediaKind.video,
    uri: 'content://media/external/video/media/12',
    fileName: 'Movie.2024.mkv',
    folderPath: 'Movies/',
  );

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('requests matching sidecar in the video folder', () async {
    MethodCall? request;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          request = call;
          return {
            'name': 'Movie.2024.sw.srt',
            'bytes': Uint8List.fromList([1, 2]),
          };
        });
    final result = await const AndroidCompanionSubtitleFinder().find(media, [
      'SW',
      'EN',
    ]);
    expect(request?.method, 'findCompanionSubtitle');
    expect(request?.arguments['folderPath'], 'Movies/');
    expect(result?.name, 'Movie.2024.sw.srt');
    expect(result?.bytes, [1, 2]);
  });

  test('returns no match when the Android bridge is unavailable', () async {
    expect(
      await const AndroidCompanionSubtitleFinder().find(media, ['EN']),
      isNull,
    );
  });
}
