# Contributing to Rolling Text

Contributions are welcome. Open an [issue](https://github.com/XeroIP/rolling-text/issues) before starting non-trivial work so the approach can be agreed on first.

## Setting up

Rolling Text pins **Flutter 3.44.8**. Both CI workflows install exactly that version, and a different local Flutter resolves `pubspec.lock` differently and rewrites it on `flutter pub get` — which shows up as unrelated lockfile churn in your diff.

```bash
git clone https://github.com/XeroIP/rolling-text.git
cd rolling-text
flutter pub get
flutter run -d chrome
```

## Before opening a pull request

- `flutter analyze` reports no issues.
- `flutter test` passes. The release workflow runs the same suite and refuses to publish if it fails.
- Test on the platform you changed. Android, iOS, and Web share one code path, so a fix for one usually affects all three.

Two tests deserve a note, because a failure means something other than "the test is wrong":

- `test/framework_assumptions_test.dart` asserts Flutter behaviour the app deliberately does not reimplement — Escape dismissal, arrow-key focus traversal, scroll-into-view. If it fails after an SDK upgrade, add the behaviour back to the app. Do not delete the test.
- `test/android_manifest_test.dart` guards the `INTERNET` permission in the release manifest. Debug builds grant it automatically for hot reload, so removing it breaks Google Fonts downloads in release builds only.

## Commits and branches

- Never commit to `main`. Branch first.
- [Conventional commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `build:`.
- Reference the issue: `Closes #N` when the change fully resolves it, `Refs #N` otherwise.

## Changing user-facing behaviour

Add an entry to the `## [Unreleased]` section of [`CHANGELOG.md`](CHANGELOG.md).

**Keep every bullet on one unbroken line.** GitHub's release renderer preserves mid-bullet newlines as visible line breaks instead of reflowing them, so a hard-wrapped bullet publishes as broken release notes.

Do not bump the version in `pubspec.yaml` in a feature PR. Versioning happens at release time, where the git tag, the `pubspec.yaml` version, and a matching `CHANGELOG.md` section all have to agree or the release workflow fails. See [Releasing](README.md#releasing).

## Editing workflows

`policy-pinned-actions.yml` fails any pull request that references a third-party action by tag or branch. Pin to a full 40-character commit SHA with the version in a trailing comment, matching the existing entries:

```yaml
- uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
```

## Things that will not be merged

Rolling Text exists so that what you write is not kept. Anything that persists, transmits, syncs, or recovers editor text — autosave, undo history that survives truncation, crash recovery, analytics on content — contradicts the premise of the app. Settings persist; text never does.
