#!/usr/bin/env bash
# ---------------------------------------------------------------
# Rolling Text — Raspberry Pi Setup
#
# Run this on your Pi Zero 2 W to install dependencies.
# Tested on Raspberry Pi OS Bookworm (Lite, no desktop).
# ---------------------------------------------------------------
set -e

echo "=== Rolling Text — Pi Setup ==="
echo ""

# --- System packages ---
echo "Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y python3-pygame fonts-dejavu-core

# --- Verify KMS driver ---
if ! grep -q "^dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt 2>/dev/null &&
   ! grep -q "^dtoverlay=vc4-kms-v3d" /boot/config.txt 2>/dev/null; then
    echo ""
    echo "WARNING: vc4-kms-v3d overlay not found in config.txt."
    echo "The AMOLED display needs KMS/DRM. Add this line to your config.txt:"
    echo "  dtoverlay=vc4-kms-v3d"
    echo ""
fi

# --- Config directory ---
mkdir -p ~/.config/rolling-text

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "Setup complete!"
echo ""
echo "To run:  python3 ${SCRIPT_DIR}/rolling_text.py"
echo ""
echo "--- Optional: Auto-launch on a virtual terminal ---"
echo ""
echo "Add this to your ~/.bashrc or ~/.bash_profile to auto-start"
echo "Rolling Text when you switch to a specific VT (e.g. tty3):"
echo ""
echo "  if [ \"\$(tty)\" = \"/dev/tty3\" ]; then"
echo "    python3 ${SCRIPT_DIR}/rolling_text.py"
echo "  fi"
echo ""
echo "--- Optional: Custom font ---"
echo ""
echo "Drop a .ttf file (e.g. SourceCodePro-Regular.ttf) into"
echo "  ${SCRIPT_DIR}/"
echo "and it will be used automatically on next launch."
