#!/usr/bin/env python3
"""
Rolling Text - Raspberry Pi Edition

A distraction-free writing app where text rolls away as you type.
Designed for Pi Zero 2 W + AMOLED display + USB mechanical keyboard.

Shortcuts (designed for 40% keyboards like the Air40):
    Ctrl+Q              Quit
    Ctrl+T              Toggle theme (dark / light)
    Ctrl+Up             Increase character limit (x2)
    Ctrl+Down           Decrease character limit (/2)
    Ctrl+=              Increase font size (+2pt)
    Ctrl+-              Decrease font size (-2pt)
    Ctrl+X              Clear all text
    Ctrl+H  or Escape   Toggle help overlay

Settings saved to ~/.config/rolling-text/settings.json
Place a .ttf font file next to this script to use a custom font.
"""

import json
import os
import sys

# Use KMS/DRM when no display server is running (bare console / VT)
if "DISPLAY" not in os.environ and "WAYLAND_DISPLAY" not in os.environ:
    os.environ.setdefault("SDL_VIDEODRIVER", "kmsdrm")

import pygame  # noqa: E402

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

CONFIG_DIR = os.path.expanduser("~/.config/rolling-text")
CONFIG_PATH = os.path.join(CONFIG_DIR, "settings.json")

DEFAULTS = {
    "max_chars": 128,
    "font_size": 28,
    "theme": "dark",
}

# True black for AMOLED power savings; pixels physically turn off.
THEMES = {
    "dark":  {"bg": (0, 0, 0),       "text": (255, 255, 255), "dim": (100, 100, 100)},
    "light": {"bg": (255, 255, 255), "text": (0, 0, 0),       "dim": (102, 102, 102)},
}

THEME_CYCLE = ["dark", "light"]

MARGIN = 30


# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------

