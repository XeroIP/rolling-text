# Branding

`rolling-text-icon.svg` is the canonical source of the app icon: six vertical bars fading
from dark teal to bright white, representing the oldest-to-newest span of rolling text,
on a dark rounded-square background.

## Regenerating platform icons

The platform icon slots (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`,
`android/app/src/main/res/mipmap-*/ic_launcher.png`, `web/icons/`, `web/favicon.png`) are
raster exports of this SVG, **not** the SVG with its baked-in `rx="120"` corner rounding.
iOS, Android, and the web manifest's maskable icons all apply their own corner/shape mask
on top of a full-bleed square; handing them a source that already has transparent rounded
corners causes double-rounding artifacts and, for iOS's 1024x1024 marketing icon, App
Store Connect rejects a source containing an alpha channel.

To regenerate:
1. Render the SVG with `rx="0"` (no rounding) at high resolution (2048x2048 was used) to
   get a full-bleed square master. The colors use `oklch()`, so render through a browser
   engine that supports it (headless Chrome/Chromium) rather than an SVG library that
   may not.
2. Downscale that master with high-quality resampling (e.g. Pillow's `LANCZOS`) to each
   platform's exact required dimensions and overwrite the existing files in place — no
   new filenames, `Contents.json`, or `manifest.json` entries are needed since every slot
   already existed.

The `rx="120"` version (the SVG as checked in) is the pre-rounded shape, useful for
contexts that render it directly without their own masking — README badges, social
previews, store listing screenshots — not for the OS-level icon slots above.
