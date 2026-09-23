import 'package:shared_preferences/shared_preferences.dart';

enum AccentPreference { electricBlue, cyan, violet }

const applicationPlaybackSpeeds = <double>[0.5, 0.75, 1, 1.25, 1.5, 2];

class ApplicationSettings {
  const ApplicationSettings({
    this.pureBlackTheme = false,
    this.accent = AccentPreference.electricBlue,
    this.defaultPlaybackSpeed = 1,
    this.resumePlayback = true,
    this.backgroundAudio = true,
    this.gestureControls = true,
  });

  final bool pureBlackTheme;
  final AccentPreference accent;
  final double defaultPlaybackSpeed;
  final bool resumePlayback;
  final bool backgroundAudio;
  final bool gestureControls;

  ApplicationSettings copyWith({
    bool? pureBlackTheme,
    AccentPreference? accent,
    double? defaultPlaybackSpeed,
    bool? resumePlayback,
    bool? backgroundAudio,
    bool? gestureControls,
  }) => ApplicationSettings(
    pureBlackTheme: pureBlackTheme ?? this.pureBlackTheme,
    accent: accent ?? this.accent,
    defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
    resumePlayback: resumePlayback ?? this.resumePlayback,
    backgroundAudio: backgroundAudio ?? this.backgroundAudio,
    gestureControls: gestureControls ?? this.gestureControls,
  );
}

class ApplicationPreferences {
  ApplicationPreferences({SharedPreferencesAsync? preferences})
    : _preferencesInstance = preferences;

  SharedPreferencesAsync? _preferencesInstance;
  SharedPreferencesAsync get _preferences =>
      _preferencesInstance ??= SharedPreferencesAsync();
  static const _pureBlack = 'app.pure_black_theme';
  static const _accent = 'app.accent';
  static const _playbackSpeed = 'playback.default_speed';
  static const _resume = 'playback.resume';
  static const _backgroundAudio = 'playback.background_audio';
  static const _gestures = 'playback.gesture_controls';

  Future<ApplicationSettings> load() async {
    final accentName = await _preferences.getString(_accent);
    final storedPlaybackSpeed = await _preferences.getDouble(_playbackSpeed);
    return ApplicationSettings(
      pureBlackTheme: await _preferences.getBool(_pureBlack) ?? false,
      accent: AccentPreference.values.firstWhere(
        (value) => value.name == accentName,
        orElse: () => AccentPreference.electricBlue,
      ),
      defaultPlaybackSpeed:
          applicationPlaybackSpeeds.contains(storedPlaybackSpeed)
          ? storedPlaybackSpeed!
          : 1,
      resumePlayback: await _preferences.getBool(_resume) ?? true,
      backgroundAudio: await _preferences.getBool(_backgroundAudio) ?? true,
      gestureControls: await _preferences.getBool(_gestures) ?? true,
    );
  }

  Future<void> save(ApplicationSettings settings) async {
    await Future.wait([
      _preferences.setBool(_pureBlack, settings.pureBlackTheme),
      _preferences.setString(_accent, settings.accent.name),
      _preferences.setDouble(_playbackSpeed, settings.defaultPlaybackSpeed),
      _preferences.setBool(_resume, settings.resumePlayback),
      _preferences.setBool(_backgroundAudio, settings.backgroundAudio),
      _preferences.setBool(_gestures, settings.gestureControls),
    ]);
  }

  Future<void> reset() async {
    await Future.wait([
      _preferences.remove(_pureBlack),
      _preferences.remove(_accent),
      _preferences.remove(_playbackSpeed),
      _preferences.remove(_resume),
      _preferences.remove(_backgroundAudio),
      _preferences.remove(_gestures),
    ]);
  }
}
