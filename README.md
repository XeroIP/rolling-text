# Rolling Text

[![Android](https://img.shields.io/badge/Android-7.0%2B-green)](https://www.android.com)
[![iOS](https://img.shields.io/badge/iOS-12.0%2B-blue)](https://www.apple.com/ios/)
[![Web](https://img.shields.io/badge/Web-Chrome%2FSafari-orange)](https://github.com/XeroIP/rolling-text)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A simple app for Android, iOS, and Web that gives you a place to write down your thoughts without keeping them. As you type, older text quietly disappears. Nothing is saved. Nothing is stored.

## About

We all carry thoughts we wish we didn't. The worries that keep us up at night. The harsh things we say to ourselves. The moments we replay over and over even though we can't change them. That's just part of being human, and it can be really heavy.

Rolling Text is a simple place to set those thoughts down. As you type, your words quietly disappear. Nothing is saved. Nothing is stored. You don't have to organize your feelings or make them make sense. Just let them out, and let them go.

There's something powerful about putting a difficult thought into words and then watching it leave. You're not ignoring what you feel. You're giving yourself permission to feel it, express it, and release it.

And it turns out, science agrees.

**Writing down your thoughts and letting them go actually works.** Researchers found that when people wrote down negative thoughts and then discarded them, even digitally by dragging them to the recycle bin on a computer, those thoughts lost their grip. They had significantly less influence on emotions and self-perception afterward. It wasn't just the writing that helped. It was the act of letting go. (Briñol, Petty, Gascó & Horcajo, 2012, *Psychological Science*)

**Putting your feelings into words is a form of healing.** Over four decades of research on expressive writing, pioneered by psychologist James Pennebaker, has shown that writing about what's bothering us, even for just a few minutes, can meaningfully improve both our emotional and physical well-being. You don't have to write well. You just have to write honestly. (Pennebaker, 2018, *Perspectives on Psychological Science*)

**You are not your thoughts.** In Acceptance and Commitment Therapy (ACT), a practice called cognitive defusion helps people step back and see their thoughts for what they really are: passing mental events, not permanent truths. Research shows that this kind of distance reduces both the pain and the believability of harsh, self-critical thoughts more effectively than trying to distract yourself or push them away. (Masuda et al., 2004, *Behavior Therapy*; Larsson et al., 2016, *Behavior Modification*)

**Letting go isn't weakness. It's a skill.** A 2023 study from the University of Cambridge found that people who practiced actively releasing unwanted thoughts experienced less anxiety, less depression, and fewer intrusive negative emotions. This was true even for those living with clinical mental health conditions. Sometimes the bravest thing you can do is choose not to hold on. (Mamat et al., 2023, *Science Advances*)

Rolling Text isn't therapy, and it's not a replacement for professional support. If you're struggling, please reach out to someone who can help. But for the everyday weight of being human, for the thoughts that just need somewhere to go, this is a quiet place to let them pass through.

## How It Works

The app maintains a rolling character limit. When you type past the limit, the oldest text is automatically removed from the beginning. Your cursor stays at the end so you can keep typing.

```
Limit: 10 characters

Type: "Hello Wor"  -> 9 chars, OK
Type: "Hello Worl" -> 10 chars, at limit
Type: "Hello World" -> "ello World" ('H' removed automatically)
```

## Features

- **Configurable character limit** - Set anywhere from 1 to 1,000,000 characters
- **Themes** - Light, Dark, and Sepia
- **Font picker** - Choose from 20 curated Google Fonts or System Default
- **Adjustable font size** - 6pt to 144pt via slider, with custom sizes up to 999pt
- **Settings persistence** - Character limit, theme, font, and font size are saved between sessions. Text is never saved.
- **Unicode and emoji support** - Handles multi-byte characters correctly

## Installation

### Run from source

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
- **Framework**: Flutter 3.x
- **Architecture**: Provider (ChangeNotifier)
- **Dependencies**: `provider`, `shared_preferences`, `google_fonts`

## Roadmap

Have an idea for Rolling Text? Feature requests are welcome on the [GitHub Issues](https://github.com/XeroIP/rolling-text/issues) page.

## Contributing

Contributions are welcome! Open an issue or submit a pull request on [GitHub](https://github.com/XeroIP/rolling-text).

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Created by Peter Kirschman
