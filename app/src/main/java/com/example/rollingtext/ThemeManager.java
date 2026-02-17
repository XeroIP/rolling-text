package com.example.rollingtext;

import android.content.Context;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import androidx.core.content.ContextCompat;

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

        public ThemeColors(int bg, int txt, int txtSec) {
            background = bg;
            text = txt;
            textSecondary = txtSec;
        }
    }

    /**
     * Get theme colors for the specified theme, resolved from XML color resources.
     *
     * @param theme Theme name ("light", "dark", or "sepia")
     * @param context Context for resolving color resources
     * @return ThemeColors object with color values
     */
    public ThemeColors getThemeColors(String theme, Context context) {
        switch (theme) {
            case "dark":
                return new ThemeColors(
                    ContextCompat.getColor(context, R.color.dark_background),
                    ContextCompat.getColor(context, R.color.dark_text),
                    ContextCompat.getColor(context, R.color.dark_text_secondary)
                );
            case "sepia":
                return new ThemeColors(
                    ContextCompat.getColor(context, R.color.sepia_background),
                    ContextCompat.getColor(context, R.color.sepia_text),
                    ContextCompat.getColor(context, R.color.sepia_text_secondary)
                );
            default: // light
                return new ThemeColors(
                    ContextCompat.getColor(context, R.color.light_background),
                    ContextCompat.getColor(context, R.color.light_text),
                    ContextCompat.getColor(context, R.color.light_text_secondary)
                );
        }
    }

    /**
     * Apply theme to views.
     *
     * @param theme Theme name ("light", "dark", or "sepia")
     * @param context Context for resolving color resources
     * @param rootView Root view for background
     * @param charCounter Character counter text view
     * @param editText Edit text view
     */
    public void applyTheme(String theme, Context context, View rootView,
                          TextView charCounter, EditText editText) {
        ThemeColors colors = getThemeColors(theme, context);

        rootView.setBackgroundColor(colors.background);

        if (charCounter != null) {
            charCounter.setTextColor(colors.textSecondary);
        }

        editText.setTextColor(colors.text);
        editText.setHintTextColor(colors.textSecondary);
    }
}
