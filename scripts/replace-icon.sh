#!/bin/bash
# Replace terminal-notifier app icon with custom Claude Code icon
# Run after: brew install terminal-notifier OR brew upgrade terminal-notifier

set -e

ICON_SRC="$HOME/.claude/claude-icon.png"
APP_RESOURCES="/opt/homebrew/Cellar/terminal-notifier/2.0.0/terminal-notifier.app/Contents/Resources"
ICONSET_DIR="/tmp/claude-icon.iconset"

# Check source icon exists
if [ ! -f "$ICON_SRC" ]; then
  echo "ERROR: Source icon not found at $ICON_SRC"
  exit 1
fi

# Create iconset from PNG
echo "Converting PNG to ICNS..."
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

for size in 16 32 64 128 256 512; do
  sips -z $size $size "$ICON_SRC" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null 2>&1
done
for size in 16 32 64 128 256 512; do
  double=$((size * 2))
  if [ $double -le 1024 ]; then
    sips -z $double $double "$ICON_SRC" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null 2>&1
  fi
done

iconutil -c icns "$ICONSET_DIR" -o /tmp/claude-icon.icns
echo "ICNS created at /tmp/claude-icon.icns"

# Backup and replace
if [ -f "$APP_RESOURCES/Terminal.icns" ] && [ ! -f "$APP_RESOURCES/Terminal.icns.bak" ]; then
  cp "$APP_RESOURCES/Terminal.icns" "$APP_RESOURCES/Terminal.icns.bak"
  echo "Original icon backed up"
fi

cp /tmp/claude-icon.icns "$APP_RESOURCES/Terminal.icns"
echo "Icon replaced"

# Clear icon cache
echo "Clearing macOS icon cache..."
sudo rm -rfv /Library/Caches/com.apple.iconservices.store 2>/dev/null || true
sudo find /private/var/folders/ -name com.apple.iconservices -exec rm -rfv {} \; 2>/dev/null || true
sudo killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

echo ""
echo "Done! Log out and back in (or restart) for the icon to take effect."