class RollingText:
    def __init__(self):
        self.settings = dict(DEFAULTS)
        self._load_settings()
        self.text = ""
        self.cursor_on = True
        self.cursor_ms = 0
        self.help_visible = False
        self.dirty = True  # Track when screen needs redraw

        pygame.init()
        info = pygame.display.Info()
        self.sw = info.current_w if info.current_w > 0 else 1080
        self.sh = info.current_h if info.current_h > 0 else 1920

        try:
            self.screen = pygame.display.set_mode(
                (self.sw, self.sh), pygame.FULLSCREEN | pygame.DOUBLEBUF
            )
        except pygame.error:
            # Fallback without hardware flags
            self.screen = pygame.display.set_mode((self.sw, self.sh))

        pygame.display.set_caption("Rolling Text")
        pygame.mouse.set_visible(False)
        pygame.key.set_repeat(400, 35)
        self._load_font()
        self.clock = pygame.time.Clock()

    # ---- settings persistence ----

    def _load_settings(self):
        try:
            with open(CONFIG_PATH) as f:
                for k, v in json.load(f).items():
                    if k in DEFAULTS:
                        self.settings[k] = v
        except (FileNotFoundError, json.JSONDecodeError, OSError):
            pass
        # Migrate away from removed themes
        if self.settings["theme"] not in THEMES:
            self.settings["theme"] = "dark"

    def _save_settings(self):
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(CONFIG_PATH, "w") as f:
            json.dump(self.settings, f, indent=2)

    # ---- font loading ----

    def _load_font(self):
        size = self.settings["font_size"]

        # Prefer a .ttf file placed alongside this script
        here = os.path.dirname(os.path.abspath(__file__))
        for name in sorted(os.listdir(here)):
            if name.lower().endswith(".ttf"):
                try:
                    path = os.path.join(here, name)
                    self.font = pygame.font.Font(path, size)
                    self.ui_font = pygame.font.Font(path, 18)
                    return
                except pygame.error:
                    continue

        # Fall back to system monospace font
        self.font = pygame.font.SysFont("monospace", size)
        self.ui_font = pygame.font.SysFont("monospace", 18)

    # ---- theme ----

    @property
    def theme(self):
        return THEMES.get(self.settings["theme"], THEMES["dark"])

    # ---- core rolling-text logic ----

    def _truncate(self):
        """Remove oldest characters when text exceeds the limit.

        Counts by Unicode code points, matching the Flutter version.
        Python 3 str length is already code-point based.
        """
        mx = self.settings["max_chars"]
        if len(self.text) > mx:
            self.text = self.text[-mx:]

    # ---- word wrap ----

    def _wrap(self, text, max_px):
        """Word-wrap *text* so each line fits within *max_px* pixels."""
        if not text:
            return [""]
        lines = []
        for para in text.split("\n"):
            if not para:
                lines.append("")
                continue
            words = para.split(" ")
            cur = ""
            for w in words:
                trial = (cur + " " + w) if cur else w
                if self.font.size(trial)[0] <= max_px:
                    cur = trial
                else:
                    if cur:
                        lines.append(cur)
                    # Break words that are wider than the whole line
                    while w and self.font.size(w)[0] > max_px:
                        for i in range(len(w), 0, -1):
                            if self.font.size(w[:i])[0] <= max_px:
                                lines.append(w[:i])
                                w = w[i:]
                                break
                        else:
                            lines.append(w[0])
                            w = w[1:]
                    cur = w
            lines.append(cur)
        return lines

    # ---- rendering ----

    def _render(self):
        t = self.theme
        self.screen.fill(t["bg"])
        lh = self.font.get_linesize()

        # Bottom bar
        counter = f"{len(self.text)} / {self.settings['max_chars']}"
        c_surf = self.ui_font.render(counter, True, t["dim"])
        h_surf = self.ui_font.render("Ctrl+H: help", True, t["dim"])
        bar_h = c_surf.get_height() + 16

        self.screen.blit(
            c_surf, c_surf.get_rect(bottomright=(self.sw - MARGIN, self.sh - MARGIN))
        )
        self.screen.blit(
            h_surf, h_surf.get_rect(bottomleft=(MARGIN, self.sh - MARGIN))
        )

        # Text area dimensions
        max_w = self.sw - 2 * MARGIN
        avail_h = self.sh - 2 * MARGIN - bar_h
        max_lines = max(1, avail_h // lh)

        if not self.text:
            # Placeholder hint
            ph = self.font.render("Start typing\u2026", True, t["dim"])
            self.screen.blit(ph, (MARGIN, MARGIN))
            if self.cursor_on:
                pygame.draw.rect(
                    self.screen, t["text"], (MARGIN, MARGIN + 2, 2, lh - 4)
                )
        else:
            lines = self._wrap(self.text, max_w)
            visible = lines[-max_lines:] if len(lines) > max_lines else lines

            y = MARGIN
            for line in visible:
                if line:
                    surf = self.font.render(line, True, t["text"])
                    self.screen.blit(surf, (MARGIN, y))
                y += lh

            # Blinking cursor at end of last line
            if self.cursor_on:
                last = visible[-1] if visible else ""
                cx = MARGIN + self.font.size(last)[0] + 2
                cy = MARGIN + (len(visible) - 1) * lh
                pygame.draw.rect(
                    self.screen, t["text"], (cx, cy + 2, 2, lh - 4)
                )

        pygame.display.flip()

    def _render_help(self):
        t = self.theme
        self.screen.fill(t["bg"])

        tf = pygame.font.Font(None, 36)
        bf = pygame.font.Font(None, 26)

        rows = [
            (tf, t["text"], "Rolling Text  -  Pi Edition"),
            (bf, t["text"], ""),
            (bf, t["text"], "Ctrl+Q              Quit"),
            (bf, t["text"], "Ctrl+T              Toggle theme"),
            (bf, t["text"], "Ctrl+Up             Char limit x2"),
            (bf, t["text"], "Ctrl+Down           Char limit /2"),
            (bf, t["text"], "Ctrl+=              Font size +2"),
            (bf, t["text"], "Ctrl+-              Font size -2"),
            (bf, t["text"], "Ctrl+X              Clear text"),
            (bf, t["text"], "Ctrl+H / Escape     Toggle help"),
            (bf, t["text"], ""),
            (bf, t["dim"],  f"Theme: {self.settings['theme']}    "
                            f"Limit: {self.settings['max_chars']}    "
                            f"Size: {self.settings['font_size']}pt"),
            (bf, t["text"], ""),
            (bf, t["dim"],  "Press any key to return..."),
        ]

        y = 50
        for font, color, txt in rows:
            if txt:
                self.screen.blit(font.render(txt, True, color), (40, y))
            y += font.get_linesize() + 4

        pygame.display.flip()

    # ---- keyboard shortcuts ----

    def _shortcut(self, key, mod):
        ctrl = mod & pygame.KMOD_CTRL

        if key == pygame.K_ESCAPE:
            self.help_visible = not self.help_visible
            self.dirty = True
            return True

        if not ctrl:
            return False

        if key == pygame.K_q:
            self._save_settings()
            pygame.quit()
            sys.exit(0)

        if key == pygame.K_t:
            i = THEME_CYCLE.index(self.settings["theme"])
            self.settings["theme"] = THEME_CYCLE[(i + 1) % len(THEME_CYCLE)]
            self._save_settings()
            self.dirty = True
            return True

        if key == pygame.K_UP:
            self.settings["max_chars"] = min(1_000_000, self.settings["max_chars"] * 2)
            self._save_settings()
            self.dirty = True
            return True

        if key == pygame.K_DOWN:
            self.settings["max_chars"] = max(16, self.settings["max_chars"] // 2)
            self._truncate()
            self._save_settings()
            self.dirty = True
            return True

        if key == pygame.K_EQUALS:
            self.settings["font_size"] = min(144, self.settings["font_size"] + 2)
            self._load_font()
            self._save_settings()
            self.dirty = True
            return True

        if key == pygame.K_MINUS:
            self.settings["font_size"] = max(8, self.settings["font_size"] - 2)
            self._load_font()
            self._save_settings()
            self.dirty = True
            return True

        if key == pygame.K_x:
            self.text = ""
            self.dirty = True
            return True

        if key == pygame.K_h:
            self.help_visible = not self.help_visible
            self.dirty = True
            return True

        return False

    # ---- main loop ----

    def run(self):
        while True:
            for ev in pygame.event.get():
                if ev.type == pygame.QUIT:
                    self._save_settings()
                    pygame.quit()
                    sys.exit(0)

                if ev.type == pygame.KEYDOWN:
                    # While help is showing, any non-Ctrl key dismisses it
                    if self.help_visible:
                        if not (ev.mod & pygame.KMOD_CTRL):
                            self.help_visible = False
                            self.dirty = True
                            continue
                        self._shortcut(ev.key, ev.mod)
                        continue

                    if self._shortcut(ev.key, ev.mod):
                        continue

                    if ev.key == pygame.K_BACKSPACE:
                        if self.text:
                            self.text = self.text[:-1]
                            self.dirty = True
                    elif ev.key == pygame.K_RETURN:
                        self.text += "\n"
                        self._truncate()
                        self.dirty = True
                    elif ev.key == pygame.K_TAB:
                        self.text += "    "
                        self._truncate()
                        self.dirty = True

                elif ev.type == pygame.TEXTINPUT and not self.help_visible:
                    self.text += ev.text
                    self._truncate()
                    self.dirty = True

            # Cursor blink (~530 ms period)
            self.cursor_ms += self.clock.get_time()
            if self.cursor_ms >= 530:
                self.cursor_on = not self.cursor_on
                self.cursor_ms = 0
                self.dirty = True

            # Only redraw when something changed (saves CPU/battery)
            if self.dirty:
                if self.help_visible:
                    self._render_help()
                else:
                    self._render()
                self.dirty = False

            self.clock.tick(30)


if __name__ == "__main__":
    RollingText().run()
