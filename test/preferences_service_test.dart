// Regression coverage for #19: preferences load with no type, range, or
// allow-list guarding, so corrupt or hand-edited storage crashes startup.
//
// getInt/getDouble/getString in shared_preferences do an unchecked cast to
// the requested type and throw on a mismatch (see the package's own
// SharedPreferencesStorePlatform-backed implementation). Seeding a wrong type
// through SharedPreferences.setMockInitialValues reproduces that here: it
// stores the value exactly as given, with no validation of its own.
//
// These test loadInto() directly rather than through MainScreen. MainScreen's
// test harness (widget_test.dart's _pumpMainScreen) never calls loadInto -- it
// builds AppSettings from explicit theme/fontFamily parameters -- so it cannot
// observe this behaviour at all.

import 'package:flutter_test/flutter_test.dart';
import 'package:rolling_text/models/app_settings.dart';
import 'package:rolling_text/services/preferences_service.dart';
import 'package:rolling_text/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PreferencesService> _serviceWith(Map<String, Object> stored) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  return PreferencesService(prefs);
}

void main() {
  test('valid stored values load unchanged', () async {
    final service = await _serviceWith({
      'maxCharacters': 500,
      'theme': 'dark',
      'fontFamily': 'Lora',
      'fontSize': 24.0,
    });
    final settings = AppSettings();

    service.loadInto(settings);

    expect(settings.maxChars, 500);
    expect(settings.theme, AppTheme.dark);
    expect(settings.fontFamily, 'Lora');
    expect(settings.fontSize, 24.0);
  });

  test('valid stored night and darkSepia themes load correctly', () async {
    final nightService = await _serviceWith({'theme': 'night'});
    final darkSepiaService = await _serviceWith({'theme': 'darkSepia'});

    final nightSettings = AppSettings();
    final darkSepiaSettings = AppSettings();

    nightService.loadInto(nightSettings);
    darkSepiaService.loadInto(darkSepiaSettings);

    expect(nightSettings.theme, AppTheme.night);
    expect(darkSepiaSettings.theme, AppTheme.darkSepia);
  });

  test('a wrong-typed maxCharacters falls back to the default instead of throwing', () async {
    final service = await _serviceWith({'maxCharacters': 'not a number'});
    final settings = AppSettings();

    service.loadInto(settings);

    expect(settings.maxChars, defaultMaxChars);
  });

  test('a wrong-typed fontSize falls back to the default instead of throwing', () async {
    final service = await _serviceWith({'fontSize': 'not a number'});
    final settings = AppSettings();

    service.loadInto(settings);

    expect(settings.fontSize, 16.0);
  });

  test('a wrong-typed theme falls back to light instead of throwing', () async {
    final service = await _serviceWith({'theme': 12345});
    final settings = AppSettings();

    service.loadInto(settings);

    expect(settings.theme, AppTheme.light);
  });

  test('an out-of-range maxCharacters falls back to the default', () async {
    final tooLow = await _serviceWith({'maxCharacters': 0});
    final tooHigh = await _serviceWith({'maxCharacters': 2000000});

    final lowSettings = AppSettings();
    final highSettings = AppSettings();
    tooLow.loadInto(lowSettings);
    tooHigh.loadInto(highSettings);

    expect(lowSettings.maxChars, defaultMaxChars);
    expect(highSettings.maxChars, defaultMaxChars);
  });

  test('a value above the lowered ceiling falls back to the default', () async {
    // Pins the #18 ceiling reduction: this value was a valid maxCharacters
    // under the old 1,000,000 limit and must now be rejected on load.
    final service = await _serviceWith({'maxCharacters': 100000});
    final settings = AppSettings();

    service.loadInto(settings);

    expect(settings.maxChars, defaultMaxChars);
  });

  test('a value at the lowered ceiling still loads unchanged', () async {
    final service = await _serviceWith({'maxCharacters': maxMaxChars});
    final settings = AppSettings();

    service.loadInto(settings);

    expect(settings.maxChars, maxMaxChars);
  });

  test('an out-of-range fontSize falls back to the default', () async {
    final tooLow = await _serviceWith({'fontSize': 5.0});
    final tooHigh = await _serviceWith({'fontSize': 9999.0});

    final lowSettings = AppSettings();
    final highSettings = AppSettings();
    tooLow.loadInto(lowSettings);
    tooHigh.loadInto(highSettings);

    expect(lowSettings.fontSize, 16.0);
    expect(highSettings.fontSize, 16.0);
  });

  test('a font size saved above the slider max but within the field range survives', () async {
    // The slider only reaches 144; the numeric field accepts up to 999. A
    // validator clamped to the slider's range would silently shrink a
    // legitimately saved larger size on every future load.
    final service = await _serviceWith({'fontSize': 200.0});
    final settings = AppSettings();

    service.loadInto(settings);

    expect(settings.fontSize, 200.0);
  });

  test('an unknown font family falls back to the app default instead of crashing font resolution', () async {
    final service = await _serviceWith({'fontFamily': 'Not A Real Font'});
    final settings = AppSettings();

    service.loadInto(settings);

    expect(settings.fontFamily, isNull);
  });

  test('a wrong-typed font family falls back to the app default', () async {
    final service = await _serviceWith({'fontFamily': 42});
    final settings = AppSettings();

    service.loadInto(settings);

    expect(settings.fontFamily, isNull);
  });

  test('no stored values load the same defaults as a fresh install', () async {
    final service = await _serviceWith({});
    final settings = AppSettings();

    service.loadInto(settings);

    expect(settings.maxChars, defaultMaxChars);
    expect(settings.theme, AppTheme.light);
    expect(settings.fontFamily, isNull);
    expect(settings.fontSize, 16.0);
  });
}
