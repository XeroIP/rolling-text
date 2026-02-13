package com.example.rollingtext;

import android.content.SharedPreferences;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;
import android.graphics.drawable.GradientDrawable;
import android.view.View;
import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Main activity for the RollingText app.
 * 
 * This app maintains a rolling character limit - when the user exceeds the limit,
 * the oldest characters are automatically removed from the beginning of the text.
 * 
 * Features:
 * - Rolling character limit with Unicode/emoji support
 * - Theme selection (Light, Dark, Sepia)
 * - Font picker from system fonts
 * - Auto-save with debouncing to prevent excessive I/O
 * - Configuration change handling (survives rotation)
 */
public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    
    // UI Components
    private EditText editText;
    private TextView charCounter;
    private TextView titleText;
    private TextView limitLabel;
    private Button settingsButton;
    private Button themeButton;
    private Button fontButton;
    private View rootView;
    
    // ViewModel for configuration change handling
    private TextViewModel viewModel;
    
    // Repository for SharedPreferences operations
    private PreferencesRepository preferencesRepo;
    
    // TextWatcher instance (stored for proper cleanup)
    private TextWatcher textWatcher;
    
    // Debouncing for auto-save
    private Handler saveHandler;
    private Runnable saveRunnable;
    private static final int SAVE_DELAY_MS = 500; // Save 500ms after user stops typing
    
    // Lock for thread-safe isUpdating flag
    private final Object updateLock = new Object();
    private volatile boolean isUpdating = false;
    
    // Font caching to avoid reloading from disk
    private Map<String, Typeface> typefaceCache = new HashMap<>();
    
    // Cached font list for performance
    private List<File> cachedFonts = null;
    
    // Reusable drawable for EditText background (prevents recreation)
    private GradientDrawable editTextDrawable = null;

    /**
     * Theme color configuration container.
     * Holds all colors needed for a theme.
     */
    private static class ThemeColors {
        int background;
        int text;
        int textSecondary;
        int editBackground;
        
        ThemeColors(int bg, int txt, int txtSec, int editBg) {
            background = bg;
            text = txt;
            textSecondary = txtSec;
            editBackground = editBg;
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Initialize repository
        preferencesRepo = new PreferencesRepository(this);
        
        // Initialize ViewModel for configuration change handling
        viewModel = new ViewModelProvider(this).get(TextViewModel.class);
        
        // Initialize handler for debounced saves
        saveHandler = new Handler(Looper.getMainLooper());

        // Initialize UI components
        initializeViews();
        
        // Load state from ViewModel or SharedPreferences
        loadState(savedInstanceState);
        
        // Apply saved theme and font
        applyTheme(viewModel.getCurrentTheme().getValue());
        applyFont(viewModel.getCurrentFontPath().getValue());

        // Update counter initially
        updateCounter();

        // Set up text change listener with debounced save
        setupTextWatcher();

        // Set up button click listeners
        setupButtonListeners();
        
        // Observe ViewModel LiveData
        observeViewModel();
    }

    /**
     * Initialize all view references.
     */
    private void initializeViews() {
        editText = findViewById(R.id.editText);
        charCounter = findViewById(R.id.charCounter);
        titleText = findViewById(R.id.titleText);
        limitLabel = findViewById(R.id.limitLabel);
        settingsButton = findViewById(R.id.settingsButton);
        themeButton = findViewById(R.id.themeButton);
        fontButton = findViewById(R.id.fontButton);
        rootView = findViewById(android.R.id.content);
        
        // Set content descriptions for accessibility
        settingsButton.setContentDescription("Change character limit");
        fontButton.setContentDescription("Choose font");
        
        // Make character counter less chatty for screen readers
        charCounter.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);
    }

    /**
     * Load state from savedInstanceState (on rotation) or SharedPreferences.
     * ViewModel persists data across configuration changes.
     */
    private void loadState(Bundle savedInstanceState) {
        if (savedInstanceState != null) {
            // Restore from savedInstanceState (most recent state)
            viewModel.setMaxCharacters(savedInstanceState.getInt("max_chars", 255));
            viewModel.setCurrentTheme(savedInstanceState.getString("theme", "light"));
            viewModel.setCurrentFontPath(savedInstanceState.getString("font_path", null));
            viewModel.setCurrentFontName(savedInstanceState.getString("font_name", "System Default"));
            
            String savedText = savedInstanceState.getString("current_text", "");
            viewModel.setText(savedText);
            editText.setText(savedText);
            editText.setSelection(savedText.length());
        } else if (viewModel.getText().getValue().isEmpty()) {
            // First time initialization - load from SharedPreferences
            int maxChars = preferencesRepo.getMaxCharacters();
            String theme = preferencesRepo.getTheme();
            String fontPath = preferencesRepo.getFontPath();
            String fontName = preferencesRepo.getFontName();
            String savedText = preferencesRepo.getText();
            
            viewModel.setMaxCharacters(maxChars);
            viewModel.setCurrentTheme(theme);
            viewModel.setCurrentFontPath(fontPath);
            viewModel.setCurrentFontName(fontName);
            viewModel.setText(savedText);
            
            editText.setText(savedText);
            if (savedText != null && !savedText.isEmpty()) {
                editText.setSelection(savedText.length());
            }
        }
    }

    /**
     * Observe ViewModel LiveData for updates.
     */
    private void observeViewModel() {
        // Update theme button description when theme changes
        viewModel.getCurrentTheme().observe(this, theme -> {
            themeButton.setContentDescription("Change theme. Current theme is " + theme + " mode");
        });
    }

    /**
     * Set up the TextWatcher with proper Unicode handling and debounced auto-save.
     */
    private void setupTextWatcher() {
        textWatcher = new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
                // Not needed
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                // Not needed
            }

            @Override
            public void afterTextChanged(Editable s) {
                // Enforce character limit if not already updating
                synchronized (updateLock) {
                    if (!isUpdating) {
                        enforceCharacterLimit(s);
                    }
                }
                
                // Update character counter
                updateCounter();
                
                // Debounce save operation to prevent excessive I/O
                debouncedSave(s.toString());
            }
        };
        
        editText.addTextChangedListener(textWatcher);
    }

    /**
     * Set up click listeners for all buttons.
     */
    private void setupButtonListeners() {
        settingsButton.setOnClickListener(v -> showLimitDialog());
        themeButton.setOnClickListener(v -> showThemeDialog());
        fontButton.setOnClickListener(v -> showFontDialog());
    }

    /**
     * Enforces the rolling character limit by removing oldest characters.
     * Uses Unicode code points to properly handle emoji and multi-byte characters.
     * 
     * CRITICAL FIX: Handles emoji correctly by counting code points instead of char units.
     * Example: "👨‍👩‍👧‍👦" (family emoji) is 1 code point, not 11 char units.
     * 
     * @param editable The text content being edited
     */
    private void enforceCharacterLimit(Editable editable) {
        // Count actual Unicode characters (code points), not UTF-16 code units
        int codePointCount = Character.codePointCount(editable, 0, editable.length());
        
        if (codePointCount > viewModel.getMaxCharacters().getValue()) {
            synchronized (updateLock) {
                isUpdating = true;
            }
            
            try {
                // Calculate how many code points to remove
                int codePointsToRemove = codePointCount - viewModel.getMaxCharacters().getValue();
                
                // Find the char offset for the number of code points to remove
                // This ensures we don't cut in the middle of a multi-byte character
                int offsetToRemove = 0;
                for (int i = 0; i < codePointsToRemove; i++) {
                    offsetToRemove += Character.charCount(
                        Character.codePointAt(editable, offsetToRemove)
                    );
                }
                
                // Remove characters from the beginning
                editable.delete(0, offsetToRemove);
                
                // Move cursor to the end
                editText.setSelection(editable.length());
            } catch (Exception e) {
                Log.e(TAG, "Error enforcing character limit", e);
            } finally {
                synchronized (updateLock) {
                    isUpdating = false;
                }
            }
        }
    }

    /**
     * Updates the character counter display.
     * Uses code point count for accurate Unicode character counting.
     */
    private void updateCounter() {
        int currentLength = Character.codePointCount(
            editText.getText(), 0, editText.getText().length()
        );
        charCounter.setText(currentLength + " / " + viewModel.getMaxCharacters().getValue());
    }

    /**
     * Debounces save operations to prevent excessive I/O.
     * Saves 500ms after the user stops typing.
     * 
     * CRITICAL FIX: Prevents saving on every keystroke which caused poor performance.
     * 
     * @param text The text to save
     */
    private void debouncedSave(String text) {
        // Cancel any pending save
        if (saveRunnable != null) {
            saveHandler.removeCallbacks(saveRunnable);
        }
        
        // Schedule new save
        saveRunnable = () -> {
            viewModel.setText(text);
            preferencesRepo.saveText(text);
        };
        saveHandler.postDelayed(saveRunnable, SAVE_DELAY_MS);
    }

    /**
     * Shows dialog to change the character limit.
     * Warns user if the new limit would truncate existing text.
     */
    private void showLimitDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Set Character Limit");

        final EditText input = new EditText(this);
        input.setInputType(android.text.InputType.TYPE_CLASS_NUMBER);
        input.setText(String.valueOf(viewModel.getMaxCharacters().getValue()));
        input.setSelection(input.getText().length());
        builder.setView(input);

        builder.setPositiveButton("OK", (dialog, which) -> {
            String inputText = input.getText().toString();
            if (!inputText.isEmpty()) {
                try {
                    int newLimit = Integer.parseInt(inputText);
                    if (newLimit > 0 && newLimit <= 1000000) {
                        int currentLength = Character.codePointCount(
                            editText.getText(), 0, editText.getText().length()
                        );
                        
                        // HIGH PRIORITY FIX: Warn if text will be truncated
                        if (newLimit < currentLength) {
                            int charsToRemove = currentLength - newLimit;
                            new AlertDialog.Builder(this)
                                .setTitle("Warning")
                                .setMessage("This will remove " + charsToRemove + 
                                    " character" + (charsToRemove > 1 ? "s" : "") + 
                                    " from the beginning of your text. Continue?")
                                .setPositiveButton("Yes", (d, w) -> {
                                    applyNewCharacterLimit(newLimit);
                                })
                                .setNegativeButton("No", null)
                                .show();
                        } else {
                            applyNewCharacterLimit(newLimit);
                        }
                    } else {
                        showErrorDialog("Please enter a number between 1 and 1,000,000");
                    }
                } catch (NumberFormatException e) {
                    showErrorDialog("Please enter a valid number");
                    Log.e(TAG, "Invalid number format", e);
                }
            }
        });
        
        builder.setNegativeButton("Cancel", (dialog, which) -> dialog.cancel());
        builder.show();
    }

    /**
     * Applies a new character limit and saves it.
     * 
     * @param newLimit The new character limit to apply
     */
    private void applyNewCharacterLimit(int newLimit) {
        viewModel.setMaxCharacters(newLimit);
        preferencesRepo.saveMaxCharacters(newLimit);
        
        // Enforce new limit on existing text
        Editable editable = editText.getText();
        enforceCharacterLimit(editable);
        updateCounter();
    }
    
    /**
     * Shows dialog to select theme.
     * Announces theme changes to screen readers for accessibility.
     */
    private void showThemeDialog() {
        String[] themes = {"Light", "Dark", "Sepia"};
        String currentTheme = viewModel.getCurrentTheme().getValue();
        int currentSelection = currentTheme.equals("light") ? 0 : 
                              currentTheme.equals("dark") ? 1 : 2;
        
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Select Theme");
        builder.setSingleChoiceItems(themes, currentSelection, (dialog, which) -> {
            String selectedTheme = which == 0 ? "light" : which == 1 ? "dark" : "sepia";
            viewModel.setCurrentTheme(selectedTheme);
            applyTheme(selectedTheme);
            preferencesRepo.saveTheme(selectedTheme);
            
            // Announce theme change for accessibility
            rootView.announceForAccessibility("Theme changed to " + selectedTheme + " mode");
            
            dialog.dismiss();
        });
        builder.setNegativeButton("Cancel", null);
        builder.show();
    }
    
    /**
     * Shows dialog to select font.
     * Loads fonts asynchronously to prevent ANR (Application Not Responding).
     * 
     * CRITICAL FIX: Moved font scanning to background thread to prevent UI freeze.
     */
    private void showFontDialog() {
        if (cachedFonts == null) {
            // Show progress while loading fonts on background thread
            AlertDialog progress = new AlertDialog.Builder(this)
                .setMessage("Loading fonts...")
                .setCancelable(false)
                .create();
            progress.show();
            
            // CRITICAL FIX: Load fonts on background thread to prevent ANR
            new Thread(() -> {
                try {
                    List<File> fonts = getSystemFonts();
                    
                    runOnUiThread(() -> {
                        progress.dismiss();
                        cachedFonts = fonts;
                        
                        if (fonts.isEmpty()) {
                            Toast.makeText(this, "No custom fonts found on device", 
                                Toast.LENGTH_SHORT).show();
                        }
                        
                        displayFontDialog(fonts);
                    });
                } catch (Exception e) {
                    Log.e(TAG, "Error loading fonts", e);
                    runOnUiThread(() -> {
                        progress.dismiss();
                        Toast.makeText(this, "Error loading fonts", Toast.LENGTH_SHORT).show();
                    });
                }
            }).start();
        } else {
            displayFontDialog(cachedFonts);
        }
    }
    
    /**
     * Displays the font selection dialog.
     * 
     * @param fontFiles List of available font files
     */
    private void displayFontDialog(List<File> fontFiles) {
        List<String> fontNames = new ArrayList<>();
        List<String> fontPaths = new ArrayList<>();
        
        // Add system default option
        fontNames.add("System Default");
        fontPaths.add(null);
        
        // Add system fonts
        for (File font : fontFiles) {
            fontNames.add(font.getName().replace(".ttf", "").replace(".otf", ""));
            fontPaths.add(font.getAbsolutePath());
        }
        
        String[] fontArray = fontNames.toArray(new String[0]);
        int currentSelection = 0;
        
        // Find current selection
        String currentPath = viewModel.getCurrentFontPath().getValue();
        for (int i = 0; i < fontPaths.size(); i++) {
            if ((currentPath == null && fontPaths.get(i) == null) ||
                (currentPath != null && currentPath.equals(fontPaths.get(i)))) {
                currentSelection = i;
                break;
            }
        }
        
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Select Font");
        builder.setSingleChoiceItems(fontArray, currentSelection, (dialog, which) -> {
            String selectedPath = fontPaths.get(which);
            String selectedName = fontNames.get(which);
            
            viewModel.setCurrentFontPath(selectedPath);
            viewModel.setCurrentFontName(selectedName);
            applyFont(selectedPath);
            preferencesRepo.saveFontPreference(selectedPath, selectedName);
            
            dialog.dismiss();
        });
        builder.setNegativeButton("Cancel", null);
        builder.show();
    }
    
    /**
     * Scans system font directories for available fonts.
     * This operation performs file I/O and should be called from a background thread.
     * 
     * @return List of font files found on the device
     */
    private List<File> getSystemFonts() {
        List<File> fontFiles = new ArrayList<>();
        
        // Common Android font directories
        String[] fontDirs = {
            "/system/fonts",
            "/system/font",
            "/data/fonts"
        };
        
        for (String dirPath : fontDirs) {
            File dir = new File(dirPath);
            if (dir.exists() && dir.isDirectory()) {
                File[] files = dir.listFiles((d, name) -> 
                    name.toLowerCase().endsWith(".ttf") || 
                    name.toLowerCase().endsWith(".otf"));
                
                if (files != null) {
                    // Filter to common, readable font names
                    // Exclude emoji fonts, symbol fonts, and style variants
                    for (File file : files) {
                        String name = file.getName().toLowerCase();
                        if (!name.contains("emoji") && 
                            !name.contains("symbol") && 
                            !name.contains("dingbat") &&
                            !name.contains("bold") &&
                            !name.contains("italic") &&
                            !name.contains("medium") &&
                            !name.contains("light") &&
                            !name.contains("thin") &&
                            !name.contains("black")) {
                            fontFiles.add(file);
                        }
                    }
                }
            }
        }
        
        return fontFiles;
    }
    
    /**
     * Applies the selected theme to the UI.
     * 
     * @param theme Theme name ("light", "dark", or "sepia")
     */
    private void applyTheme(String theme) {
        ThemeColors colors = getThemeColors(theme);
        
        // Apply colors to views
        rootView.setBackgroundColor(colors.background);
        titleText.setTextColor(colors.text);
        charCounter.setTextColor(colors.textSecondary);
        limitLabel.setTextColor(colors.textSecondary);
        editText.setTextColor(colors.text);
        editText.setHintTextColor(colors.textSecondary);
        
        // HIGH PRIORITY FIX: Reuse drawable instead of creating new one each time
        if (editTextDrawable == null) {
            editTextDrawable = new GradientDrawable();
            editTextDrawable.setCornerRadius(8f);
        }
        editTextDrawable.setColor(colors.editBackground);
        editTextDrawable.setStroke(2, colors.textSecondary);
        editText.setBackground(editTextDrawable);
    }
    
    /**
     * Gets theme colors for the specified theme.
     * 
     * @param theme Theme name
     * @return ThemeColors object with color values
     */
    private ThemeColors getThemeColors(String theme) {
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
     * Applies the selected font to text views.
     * HIGH PRIORITY FIX: Caches Typeface objects to avoid reloading from disk.
     * 
     * @param fontPath Path to font file, or null for system default
     */
    private void applyFont(String fontPath) {
        Typeface typeface;
        
        if (fontPath == null) {
            typeface = Typeface.DEFAULT;
        } else {
            // HIGH PRIORITY FIX: Check cache first to avoid disk I/O
            typeface = typefaceCache.get(fontPath);
            
            if (typeface == null) {
                try {
                    typeface = Typeface.createFromFile(fontPath);
                    typefaceCache.put(fontPath, typeface);
                } catch (RuntimeException e) {
                    Log.e(TAG, "Failed to load font: " + fontPath, e);
                    Toast.makeText(this, "Could not load font. Using default.", 
                        Toast.LENGTH_SHORT).show();
                    typeface = Typeface.DEFAULT;
                    viewModel.setCurrentFontPath(null);
                    viewModel.setCurrentFontName("System Default");
                    preferencesRepo.saveFontPreference(null, "System Default");
                } catch (OutOfMemoryError e) {
                    Log.e(TAG, "Font file too large: " + fontPath, e);
                    Toast.makeText(this, "Font file is too large. Using default.", 
                        Toast.LENGTH_SHORT).show();
                    typeface = Typeface.DEFAULT;
                    viewModel.setCurrentFontPath(null);
                    viewModel.setCurrentFontName("System Default");
                    preferencesRepo.saveFontPreference(null, "System Default");
                }
            }
        }
        
        // Apply typeface to all text views
        editText.setTypeface(typeface);
        titleText.setTypeface(typeface);
        charCounter.setTypeface(typeface);
        limitLabel.setTypeface(typeface);
    }

    /**
     * Shows an error dialog with the specified message.
     * 
     * @param message Error message to display
     */
    private void showErrorDialog(String message) {
        new AlertDialog.Builder(this)
            .setTitle("Invalid Input")
            .setMessage(message)
            .setPositiveButton("OK", null)
            .show();
    }

    /**
     * Save state before configuration change (e.g., rotation).
     * CRITICAL FIX: Ensures no data loss during rotation by saving to Bundle.
     */
    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString("current_text", editText.getText().toString());
        outState.putInt("max_chars", viewModel.getMaxCharacters().getValue());
        outState.putString("theme", viewModel.getCurrentTheme().getValue());
        outState.putString("font_path", viewModel.getCurrentFontPath().getValue());
        outState.putString("font_name", viewModel.getCurrentFontName().getValue());
    }

    /**
     * Save text immediately when app goes to background.
     * Cancels any pending debounced save and saves immediately.
     */
    @Override
    protected void onPause() {
        super.onPause();
        
        // Cancel pending save and save immediately
        if (saveRunnable != null) {
            saveHandler.removeCallbacks(saveRunnable);
        }
        
        String currentText = editText.getText().toString();
        viewModel.setText(currentText);
        preferencesRepo.saveText(currentText);
    }

    /**
     * Clean up resources when activity is destroyed.
     * HIGH PRIORITY FIX: Remove TextWatcher to prevent memory leaks.
     */
    @Override
    protected void onDestroy() {
        super.onDestroy();
        
        // Remove TextWatcher to prevent memory leaks
        if (editText != null && textWatcher != null) {
            editText.removeTextChangedListener(textWatcher);
        }
        
        // Cancel any pending saves
        if (saveHandler != null && saveRunnable != null) {
            saveHandler.removeCallbacks(saveRunnable);
        }
    }
}
