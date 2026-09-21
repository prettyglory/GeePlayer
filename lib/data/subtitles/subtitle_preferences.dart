import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubtitlePreferences {
  SubtitlePreferences({
    FlutterSecureStorage? secureStorage,
  }) : _secure = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;
  late final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const _apiKey = 'subdl.api_key';
  static const _autoSearch = 'subtitle.auto_search';
  static const _language = 'subtitle.language';

  Future<String?> apiKey() => _secure.read(key: _apiKey);

  Future<void> setApiKey(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _secure.delete(key: _apiKey);
    } else {
      await _secure.write(key: _apiKey, value: trimmed);
    }
  }

  Future<bool> autoSearch() async => await _prefs.getBool(_autoSearch) ?? false;

  Future<void> setAutoSearch(bool value) => _prefs.setBool(_autoSearch, value);

  Future<String> preferredLanguage() async =>
      await _prefs.getString(_language) ?? 'SW';

  Future<void> setPreferredLanguage(String value) =>
      _prefs.setString(_language, value == 'EN' ? 'EN' : 'SW');

  Future<List<String>> languageOrder() async =>
      await preferredLanguage() == 'EN' ? const ['EN'] : const ['SW', 'EN'];
}
