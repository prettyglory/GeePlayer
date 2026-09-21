import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gee_player/app/background_audio_handler.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/data/playback/playback_source_resolver.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

enum PlaybackRepeatMode { off, one, all }

/// Coordinates one media session and its persisted resume position.
class PlaybackController extends ChangeNotifier
    implements AudioPlaybackDelegate {
  PlaybackController(
    this._database,
    this._sourceResolver, {
    this.audioHandler,
    this.onHistoryChanged,
  }) {
    audioHandler?.bind(this);
  }

  void _initializePlayer() {
    if (_initialized) return;
    player = Player();
    videoController = VideoController(player);
    _subscriptions.addAll([
      player.stream.position.listen((value) {
        position = value;
        if (!loading &&
            current != null &&
            value.inSeconds >= _lastSavedSecond + 5) {
          _lastSavedSecond = value.inSeconds;
          unawaited(_savePosition());
        }
        _notify();
      }),
      player.stream.duration.listen((value) {
        duration = value;
        _notify();
      }),
      player.stream.playing.listen((value) {
        playing = value;
        if (!loading && !value) unawaited(_savePosition());
        _notify();
      }),
      player.stream.completed.listen((value) {
        if (!loading && value && current != null) {
          _completed = true;
          unawaited(_writePosition(current!.id, duration, duration));
          if (current!.kind == MediaKind.audio) {
            unawaited(_advanceAfterCompletion());
          }
        }
        _notify();
      }),
      player.stream.error.listen((value) {
        error = value;
        _notify();
      }),
    ]);
    _initialized = true;
  }

  final PlaybackDatabase _database;
  final PlaybackSourceResolver _sourceResolver;
  final GeeAudioHandler? audioHandler;
  final VoidCallback? onHistoryChanged;
  late final Player player;
  late final VideoController videoController;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  PlaybackSourceLease? _source;
  @override
  List<LocalMedia> queue = const [];
  @override
  int index = 0;
  @override
  LocalMedia? current;
  @override
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  @override
  bool playing = false;
  @override
  bool loading = false;
  String? error;
  bool _completed = false;
  bool _disposed = false;
  bool _initialized = false;
  bool _handlingCompletion = false;
  final Random _random = Random();
  int sessionRevision = 0;
  int _lastSavedSecond = 0;
  Future<void> _pendingSave = Future.value();
  bool shuffle = false;
  PlaybackRepeatMode repeatMode = PlaybackRepeatMode.off;
  Duration subtitleDelay = Duration.zero;

  bool get hasNext => index < queue.length - 1;
  bool get hasPrevious => index > 0;
  @override
  bool get completed => _completed;
  @override
  bool get shuffleEnabled => shuffle;
  @override
  bool get repeatOne => repeatMode == PlaybackRepeatMode.one;
  @override
  bool get repeatAll => repeatMode == PlaybackRepeatMode.all;

  Future<void> open(List<LocalMedia> items, int startIndex) async {
    if (loading || startIndex < 0 || startIndex >= items.length) return;
    loading = true;
    error = null;
    _notify();
    try {
      _initializePlayer();
      await _stopCurrent();
      queue = List.unmodifiable(items);
      index = startIndex;
      current = queue[index];
      _completed = false;
      position = Duration.zero;
      duration = current!.duration ?? Duration.zero;
      _lastSavedSecond = 0;
      _notify();

      final saved = await _database.positionFor(current!.id);
      _source = await _sourceResolver.resolve(current!);
      await player.open(Media(_source!.uri), play: false);
      if (saved != null && saved > Duration.zero) {
        if (player.state.duration == Duration.zero) {
          await player.stream.duration
              .firstWhere((value) => value > Duration.zero)
              .timeout(
                const Duration(seconds: 3),
                onTimeout: () => Duration.zero,
              );
        }
        await player.seek(saved);
      }
      if (current!.kind != MediaKind.audio ||
          await (audioHandler?.activate() ?? Future.value(true))) {
        await player.play();
      }
      try {
        await _database.recordPlayback(current!);
        onHistoryChanged?.call();
      } catch (_) {
        // Playback should continue when local history cannot be updated.
      }
      await setSubtitleDelay(subtitleDelay);
      sessionRevision++;
    } catch (exception) {
      error = 'Could not play ${current?.fileName ?? 'this file'}: $exception';
      try {
        if (_initialized) await player.stop();
      } catch (_) {}
      try {
        await _source?.close();
      } catch (_) {}
      _source = null;
      playing = false;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> togglePlayPause() => playing ? pause() : play();

  @override
  Future<void> play() async {
    if (current?.kind == MediaKind.audio &&
        !await (audioHandler?.activate() ?? Future.value(true))) {
      return;
    }
    await player.play();
  }

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration target) async {
    final end = duration > Duration.zero ? duration : target;
    final safe = target < Duration.zero
        ? Duration.zero
        : target > end
        ? end
        : target;
    await player.seek(safe);
    position = safe;
    _notify();
    await _savePosition();
  }

  @override
  Future<void> skipBy(Duration offset) => seek(position + offset);

  Future<void> setRate(double rate) => player.setRate(rate);

  Future<void> setAudioTrack(AudioTrack track) => player.setAudioTrack(track);

  Future<void> setSubtitleDelay(Duration value) async {
    subtitleDelay = value;
    if (_initialized && player.platform is NativePlayer) {
      try {
        await (player.platform! as NativePlayer).setProperty(
          'sub-delay',
          (value.inMilliseconds / 1000).toStringAsFixed(3),
        );
      } catch (_) {
        // Some playback backends do not expose libmpv properties.
      }
    }
    _notify();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    _notify();
  }

  void cycleRepeatMode() {
    repeatMode = switch (repeatMode) {
      PlaybackRepeatMode.off => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.off,
    };
    _notify();
  }

  Future<void> saveProgress() => _savePosition();

  @override
  Future<void> next() async {
    if (queue.isEmpty) return;
    if (shuffle && queue.length > 1) {
      var nextIndex = index;
      while (nextIndex == index) {
        nextIndex = _random.nextInt(queue.length);
      }
      await open(queue, nextIndex);
    } else if (hasNext) {
      await open(queue, index + 1);
    } else if (repeatMode == PlaybackRepeatMode.all) {
      await open(queue, 0);
    }
  }

  @override
  Future<void> previous() async {
    if (position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
    } else if (hasPrevious) {
      await open(queue, index - 1);
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<void> stop() async {
    if (loading) return;
    loading = true;
    _notify();
    try {
      await _stopCurrent();
      current = null;
      queue = const [];
      position = Duration.zero;
      duration = Duration.zero;
      playing = false;
      await audioHandler?.deactivate();
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> _stopCurrent() async {
    await _savePosition();
    try {
      if (_initialized) await player.stop();
    } finally {
      await _source?.close();
      _source = null;
    }
  }

  Future<void> _advanceAfterCompletion() async {
    if (_handlingCompletion || loading || current == null) return;
    _handlingCompletion = true;
    try {
      if (repeatMode == PlaybackRepeatMode.one) {
        _completed = false;
        await player.seek(Duration.zero);
        await player.play();
      } else if (hasNext || shuffle || repeatMode == PlaybackRepeatMode.all) {
        await next();
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  Future<void> _savePosition() async {
    final media = current;
    if (media == null || _completed) return;
    await _writePosition(media.id, position, duration);
  }

  Future<void> _writePosition(String mediaId, Duration at, Duration total) {
    _pendingSave = _pendingSave
        .then((_) => _database.savePosition(mediaId, at, total))
        .catchError((Object exception) {
          error = 'Could not save playback position: $exception';
          _notify();
        });
    return _pendingSave;
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
      audioHandler?.sync();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    audioHandler?.unbind(this);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(() async {
      await _savePosition();
      if (_initialized) {
        await player.dispose();
        await _source?.close();
      }
    }());
    super.dispose();
  }
}
