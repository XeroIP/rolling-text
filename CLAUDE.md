# Rolling Text — project instructions

A Flutter app for Android, iOS, and Web with a rolling character limit: as you type past the limit, the oldest text is dropped. Nothing you write is ever saved.

## The premise is a constraint, not a feature

Editor text is never persisted, transmitted, or recovered. Only four settings reach storage — `maxCharacters`, `theme`, `fontFamily`, `fontSize` (`lib/services/preferences_service.dart`). Do not add autosave, crash recovery, undo history that survives truncation, or any telemetry carrying content. If a change seems to require it, ask first.

`enableIMEPersonalizedLearning: false` on the editor (`lib/screens/main_screen.dart:222`) keeps typed text out of the keyboard's dictionary on Android. It is a privacy guarantee; do not drop it while editing the `TextField`.

## Limits live in exactly one place

`lib/models/app_settings.dart` declares `minMaxChars`, `maxMaxChars`, `minFontSize`, and `maxFontSize`. Sheets and validators must read those constants — never hardcode the numbers, and never restate them in the README without checking. Duplicating the limit is what caused the 0.5.6 bug, where the Character Limit sheet still advertised 1,000,000 after the ceiling dropped to 25,000.

The ceiling is 25,000 for a reason: `EditableText` does not virtualize. It lays out every glyph in the field, so a higher ceiling makes every keystroke shape the whole buffer through the font pipeline.

`maxFontSize` is 999 because that is the numeric field's range. The slider's own maximum is the separate `maxSliderFontSize` constant, applied at the slider (`lib/widgets/font_size_sheet.dart`). Do not clamp `maxFontSize` down to the slider's range — it would shrink a legitimately saved larger size on load.

## Truncation operates on grapheme clusters

`truncateRollingText` in `lib/utils/text_truncation.dart` uses the `characters` package. Never reintroduce `substring`, code-unit, or code-point slicing: it splits ZWJ sequences, skin-tone modifiers, and regional-indicator flags in half. Enforcement also preserves the user's selection and defers entirely while an IME composition is active, rather than rewriting text underneath it.

## Releasing

Three things must agree or `build-release.yml` fails the release: the git tag `vX.Y.Z`, the `version:` in `pubspec.yaml`, and a `## [X.Y.Z]` section in `CHANGELOG.md`. The build number after the `+` must also increment — Android refuses to install an APK whose build number is not higher than the installed one.

Tags publish APKs. Pushes to `main` publish the web app via `deploy-web.yml`; whatever is on `main` is what the live site serves. These are separate paths.

CHANGELOG bullets stay on one unbroken line. GitHub's release renderer preserves mid-bullet newlines as visible line breaks, so a hard-wrapped bullet publishes as broken release notes.

## Toolchain and CI

Flutter is pinned to **3.44.8** in both workflows. A different local version resolves `pubspec.lock` differently and rewrites it on `flutter pub get`, which shows up as unrelated lockfile churn.

`policy-pinned-actions.yml` fails any workflow referencing a third-party action by tag instead of a full 40-character commit SHA. Pin with the version in a trailing comment.

## Tests that mean something specific

- `test/framework_assumptions_test.dart` is a tripwire, not a unit test. It asserts Flutter defaults the app deliberately does not reimplement — Escape dismissal, arrow-key focus traversal, scroll-into-view. If it fails after an SDK upgrade, restore the behaviour in `main_screen.dart`. Do not delete the test.
- `test/android_manifest_test.dart` guards `INTERNET` in the release manifest. Debug manifests grant it automatically for hot reload, so removing it breaks uncached Google Fonts downloads in release builds only.
- `test/widget_test.dart`'s `_pumpMainScreen` builds `AppSettings` from explicit parameters and never calls `loadInto`, so preference-loading behaviour is covered separately in `preferences_service_test.dart`.
- `test/documentation_consistency_test.dart` fails when a number or fact in `README.md`, `CONTRIBUTING.md`, or `CLAUDE.md` stops matching the constant, enum, or config file it describes — this is what caught the README once advertising a 1,000,000 character limit and a three-theme list after both had changed. A failure means the doc is stale; fix the doc, not the test.

## Layout

`lib/main.dart` wires `ChangeNotifierProvider` and hands `PreferencesService` to `MainScreen`. `lib/screens/main_screen.dart` is the single screen holding the editor and toolbar; the bottom-sheet widgets were extracted to `lib/widgets/` in 0.6.0 to keep it manageable. Keep new sheet widgets there rather than growing `main_screen.dart` back.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome        # or -d android, -d ios
```
