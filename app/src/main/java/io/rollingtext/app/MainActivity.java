package io.rollingtext.app;

import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;
import com.google.android.material.button.MaterialButton;
import android.content.Intent;
import android.view.View;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * Main activity for the RollingText app.
 * <p>
 * This app maintains a rolling character limit - when the user exceeds the limit,
 * the oldest characters are automatically removed from the beginning of the text.
 * <p>
 * Features:
 * - Rolling character limit with Unicode/emoji support
 * - Theme selection (Light, Dark, Sepia)
 * - Font picker from system fonts
 * - Text is never persisted - starts fresh every launch
 * - Configuration change handling (survives rotation)
 */
public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    
    // UI Components
    private EditText editText;
    private TextView charCounter;
    private MaterialButton settingsButton;
    private MaterialButton themeButton;
    private MaterialButton fontButton;
    private MaterialButton fontSizeButton;
    private MaterialButton aboutButton;
    private View rootView;
    
    // ViewModel for configuration change handling
    private TextViewModel viewModel;
    
    // Repository for SharedPreferences operations
    private PreferencesRepository preferencesRepo;
    
    // TextWatcher instance (stored for proper cleanup)
    private TextWatcher textWatcher;
    
    // Debouncing for ViewModel sync
    private Handler saveHandler;
    private Runnable saveRunnable;
    private static final int SAVE_DELAY_MS = 500;

    // ExecutorService for background operations
    private ExecutorService backgroundExecutor;

    // Flag to prevent recursive updates (TextWatcher runs on main thread)
    private boolean isUpdating = false;

    // Font manager for font loading and caching
    private FontManager fontManager;

    // Theme manager for theme application
    private ThemeManager themeManager;

    // Cached LiveData values to avoid null checks
    private int cachedMaxCharacters = PreferencesRepository.DEFAULT_MAX_CHARS;
    private String cachedTheme = "light";
    private String cachedFontPath = null;
    private float cachedFontSize = 16f;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Initialize repository
        preferencesRepo = new PreferencesRepository(this);

        // Initialize ViewModel for configuration change handling
        viewModel = new ViewModelProvider(this).get(TextViewModel.class);

        // Initialize font manager
        fontManager = new FontManager();

        // Initialize theme manager
        themeManager = new ThemeManager();

        // Initialize handler for debounced saves
        saveHandler = new Handler(Looper.getMainLooper());

        // Initialize background executor for async operations
        backgroundExecutor = Executors.newSingleThreadExecutor();

        // Initialize UI components
        initializeViews();
        
        // Load state from ViewModel or SharedPreferences
        loadState(savedInstanceState);
        
        // Apply saved theme and font
        applyTheme(cachedTheme);
        applyFont(cachedFontPath);

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
        settingsButton = findViewById(R.id.settingsButton);
        themeButton = findViewById(R.id.themeButton);
        fontButton = findViewById(R.id.fontButton);
        fontSizeButton = findViewById(R.id.fontSizeButton);
        aboutButton = findViewById(R.id.aboutButton);
        rootView = findViewById(android.R.id.content);

        // Make character counter less chatty for screen readers
        charCounter.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);
    }

    /**
     * Load state from savedInstanceState (on rotation) or SharedPreferences.
     * ViewModel persists data across configuration changes.
     */
    private void loadState(Bundle savedInstanceState) {
        if (savedInstanceState != null) {
            // Restore from savedInstanceState (process death recovery)
            viewModel.setMaxCharacters(savedInstanceState.getInt("max_chars", PreferencesRepository.DEFAULT_MAX_CHARS));
            viewModel.setCurrentTheme(savedInstanceState.getString("theme", "light"));
            viewModel.setCurrentFontPath(savedInstanceState.getString("font_path", null));
            viewModel.setCurrentFontName(savedInstanceState.getString("font_name", getString(R.string.font_system_default)));
            viewModel.setFontSize(savedInstanceState.getFloat("font_size", 16f));

            String savedText = savedInstanceState.getString("current_text", "");
            viewModel.setText(savedText);
            editText.setText(savedText);
            editText.setSelection(savedText.length());
            viewModel.setInitialized(true);
        } else {
            if (!viewModel.isInitialized()) {
                // First launch — load user preferences from SharedPreferences
                viewModel.setMaxCharacters(preferencesRepo.getMaxCharacters());
                viewModel.setCurrentTheme(preferencesRepo.getTheme());
                viewModel.setCurrentFontPath(preferencesRepo.getFontPath());
                viewModel.setCurrentFontName(preferencesRepo.getFontName());
                viewModel.setFontSize(preferencesRepo.getFontSize());
                viewModel.setInitialized(true);
            }
            // else: configuration change (e.g., rotation) — ViewModel already holds correct state
        }

        // Cache LiveData values for performance and null-safety
        cachedMaxCharacters = viewModel.getMaxCharacters().getValue() != null ?
            viewModel.getMaxCharacters().getValue() : PreferencesRepository.DEFAULT_MAX_CHARS;
        cachedTheme = viewModel.getCurrentTheme().getValue() != null ?
            viewModel.getCurrentTheme().getValue() : "light";
        cachedFontPath = viewModel.getCurrentFontPath().getValue();
        cachedFontSize = viewModel.getFontSize().getValue() != null ?
            viewModel.getFontSize().getValue() : 16f;
        editText.setTextSize(android.util.TypedValue.COMPLEX_UNIT_PT, cachedFontSize);
    }

    /**
     * Observe ViewModel LiveData for updates.
     */
    private void observeViewModel() {
        // Update theme button description when theme changes
        viewModel.getCurrentTheme().observe(this, theme -> themeButton.setContentDescription(getString(R.string.desc_change_theme, theme)));
    }

    /**
     * Set up the TextWatcher with proper Unicode handling and debounced ViewModel sync.
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
                if (!isUpdating) {
                    enforceCharacterLimit(s);
                }

                // Update character counter
                updateCounter();

                // Debounce ViewModel sync
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
        fontSizeButton.setOnClickListener(v -> showFontSizeDialog());
        aboutButton.setOnClickListener(v -> {
            Intent intent = new Intent(this, AboutActivity.class);
            intent.putExtra("theme", cachedTheme);
            startActivity(intent);
        });
    }

    /**
     * Enforces the rolling character limit by removing oldest characters.
     * Uses Unicode code points to properly handle emoji and multi-byte characters.
     * <p>
     * Handles emoji correctly by counting code points instead of char units.
     * Example: "😀" is 1 code point but 2 UTF-16 char units (surrogate pair).
     * Note: Complex emoji like "👨‍👩‍👧‍👦" are multiple code points joined by ZWJ.
     * 
     * @param editable The text content being edited
     */
    private void enforceCharacterLimit(Editable editable) {
        // Count actual Unicode characters (code points), not UTF-16 code units
        int codePointCount = Character.codePointCount(editable, 0, editable.length());

        if (codePointCount > cachedMaxCharacters) {
            isUpdating = true;

            try {
                // Calculate how many code points to remove
                int codePointsToRemove = codePointCount - cachedMaxCharacters;

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
                isUpdating = false;
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
        charCounter.setText(getString(R.string.char_counter_format, currentLength, cachedMaxCharacters));
    }

    /**
     * Debounces ViewModel sync to avoid updating on every keystroke.
     *
     * @param text The text to sync to ViewModel
     */
    private void debouncedSave(String text) {
        if (saveRunnable != null) {
            saveHandler.removeCallbacks(saveRunnable);
        }

        saveRunnable = () -> viewModel.setText(text);
        saveHandler.postDelayed(saveRunnable, SAVE_DELAY_MS);
    }

    /**
     * Shows dialog to change the character limit.
     * Warns user if the new limit would truncate existing text.
     */
    private void showLimitDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.dialog_title_limit);

        final EditText input = new EditText(this);
        input.setInputType(android.text.InputType.TYPE_CLASS_NUMBER);
        input.setHint(R.string.hint_character_limit);
        input.setText(String.valueOf(cachedMaxCharacters));
        input.setSelection(input.getText().length());
        input.setPadding(60, 20, 60, 20);
        builder.setView(input);

        builder.setPositiveButton(getString(R.string.button_ok), (dialog, which) -> {
            String inputText = input.getText().toString();
            if (!inputText.isEmpty()) {
                try {
                    int newLimit = Integer.parseInt(inputText);
                    if (newLimit > 0 && newLimit <= 1000000) {
                        int currentLength = Character.codePointCount(
                            editText.getText(), 0, editText.getText().length()
                        );

                        // Warn if text will be truncated
                        if (newLimit < currentLength) {
                            int charsToRemove = currentLength - newLimit;
                            new AlertDialog.Builder(this)
                                .setTitle(R.string.dialog_title_warning)
                                .setMessage(getResources().getQuantityString(R.plurals.dialog_warning_truncate_plurals, charsToRemove, charsToRemove))
                                .setPositiveButton(R.string.button_yes, (d, w) -> applyNewCharacterLimit(newLimit))
                                .setNegativeButton(R.string.button_no, null)
                                .show();
                        } else {
                            applyNewCharacterLimit(newLimit);
                        }
                    } else {
                        showErrorDialog(getString(R.string.error_number_range));
                    }
                } catch (NumberFormatException e) {
                    showErrorDialog(getString(R.string.error_invalid_number));
                    Log.e(TAG, "Invalid number format", e);
                }
            }
        });

        builder.setNegativeButton(getString(R.string.button_cancel), null);
        builder.show();
    }

    /**
     * Applies a new character limit and saves it.
     * 
     * @param newLimit The new character limit to apply
     */
    private void applyNewCharacterLimit(int newLimit) {
        cachedMaxCharacters = newLimit;
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
        String[] themes = {
            getString(R.string.theme_light),
            getString(R.string.theme_dark),
            getString(R.string.theme_sepia)
        };
        int currentSelection = cachedTheme.equals("light") ? 0 :
                              cachedTheme.equals("dark") ? 1 : 2;

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.dialog_title_theme);
        builder.setSingleChoiceItems(themes, currentSelection, (dialog, which) -> {
            String selectedTheme = which == 0 ? "light" : which == 1 ? "dark" : "sepia";
            cachedTheme = selectedTheme;
            viewModel.setCurrentTheme(selectedTheme);
            applyTheme(selectedTheme);
            preferencesRepo.saveTheme(selectedTheme);

            // Announce theme change for accessibility
            rootView.announceForAccessibility(getString(R.string.announce_theme_changed, selectedTheme));

            dialog.dismiss();
        });
        builder.setNegativeButton(R.string.button_cancel, null);
        builder.show();
    }
    
    /**
     * Shows dialog to select font.
     * Loads fonts asynchronously to prevent ANR (Application Not Responding).
     * <p>
     * CRITICAL FIX: Moved font scanning to background thread to prevent UI freeze.
     */
    private void showFontDialog() {
        // Show progress while loading fonts
        AlertDialog progress = new AlertDialog.Builder(this)
            .setMessage(R.string.dialog_loading_fonts)
            .setCancelable(false)
            .create();
        progress.show();

        // Load fonts asynchronously using FontManager
        fontManager.loadFonts(backgroundExecutor, new FontManager.FontLoadCallback() {
            @Override
            public void onFontsLoaded(List<File> fonts) {
                runOnUiThread(() -> {
                    progress.dismiss();

                    if (fonts.isEmpty()) {
                        Toast.makeText(MainActivity.this, R.string.toast_no_fonts,
                            Toast.LENGTH_SHORT).show();
                    }

                    displayFontDialog(fonts);
                });
            }

            @Override
            public void onError(Exception e) {
                runOnUiThread(() -> {
                    progress.dismiss();
                    Toast.makeText(MainActivity.this, R.string.toast_error_fonts,
                        Toast.LENGTH_SHORT).show();
                });
            }
        });
    }
    
    /**
     * Displays the font selection dialog with fonts shown in their own typeface.
     *
     * @param fontFiles List of available font files
     */
    private void displayFontDialog(List<File> fontFiles) {
        List<String> fontNames = new ArrayList<>();
        List<String> fontPaths = new ArrayList<>();

        // Add system default option
        fontNames.add(getString(R.string.font_system_default));
        fontPaths.add(null);

        // Add system fonts
        for (File font : fontFiles) {
            fontNames.add(font.getName().replace(".ttf", "").replace(".otf", ""));
            fontPaths.add(font.getAbsolutePath());
        }

        int currentSelection = 0;

        // Find current selection
        for (int i = 0; i < fontPaths.size(); i++) {
            if (Objects.equals(cachedFontPath, fontPaths.get(i))) {
                currentSelection = i;
                break;
            }
        }

        // Create custom adapter to display fonts in their own typeface
        ArrayAdapter<String> adapter = new ArrayAdapter<String>(this, android.R.layout.select_dialog_singlechoice, fontNames) {
            @NonNull
            @Override
            public View getView(int position, View convertView, @NonNull ViewGroup parent) {
                View view = super.getView(position, convertView, parent);
                TextView textView = view.findViewById(android.R.id.text1);

                // Apply the font's own typeface to the text
                String fontPath = fontPaths.get(position);
                if (fontPath != null) {
                    try {
                        Typeface typeface = fontManager.loadTypeface(fontPath);
                        textView.setTypeface(typeface);
                    } catch (Exception e) {
                        Log.w(TAG, "Could not load font for preview: " + fontPath);
                    }
                }

                return view;
            }
        };

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.dialog_title_font);
        builder.setSingleChoiceItems(adapter, currentSelection, (dialog, which) -> {
            String selectedPath = fontPaths.get(which);
            String selectedName = fontNames.get(which);

            cachedFontPath = selectedPath;
            viewModel.setCurrentFontPath(selectedPath);
            viewModel.setCurrentFontName(selectedName);
            applyFont(selectedPath);
            preferencesRepo.saveFontPreference(selectedPath, selectedName);

            dialog.dismiss();
        });
        builder.setNegativeButton(R.string.button_cancel, null);
        builder.show();
    }
    
    /**
     * Applies the selected theme to the UI.
     * Uses ThemeManager for theme application.
     *
     * @param theme Theme name ("light", "dark", or "sepia")
     */
    private void applyTheme(String theme) {
        themeManager.applyTheme(theme, this, rootView, charCounter, editText,
            settingsButton, themeButton, fontButton, fontSizeButton, aboutButton);
    }
    
    /**
     * Applies the selected font to text views.
     * Uses FontManager for font loading and caching.
     *
     * @param fontPath Path to font file, or null for system default (serif monospace)
     */
    private void applyFont(String fontPath) {
        Typeface typeface;

        if (fontPath == null) {
            // Use serif monospace as default
            typeface = Typeface.create("serif-monospace", Typeface.NORMAL);
        } else {
            typeface = fontManager.loadTypeface(fontPath);

            // If font loading failed, reset to default
            if (typeface == Typeface.DEFAULT) {
                Toast.makeText(this, R.string.toast_font_error, Toast.LENGTH_SHORT).show();
                String systemDefault = getString(R.string.font_system_default);
                cachedFontPath = null;
                viewModel.setCurrentFontPath(null);
                viewModel.setCurrentFontName(systemDefault);
                preferencesRepo.saveFontPreference(null, systemDefault);
                typeface = Typeface.create("serif-monospace", Typeface.NORMAL);
            }
        }

        // Apply typeface to all text views
        editText.setTypeface(typeface);
        charCounter.setTypeface(typeface);
    }

    /**
     * Applies a new font size and saves it.
     *
     * @param size Font size in pt
     */
    private void applyFontSize(float size) {
        cachedFontSize = size;
        viewModel.setFontSize(size);
        editText.setTextSize(android.util.TypedValue.COMPLEX_UNIT_PT, size);
        preferencesRepo.saveFontSize(size);
    }

    /**
     * Shows dialog to change font size with list and custom input.
     */
    private void showFontSizeDialog() {
        String[] sizes = {"10pt", "12pt", "14pt", "16pt", "18pt", "20pt", "24pt", "28pt", "32pt", "Custom..."};
        int[] sizeValues = {10, 12, 14, 16, 18, 20, 24, 28, 32};

        int currentSelection = 3; // Default to 16pt
        for (int i = 0; i < sizeValues.length; i++) {
            if (sizeValues[i] == (int)cachedFontSize) {
                currentSelection = i;
                break;
            }
        }

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.dialog_title_font_size);
        builder.setSingleChoiceItems(sizes, currentSelection, (dialog, which) -> {
            if (which == sizes.length - 1) {
                // Custom option selected
                dialog.dismiss();
                showCustomFontSizeDialog();
            } else {
                float newSize = sizeValues[which];
                applyFontSize(newSize);
                dialog.dismiss();
            }
        });
        builder.setNegativeButton(R.string.button_cancel, null);
        builder.show();
    }

    /**
     * Shows dialog for custom font size input.
     */
    private void showCustomFontSizeDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.dialog_title_font_size);

        final EditText input = new EditText(this);
        input.setInputType(android.text.InputType.TYPE_CLASS_NUMBER);
        input.setHint(R.string.hint_font_size);
        input.setText(String.valueOf((int)cachedFontSize));
        input.setSelection(input.getText().length());
        builder.setView(input);

        builder.setPositiveButton(getString(R.string.button_ok), (dialog, which) -> {
            String inputText = input.getText().toString();
            if (!inputText.isEmpty()) {
                try {
                    int newSize = Integer.parseInt(inputText);
                    if (newSize >= 6 && newSize <= 72) {
                        applyFontSize(newSize);
                    } else {
                        showErrorDialog(getString(R.string.error_font_size_range));
                    }
                } catch (NumberFormatException e) {
                    showErrorDialog(getString(R.string.error_invalid_number));
                    Log.e(TAG, "Invalid number format", e);
                }
            }
        });

        builder.setNegativeButton(getString(R.string.button_cancel), null);
        builder.show();
    }

    /**
     * Shows an error dialog with the specified message.
     *
     * @param message Error message to display
     */
    private void showErrorDialog(String message) {
        new AlertDialog.Builder(this)
            .setTitle(R.string.dialog_title_error)
            .setMessage(message)
            .setPositiveButton(R.string.button_ok, null)
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
        Integer maxChars = viewModel.getMaxCharacters().getValue();
        if (maxChars != null) {
            outState.putInt("max_chars", maxChars);
        }
        outState.putString("theme", viewModel.getCurrentTheme().getValue());
        outState.putString("font_path", viewModel.getCurrentFontPath().getValue());
        outState.putString("font_name", viewModel.getCurrentFontName().getValue());
        Float fontSize = viewModel.getFontSize().getValue();
        if (fontSize != null) {
            outState.putFloat("font_size", fontSize);
        }
    }

    @Override
    protected void onPause() {
        super.onPause();

        // Cancel pending ViewModel sync
        if (saveRunnable != null) {
            saveHandler.removeCallbacks(saveRunnable);
        }
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

        // Clear font manager cache to free memory
        if (fontManager != null) {
            fontManager.clearCache();
        }

        // Shutdown executor
        if (backgroundExecutor != null) {
            backgroundExecutor.shutdown();
            try {
                if (!backgroundExecutor.awaitTermination(1, TimeUnit.SECONDS)) {
                    backgroundExecutor.shutdownNow();
                }
            } catch (InterruptedException e) {
                backgroundExecutor.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }
    }
}
