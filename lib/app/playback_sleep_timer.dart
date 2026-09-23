import 'dart:async';

import 'package:flutter/foundation.dart';

class PlaybackSleepTimer extends ChangeNotifier {
  PlaybackSleepTimer(this._onElapsed);

  final Future<void> Function() _onElapsed;
  Timer? _expiryTimer;
  Timer? _ticker;
  DateTime? _endsAt;
  bool _disposed = false;

  bool get active => _endsAt != null;

  Duration get remaining {
    final endsAt = _endsAt;
    if (endsAt == null) return Duration.zero;
    final value = endsAt.difference(DateTime.now());
    return value.isNegative ? Duration.zero : value;
  }

  void schedule(Duration duration) {
    if (duration <= Duration.zero) {
      cancel();
      return;
    }
    _cancelTimers();
    _endsAt = DateTime.now().add(duration);
    _expiryTimer = Timer(duration, _expire);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _notify());
    _notify();
  }

  void cancel() {
    if (!active && _expiryTimer == null && _ticker == null) return;
    _cancelTimers();
    _endsAt = null;
    _notify();
  }

  void _expire() {
    _cancelTimers();
    _endsAt = null;
    _notify();
    unawaited(_onElapsed());
  }

  void _cancelTimers() {
    _expiryTimer?.cancel();
    _ticker?.cancel();
    _expiryTimer = null;
    _ticker = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    super.dispose();
  }
}
