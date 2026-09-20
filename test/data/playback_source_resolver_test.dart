import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/data/playback/playback_source_resolver.dart';
import 'package:gee_player/domain/media/local_media.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.gee.player/media_library');
  const media = LocalMedia(
    id: 'video:42',
    kind: MediaKind.video,
    uri: 'content://media/external/video/media/42',
    fileName: 'Trip.mp4',
    folderPath: 'Movies',
  );

  test('Android opens a file descriptor and releases it afterward', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'openPlayback') {
            expect(call.arguments, {'uri': media.uri});
            return 'fd://42';
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final source = await const PlaybackSourceResolver(
      channel: channel,
      platform: TargetPlatform.android,
    ).resolve(media);
    expect(source.uri, 'fd://42');
    await source.close();
    expect(calls, ['openPlayback', 'closePlayback']);
  });

  test('iOS uses the imported file URL directly', () async {
    final source = await const PlaybackSourceResolver(
      platform: TargetPlatform.iOS,
    ).resolve(media);
    expect(source.uri, media.uri);
    await source.close();
  });
}
