import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/app/background_audio_handler.dart';
import 'package:gee_player/domain/media/local_media.dart';

void main() {
  test('publishes music metadata and delegates media controls', () async {
    final handler = GeeAudioHandler();
    final delegate = _FakePlaybackDelegate();

    handler.bind(delegate);

    expect(handler.mediaItem.value?.title, 'Sunrise');
    expect(handler.mediaItem.value?.artist, 'Gee');
    expect(handler.queue.value, hasLength(1));
    expect(handler.playbackState.value.playing, isTrue);
    expect(
      handler.playbackState.value.processingState,
      AudioProcessingState.ready,
    );

    await handler.pause();
    await handler.seek(const Duration(seconds: 45));
    await handler.skipToNext();
    await handler.skipToPrevious();

    expect(delegate.pauseCount, 1);
    expect(delegate.seekTarget, const Duration(seconds: 45));
    expect(delegate.nextCount, 1);
    expect(delegate.previousCount, 1);
  });

  test('does not publish a media notification for video playback', () {
    final handler = GeeAudioHandler();
    final delegate = _FakePlaybackDelegate(
      media: const LocalMedia(
        id: 'video:1',
        kind: MediaKind.video,
        uri: 'content://video/1',
        fileName: 'Movie.mp4',
        folderPath: 'Movies',
      ),
    );

    handler.bind(delegate);

    expect(handler.mediaItem.value, isNull);
    expect(
      handler.playbackState.value.processingState,
      AudioProcessingState.idle,
    );
  });
}

class _FakePlaybackDelegate implements AudioPlaybackDelegate {
  _FakePlaybackDelegate({
    this.media = const LocalMedia(
      id: 'audio:1',
      kind: MediaKind.audio,
      uri: 'content://audio/1',
      fileName: 'Sunrise.mp3',
      folderPath: 'Music',
      artist: 'Gee',
      duration: Duration(minutes: 3),
    ),
  });

  final LocalMedia media;
  int pauseCount = 0;
  int nextCount = 0;
  int previousCount = 0;
  Duration? seekTarget;

  @override
  bool get completed => false;

  @override
  LocalMedia get current => media;

  @override
  int get index => 0;

  @override
  bool get loading => false;

  @override
  bool get playing => true;

  @override
  Duration get position => const Duration(seconds: 30);

  @override
  List<LocalMedia> get queue => [media];

  @override
  bool get repeatAll => false;

  @override
  bool get repeatOne => false;

  @override
  bool get shuffleEnabled => false;

  @override
  Future<void> next() async => nextCount++;

  @override
  Future<void> pause() async => pauseCount++;

  @override
  Future<void> play() async {}

  @override
  Future<void> previous() async => previousCount++;

  @override
  Future<void> seek(Duration position) async => seekTarget = position;

  @override
  Future<void> skipBy(Duration offset) async {}

  @override
  Future<void> stop() async {}
}
