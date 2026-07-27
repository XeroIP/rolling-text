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
