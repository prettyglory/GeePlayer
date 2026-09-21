import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidPlayerControls {
  const AndroidPlayerControls();

  static const _channel = MethodChannel('com.gee.player/player_controls');

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<double?> volume() => _read('getVolume');

  Future<void> setVolume(double value) => _write('setVolume', value);

  Future<double?> brightness() => _read('getBrightness');

  Future<void> setBrightness(double value) => _write('setBrightness', value);

  Future<bool> enterPictureInPicture() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('enterPictureInPicture') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<double?> _read(String method) async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<double>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> _write(String method, double value) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>(method, {
        'value': value.clamp(0.0, 1.0),
      });
    } on PlatformException {
      // Gesture controls remain optional on unsupported Android devices.
    } on MissingPluginException {
      // Allows widget tests and other targets to use the same player UI.
    }
  }
}
