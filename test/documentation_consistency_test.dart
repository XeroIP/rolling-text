// Guards documented facts against the code that actually backs them.
//
// The feature list -- now docs/user-guide.md, previously README.md -- has
// twice advertised a number the app no longer enforced: the character limit
// stayed at 1,000,000 after the real ceiling dropped to 25,000, and the
// Themes list named three themes after a fourth and fifth shipped. Both were
// only caught by a manual audit; this test makes that audit automatic. A
// failure here means a doc went stale, not that the test is wrong -- fix the
// doc.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rolling_text/models/app_settings.dart';
import 'package:rolling_text/theme/app_theme.dart';

/// The repo is checked out with CRLF line endings on Windows but LF on the
/// Ubuntu CI runner; every regex below assumes LF, so normalize on read.
String _readFile(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');

/// The user-facing feature list. The bullets checked below live here.
const _userGuide = 'docs/user-guide.md';

/// Same grouping a reader uses: digits from the right, in threes.
String _withThousandsSeparator(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Text of the bold bullet starting with `- **[label]**` in [path], up to the
/// end of that line. Fails with the label name if the bullet is gone or
/// renamed, rather than silently matching nothing -- which is also what keeps
/// a wrong [path] from passing vacuously.
String _bullet(String path, String label) {
  final pattern = RegExp('- \\*\\*$label\\*\\*[^\\n]*');
  final match = pattern.firstMatch(_readFile(path));
  expect(
    match,
    isNotNull,
    reason: '$path has no "- **$label**" bullet to check against '
        '$label -- did it get renamed or moved to another file?',
  );
  return match!.group(0)!;
}

void main() {
  group('Documented claims that must match app_settings.dart / app_theme.dart',
      () {
    test('character limit matches minMaxChars/maxMaxChars', () {
      final bullet = _bullet(_userGuide, 'Configurable character limit');
      expect(
        bullet,
        contains(
          'from $minMaxChars to ${_withThousandsSeparator(maxMaxChars)} characters',
        ),
        reason:
            'The $_userGuide character limit no longer matches maxMaxChars in '
            'lib/models/app_settings.dart. This is exactly how the docs '
            'once advertised 1,000,000 after the real ceiling dropped to '
            '25,000 -- update the user guide bullet, not this test.',
      );
    });

    test('theme list matches AppTheme.values', () {
      final bullet = _bullet(_userGuide, 'Themes');
      final listed = bullet
          .replaceFirst('- **Themes** - ', '')
          .split(RegExp(r',\s*(?:and\s+)?|\s+and\s+'))
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toSet();
      final actual = AppTheme.values.map((theme) => theme.label).toSet();

      expect(
        listed,
        equals(actual),
        reason:
            'The $_userGuide Themes bullet lists $listed but AppTheme.values '
            'in lib/theme/app_theme.dart has $actual. This is exactly how the '
            'docs once undercounted the themes after Night and Dark Sepia '
            'shipped -- update the user guide bullet, not this test.',
      );
    });

    test('font count matches availableFonts.length', () {
      final bullet = _bullet(_userGuide, 'Font picker');
      expect(
        bullet,
        contains('${availableFonts.length} curated Google Fonts'),
        reason:
            'The $_userGuide font count no longer matches '
            'availableFonts.length in lib/models/app_settings.dart.',
      );
    });

    test('font size range matches minFontSize/maxFontSize/maxSliderFontSize', () {
      final bullet = _bullet(_userGuide, 'Adjustable font size');
      expect(
        bullet,
        contains(
          '${minFontSize.round()}pt to ${maxFontSize.round()}pt',
        ),
        reason:
            'The numeric field range in $_userGuide no longer matches '
            'minFontSize/maxFontSize in lib/models/app_settings.dart.',
      );
      expect(
        bullet,
        contains(
          'slider for ${minFontSize.round()}pt to ${maxSliderFontSize.round()}pt',
        ),
        reason:
            'The slider range in $_userGuide no longer matches '
            'minFontSize/maxSliderFontSize in lib/models/app_settings.dart.',
      );
    });
  });

  group('Toolchain claims that must match the workflows and pubspec', () {
    String flutterVersionFrom(String workflowPath) {
      final contents = _readFile(workflowPath);
      final match = RegExp(r'flutter-version:\s*(\S+)').firstMatch(contents);
      expect(
        match,
        isNotNull,
        reason: '$workflowPath has no flutter-version: line to check.',
      );
      return match!.group(1)!;
    }

    test('both workflows pin the same Flutter version', () {
      final buildRelease =
          flutterVersionFrom('.github/workflows/build-release.yml');
      final deployWeb = flutterVersionFrom('.github/workflows/deploy-web.yml');

      expect(
        buildRelease,
        equals(deployWeb),
        reason:
            'build-release.yml pins Flutter $buildRelease but deploy-web.yml '
            'pins $deployWeb. A local Flutter matching only one of them will '
            'resolve pubspec.lock differently than the workflow that '
            'disagrees.',
      );
    });

    test('every doc that names the toolchain states the pinned Flutter version',
        () {
      final version =
          flutterVersionFrom('.github/workflows/build-release.yml');

      for (final path in [
        'README.md',
        'CONTRIBUTING.md',
        'CLAUDE.md',
        'docs/releasing.md',
      ]) {
        expect(
          _readFile(path),
          contains(version),
          reason:
              '$path does not mention Flutter $version, the version pinned '
              'in build-release.yml. This is the class of drift that once '
              'left "Flutter 3.x" in the README next to a hard 3.44.8 pin.',
        );
      }
    });

    test('README dependency list matches pubspec.yaml dependencies', () {
      final pubspec = _readFile('pubspec.yaml');
      // Captures indented (or blank) lines directly under "dependencies:",
      // stopping at the next line that starts a new top-level key.
      final depsBlock = RegExp(
        r'\ndependencies:\n((?:  .*\n|\n)*)',
      ).firstMatch(pubspec);
      expect(
        depsBlock,
        isNotNull,
        reason: 'pubspec.yaml has no dependencies: block to check against.',
      );

      final pubspecDeps = RegExp(r'^\s{2}([a-zA-Z0-9_]+):', multiLine: true)
          .allMatches(depsBlock!.group(1)!)
          .map((m) => m.group(1)!)
          .where((name) => name != 'flutter')
          .toSet();

      final bullet = _bullet('README.md', 'Dependencies');
      final readmeDeps = RegExp(r'`([a-zA-Z0-9_]+)`')
          .allMatches(bullet)
          .map((m) => m.group(1)!)
          .toSet();

      expect(
        readmeDeps,
        equals(pubspecDeps),
        reason:
            'README Dependencies bullet lists $readmeDeps but pubspec.yaml '
            'dependencies: has $pubspecDeps. Adding or removing a package '
            'should update both.',
      );
    });
  });
}
