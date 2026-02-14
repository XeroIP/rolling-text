package com.example.rollingtext;

import android.graphics.drawable.GradientDrawable;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;

/**
 * Manages theme colors and application to views.
 * Extracted from MainActivity for better separation of concerns.
 */
public class ThemeManager {

    /**
     * Theme color configuration container.
     * Holds all colors needed for a theme.
     */
    public static class ThemeColors {
        public final int background;
        public final int text;
        public final int textSecondary;
        public final int editBackground;

        public ThemeColors(int bg, int txt, int txtSec, int editBg) {
            background = bg;
            text = txt;
            textSecondary = txtSec;
            editBackground = editBg;
        }
    }

    // Reusable drawable for EditText background (prevents recreation)
    private GradientDrawable editTextDrawable;

    /**
     * Get theme colors for the specified theme.
     *
     * @param theme Theme name ("light", "dark", or "sepia")
     * @return ThemeColors object with color values
     */
    public ThemeColors getThemeColors(String theme) {
        switch (theme) {
            case "dark":
                return new ThemeColors(
                    0xFF121212, // background
                    0xFFFFFFFF, // text
                    0xFFB0B0B0, // text secondary
                    0xFF1E1E1E  // edit background
                );
            case "sepia":
                return new ThemeColors(
                    0xFFE8D5B8, // background - more intense
                    0xFF2C1810, // text - darker
                    0xFF5D4037, // text secondary - more intense
                    0xFFD4BC98  // edit background - more intense
                );
            default: // light
                return new ThemeColors(
                    0xFFFFFFFF, // background
                    0xFF000000, // text
                    0xFF666666, // text secondary
                    0xFFF5F5F5  // edit background
                );
        }
    }

    /**
     * Apply theme to views.
     *
     * @param theme Theme name ("light", "dark", or "sepia")
     * @param rootView Root view for background
     * @param titleText Title text view (can be null)
     * @param charCounter Character counter text view
     * @param limitLabel Limit label text view (can be null)
     * @param editText Edit text view
     */
    public void applyTheme(String theme, View rootView, TextView titleText,
                          TextView charCounter, TextView limitLabel, EditText editText) {
        ThemeColors colors = getThemeColors(theme);

        // Apply colors to views
        rootView.setBackgroundColor(colors.background);

        // Only apply to views that exist
        if (titleText != null) {
            titleText.setTextColor(colors.text);
        }
        if (charCounter != null) {
            charCounter.setTextColor(colors.textSecondary);
        }
        if (limitLabel != null) {
            limitLabel.setTextColor(colors.textSecondary);
        }

        editText.setTextColor(colors.text);
        editText.setHintTextColor(colors.textSecondary);

        // Don't set background - using Material 3 transparent background
        // The EditText has android:background="@null" for borderless design
    }
}
