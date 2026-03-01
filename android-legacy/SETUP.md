# Setup Guide

Quick guide to get the RollingText app running on your machine.

## Prerequisites

- **Android Studio** (Arctic Fox or later recommended)
- **JDK 8** or higher
- **Android SDK** with:
  - Android 14 (API 34) - Target SDK
  - Android 7.0 (API 24) - Minimum SDK
- **Git** (for cloning the repository)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/rolling-text-android.git
cd rolling-text-android
```

### 2. Open in Android Studio

1. Launch Android Studio
2. Click **File → Open**
3. Navigate to the `rolling-text-android` directory
4. Click **OK**
5. Wait for Gradle sync to complete (may take a few minutes on first run)

### 3. Sync Gradle

If Gradle doesn't sync automatically:
1. Click **File → Sync Project with Gradle Files**
2. Wait for the sync to complete
3. Resolve any errors (usually missing SDK components)

### 4. Run the App

#### On an Emulator:
1. Click **Tools → AVD Manager**
2. Create a new Virtual Device (if you don't have one)
   - Recommended: Pixel 6 with Android 14
3. Click the **Run** button (green play icon) or press `Shift+F10`
4. Select your emulator from the list
5. Click **OK**

#### On a Physical Device:
1. Enable **Developer Options** on your Android device:
   - Go to **Settings → About Phone**
   - Tap **Build Number** 7 times
2. Enable **USB Debugging**:
   - Go to **Settings → Developer Options**
   - Toggle **USB Debugging** on
3. Connect your device via USB
4. Click the **Run** button (green play icon)
5. Select your device from the list
6. Click **OK**

## Project Structure

```
rolling-text-android/
├── app/                          # Main application module
│   ├── src/
│   │   └── main/
│   │       ├── java/             # Java source files
│   │       │   └── com/example/rollingtext/
│   │       │       ├── MainActivity.java          # Main UI activity
│   │       │       ├── TextViewModel.java         # Data persistence across rotations
│   │       │       └── PreferencesRepository.java # SharedPreferences wrapper
│   │       ├── res/              # Resources (layouts, colors, themes)
│   │       │   ├── layout/       # XML layouts
│   │       │   └── values/       # Colors, themes, strings
│   │       └── AndroidManifest.xml
│   └── build.gradle              # App module build configuration
├── gradle/                       # Gradle wrapper files
├── build.gradle                  # Project-level build configuration
├── settings.gradle               # Project settings
└── README.md                     # Documentation
```

## Common Issues

### Issue: "SDK not found"

**Solution:**
1. Open **File → Project Structure → SDK Location**
2. Set the Android SDK path (usually `~/Android/Sdk` on Mac/Linux or `C:\Users\YourName\AppData\Local\Android\Sdk` on Windows)
3. Click **Apply**

### Issue: "Gradle sync failed"

**Solution:**
1. Check your internet connection
2. Click **File → Invalidate Caches / Restart**
3. Try **Build → Clean Project** then **Build → Rebuild Project**
4. If still failing, delete `.gradle` folder and sync again

### Issue: "Minimum SDK version" error

**Solution:**
1. Open **Tools → SDK Manager**
2. Install **Android 7.0 (API 24)** or higher
3. Sync Gradle again

### Issue: App crashes on launch

**Solution:**
1. Check LogCat for error messages (**View → Tool Windows → Logcat**)
2. Common causes:
   - Missing lifecycle dependencies (should be in build.gradle)
   - Corrupted build cache (clean and rebuild)
   - Emulator/device incompatibility (try different device)

## Building APK

### Debug APK (for testing):
```bash
./gradlew assembleDebug
```
APK location: `app/build/outputs/apk/debug/app-debug.apk`

### Release APK (for distribution):
1. Generate signing key:
```bash
keytool -genkey -v -keystore my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
```

2. Add to `app/build.gradle`:
```gradle
android {
    signingConfigs {
        release {
            storeFile file("my-release-key.jks")
            storePassword "your-password"
            keyAlias "my-key-alias"
            keyPassword "your-password"
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

3. Build release APK:
```bash
./gradlew assembleRelease
```
APK location: `app/build/outputs/apk/release/app-release.apk`

## Development Tips

### Enable Auto-Import
1. **File → Settings → Editor → General → Auto Import**
2. Check **Optimize imports on the fly**
3. Check **Add unambiguous imports on the fly**

### Code Style
This project follows standard Java conventions:
- 4 spaces for indentation
- Braces on same line
- Meaningful variable names
- JavaDoc comments for public methods

### Debugging
1. Set breakpoints by clicking on the line number gutter
2. Click **Run → Debug 'app'** or press `Shift+F9`
3. Use **Logcat** to view logs: `View → Tool Windows → Logcat`

### Testing Changes
1. Make your changes in the code
2. Click **Build → Make Project** or press `Ctrl+F9` (Cmd+F9 on Mac)
3. Click **Run** to deploy changes
4. Hot Swap may work for minor changes (no need to restart app)

## Gradle Commands

```bash
# Clean build
./gradlew clean

# Build debug APK
./gradlew assembleDebug

# Install on connected device
./gradlew installDebug

# Run all checks
./gradlew check

# List all tasks
./gradlew tasks
```

## Next Steps

- Read [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
- Check [CHANGELOG.md](CHANGELOG.md) for version history
- Review code comments in MainActivity.java for implementation details
- Report issues on GitHub

## Getting Help

- **Android Studio Issues**: [stackoverflow.com/questions/tagged/android-studio](https://stackoverflow.com/questions/tagged/android-studio)
- **Gradle Issues**: [docs.gradle.org](https://docs.gradle.org)
- **Project Issues**: [GitHub Issues](https://github.com/yourusername/rolling-text-android/issues)

## Resources

- [Android Developer Guide](https://developer.android.com/guide)
- [Android Studio User Guide](https://developer.android.com/studio/intro)
- [Gradle Build Tool](https://gradle.org/guides/)
- [Material Design Guidelines](https://material.io/design)

Happy coding! 🚀
