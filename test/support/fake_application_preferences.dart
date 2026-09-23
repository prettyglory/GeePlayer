import 'package:gee_player/data/settings/application_preferences.dart';

class FakeApplicationPreferences extends ApplicationPreferences {
  ApplicationSettings settings = const ApplicationSettings();

  @override
  Future<ApplicationSettings> load() async => settings;

  @override
  Future<void> save(ApplicationSettings value) async {
    settings = value;
  }

  @override
  Future<void> reset() async {
    settings = const ApplicationSettings();
  }
}
