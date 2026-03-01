import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';

class PreferencesService {
  static const _keyMaxChars = 'maxCharacters';
  static const _keyTheme = 'theme';
  static const _keyFontFamily = 'fontFamily';
  static const _keyFontSize = 'fontSize';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  void loadInto(AppSettings settings) {
    settings.loadFrom(
      maxChars: _prefs.getInt(_keyMaxChars) ?? defaultMaxChars,
      theme: AppThemeExtension.fromKey(_prefs.getString(_keyTheme) ?? 'light'),
      fontFamily: _prefs.getString(_keyFontFamily),
      fontSize: _prefs.getDouble(_keyFontSize) ?? 16.0,
    );
  }

  Future<void> saveMaxChars(int value) => _prefs.setInt(_keyMaxChars, value);

  Future<void> saveTheme(AppTheme value) =>
      _prefs.setString(_keyTheme, value.key);

  Future<void> saveFontFamily(String? value) {
    if (value == null) return _prefs.remove(_keyFontFamily);
    return _prefs.setString(_keyFontFamily, value);
  }

  Future<void> saveFontSize(double value) =>
      _prefs.setDouble(_keyFontSize, value);
}
