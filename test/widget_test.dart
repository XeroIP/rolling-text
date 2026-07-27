import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:rolling_text/models/app_settings.dart';
import 'package:rolling_text/screens/main_screen.dart';
import 'package:rolling_text/services/preferences_service.dart';
import 'package:rolling_text/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the app the way [RollingTextApp] does, including the real
/// [themeDataFor] theme. Tests that pump a bare MaterialApp silently get
/// Flutter's default light theme and cannot catch contrast regressions.
Future<void> _pumpMainScreen(
  WidgetTester tester, {
  AppTheme theme = AppTheme.light,
}) async {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'Rolling Text',
    packageName: 'io.rollingtext.rolling_text',
    version: '0.4.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final preferences = await SharedPreferences.getInstance();
  final settings = AppSettings()..setTheme(theme);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        theme: themeDataFor(theme),
        home: MainScreen(prefsService: PreferencesService(preferences)),
      ),
    ),
  );
  await tester.pump();
}

/// Reads the colour a bottom sheet actually paints, rather than the value of a
/// constructor argument, so the assertion reflects what the user sees.
Color _sheetSurfaceColor(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .descendant(of: find.byType(BottomSheet), matching: find.byType(Material))
        .first,
  );
  return material.color!;
}

void main() {
  testWidgets('editor renders one app-owned hint until text is entered', (
    tester,
  ) async {
    await _pumpMainScreen(tester);

    expect(find.text('Start typing…'), findsOneWidget);
    final editor = tester.widget<TextField>(find.byType(TextField).first);
    expect(editor.decoration?.hintText, isNull);
    expect(tester.getSize(find.byType(TextField).first).width, greaterThan(700));
    expect(
      tester.getTopLeft(find.text('Start typing…')),
      tester.getTopLeft(find.byType(TextField).first),
    );

    await tester.enterText(find.byType(TextField).first, 'Hello');
    await tester.pump();

    expect(find.text('Start typing…'), findsNothing);
    expect(tester.getSize(find.byType(TextField).first).width, greaterThan(700));
  });

  for (final theme in AppTheme.values) {
    testWidgets('${theme.label} sheets are distinguishable from the editor', (
      tester,
    ) async {
      await _pumpMainScreen(tester, theme: theme);

      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();

      expect(
        _sheetSurfaceColor(tester),
        isNot(colorsFor(theme).background),
        reason: 'A sheet painted in the editor background has no visible edge',
      );
    });
  }
}
