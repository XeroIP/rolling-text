import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Flutter's debug manifest grants INTERNET automatically for hot reload, so
  // downloading Google Fonts works in development even when the main manifest
  // is missing the permission -- the failure only appears in release builds.
  // This test closes that gap.
  test('Android release manifest allows uncached Google Fonts to download', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      matches(
        RegExp(
          r'<uses-permission\s+android:name="android\.permission\.INTERNET"\s*/>',
        ),
      ),
      reason: 'Release builds cannot fetch uncached fonts without INTERNET',
    );
  });
}
