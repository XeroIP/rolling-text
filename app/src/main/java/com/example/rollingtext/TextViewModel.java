package com.example.rollingtext;

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
    private final MutableLiveData<Integer> maxCharacters = new MutableLiveData<>(255);
    
    // Current theme ("light", "dark", or "sepia")
    private final MutableLiveData<String> currentTheme = new MutableLiveData<>("light");
    
    // Current font file path (null for system default)
    private final MutableLiveData<String> currentFontPath = new MutableLiveData<>(null);
    
    // Current font display name
    private final MutableLiveData<String> currentFontName = new MutableLiveData<>("System Default");
    
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
    
    /**
     * Called when ViewModel is no longer used and will be destroyed.
     * Clean up any resources if needed.
     */
    @Override
    protected void onCleared() {
        super.onCleared();
        // No cleanup needed for basic data types
    }
}
