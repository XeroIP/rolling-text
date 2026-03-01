package io.rollingtext.app;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * Repository class for managing SharedPreferences operations.
 * 
 * Separates data persistence logic from UI logic (MainActivity).
 * This follows the Repository pattern from Android architecture best practices.
 * 
 * Benefits:
 * - Cleaner code organization
 * - Easier to test
 * - Single source of truth for preference access
 * - Can easily switch storage mechanism later (e.g., to Room database)
 */
public class PreferencesRepository {
    
    public static final int DEFAULT_MAX_CHARS = 128;

    private static final String PREFS_NAME = "RollingTextPrefs";
    private static final String KEY_MAX_CHARS = "maxCharacters";
    private static final String KEY_THEME = "theme";
    private static final String KEY_FONT_PATH = "fontPath";
    private static final String KEY_FONT_NAME = "fontName";
    private static final String KEY_FONT_SIZE = "fontSize";
    
    private final SharedPreferences prefs;
    
    /**
     * Constructor.
     * 
     * @param context Application context
     */
    public PreferencesRepository(Context context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }
    
    /**
     * Save maximum character limit.
     * 
     * @param maxChars Maximum character limit
     */
    public void saveMaxCharacters(int maxChars) {
        prefs.edit()
            .putInt(KEY_MAX_CHARS, maxChars)
            .apply();
    }
    
    /**
     * Get saved maximum character limit.
     *
     * @return Saved limit, or 128 (default) if none exists
     */
    public int getMaxCharacters() {
        return prefs.getInt(KEY_MAX_CHARS, DEFAULT_MAX_CHARS);
    }
    
    /**
     * Save theme preference.
     * 
     * @param theme Theme name ("light", "dark", or "sepia")
     */
    public void saveTheme(String theme) {
        prefs.edit()
            .putString(KEY_THEME, theme)
            .apply();
    }
    
    /**
     * Get saved theme preference.
     * 
     * @return Saved theme, or "light" (default) if none exists
     */
    public String getTheme() {
        return prefs.getString(KEY_THEME, "light");
    }
    
    /**
     * Save font preference.
     * 
     * @param fontPath Path to font file, or null for system default
     * @param fontName Display name of font
     */
    public void saveFontPreference(String fontPath, String fontName) {
        prefs.edit()
            .putString(KEY_FONT_PATH, fontPath)
            .putString(KEY_FONT_NAME, fontName)
            .apply();
    }
    
    /**
     * Get saved font path.
     * 
     * @return Saved font path, or null for system default
     */
    public String getFontPath() {
        return prefs.getString(KEY_FONT_PATH, null);
    }
    
    /**
     * Get saved font name.
     *
     * @return Saved font name, or "System Default" if none exists
     */
    public String getFontName() {
        return prefs.getString(KEY_FONT_NAME, "System Default");
    }

    /**
     * Save font size preference.
     *
     * @param fontSize Font size in pt
     */
    public void saveFontSize(float fontSize) {
        prefs.edit()
            .putFloat(KEY_FONT_SIZE, fontSize)
            .apply();
    }

    /**
     * Get saved font size.
     *
     * @return Saved font size, or 16 (default) if none exists
     */
    public float getFontSize() {
        return prefs.getFloat(KEY_FONT_SIZE, 16f);
    }
}
