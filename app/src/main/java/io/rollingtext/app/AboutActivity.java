package io.rollingtext.app;

import android.content.res.ColorStateList;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.google.android.material.button.MaterialButton;

/**
 * Activity displaying the About screen with research citations.
 * Receives the current theme from the launching activity via intent extras.
 */
public class AboutActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_about);

        // Set up back button
        MaterialButton backButton = findViewById(R.id.backButton);
        backButton.setOnClickListener(v -> finish());

        // Apply theme from intent
        String theme = getIntent().getStringExtra("theme");
        if (theme == null) {
            theme = "light";
        }
        applyTheme(theme);
    }

    private void applyTheme(String theme) {
        ThemeManager themeManager = new ThemeManager();
        ThemeManager.ThemeColors colors = themeManager.getThemeColors(theme, this);

        View scrollView = findViewById(R.id.aboutScrollView);
        View content = findViewById(R.id.aboutContent);
        scrollView.setBackgroundColor(colors.background);
        content.setBackgroundColor(colors.background);

        // Apply text colors to all TextViews
        int[] titleIds = {
            R.id.aboutTitle,
            R.id.study1Title, R.id.study2Title,
            R.id.study3Title, R.id.study4Title
        };
        for (int id : titleIds) {
            ((TextView) findViewById(id)).setTextColor(colors.text);
        }

        int[] bodyIds = {
            R.id.aboutIntro, R.id.aboutConcept, R.id.aboutPower,
            R.id.aboutScienceIntro,
            R.id.study1Body, R.id.study2Body,
            R.id.study3Body, R.id.study4Body,
            R.id.aboutClosing
        };
        for (int id : bodyIds) {
            ((TextView) findViewById(id)).setTextColor(colors.text);
        }

        int[] citationIds = {
            R.id.study1Citation, R.id.study2Citation,
            R.id.study3Citation, R.id.study4Citation
        };
        for (int id : citationIds) {
            ((TextView) findViewById(id)).setTextColor(colors.textSecondary);
        }

        // Style the back button to match the theme
        MaterialButton backButton = findViewById(R.id.backButton);
        backButton.setTextColor(colors.textSecondary);
        backButton.setIconTint(ColorStateList.valueOf(colors.textSecondary));
        backButton.setBackgroundTintList(ColorStateList.valueOf(colors.buttonBackground));

        // Status bar: dark icons for light/sepia backgrounds, light icons for dark
        Window window = getWindow();
        WindowInsetsControllerCompat insetsController =
            WindowCompat.getInsetsController(window, window.getDecorView());
        insetsController.setAppearanceLightStatusBars(!theme.equals("dark"));
    }
}
