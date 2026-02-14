package com.example.rollingtext;

import android.content.Context;
import android.graphics.Typeface;
import android.util.Log;
import java.io.File;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;

/**
 * Manages font loading, caching, and application.
 * Extracted from MainActivity for better separation of concerns.
 */
public class FontManager {
    private static final String TAG = "FontManager";

    // LRU cache for loaded typefaces (max 20 fonts)
    private final Map<String, Typeface> typefaceCache = new LinkedHashMap<String, Typeface>(16, 0.75f, true) {
        @Override
        protected boolean removeEldestEntry(Map.Entry<String, Typeface> eldest) {
            return size() > 20;
        }
    };

    private List<File> cachedFonts = null;
    private final Context context;

    public FontManager(Context context) {
        this.context = context;
    }

    /**
     * Get cached font list, or scan if not cached.
     * Loads fonts asynchronously on background thread.
     */
    public void loadFonts(ExecutorService executor, FontLoadCallback callback) {
        if (cachedFonts != null) {
            callback.onFontsLoaded(cachedFonts);
            return;
        }

        executor.execute(() -> {
            try {
                List<File> fonts = scanSystemFonts();
                cachedFonts = fonts;
                callback.onFontsLoaded(fonts);
            } catch (Exception e) {
                Log.e(TAG, "Error loading fonts", e);
                callback.onError(e);
            }
        });
    }

    /**
     * Scan system directories for font files.
     * This operation performs file I/O and should be called from a background thread.
     */
    private List<File> scanSystemFonts() {
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
     * Load typeface from file path with LRU caching.
     * Returns Typeface.DEFAULT if path is null or loading fails.
     */
    public Typeface loadTypeface(String fontPath) {
        if (fontPath == null) {
            return Typeface.DEFAULT;
        }

        // Check cache first
        Typeface cached = typefaceCache.get(fontPath);
        if (cached != null) {
            return cached;
        }

        // Load from file and cache
        try {
            Typeface typeface = Typeface.createFromFile(fontPath);
            typefaceCache.put(fontPath, typeface);
            return typeface;
        } catch (RuntimeException e) {
            Log.e(TAG, "Failed to load font: " + fontPath, e);
            return Typeface.DEFAULT;
        } catch (OutOfMemoryError e) {
            Log.e(TAG, "Font file too large: " + fontPath, e);
            return Typeface.DEFAULT;
        }
    }

    /**
     * Clear all caches to free memory.
     * Should be called in onDestroy().
     */
    public void clearCache() {
        typefaceCache.clear();
        if (cachedFonts != null) {
            cachedFonts.clear();
            cachedFonts = null;
        }
    }

    /**
     * Callback interface for asynchronous font loading operations.
     */
    public interface FontLoadCallback {
        void onFontsLoaded(List<File> fonts);
        void onError(Exception e);
    }
}
