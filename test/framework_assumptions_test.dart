// Regression net for Flutter behaviour this app deliberately does NOT
// reimplement.
//
// Rolling Text's keyboard accessibility relies on framework defaults rather
// than custom key handling: Escape dismissal, arrow-key focus traversal, and
// scroll-into-view all come from Flutter itself. That keeps the app code small,
// but it means a future SDK upgrade could break accessibility with no failing
// test to explain why.
//
// These tests fail loudly if that ever stops being true. If one breaks after a
// Flutter upgrade, the fix is to add the corresponding behaviour back to
// main_screen.dart -- not to delete the test.

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:rolling_text/models/app_settings.dart';
import 'package:rolling_text/screens/main_screen.dart';
import 'package:rolling_text/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'Rolling Text',
    packageName: 'io.rollingtext.rolling_text',
    version: '0.4.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: AppSettings(),
      child: MaterialApp(
        home: MainScreen(prefsService: PreferencesService(preferences)),
      ),
    ),
  );
  await tester.pump();
}

/// Opens a sheet shaped like the app's Theme and Font sheets: a scrolling list
/// of [ListTile]s inside a modal bottom sheet.
Future<void> _pumpTileSheet(
  WidgetTester tester, {
  required int count,
  required double height,
  void Function(String label)? onActivate,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => SizedBox(
                  height: height,
                  child: ListView(
                    children: List.generate(
                      count,
                      (i) => ListTile(
                        autofocus: i == 0,
                        title: Text('Item $i'),
                        onTap: () => onActivate?.call('Item $i'),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

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

void main() {
  testWidgets('ModalRoute dismisses a bottom sheet on Escape', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('Character Limit'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Character Limit'), findsNothing);
  });

  test('bare arrows traverse focus off-Web but scroll on Web', () {
    // The single most important platform difference in this app's keyboard
    // support. WidgetsApp.defaultShortcuts returns a *different map* when
    // kIsWeb: bare arrows become ScrollIntent and only Tab traverses focus.
    // Every arrow-traversal test in this suite runs off-Web and therefore
    // passes while the browser cannot select a theme or font at all.
    //
    // This is why the Theme and Font sheets bind arrows to
    // DirectionalFocusIntent themselves (_rowTraversalShortcuts). If a future
    // SDK unifies the maps, this test fails and that binding becomes redundant
    // -- but harmless, so prefer leaving it.
    const down = SingleActivator(LogicalKeyboardKey.arrowDown);
    final Intent? offWeb = WidgetsApp.defaultShortcuts[down];

    expect(
      offWeb,
      isA<DirectionalFocusIntent>(),
      reason: 'off-Web (this test platform) bare arrows traverse focus, which is '
          'exactly why widget tests cannot catch the Web behaviour',
    );
    expect(
      kIsWeb,
      isFalse,
      reason: 'if this ever runs on Web, the expectation above must flip to '
          'ScrollIntent -- see WidgetsApp._defaultWebShortcuts',
    );
  });

  testWidgets('arrow keys traverse ListTiles and Enter activates the focused row', (
    tester,
  ) async {
    String? activated;
    await _pumpTileSheet(
      tester,
      count: 20,
      height: 400,
      onActivate: (label) => activated = label,
    );

    expect(_focusedTileLabel(), 'Item 0');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_focusedTileLabel(), 'Item 1');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activated, 'Item 1');
  });

  testWidgets('Enter reaches an enclosing CallbackShortcuts even while a field has focus', (
    tester,
  ) async {
    var submitted = 0;
    var shortcutFired = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.enter): () => shortcutFired++,
            },
            child: Column(
              children: [
                TextField(autofocus: true, onSubmitted: (_) => submitted++),
                TextButton(onPressed: () {}, child: const Text('other')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // The Font Size sheet needs Enter to commit from the slider as well as the
    // field, so it binds Enter at the sheet level. This pins why that binding
    // cannot be the *only* Enter path, and why the commit must be re-entrant:
    //
    // - A raw Enter reaches the sheet-level binding whatever holds focus, so a
    //   field-focused Enter can trigger the sheet binding too.
    // - A raw Enter does NOT fire onSubmitted; that arrives as a platform text
    //   input action instead (TextInputAction.done), which is the only Enter an
    //   Android soft keyboard produces. Dropping onSubmitted would break Enter
    //   on mobile.
    //
    // On Web both fire for one keypress, hence the _closing guard on the commit
    // path. Tests driving the field's own Enter must use
    // testTextInput.receiveAction, not sendKeyEvent.
    expect(shortcutFired, 1, reason: 'sheet-level Enter fires regardless of focus');
    expect(submitted, 0, reason: 'onSubmitted comes from the platform action, not a raw key');
  });

  testWidgets(
    'a bare TextField unfocuses itself on an outside tap on desktop platforms',
    (tester) async {
      // This is the framework default #29's fix works around: EditableText's
      // built-in TapRegion unfocuses on an outside tap on desktop platforms
      // (and, separately, on Web) unless onTapOutside is overridden. The
      // editor in main_screen.dart supplies its own onTapOutside specifically
      // to prevent this. If a future SDK stops unfocusing here by default,
      // that override becomes redundant -- but harmless, so prefer leaving it
      // rather than deleting this test.
      // Reset before the test ends, not via addTearDown: flutter_test checks
      // this debug variable is back to its original value immediately after
      // the test body returns, which runs before addTearDown callbacks fire.
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextField(focusNode: focusNode, autofocus: true),
                  const SizedBox(height: 200, child: Text('elsewhere')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        await tester.tap(find.text('elsewhere'));
        await tester.pumpAndSettle();

        expect(focusNode.hasFocus, isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('focus traversal reaches and reveals off-screen tiles', (
    tester,
  ) async {
    await _pumpTileSheet(tester, count: 21, height: 300);

    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.pixels, 0);

    for (var i = 0; i < 20; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }

    // Tiles past the viewport are built lazily; traversal must still reach them
    // and scroll them into view without any manual scroll math.
    expect(_focusedTileLabel(), 'Item 20');
    expect(scrollable.position.pixels, greaterThan(0));
  });
}
