import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:gee_player/domain/media/local_media.dart';

abstract interface class AudioPlaybackDelegate {
  LocalMedia? get current;
  List<LocalMedia> get queue;
  int get index;
  Duration get position;
  bool get playing;
  bool get loading;
  bool get completed;
  bool get shuffleEnabled;
  bool get repeatOne;
  bool get repeatAll;

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> next();
  Future<void> previous();
  Future<void> skipBy(Duration offset);
}

class GeeAudioHandler extends BaseAudioHandler {
  AudioPlaybackDelegate? _delegate;
  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<void>? _noisySubscription;
  bool _resumeAfterInterruption = false;
  String? _publishedMediaId;
  List<String> _publishedQueueIds = const [];
  DateTime _lastStateUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _lastPosition = Duration.zero;
  bool? _lastPlaying;
  bool? _lastLoading;

  Future<void> initializeSession() async {
    final session = await AudioSession.instance;
    _session = session;
    await session.configure(const AudioSessionConfiguration.music());
    await _interruptionSubscription?.cancel();
    await _noisySubscription?.cancel();
    _interruptionSubscription = session.interruptionEventStream.listen(
      _handleInterruption,
    );
    _noisySubscription = session.becomingNoisyEventStream.listen((_) {
      final delegate = _delegate;
      if (delegate?.playing ?? false) unawaited(delegate!.pause());
    });
  }

  void bind(AudioPlaybackDelegate delegate) {
    _delegate = delegate;
    sync(force: true);
  }

  void unbind(AudioPlaybackDelegate delegate) {
    if (identical(_delegate, delegate)) _delegate = null;
  }

  Future<bool> activate() async => await _session?.setActive(true) ?? true;

  Future<void> deactivate() async {
    await _session?.setActive(false);
  }

  void sync({bool force = false}) {
    final delegate = _delegate;
    if (delegate == null) return;
    final current = delegate.current;
    if (current == null || current.kind != MediaKind.audio) {
      if (_publishedMediaId != null) {
        _publishedMediaId = null;
        _publishedQueueIds = const [];
        queue.add(const []);
        mediaItem.add(null);
        playbackState.add(
          PlaybackState(processingState: AudioProcessingState.idle),
        );
      }
      return;
    }

    final audioQueue = delegate.queue
        .where((item) => item.kind == MediaKind.audio)
        .toList();
    final queueIds = audioQueue.map((item) => item.id).toList();
    if (!_sameIds(queueIds, _publishedQueueIds)) {
      _publishedQueueIds = queueIds;
      queue.add(audioQueue.map(_mediaItem).toList());
      force = true;
    }
    if (_publishedMediaId != current.id) {
      _publishedMediaId = current.id;
      mediaItem.add(_mediaItem(current));
      force = true;
    }

    final now = DateTime.now();
    final positionChanged =
        (delegate.position - _lastPosition).abs() > const Duration(seconds: 2);
    final stateChanged =
        delegate.playing != _lastPlaying || delegate.loading != _lastLoading;
    if (!force && !positionChanged && !stateChanged) return;
    if (!force &&
        !stateChanged &&
        now.difference(_lastStateUpdate) < const Duration(seconds: 1)) {
      return;
    }
    _lastStateUpdate = now;
    _lastPosition = delegate.position;
    _lastPlaying = delegate.playing;
    _lastLoading = delegate.loading;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          delegate.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekBackward,
          MediaAction.seekForward,
        },
        processingState: delegate.loading
            ? AudioProcessingState.loading
            : delegate.completed
            ? AudioProcessingState.completed
            : AudioProcessingState.ready,
        playing: delegate.playing,
        updatePosition: delegate.position,
        bufferedPosition: delegate.position,
        queueIndex: delegate.index,
        shuffleMode: delegate.shuffleEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        repeatMode: delegate.repeatOne
            ? AudioServiceRepeatMode.one
            : delegate.repeatAll
            ? AudioServiceRepeatMode.all
            : AudioServiceRepeatMode.none,
      ),
    );
  }

  MediaItem _mediaItem(LocalMedia media) => MediaItem(
    id: media.id,
    title: media.title,
    artist: media.artist,
    album: media.folderPath,
    duration: media.duration,
    extras: {'uri': media.uri},
  );

  bool _sameIds(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  void _handleInterruption(AudioInterruptionEvent event) {
    final delegate = _delegate;
    if (delegate == null) return;
    if (event.begin) {
      if (event.type == AudioInterruptionType.pause ||
          event.type == AudioInterruptionType.unknown) {
        _resumeAfterInterruption = delegate.playing;
        if (delegate.playing) unawaited(delegate.pause());
      }
    } else if (event.type == AudioInterruptionType.pause &&
        _resumeAfterInterruption) {
      _resumeAfterInterruption = false;
      unawaited(delegate.play());
    }
  }

  @override
  Future<void> play() async => _delegate?.play();

  @override
  Future<void> pause() async => _delegate?.pause();

  @override
  Future<void> stop() async {
    await _delegate?.stop();
    await deactivate();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
    mediaItem.add(null);
  }

  @override
  Future<void> seek(Duration position) async => _delegate?.seek(position);

  @override
  Future<void> skipToNext() async => _delegate?.next();

  @override
  Future<void> skipToPrevious() async => _delegate?.previous();

  @override
  Future<void> fastForward() async =>
      _delegate?.skipBy(const Duration(seconds: 10));

  @override
  Future<void> rewind() async =>
      _delegate?.skipBy(const Duration(seconds: -10));
}
