import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/data/settings/application_preferences.dart';

final applicationPreferencesProvider = Provider<ApplicationPreferences>(
  (ref) => ApplicationPreferences(),
);

final applicationSettingsProvider =
    AsyncNotifierProvider<ApplicationSettingsController, ApplicationSettings>(
      ApplicationSettingsController.new,
      retry: (retryCount, error) => null,
    );

class ApplicationSettingsController extends AsyncNotifier<ApplicationSettings> {
  ApplicationPreferences get _preferences =>
      ref.read(applicationPreferencesProvider);

  @override
  Future<ApplicationSettings> build() => _preferences.load();

  Future<void> saveSettings(ApplicationSettings settings) async {
    final previous = state.value ?? const ApplicationSettings();
    state = AsyncData(settings);
    try {
      await _preferences.save(settings);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> reset() async {
    final previous = state.value ?? const ApplicationSettings();
    const defaults = ApplicationSettings();
    state = const AsyncData(defaults);
    try {
      await _preferences.reset();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
