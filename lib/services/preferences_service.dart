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

  /// Loads settings from storage, validating every value first.
  ///
  /// `getInt`/`getDouble`/`getString` do an unchecked cast to the requested
  /// type internally and throw on a mismatch (see the shared_preferences
  /// source), so a value written by a different type -- corrupted storage, a
  /// hand-edited web LocalStorage entry, a future version that changes a
  /// key's type -- would crash startup before the first frame. Reading
  /// through [SharedPreferences.get], which returns the untyped value with no
  /// cast, lets a bad value fall back to its default instead.
  void loadInto(AppSettings settings) {
    settings.loadFrom(
      maxChars: _validMaxChars(_prefs.get(_keyMaxChars)),
      theme: AppThemeExtension.fromKey(_validThemeKey(_prefs.get(_keyTheme))),
      fontFamily: _validFontFamily(_prefs.get(_keyFontFamily)),
      fontSize: _validFontSize(_prefs.get(_keyFontSize)),
    );
  }

  // AppThemeExtension.fromKey already falls back to light for any string it
  // does not recognise; this only needs to guard against a non-String value
  // reaching it in the first place.
  String _validThemeKey(Object? stored) => stored is String ? stored : 'light';

  int _validMaxChars(Object? stored) {
    if (stored is! int || stored < minMaxChars || stored > maxMaxChars) {
      return defaultMaxChars;
    }
    return stored;
  }

  double _validFontSize(Object? stored) {
    if (stored is! double || stored < minFontSize || stored > maxFontSize) {
      return 16.0;
    }
    return stored;
  }

  /// Unknown font names -- from a hand-edited value, or a font retired from
  /// [availableFonts] in a future release -- fall back to the app default
  /// (null selects Source Code Pro) rather than being passed to
  /// GoogleFonts.getFont, which throws for a name it does not recognise.
  String? _validFontFamily(Object? stored) {
    if (stored is! String || !availableFonts.contains(stored)) return null;
    return stored;
  }

  Future<bool> saveMaxChars(int value) => _prefs.setInt(_keyMaxChars, value);

  Future<bool> saveTheme(AppTheme value) =>
      _prefs.setString(_keyTheme, value.key);

  Future<bool> saveFontFamily(String? value) {
    if (value == null) return _prefs.remove(_keyFontFamily);
    return _prefs.setString(_keyFontFamily, value);
  }

  Future<bool> saveFontSize(double value) =>
      _prefs.setDouble(_keyFontSize, value);
}
