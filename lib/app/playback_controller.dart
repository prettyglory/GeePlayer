import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/data/playback/playback_source_resolver.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Coordinates one media session and its persisted resume position.
class PlaybackController extends ChangeNotifier {
  PlaybackController(
    this._database,
    this._sourceResolver, {
    this.onHistoryChanged,
  });

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
  final VoidCallback? onHistoryChanged;
  late final Player player;
  late final VideoController videoController;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  PlaybackSourceLease? _source;
  List<LocalMedia> queue = const [];
  int index = 0;
  LocalMedia? current;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool playing = false;
  bool loading = false;
  String? error;
  bool _completed = false;
  bool _disposed = false;
  bool _initialized = false;
  int sessionRevision = 0;
  int _lastSavedSecond = 0;
  Future<void> _pendingSave = Future.value();

  bool get hasNext => index < queue.length - 1;
  bool get hasPrevious => index > 0;

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
      await player.play();
      await _database.recordPlayback(current!);
      onHistoryChanged?.call();
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

  Future<void> togglePlayPause() => player.playOrPause();

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

  Future<void> skipBy(Duration offset) => seek(position + offset);

  Future<void> setRate(double rate) => player.setRate(rate);

  Future<void> saveProgress() => _savePosition();

  Future<void> next() async {
    if (hasNext) await open(queue, index + 1);
  }

  Future<void> previous() async {
    if (position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
    } else if (hasPrevious) {
      await open(queue, index - 1);
    } else {
      await seek(Duration.zero);
    }
  }

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
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
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
