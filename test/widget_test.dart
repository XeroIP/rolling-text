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

AppSettings _settings(WidgetTester tester) => Provider.of<AppSettings>(
  tester.element(find.byType(MainScreen)),
  listen: false,
);

/// The numeric field inside an open sheet. The editor is the first TextField on
/// screen, so the sheet's own field is the last.
TextEditingController _sheetInput(WidgetTester tester) =>
    tester.widgetList<TextField>(find.byType(TextField)).last.controller!;

Future<void> _openCustomFontSize(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.format_size));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Enter custom size…'));
  await tester.pumpAndSettle();
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

  group('numeric sheets are usable from the keyboard alone', () {
    testWidgets('character limit preselects its value so typing replaces it', (
      tester,
    ) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      final expected = '${_settings(tester).maxChars}';
      final input = _sheetInput(tester);
      expect(input.text, expected);
      expect(
        input.selection,
        TextSelection(baseOffset: 0, extentOffset: expected.length),
        reason: 'Without a full selection the first keystroke appends to the '
            'existing limit instead of replacing it',
      );
    });

    testWidgets('character limit applies on Enter', (tester) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '200');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Character Limit'), findsNothing);
      expect(_settings(tester).maxChars, 200);
    });

    testWidgets('custom font size preselects its value so typing replaces it', (
      tester,
    ) async {
      await _pumpMainScreen(tester);
      await _openCustomFontSize(tester);

      final input = _sheetInput(tester);
      expect(
        input.selection,
        TextSelection(baseOffset: 0, extentOffset: input.text.length),
      );
    });

    testWidgets('custom font size applies on Enter', (tester) async {
      await _pumpMainScreen(tester);
      await _openCustomFontSize(tester);

      await tester.enterText(find.byType(TextField).last, '42');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Custom Font Size'), findsNothing);
      expect(_settings(tester).fontSize, 42);
    });
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
