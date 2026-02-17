package io.rollingtext.app;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

/**
 * ViewModel for MainActivity.
 * 
 * Survives configuration changes (like screen rotation) and maintains app state.
 * This prevents data loss when the device is rotated.
 * 
 * LiveData is used for reactive updates - when data changes, observers are notified.
 */
public class TextViewModel extends ViewModel {
    
    // Current text content
    private final MutableLiveData<String> text = new MutableLiveData<>("");
    
    // Maximum character limit
    private final MutableLiveData<Integer> maxCharacters = new MutableLiveData<>(PreferencesRepository.DEFAULT_MAX_CHARS);
    
    // Current theme ("light", "dark", or "sepia")
    private final MutableLiveData<String> currentTheme = new MutableLiveData<>("light");
    
    // Current font file path (null for system default)
    private final MutableLiveData<String> currentFontPath = new MutableLiveData<>(null);
    
    // Current font display name
    private final MutableLiveData<String> currentFontName = new MutableLiveData<>("System Default");

    // Current font size in pt
    private final MutableLiveData<Float> fontSize = new MutableLiveData<>(16f);

    // Whether the ViewModel has been initialized with preferences data.
    // Plain boolean (not LiveData) — only checked in loadState() on the main thread.
    private boolean initialized = false;

    public boolean isInitialized() {
        return initialized;
    }

    public void setInitialized(boolean value) {
        initialized = value;
    }

    // Getters for LiveData (read-only access)
    
    public LiveData<String> getText() {
        return text;
    }
    
    public LiveData<Integer> getMaxCharacters() {
        return maxCharacters;
    }
    
    public LiveData<String> getCurrentTheme() {
        return currentTheme;
    }
    
    public LiveData<String> getCurrentFontPath() {
        return currentFontPath;
    }
    
    public LiveData<String> getCurrentFontName() {
        return currentFontName;
    }

    public LiveData<Float> getFontSize() {
        return fontSize;
    }

    // Setters for updating values
    
    public void setText(String value) {
        text.setValue(value);
    }
    
    public void setMaxCharacters(int value) {
        maxCharacters.setValue(value);
    }
    
    public void setCurrentTheme(String value) {
        currentTheme.setValue(value);
    }
    
    public void setCurrentFontPath(String value) {
        currentFontPath.setValue(value);
    }
    
    public void setCurrentFontName(String value) {
        currentFontName.setValue(value);
    }

    public void setFontSize(float value) {
        fontSize.setValue(value);
    }
}
