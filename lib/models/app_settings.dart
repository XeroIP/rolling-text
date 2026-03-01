import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';

const int defaultMaxChars = 128;

class AppSettings extends ChangeNotifier {
  int _maxChars = defaultMaxChars;
  AppTheme _theme = AppTheme.light;
  String? _fontFamily;
  double _fontSize = 16.0;

  int get maxChars => _maxChars;
  AppTheme get theme => _theme;
  String? get fontFamily => _fontFamily;
  double get fontSize => _fontSize;

  void setMaxChars(int value) {
    _maxChars = value;
    notifyListeners();
  }

  void setTheme(AppTheme value) {
    _theme = value;
    notifyListeners();
  }

  void setFontFamily(String? value) {
    _fontFamily = value;
    notifyListeners();
  }

  void setFontSize(double value) {
    _fontSize = value;
    notifyListeners();
  }

  /// Called once at startup before widget tree builds. No notification needed.
  void loadFrom({
    required int maxChars,
    required AppTheme theme,
    String? fontFamily,
    required double fontSize,
  }) {
    _maxChars = maxChars;
    _theme = theme;
    _fontFamily = fontFamily;
    _fontSize = fontSize;
  }
}
