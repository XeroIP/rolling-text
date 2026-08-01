# Rolling Text

[![Android](https://img.shields.io/badge/Android-7.0%2B-green)](https://www.android.com)
[![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue)](https://www.apple.com/ios/)
[![Web](https://img.shields.io/badge/Web-Chrome%2FSafari-orange)](https://github.com/XeroIP/rolling-text)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A simple app for Android, iOS, and Web that gives you a place to write down your thoughts without keeping them. As you type, older text quietly disappears. Nothing is saved. Nothing is stored.

## Documentation

- [User guide](docs/user-guide.md) — how the rolling limit works, and every setting
- [Why this works](docs/about.md) — the premise, and the research behind it
- [Contributing](CONTRIBUTING.md) — setup, tests, and commit conventions
- [Releasing](docs/releasing.md) — release process and CI workflows

## Installation

### Web app

Try it in your browser at https://xeroip.github.io/rolling-text/

### Run from source

Requires Flutter 3.44.8. CI is pinned to this version; a different local Flutter will
resolve `pubspec.lock` differently and rewrite it on `flutter pub get`.

1. Clone the repository:

    ```bash
    git clone https://github.com/XeroIP/rolling-text.git
    cd rolling-text
    ```

2. Install dependencies:

    ```bash
    flutter pub get
    ```

3. Run on your target platform:

    ```bash
    flutter run -d chrome        # Web
    flutter run -d android       # Android device or emulator
    flutter run -d ios           # iOS device or simulator (requires macOS + Xcode)
    ```

### Build

```bash
flutter build apk                        # Android APK
flutter build appbundle                  # Android App Bundle
flutter build ios --no-codesign          # iOS (requires macOS + Xcode)
flutter build web                        # Web
```

### APK download

Download the latest APK from the [Releases](https://github.com/XeroIP/rolling-text/releases) page.

## Technical Details

- **Platforms**: Android, iOS, Web
- **Language**: Dart
- **Framework**: Flutter 3.44.8 (pinned; see [Run from source](#run-from-source))
- **Architecture**: Provider (ChangeNotifier)
- **Dependencies**: `provider`, `shared_preferences`, `google_fonts`, `package_info_plus`, `characters`, `cupertino_icons`

## Roadmap

Have an idea for Rolling Text? Feature requests are welcome on the [GitHub Issues](https://github.com/XeroIP/rolling-text/issues) page.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the setup, testing, and commit conventions, then open an issue or pull request on [GitHub](https://github.com/XeroIP/rolling-text).

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Created by Peter Kirschman
