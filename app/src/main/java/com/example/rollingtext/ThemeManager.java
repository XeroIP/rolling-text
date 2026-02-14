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
                    0xFFF4ECD8, // background
                    0xFF3E2723, // text
                    0xFF6D4C41, // text secondary
                    0xFFEDE0C8  // edit background
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
     * @param titleText Title text view
     * @param charCounter Character counter text view
     * @param limitLabel Limit label text view
     * @param editText Edit text view
     */
    public void applyTheme(String theme, View rootView, TextView titleText,
                          TextView charCounter, TextView limitLabel, EditText editText) {
        ThemeColors colors = getThemeColors(theme);

        // Apply colors to views
        rootView.setBackgroundColor(colors.background);
        titleText.setTextColor(colors.text);
        charCounter.setTextColor(colors.textSecondary);
        limitLabel.setTextColor(colors.textSecondary);
        editText.setTextColor(colors.text);
        editText.setHintTextColor(colors.textSecondary);

        // Reuse drawable instead of creating new one each time
        if (editTextDrawable == null) {
            editTextDrawable = new GradientDrawable();
            editTextDrawable.setCornerRadius(8f);
        }
        editTextDrawable.setColor(colors.editBackground);
        editTextDrawable.setStroke(2, colors.textSecondary);
        editText.setBackground(editTextDrawable);
    }
}
