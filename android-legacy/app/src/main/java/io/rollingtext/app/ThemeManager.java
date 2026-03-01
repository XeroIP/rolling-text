package io.rollingtext.app;

import android.app.Activity;
import android.content.Context;
import android.content.res.ColorStateList;
import android.view.View;
import android.view.Window;
import android.widget.EditText;
import android.widget.TextView;
import androidx.core.content.ContextCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.google.android.material.button.MaterialButton;

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
        public final int buttonBackground;
        public final int buttonIcon;

        public ThemeColors(int bg, int txt, int txtSec, int btnBg, int btnIcon) {
            background = bg;
            text = txt;
            textSecondary = txtSec;
            buttonBackground = btnBg;
            buttonIcon = btnIcon;
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
                    ContextCompat.getColor(context, R.color.dark_text_secondary),
                    ContextCompat.getColor(context, R.color.dark_button_background),
                    ContextCompat.getColor(context, R.color.dark_button_icon)
                );
            case "sepia":
                return new ThemeColors(
                    ContextCompat.getColor(context, R.color.sepia_background),
                    ContextCompat.getColor(context, R.color.sepia_text),
                    ContextCompat.getColor(context, R.color.sepia_text_secondary),
                    ContextCompat.getColor(context, R.color.sepia_button_background),
                    ContextCompat.getColor(context, R.color.sepia_button_icon)
                );
            default: // light
                return new ThemeColors(
                    ContextCompat.getColor(context, R.color.light_background),
                    ContextCompat.getColor(context, R.color.light_text),
                    ContextCompat.getColor(context, R.color.light_text_secondary),
                    ContextCompat.getColor(context, R.color.light_button_background),
                    ContextCompat.getColor(context, R.color.light_button_icon)
                );
        }
    }

    /**
     * Apply theme to views, including status bar icon appearance and button tinting.
     *
     * @param theme Theme name ("light", "dark", or "sepia")
     * @param activity The Activity (needed for Window access)
     * @param rootView Root view for background
     * @param charCounter Character counter text view
     * @param editText Edit text view
     * @param buttons MaterialButtons to tint
     */
    public void applyTheme(String theme, Activity activity, View rootView,
                          TextView charCounter, EditText editText,
                          MaterialButton... buttons) {
        ThemeColors colors = getThemeColors(theme, activity);

        rootView.setBackgroundColor(colors.background);

        if (charCounter != null) {
            charCounter.setTextColor(colors.textSecondary);
        }

        editText.setTextColor(colors.text);
        editText.setHintTextColor(colors.textSecondary);

        // Tint buttons to match theme
        ColorStateList btnBgTint = ColorStateList.valueOf(colors.buttonBackground);
        ColorStateList btnIconTint = ColorStateList.valueOf(colors.buttonIcon);
        for (MaterialButton button : buttons) {
            button.setBackgroundTintList(btnBgTint);
            button.setIconTint(btnIconTint);
        }

        // Status bar: dark icons for light/sepia backgrounds, light icons for dark
        Window window = activity.getWindow();
        WindowInsetsControllerCompat insetsController =
            WindowCompat.getInsetsController(window, window.getDecorView());
        insetsController.setAppearanceLightStatusBars(!theme.equals("dark"));
    }
}
