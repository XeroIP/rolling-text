# Rolling Text - Raspberry Pi Edition

A lightweight Python + Pygame port of Rolling Text designed for the Raspberry Pi Zero 2 W with an AMOLED display and mechanical keyboard.

## Hardware

This edition is designed for a portable WriterDeck built with:

| Component | Notes |
|-----------|-------|
| Raspberry Pi Zero 2 W | Without headers |
| 5.5" AMOLED Screen | Via mini HDMI |
| UPS and Hub Pi Hat | Battery power management |
| 18650 Battery | Portable power |
| Air40 Keyboard PCB | 40% mechanical, Cherry MX footprint |
| Keyboard Switches (x48) | Cherry MX compatible |
| Keycaps (x48) | DSA or XDA profile |
| Mini to Mini HDMI Cable | 0.3M |
| USB A to C Cable | Keyboard connection |
| USB C Extender | Charging access |

Reference BOM: [bee-write-back Hardware BOM](https://github.com/shmimel/bee-write-back/blob/main/Hardware/BOM.md)

## Setup

### 1. Install dependencies

```bash
cd pi/
./setup.sh
```

This installs `python3-pygame` and `fonts-dejavu-core` via apt, and checks that the KMS/DRM video driver is configured.

### 2. Verify config.txt

The AMOLED display requires the KMS/DRM video driver. Ensure this line exists in `/boot/firmware/config.txt` (or `/boot/config.txt` on older images):

```
dtoverlay=vc4-kms-v3d
```

If your 5.5" AMOLED is in portrait orientation and needs rotation, add:

```
display_hdmi_rotate=1
```

Reboot after any config.txt changes.

### 3. Run

```bash
python3 pi/rolling_text.py
```

The app launches fullscreen via KMS/DRM when no desktop environment is running. It also works under X11/Wayland if a desktop is present.

## Keyboard Shortcuts

Designed for 40% keyboards where brackets and function keys are on layers.

| Shortcut | Action |
|----------|--------|
| Ctrl+Q | Quit |
| Ctrl+T | Toggle theme (dark / light) |
| Ctrl+Up | Increase character limit (x2) |
| Ctrl+Down | Decrease character limit (/2) |
| Ctrl+= | Increase font size (+2pt) |
| Ctrl+- | Decrease font size (-2pt) |
| Ctrl+X | Clear all text |
| Ctrl+H / Escape | Toggle help overlay |

## Settings

Settings are saved automatically to `~/.config/rolling-text/settings.json`:

| Setting | Default | Range |
|---------|---------|-------|
| `max_chars` | 128 | 16 - 1,000,000 |
| `font_size` | 28 | 8 - 144 |
| `theme` | dark | dark, light |

## Custom Fonts

Drop a `.ttf` font file into the `pi/` directory alongside `rolling_text.py`. The app picks up the first `.ttf` it finds (alphabetically) on launch. If no `.ttf` is present, it falls back to the system monospace font.

Example:
```bash
# Download Source Code Pro (the Flutter edition's default font)
cp SourceCodePro-Regular.ttf pi/
```

## Auto-Launch on a Virtual Terminal

The bee-write-back project uses virtual terminals (VTs) to run different apps. To auto-launch Rolling Text on a specific VT (e.g., tty3), add this to `~/.bashrc` or `~/.bash_profile`:

```bash
if [ "$(tty)" = "/dev/tty3" ]; then
    python3 /path/to/pi/rolling_text.py
fi
```

Then switch to that VT with `Ctrl+Alt+F3`.

## Technical Notes

- **Rendering**: Pygame with SDL2 KMS/DRM backend, direct framebuffer access
- **Performance**: ~20-30MB RAM, dirty-flag rendering (only redraws on state changes), 30 FPS cap
- **Text handling**: Unicode code-point counting, matching the Flutter edition's behavior
- **AMOLED optimization**: Dark theme uses true black (#000000) so pixels physically turn off
- **No network required**: Runs fully offline, no external dependencies at runtime
