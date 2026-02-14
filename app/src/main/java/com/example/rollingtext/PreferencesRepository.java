package com.example.rollingtext;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

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
    
    private static final String TAG = "PreferencesRepository";
    
    private static final String PREFS_NAME = "RollingTextPrefs";
    private static final String KEY_MAX_CHARS = "maxCharacters";
    private static final String KEY_SAVED_TEXT = "savedText";
    private static final String KEY_THEME = "theme";
    private static final String KEY_FONT_PATH = "fontPath";
    private static final String KEY_FONT_NAME = "fontName";
    private static final String KEY_FONT_SIZE = "fontSize";
    private static final String KEY_AUTO_SAVE = "autoSaveText";
    
    // Maximum safe size for SharedPreferences (500KB)
    private static final int MAX_TEXT_SIZE = 500000;
    
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
     * Save text content to SharedPreferences.
     * Checks size to prevent exceeding SharedPreferences limits.
     * 
     * @param text Text to save
     */
    public void saveText(String text) {
        if (text == null) {
            text = "";
        }
        
        // Check if text is too large for SharedPreferences
        if (text.length() > MAX_TEXT_SIZE) {
            Log.w(TAG, "Text exceeds safe size limit (" + text.length() + " > " + MAX_TEXT_SIZE + ")");
            // Truncate to safe size
            text = text.substring(0, MAX_TEXT_SIZE);
        }
        
        prefs.edit()
            .putString(KEY_SAVED_TEXT, text)
            .apply();
    }
    
    /**
     * Get saved text content.
     * 
     * @return Saved text, or empty string if none exists
     */
    public String getText() {
        return prefs.getString(KEY_SAVED_TEXT, "");
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
        return prefs.getInt(KEY_MAX_CHARS, 128);
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
     * @param fontSize Font size in sp
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

    /**
     * Save auto-save text preference.
     *
     * @param autoSave Whether to auto-save text on exit
     */
    public void setAutoSaveText(boolean autoSave) {
        prefs.edit()
            .putBoolean(KEY_AUTO_SAVE, autoSave)
            .apply();
    }

    /**
     * Get auto-save text preference.
     *
     * @return True if auto-save is enabled (default), false otherwise
     */
    public boolean getAutoSaveText() {
        return prefs.getBoolean(KEY_AUTO_SAVE, true);
    }

    /**
     * Clear all saved preferences.
     * Useful for a "Reset to Defaults" feature.
     */
    public void clearAll() {
        prefs.edit()
            .clear()
            .apply();
    }
}
