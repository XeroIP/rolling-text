# Releasing and CI

Maintainer documentation. For contributor setup and commit conventions, see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Releasing

Releases are cut from tags. [`CHANGELOG.md`](../CHANGELOG.md) is the single source of truth for what a release says.

1. Add a `## [X.Y.Z] - YYYY-MM-DD` section to `CHANGELOG.md`. Keep every bullet on one unbroken line — GitHub's release renderer turns mid-bullet newlines into visible line breaks instead of reflowing them.
2. Set the matching version in `pubspec.yaml`, incrementing the build number after the `+` as well. Android refuses to install an APK whose build number is not higher than the installed one.
3. Tag and push:

    ```bash
    git tag v0.5.0
    git push origin v0.5.0
    ```

The `Build and release` workflow then runs the tests, builds signed release and debug APKs, and publishes a GitHub release whose notes are that CHANGELOG section followed by the auto-generated list of merged pull requests, with both APKs attached.

It fails the release rather than publishing something wrong if the tag does not match `pubspec.yaml`, or if `CHANGELOG.md` has no section for that version.

To build APKs without releasing, run the workflow manually from the Actions tab (`Actions > Build and release > Run workflow`); the APKs are uploaded as build artifacts instead.

Tagging only publishes the APKs. The web app is published separately, as described below, so a release tag is not what updates the site.

## Continuous integration

Three workflows run in `.github/workflows/`, all pinned to Flutter 3.44.8:

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `build-release.yml` | Tag `v*.*.*`, or manual | Tests, builds signed APKs, publishes the GitHub release. See [Releasing](#releasing). |
| `deploy-web.yml` | Every push to `main` | Builds `flutter build web --release --base-href /rolling-text/` and publishes it to GitHub Pages. |
| `policy-pinned-actions.yml` | Push to `main`, and any PR touching `.github/workflows/**` | Fails if a third-party action is referenced by tag instead of a full 40-character commit SHA. |

Because `deploy-web.yml` fires on every push to `main`, whatever is on `main` is what https://xeroip.github.io/rolling-text/ serves. There is no separate step to publish the web app.
