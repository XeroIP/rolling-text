import 'package:flutter/material.dart';

enum AppTheme { light, dark, sepia }

extension AppThemeExtension on AppTheme {
  String get label => switch (this) {
    AppTheme.light => 'Light',
    AppTheme.dark => 'Dark',
    AppTheme.sepia => 'Sepia',
  };

  String get key => switch (this) {
    AppTheme.light => 'light',
    AppTheme.dark => 'dark',
    AppTheme.sepia => 'sepia',
  };

  static AppTheme fromKey(String key) => switch (key) {
    'dark' => AppTheme.dark,
    'sepia' => AppTheme.sepia,
    _ => AppTheme.light,
  };
}

class AppColors {
  final Color background;
  final Color text;
  final Color textSecondary;
  final Color buttonBackground;
  final Color buttonIcon;

  const AppColors({
    required this.background,
    required this.text,
    required this.textSecondary,
    required this.buttonBackground,
    required this.buttonIcon,
  });
}

const lightColors = AppColors(
  background: Color(0xFFFFFFFF),
  text: Color(0xFF000000),
  textSecondary: Color(0xFF666666),
  buttonBackground: Color(0xFFE8DEF8),
  buttonIcon: Color(0xFF1D192B),
);

const darkColors = AppColors(
  background: Color(0xFF121212),
  text: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFB0B0B0),
  buttonBackground: Color(0xFF2C2C2C),
  buttonIcon: Color(0xFFE0E0E0),
);

const sepiaColors = AppColors(
  background: Color(0xFFE8D5B8),
  text: Color(0xFF2C1810),
  textSecondary: Color(0xFF4E342E),
  buttonBackground: Color(0xFFC9AD88),
  buttonIcon: Color(0xFF2C1810),
);

AppColors colorsFor(AppTheme theme) => switch (theme) {
  AppTheme.light => lightColors,
  AppTheme.dark => darkColors,
  AppTheme.sepia => sepiaColors,
};

ThemeData themeDataFor(AppTheme theme) {
  final colors = colorsFor(theme);
  final brightness =
      theme == AppTheme.dark ? Brightness.dark : Brightness.light;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.buttonIcon,
      onPrimary: colors.buttonBackground,
      secondary: colors.buttonIcon,
      onSecondary: colors.buttonBackground,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: colors.background,
      onSurface: colors.text,
      onSurfaceVariant: colors.textSecondary,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.background,
      titleTextStyle: TextStyle(
        color: colors.text,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: colors.text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: colors.textSecondary),
    ),
  );
}
