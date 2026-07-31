import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("app/../key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "io.rollingtext.rolling_text"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "io.rollingtext.rolling_text"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Configuration runs for every variant regardless of which task is invoked, so a debug
// or profile build must not be blocked by a missing release keystore. Only fail once the
// task graph is known to actually contain a release assemble/bundle task.
gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any {
        it.name.startsWith("assembleRelease") || it.name.startsWith("bundleRelease")
    }
    if (buildingRelease && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "Release build requested but android/key.properties is missing, so there is " +
            "no release signing key to sign the APK/AAB with. Falling back to debug " +
            "signing would produce a release artifact that can't receive normal upgrades " +
            "from a properly-signed release. Create android/key.properties (see " +
            "android/app/build.gradle.kts for the expected keys) or build a debug/profile " +
            "variant instead."
        )
    }
}

flutter {
    source = "../.."
}
