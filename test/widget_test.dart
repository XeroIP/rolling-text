import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? fontFamily,
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
  if (fontFamily != null) settings.setFontFamily(fontFamily);

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

/// Walks up from the primary focus to its enclosing [ListTile] title, so tests
/// can assert *which* row owns focus.
String? _focusedTileLabel() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  ListTile? tile;
  context.visitAncestorElements((element) {
    if (element.widget is ListTile) {
      tile = element.widget as ListTile;
      return false;
    }
    return true;
  });
  final title = tile?.title;
  return title is Text ? title.data : null;
}

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

  group('numeric sheets only commit valid values', () {
    testWidgets('an invalid limit keeps the sheet open with the value intact', (
      tester,
    ) async {
      await _pumpMainScreen(tester);
      final before = _settings(tester).maxChars;

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Invalid Input'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        find.text('Character Limit'),
        findsOneWidget,
        reason: 'Closing the sheet would discard the value the user must fix',
      );
      expect(_sheetInput(tester).text, '0');
      expect(_settings(tester).maxChars, before);
    });

    testWidgets('a rejected limit is refocused and reselected for retyping', (
      tester,
    ) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        _sheetInput(tester).selection,
        const TextSelection(baseOffset: 0, extentOffset: 1),
      );
      expect(tester.testTextInput.hasAnyClients, isTrue);
    });

    testWidgets('a corrected limit applies after a rejection', (tester) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '300');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Character Limit'), findsNothing);
      expect(_settings(tester).maxChars, 300);
    });

    testWidgets('cancelling the limit sheet changes nothing', (tester) async {
      await _pumpMainScreen(tester);
      final before = _settings(tester).maxChars;

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '900');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(_settings(tester).maxChars, before);
    });

    testWidgets('an invalid font size keeps the sheet open', (tester) async {
      await _pumpMainScreen(tester);
      final before = _settings(tester).fontSize;

      await _openCustomFontSize(tester);
      await tester.enterText(find.byType(TextField).last, '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Invalid Input'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Font Size'), findsOneWidget);
      expect(_settings(tester).fontSize, before);
    });
  });

  group('theme and font sheets are keyboard navigable', () {
    testWidgets('theme sheet opens with the active theme focused', (
      tester,
    ) async {
      await _pumpMainScreen(tester, theme: AppTheme.sepia);

      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();

      expect(_focusedTileLabel(), 'Sepia');
    });

    testWidgets('theme sheet applies the focused theme on Enter', (
      tester,
    ) async {
      await _pumpMainScreen(tester);
      expect(_settings(tester).theme, AppTheme.light);

      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedTileLabel(), 'Dark');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(_settings(tester).theme, AppTheme.dark);
      expect(find.text('Select Theme'), findsNothing);
    });

    testWidgets('font sheet opens with the active font focused', (tester) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.text_format));
      await tester.pumpAndSettle();

      expect(_focusedTileLabel(), 'Source Code Pro (Default)');
    });

    testWidgets('font sheet applies the focused font on Enter', (tester) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.text_format));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedTileLabel(), 'Courier Prime');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(_settings(tester).fontFamily, 'Courier Prime');
      expect(find.text('Select Font'), findsNothing);
    });

    testWidgets('font sheet reveals an active font far down the list', (
      tester,
    ) async {
      // Work Sans is last of 20. Tiles past the viewport are built lazily, so a
      // tile that is never built cannot take autofocus.
      await _pumpMainScreen(tester, fontFamily: 'Work Sans');

      await tester.tap(find.byIcon(Icons.text_format));
      await tester.pumpAndSettle();

      expect(_focusedTileLabel(), 'Work Sans');
      expect(find.text('Work Sans'), findsOneWidget);
    });

    testWidgets('Enter activates the focused control, not the list', (
      tester,
    ) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();

      // Move focus off the list and onto the Close button.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab, character: null);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(_focusedTileLabel(), isNull, reason: 'focus should be off the list');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // A sheet-wide Enter binding would apply a theme here instead of
      // activating the focused button.
      expect(find.text('Select Theme'), findsNothing);
      expect(_settings(tester).theme, AppTheme.light);
    });
  });

  group('about sheet is readable from the keyboard', () {
    Future<ScrollableState> openAbout(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      return tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Scrollable),
            )
            .last,
      );
    }

    testWidgets('arrow keys scroll the about text', (tester) async {
      await _pumpMainScreen(tester);
      final scrollable = await openAbout(tester);
      final start = scrollable.position.pixels;

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final afterDown = scrollable.position.pixels;
      expect(afterDown, greaterThan(start));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, lessThan(afterDown));
    });

    testWidgets('page keys scroll the about text further than arrows', (
      tester,
    ) async {
      await _pumpMainScreen(tester);
      final scrollable = await openAbout(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, greaterThan(0));
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
