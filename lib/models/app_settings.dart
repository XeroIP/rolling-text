import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';

const int defaultMaxChars = 128;

// Bounds a saved value must fall inside to be trusted on load. These mirror
// the ranges the settings sheets themselves enforce in main_screen.dart --
// keep both in sync if either changes.
const int minMaxChars = 1;
const int maxMaxChars = 1000000;
const double minFontSize = 6;
const double maxFontSize = 999; // The numeric field's range, not the slider's
// (6-144). Clamping to the slider's max would shrink a legitimately saved
// larger size on load.

/// Curated list of 20 Google Fonts, sorted alphabetically.
const List<String> availableFonts = [
  'Courier Prime',
  'Crimson Text',
  'EB Garamond',
  'Fira Code',
  'IBM Plex Mono',
  'Inconsolata',
  'Inter',
  'JetBrains Mono',
  'Karla',
  'Lato',
  'Libre Baskerville',
  'Lora',
  'Merriweather',
  'Nunito',
  'Open Sans',
  'Playfair Display',
  'PT Serif',
  'Raleway',
  'Source Code Pro',
  'Work Sans',
];

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
