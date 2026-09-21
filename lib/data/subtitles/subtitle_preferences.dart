import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubtitleAppearance {
  const SubtitleAppearance({
    this.fontSize = 32,
    this.textColor = 0xFFFFFFFF,
    this.backgroundColor = 0xAA000000,
    this.bottomPadding = 24,
    this.delayMilliseconds = 0,
  });

  final double fontSize;
  final int textColor;
  final int backgroundColor;
  final double bottomPadding;
  final int delayMilliseconds;

  SubtitleAppearance copyWith({
    double? fontSize,
    int? textColor,
    int? backgroundColor,
    double? bottomPadding,
    int? delayMilliseconds,
  }) => SubtitleAppearance(
    fontSize: fontSize ?? this.fontSize,
    textColor: textColor ?? this.textColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    bottomPadding: bottomPadding ?? this.bottomPadding,
    delayMilliseconds: delayMilliseconds ?? this.delayMilliseconds,
  );
}

class SubtitlePreferences {
  SubtitlePreferences({FlutterSecureStorage? secureStorage})
    : _secure = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;
  late final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const _apiKey = 'subdl.api_key';
  static const _autoSearch = 'subtitle.auto_search';
  static const _language = 'subtitle.language';
  static const _fontSize = 'subtitle.font_size';
  static const _textColor = 'subtitle.text_color';
  static const _backgroundColor = 'subtitle.background_color';
  static const _bottomPadding = 'subtitle.bottom_padding';
  static const _delayMilliseconds = 'subtitle.delay_ms';

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

  Future<SubtitleAppearance> appearance() async => SubtitleAppearance(
    fontSize: await _prefs.getDouble(_fontSize) ?? 32,
    textColor: await _prefs.getInt(_textColor) ?? 0xFFFFFFFF,
    backgroundColor: await _prefs.getInt(_backgroundColor) ?? 0xAA000000,
    bottomPadding: await _prefs.getDouble(_bottomPadding) ?? 24,
    delayMilliseconds: await _prefs.getInt(_delayMilliseconds) ?? 0,
  );

  Future<void> setAppearance(SubtitleAppearance appearance) async {
    await Future.wait([
      _prefs.setDouble(_fontSize, appearance.fontSize),
      _prefs.setInt(_textColor, appearance.textColor),
      _prefs.setInt(_backgroundColor, appearance.backgroundColor),
      _prefs.setDouble(_bottomPadding, appearance.bottomPadding),
      _prefs.setInt(_delayMilliseconds, appearance.delayMilliseconds),
    ]);
  }
}
