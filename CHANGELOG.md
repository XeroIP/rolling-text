# Changelog

All notable changes to Rolling Text will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> Bullets in this file are single unbroken lines on purpose. GitHub's release renderer preserves mid-bullet newlines as visible line breaks instead of reflowing them, so a hard-wrapped bullet publishes as broken release notes.

## [Unreleased]

### Changed
- **Typed text is no longer offered to the Android keyboard** - The editor opts out of IME personalized learning, so what you type is not added to your keyboard's dictionary or typing history

### Fixed
- **Editor stopped accepting keystrokes after tapping empty space or leaving the window** - Tapping away from the editor or switching to another window and back left typing dead until the page was reloaded
- **Corrupt or out-of-range saved settings could crash the app on launch** - Settings are now validated when they load, and anything invalid falls back to its default instead of throwing
- **A setting that failed to save appeared to have been saved** - A failed write now warns that the change will not be remembered, rather than silently leaving the app and storage disagreeing

## [0.5.0] - 2026-07-30

### Keyboard Accessibility Release

Every settings sheet can now be driven without a mouse. Version 0.4.0 was only ever tagged as `v0.4.0-beta.1` and never released, so the changes staged for it are included here.

### Added
- **Keyboard operation of every settings sheet** - Arrow keys move between themes and fonts, Enter applies the focused choice, and Escape closes the sheet
- **Focus opens on the active row** - The theme and font sheets focus the current selection when they open, so arrow keys navigate from where you already are rather than from the top of the list
- **Off-screen selection is revealed** - The font sheet scrolls an active font that sits below the fold into view when it opens, since a row that is never built can neither be seen nor take keyboard focus
- **Keyboard scrolling in About** - The About text scrolls with the arrow and page keys, all the way to the end of the content
- **Immediately typeable font size** - The Font Size sheet opens with its numeric field focused and preselected, with the slider one Tab away
- **Screen reader support for the character counter** - The counter is announced as "N of M characters used" instead of being hidden from assistive technology
- **Release signing and CI builds** - Tagged releases produce signed release and debug APKs
- **Unit tests for the rolling truncation logic** - Including Unicode and emoji boundary cases

### Changed
- **Reducing the character limit no longer asks for confirmation** - A lower limit applies immediately and the oldest characters are removed; that text is not recoverable
- **Font size preview is a true preview** - The Font Size sheet previews live while open; Apply commits it, while Cancel, Escape, the close button and a barrier tap all revert to the size the sheet opened with
- **Validation errors are inline** - Out-of-range values in the Character Limit and Font Size sheets are reported beneath the field and keep the sheet open, replacing the modal error dialogs. No dialogs remain anywhere in the app
- **Font size is entered in the sheet itself** - A single field accepts any size from 6pt to 999pt, replacing the separate "Enter custom size" button and the second sheet it opened
- **Bottom sheets have a visible edge** - Sheets are painted on a distinct surface so they separate from the editor in every theme
- **Character count no longer rebuilds the whole screen** - Counting flows through a `ValueNotifier` rather than an empty `setState` on every keystroke

### Fixed
- **Android release builds could not download uncached Google Fonts** - A fresh install could not apply most fonts in the picker
- **Editor stopped accepting keystrokes after closing a sheet on Web** - Dismissing any bottom sheet left the browser with no focused input element, and only a page reload recovered it
- **Theme and font could not be selected with arrow keys on Web** - Flutter binds bare arrows to scrolling rather than focus traversal on Web, so the theme sheet ignored them entirely and the font sheet scrolled without moving the selection
- **Picker sheets opened with focus outside the sheet on Web** - Focus stayed on the toolbar button behind the modal barrier instead of moving into the sheet
- **About text could not be scrolled to its end with the keyboard** - The focus anchor it relied on was unmounted once it scrolled beyond the list's cache extent
- **Out-of-range values could be committed** - The Character Limit and Font Size sheets now only accept values inside their valid range
- **Font size wrote to disk on every drag tick** - The new size is saved once, when the sheet closes
- **Duplicate hint text on focus** - The editor no longer showed a second hint in a different font

