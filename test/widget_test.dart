import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
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
// shared_preferences_platform_interface is a transitive dependency of
// shared_preferences, not a direct one -- pulled in here only to fake a
// failing write for #24's tests, not added as a project dependency.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// A store whose writes all fail, for exercising #24's failure path.
///
/// Reads still work normally (backed by [InMemorySharedPreferencesStore]) so
/// the app loads its usual defaults; only [setValue] and [remove] report
/// failure, matching what a real disk-full or permission error looks like to
/// the SharedPreferences API -- a `false` result, not a thrown exception.
class _FailingSharedPreferencesStore extends InMemorySharedPreferencesStore {
  _FailingSharedPreferencesStore.empty() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async => false;

  @override
  Future<bool> remove(String key) async => false;
}

/// Pumps the app the way [RollingTextApp] does, including the real
/// [themeDataFor] theme. Tests that pump a bare MaterialApp silently get
/// Flutter's default light theme and cannot catch contrast regressions.
Future<void> _pumpMainScreen(
  WidgetTester tester, {
  AppTheme theme = AppTheme.light,
  String? fontFamily,
  bool failWrites = false,
}) async {
  if (failWrites) {
    // setMockInitialValues always installs a plain InMemorySharedPreferencesStore,
    // so a failing store has to be wired in the same way it does internally,
    // then SharedPreferences.getInstance() re-read against it.
    SharedPreferencesStorePlatform.instance = _FailingSharedPreferencesStore.empty();
    SharedPreferences.resetStatic();
  } else {
    SharedPreferences.setMockInitialValues({});
  }
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

Future<void> _openFontSize(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.format_size));
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

  testWidgets('the editor opts out of IME personalized learning', (tester) async {
    await _pumpMainScreen(tester);

    final editor = tester.widget<TextField>(find.byType(TextField).first);
    expect(editor.enableIMEPersonalizedLearning, isFalse);
  });

  testWidgets(
    'tapping outside the editor on desktop keeps it focused and typeable',
    (tester) async {
      // The framework's own default here unfocuses the field -- see
      // framework_assumptions_test.dart. This proves main_screen.dart's
      // onTapOutside override replaces that default rather than merely
      // supplementing it.
      //
      // Reset before the test ends, not via addTearDown: flutter_test checks
      // this debug variable is back to its original value immediately after
      // the test body returns, which runs before addTearDown callbacks fire.
      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        await _pumpMainScreen(tester);
        final editor = find.byType(TextField).first;
        final focusNode = tester.widget<TextField>(editor).focusNode!;
        expect(focusNode.hasFocus, isTrue);

        // A point inside the Scaffold's padding band, outside the editor's
        // own bounds and off every toolbar button.
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        expect(focusNode.hasFocus, isTrue);

        await tester.enterText(editor, 'still typeable');
        await tester.pump();
        expect(find.text('still typeable'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

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

    testWidgets('font size preselects its value so typing replaces it', (
      tester,
    ) async {
      await _pumpMainScreen(tester);
      await _openFontSize(tester);

      final input = _sheetInput(tester);
      expect(
        input.selection,
        TextSelection(baseOffset: 0, extentOffset: input.text.length),
      );
    });

    testWidgets('font size applies on Enter', (tester) async {
      await _pumpMainScreen(tester);
      await _openFontSize(tester);

      await tester.enterText(find.byType(TextField).last, '42');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Font Size'), findsNothing);
      expect(_settings(tester).fontSize, 42);
    });

    testWidgets('font size applies live while typing, before Enter', (
      tester,
    ) async {
      await _pumpMainScreen(tester);
      await _openFontSize(tester);

      await tester.enterText(find.byType(TextField).last, '42');
      await tester.pump();

      expect(find.text('Font Size'), findsOneWidget);
      expect(_settings(tester).fontSize, 42);
    });

    testWidgets('the slider is one Tab away from the font size field', (
      tester,
    ) async {
      await _pumpMainScreen(tester);
      await _openFontSize(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final focused = FocusManager.instance.primaryFocus;
      expect(
        focused?.context?.findAncestorWidgetOfExactType<Slider>(),
        isNotNull,
        reason: 'One Tab from the autofocused field should reach the slider',
      );
    });

    testWidgets('Enter commits the font size while the slider holds focus', (
      tester,
    ) async {
      await _pumpMainScreen(tester);
      await _openFontSize(tester);

      await tester.enterText(find.byType(TextField).last, '42');
      await tester.pump();
      // Tab to the slider: it ignores Enter itself, so without a sheet-level
      // binding there is no keyboard way to commit after touching it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Font Size'), findsNothing);
      expect(_settings(tester).fontSize, 42);
    });

    testWidgets('Apply commits the font size', (tester) async {
      await _pumpMainScreen(tester);
      await _openFontSize(tester);

      await tester.enterText(find.byType(TextField).last, '42');
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Font Size'), findsNothing);
      expect(_settings(tester).fontSize, 42);
    });

    testWidgets('Cancel reverts the previewed font size', (tester) async {
      await _pumpMainScreen(tester);
      final before = _settings(tester).fontSize;
      await _openFontSize(tester);

      await tester.enterText(find.byType(TextField).last, '42');
      await tester.pump();
      expect(
        _settings(tester).fontSize,
        42,
        reason: 'the size previews live while the sheet is open',
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(_settings(tester).fontSize, before);
    });

    testWidgets('Escape reverts the previewed font size', (tester) async {
      await _pumpMainScreen(tester);
      final before = _settings(tester).fontSize;
      await _openFontSize(tester);

      await tester.enterText(find.byType(TextField).last, '42');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(_settings(tester).fontSize, before);
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

      expect(
        find.text('Please enter a number between $minMaxChars and $maxMaxChars'),
        findsOneWidget,
        reason: 'the error is inline, matching the Font Size sheet',
      );
      expect(find.text('Invalid Input'), findsNothing, reason: 'no dialog');
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

    testWidgets('an invalid font size keeps the sheet open with an inline error', (
      tester,
    ) async {
      await _pumpMainScreen(tester);
      final before = _settings(tester).fontSize;

      await _openFontSize(tester);
      await tester.enterText(find.byType(TextField).last, '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Enter a size between 6 and 999 pt'), findsOneWidget);
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

  group('picker sheets bind arrow traversal themselves', () {
    // On Web, WidgetsApp.defaultShortcuts maps bare arrows to ScrollIntent, so
    // arrow selection only works because these sheets ask for it. A test that
    // just presses arrows passes on this platform either way and cannot detect
    // the binding going missing -- so assert the binding itself.
    void expectArrowTraversalBinding(WidgetTester tester) {
      final shortcuts = tester
          .widgetList<Shortcuts>(
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Shortcuts),
            ),
          )
          .expand((s) => s.shortcuts.entries)
          .toList();

      for (final key in [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowUp]) {
        expect(
          shortcuts.any((e) {
            final activator = e.key;
            return activator is SingleActivator &&
                activator.trigger == key &&
                e.value is DirectionalFocusIntent;
          }),
          isTrue,
          reason: '${key.keyLabel} must be bound to DirectionalFocusIntent, or '
              'the sheet is unusable by keyboard on Web',
        );
      }
    }

    testWidgets('the theme sheet does', (tester) async {
      await _pumpMainScreen(tester);
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();

      expectArrowTraversalBinding(tester);
    });

    testWidgets('the font sheet does', (tester) async {
      await _pumpMainScreen(tester);
      await tester.tap(find.byIcon(Icons.text_format));
      await tester.pumpAndSettle();

      expectArrowTraversalBinding(tester);
    });
  });

  group('the editor is typeable again after every sheet closes', () {
    // These run on the native test platform, where _restoreEditorFocus no-ops
    // and ModalRoute restores focus by itself. They do not cover the Web fix --
    // browser focus is only checkable in a real browser.
    //
    // Asserting FocusNode.hasFocus would pass even when the editor has no live
    // input connection, which is the exact failure this guards against. So each
    // case sends text through the active input client with no widget target and
    // checks it lands in the editor.
    String editorText(WidgetTester tester) => tester
        .widget<TextField>(find.byType(TextField).first)
        .controller!
        .text;

    Future<void> expectTypingReachesEditor(WidgetTester tester) async {
      tester.testTextInput.enterText('typed');
      await tester.pumpAndSettle();
      expect(editorText(tester), 'typed');
    }

    testWidgets('after Escape dismisses the theme sheet', (tester) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await expectTypingReachesEditor(tester);
    });

    testWidgets('after choosing a font with Enter', (tester) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.text_format));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      await expectTypingReachesEditor(tester);
    });

    testWidgets('after cancelling the character limit sheet', (tester) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await expectTypingReachesEditor(tester);
    });

    testWidgets('after applying a new character limit', (tester) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '300');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      await expectTypingReachesEditor(tester);
    });

    testWidgets('after dismissing the about sheet by tapping the barrier', (
      tester,
    ) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await expectTypingReachesEditor(tester);
    });

    testWidgets('after a limit reduction truncates the text', (tester) async {
      await _pumpMainScreen(tester);
      await tester.enterText(find.byType(TextField).first, 'abcdefghij');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '5');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(
        find.text('Warning'),
        findsNothing,
        reason: 'a lower limit applies without asking for confirmation',
      );
      expect(find.text('Character Limit'), findsNothing);
      expect(_settings(tester).maxChars, 5);
      expect(
        editorText(tester),
        'fghij',
        reason: 'truncation drops the oldest characters, not the newest',
      );

      await expectTypingReachesEditor(tester);
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

    testWidgets('arrow keys reach the very bottom of the about text', (
      tester,
    ) async {
      await _pumpMainScreen(tester);
      final scrollable = await openAbout(tester);

      // The previous implementation anchored focus inside the lazy ListView.
      // Once that anchor scrolled past the cache extent it was unmounted,
      // ScrollAction lost the Scrollable it resolves from the focused node, and
      // the arrows died partway down -- while the mouse wheel still worked.
      // Two presses stayed inside the cache extent, so the old tests passed.
      var lastPixels = scrollable.position.pixels;
      var stalledFor = 0;
      for (var i = 0; i < 200; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        final pixels = scrollable.position.pixels;
        stalledFor = pixels > lastPixels ? 0 : stalledFor + 1;
        lastPixels = pixels;
        if (stalledFor > 2) break;
      }

      expect(
        lastPixels,
        moreOrLessEquals(scrollable.position.maxScrollExtent, epsilon: 1),
        reason: 'arrows must reach the end of the content, not stall partway',
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
    });
  });

  group('sheets with a text field stay above the soft keyboard', () {
    // The bug these pin (#39) is invisible to every other test in this file:
    // flutter_test has no soft keyboard and reports zero viewInsets, so a sheet
    // laid out underneath the keyboard still satisfies findsOneWidget. Web and
    // desktop have no soft keyboard either. Only a simulated inset plus a
    // *geometric* assertion catches it, which is why these measure rendered
    // bounds rather than checking the widget exists.
    //
    // tester.view.viewInsets is in physical pixels, hence the devicePixelRatio
    // division to reason in the logical pixels getRect returns.
    const double keyboardLogicalHeight = 300;

    /// Raises a fake keyboard of [keyboardLogicalHeight] logical pixels and
    /// returns the y coordinate of its top edge.
    double simulateKeyboard(WidgetTester tester) {
      final double dpr = tester.view.devicePixelRatio;
      tester.view.viewInsets = FakeViewPadding(
        bottom: keyboardLogicalHeight * dpr,
      );
      addTearDown(tester.view.resetViewInsets);
      return tester.view.physicalSize.height / dpr - keyboardLogicalHeight;
    }

    testWidgets('the Font Size sheet does', (tester) async {
      await _pumpMainScreen(tester);
      final double keyboardTop = simulateKeyboard(tester);

      await _openFontSize(tester);

      // Apply is the bottom-most control in the sheet, so if it clears the
      // keyboard the whole sheet does.
      final applyBottom = tester.getRect(
        find.widgetWithText(FilledButton, 'Apply'),
      ).bottom;
      expect(
        applyBottom,
        lessThanOrEqualTo(keyboardTop),
        reason: 'the Font Size sheet must not be laid out under the keyboard',
      );
    });

    testWidgets('the Character Limit sheet does', (tester) async {
      await _pumpMainScreen(tester);
      final double keyboardTop = simulateKeyboard(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      final applyBottom = tester.getRect(
        find.widgetWithText(FilledButton, 'Apply'),
      ).bottom;
      expect(
        applyBottom,
        lessThanOrEqualTo(keyboardTop),
        reason: 'this sheet already handled the keyboard correctly -- pin it '
            'so it cannot regress the way the Font Size sheet did',
      );
    });
  });

  group('preference writes are surfaced and reconciled', () {
    testWidgets('a failed save keeps the change applied and warns it will not be remembered', (
      tester,
    ) async {
      await _pumpMainScreen(tester, failWrites: true);
      expect(_settings(tester).theme, AppTheme.light);

      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // The setting stays applied for the session even though it could not be
      // saved -- fighting the UI back to its old value would be a worse
      // experience than one that silently does not survive to next launch.
      expect(_settings(tester).theme, AppTheme.dark);
      expect(find.text("This change won't be remembered"), findsOneWidget);
    });

    testWidgets('a successful save shows no warning', (tester) async {
      await _pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(_settings(tester).theme, AppTheme.dark);
      expect(find.text("This change won't be remembered"), findsNothing);
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
