# Rolling Text — user guide

Everything the app does, and how each setting behaves. For why the app works the way it does, see [Why this works](about.md).

## How It Works

The app maintains a rolling character limit. When you type past the limit, the oldest text is automatically removed from the beginning. Your cursor keeps its place in the text that survives, so you can keep typing.

A character here means an extended grapheme cluster, which is what a reader thinks of as one character. A flag emoji or an accented letter counts once and is removed whole, rather than being cut apart into the code points it is built from.

```
Limit: 10 characters

Type: "Hello Wor"  -> 9 chars, OK
Type: "Hello Worl" -> 10 chars, at limit
Type: "Hello World" -> "ello World" ('H' removed automatically)
```

Lowering the limit below what you have already written removes the oldest characters immediately, without asking. Like everything else in Rolling Text, that text is gone rather than recoverable.

## Features

- **Configurable character limit** - Set anywhere from 1 to 25,000 characters
- **Themes** - Light, Dark, Sepia, Night, and Dark Sepia
- **Font picker** - Choose from 20 curated Google Fonts, or Source Code Pro as the default. Uncached fonts require an internet connection on first use.
- **Adjustable font size** - Type any size from 6pt to 999pt, or drag the slider for 6pt to 144pt
- **Keyboard operation** - Every settings sheet works without a mouse: arrow keys move between themes and fonts, Enter applies, Escape closes, and arrow or page keys scroll the About text. Focus returns to the editor when a sheet closes, when you tap elsewhere in the app, or when you switch back to the app after leaving it.
- **Settings persistence** - Character limit, theme, font, and font size are saved between sessions. Text is never saved. Saved values are validated on load and fall back to defaults if storage is corrupt or out of range. A setting that fails to save still applies for the session, with a warning that it won't be remembered.
- **Private by default on Android** - The editor opts out of IME personalized learning, so what you type is not added to your keyboard's dictionary or typing history
- **Unicode and emoji support** - Truncation removes whole extended grapheme clusters, so accented letters, flag emoji, skin-tone modifiers, and ZWJ sequences are never split in half at the boundary