### Known Issues
- **iOS is untested on hardware** - It takes the same code path as Android, which was verified on a Pixel 8 Pro
- **Editor can lose text input** - Tapping empty space or switching windows can leave the editor unable to accept typing until the page is reloaded ([#29](https://github.com/XeroIP/rolling-text/issues/29))

---

## [0.3.0] - 2026-02-28

### Complete Rewrite in Flutter

The app has been rewritten from scratch in Flutter/Dart, replacing the native Android codebase. The original Android code is preserved in `android-legacy/`.

### Added
- **iOS and Web support** - App now runs on Android, iOS, and Web from a single codebase
- **20 curated Google Fonts** - Font picker now offers a handpicked selection (Courier Prime, Crimson Text, EB Garamond, Fira Code, IBM Plex Mono, Inconsolata, Inter, JetBrains Mono, Karla, Lato, Libre Baskerville, Lora, Merriweather, Nunito, Open Sans, Playfair Display, PT Serif, Raleway, Source Code Pro, Work Sans) plus System Default
- **Font size slider** - Smooth slider from 6pt to 144pt with custom input up to 999pt
- **Bottom sheet UI** - All settings (character limit, theme, font, font size) and the About page use Material 3 bottom sheets instead of dialogs
- **Source Code Pro default font** - Monospace default for a focused writing experience

### Changed
- **Platform**: Native Android (Java) → Flutter (Dart), targeting Android, iOS, and Web
- **Font picker**: System font scanner replaced with curated Google Fonts list
- **Font size range**: Extended from 6–72pt to 6–144pt; custom sizes up to 999pt
- **Settings UI**: All pickers converted from `AlertDialog` to `showModalBottomSheet`
- **About page**: Converted from a separate screen to a full-height draggable bottom sheet
- **Architecture**: MVVM (ViewModel + LiveData) → Provider (`ChangeNotifier`)
- **Preferences**: AndroidX SharedPreferences → `shared_preferences` Flutter package

### Removed
- System font scanner (replaced by Google Fonts)

### Technical Details
- **Language**: Dart
- **Framework**: Flutter 3.x
- **Key dependencies**: `provider`, `shared_preferences`, `google_fonts`

---

## [0.2.1] - 2026-02-13

### Code Quality & Correctness Release

This release removes text persistence (the app now always starts with a blank editor, true to its philosophy), and implements all findings from a comprehensive code review focused on correctness, security, and code quality.

### Removed
- **Auto-save text persistence** - The app no longer saves or restores typed text between sessions
  - Removed auto-save checkbox from settings dialog
  - Removed `saveText()`, `getText()`, `setAutoSaveText()`, `getAutoSaveText()` from PreferencesRepository
  - Removed `onPause` text saving and startup text loading
  - User settings (theme, font, font size, character limit) are still persisted
- **`configChanges` from AndroidManifest** - Removed `android:configChanges="orientation|screenSize|keyboardHidden"` from MainActivity to let the ViewModel handle configuration changes properly (the modern Android standard)
- **Unused code cleanup**:
  - Removed unused `Context` field and constructor parameter from `FontManager` (eliminated Activity reference memory leak risk)
  - Removed unused imports from MainActivity (`LayoutInflater`, `Button`, `CheckBox`, `LinearLayout`)
  - Removed empty `onCleared()` override from `TextViewModel`
  - Removed unused `clearAll()` method from `PreferencesRepository`
  - Removed unused `TAG` constant and `Log` import from `PreferencesRepository`
  - Removed unused `editTextDrawable` field and `GradientDrawable` import from `ThemeManager`
  - Removed unused `editBackground` field from `ThemeManager.ThemeColors`
  - Removed always-null `titleText` and `limitLabel` parameters from `ThemeManager.applyTheme()`
  - Removed 3 unused `*_edit_background` color resources from `colors.xml`

### Fixed
- **Thread safety** - Added `volatile` to `cachedFonts` field in `FontManager` to fix data race between main and background threads
- **Default character limit mismatch** - `TextViewModel` defaulted to 255 characters while `PreferencesRepository` defaulted to 128; introduced `PreferencesRepository.DEFAULT_MAX_CHARS` constant as single source of truth
- **Font size not surviving configuration changes** - Added `fontSize` LiveData to `TextViewModel` and `onSaveInstanceState` so font size persists across screen rotation and process death
- **Stale comments** - Fixed comment claiming "prevent excessive I/O" when no I/O occurs (now "prevent excessive ViewModel sync")
- **Incorrect emoji comment** - Fixed claim that family emoji is 1 code point (it's actually 7 code points joined by ZWJ characters)
- **Javadoc error** - Fixed `saveFontSize` documentation saying "sp" when the unit is "pt"
- **Hardcoded color** - Replaced hardcoded `#666666` on character counter in `activity_main.xml` with `?attr/colorOnSurfaceVariant`

### Changed
- **ThemeManager refactored to use XML color resources** - Replaced all hardcoded hex color values with `ContextCompat.getColor()` calls resolving from `colors.xml`, eliminating duplication between Java and XML
- **Hardcoded strings moved to resources** - Moved 3 remaining hardcoded UI strings to `strings.xml`:
  - `"Character limit"` → `@string/hint_character_limit`
  - `"Enter size in pt (6-72)"` → `@string/hint_font_size`
  - `"Please enter a size between 6 and 72 pt"` → `@string/error_font_size_range`
- **Static content descriptions moved to XML** - Moved content descriptions for `settingsButton`, `fontButton`, and `fontSizeButton` from Java to `activity_main.xml` (only the dynamic theme button description remains in Java)
- **Simplified font path comparison** - Replaced manual null-check with `Objects.equals()`
- **`android:allowBackup` set to `false`** - Aligns with the app's "nothing is stored" philosophy

### Security & Build
- **Enabled ProGuard/R8** - Set `minifyEnabled true` and `shrinkResources true` for release builds (code shrinking, obfuscation, and unused resource removal)
- **Removed duplicate dependency** - Removed duplicate `appcompat` entry from `build.gradle`

### Technical Details
- **Files Changed**: 11 (7 Java, 3 XML resources, 1 Gradle)
- **New String Resources**: 3
- **Removed Color Resources**: 3
- **Build Verified**: `assembleDebug` passes successfully

---

## [0.2.0] - 2026-02-12

### Major Release - Production Ready

This release includes comprehensive improvements based on a thorough code review. All critical and high-priority issues have been resolved, making the app production-ready.

### Critical Fixes

#### Fixed
- **Unicode/Emoji Character Counting** - Now correctly counts Unicode code points instead of UTF-16 char units
  - Emoji like 👨‍👩‍👧‍👦 (family) now count as 1 character instead of 11
  - Multi-byte characters in languages like Chinese, Arabic, etc. are handled correctly
  - Fixed potential text corruption when deleting multi-byte characters

- **Configuration Change Handling** - App now survives screen rotation without data loss
  - Implemented ViewModel architecture to persist data across configuration changes
  - Added onSaveInstanceState() backup for critical data
  - Text, settings, and preferences all survive rotation

- **Performance - Debounced Auto-Save** - Eliminated excessive disk I/O
  - Changed from saving on every keystroke to debounced save (500ms after typing stops)
  - Reduces disk writes from 1000s to 1 per typing session
  - Significantly improved battery life and app responsiveness
  - Immediate save on app background/pause to prevent data loss

- **ANR Prevention** - Font scanning moved to background thread
  - Font loading now happens asynchronously with progress dialog
  - Prevents "Application Not Responding" errors on devices with many fonts
  - UI remains responsive during font scanning

### High Priority Improvements

#### Added
- **Typeface Caching** - Fonts are now cached after first load
  - Eliminates redundant disk I/O when switching fonts
  - Faster font application (instantaneous after first load)
  - Reduced memory allocations

- **Keyboard Handling** - Better UX when keyboard is visible
  - Wrapped layout in ScrollView to prevent button obscuring
  - Buttons remain accessible when keyboard is open
  - Improved windowSoftInputMode configuration

- **User Warnings** - Confirmation before data loss
  - Dialog warns users before truncating text when reducing character limit
  - Shows exact number of characters that will be removed
  - Prevents accidental data loss

- **Memory Leak Prevention** - Proper resource cleanup
  - TextWatcher removed in onDestroy() to prevent memory leaks
  - Handler callbacks cancelled when activity is destroyed
  - Prevents activity from leaking after configuration changes

- **Accessibility Improvements** - Better screen reader support
  - Added content descriptions to all interactive elements
  - Theme changes announced to screen readers
  - Character counter made less "chatty" for TalkBack users

#### Changed
- **Architecture** - Refactored to MVVM pattern
  - Separated UI logic (MainActivity) from data (ViewModel)
  - Created PreferencesRepository for data persistence
  - Cleaner code organization and better testability

- **Code Documentation** - Comprehensive comments added
  - Every public method documented with JavaDoc
  - Complex algorithms explained
  - Critical fixes marked with "CRITICAL FIX" comments

- **Error Handling** - Robust exception handling
  - Better handling of corrupted font files
  - OutOfMemoryError protection for large fonts
  - Graceful degradation with user-friendly error messages

### Medium Priority Enhancements

#### Added
- **RTL Language Support** - Right-to-left language compatibility
  - Added android:supportsRtl="true" to manifest
  - Layout uses start/end instead of left/right
  - Tested with Arabic and Hebrew

- **SharedPreferences Size Limit** - Protection against data loss
  - Added 500KB safety limit for text storage
  - Text truncated with warning if exceeds limit
  - Prevents SharedPreferences corruption

- **GradientDrawable Reuse** - Minor performance optimization
  - EditText background drawable reused instead of recreated
  - Reduces object allocations during theme switching

#### Changed
- **AndroidManifest Configuration** - Improved settings
  - Added configChanges to handle orientation properly
  - Enhanced windowSoftInputMode for better keyboard behavior
  - Added stateHidden to keyboard settings

- **EditText Configuration** - Better UX
  - Added scrollbars for long text
  - Disabled horizontal scrolling
  - Added importantForAutofill flag
  - Improved content description for accessibility

### Low Priority Improvements

#### Added
- **Logging** - Strategic log points for debugging
  - Error logging for font loading failures
  - Warning logs for SharedPreferences size issues
  - Easier troubleshooting in production

- **Dependencies** - Added lifecycle components
  - androidx.lifecycle:lifecycle-viewmodel:2.7.0
  - androidx.lifecycle:lifecycle-livedata:2.7.0
  - androidx.lifecycle:lifecycle-runtime:2.7.0

#### Fixed
- **Thread Safety** - Improved isUpdating flag pattern
  - Added synchronized blocks for thread-safe updates
  - Used volatile keyword for visibility
  - Prevents race conditions in edge cases

### Technical Details

- **Lines of Code**: ~1,200 (MainActivity: 500, ViewModel: 80, Repository: 150)
- **Code Comments**: ~40% coverage
- **Dependencies Added**: 3 (lifecycle components)
- **Files Changed**: 7
- **New Classes**: 2 (TextViewModel, PreferencesRepository)

## [0.1.0] - 2026-02-11

### Initial Release

#### Added
- Basic rolling character limit functionality
- Theme selection (Light, Dark, Sepia)
- Font picker from system fonts
- Character counter
- Auto-save to SharedPreferences
- Basic UI with three buttons

#### Known Issues (Fixed in 0.2.0)
- Emoji counted incorrectly
- Text lost on screen rotation
- Performance issues with typing
- Font loading freezes UI
- No warnings before data loss
- Potential memory leaks

---

## Version Numbering

This project uses Semantic Versioning (SemVer):
- **MAJOR** version for incompatible API changes or full platform rewrites
- **MINOR** version for backwards-compatible functionality additions
- **PATCH** version for backwards-compatible bug fixes

## Links

- [Compare Versions](https://github.com/XeroIP/rolling-text/compare)
- [Full Changelog](https://github.com/XeroIP/rolling-text/blob/main/CHANGELOG.md)
