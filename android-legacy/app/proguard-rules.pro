# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# RollingText - ProGuard Rules

# Keep ViewModel classes (reflection used by ViewModelProvider)
-keep class androidx.lifecycle.ViewModel { *; }
-keep class * extends androidx.lifecycle.ViewModel {
    <init>();
}

# Keep LiveData (accessed via reflection)
-keep class androidx.lifecycle.LiveData { *; }
-keep class androidx.lifecycle.MutableLiveData { *; }

# Keep our ViewModel implementation
-keep class io.rollingtext.app.TextViewModel { *; }

# Keep PreferencesRepository (may use reflection for SharedPreferences)
-keep class io.rollingtext.app.PreferencesRepository {
    <init>(...);
    public *;
}

# Keep MainActivity (entry point)
-keep class io.rollingtext.app.MainActivity {
    <init>(...);
}

# Keep Typeface-related code (uses reflection for font loading)
-keep class android.graphics.Typeface { *; }

# AndroidX and Material Components
-dontwarn com.google.android.material.**
-keep class com.google.android.material.** { *; }

# ConstraintLayout
-keep class androidx.constraintlayout.** { *; }
-dontwarn androidx.constraintlayout.**

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
