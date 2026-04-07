#!/bin/bash
# ============================================================================
# Claude Code macOS Notifications — Full Setup
# ============================================================================
# Sends macOS Notification Centre banners when Claude Code:
#   - Finishes a task (Stop hook)        — "Glass" sound
#   - Needs your input (Notification hook) — "Purr" sound
#
# Requires: macOS, Homebrew, Claude Code CLI
#
# Usage:
#   chmod +x setup-notifications.sh
#   ./setup-notifications.sh
#
# After running, log out and back in (or restart) for the custom icon to
# appear in notification banners.
# ============================================================================

set -e

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
ICON_FILE="$CLAUDE_DIR/claude-icon.png"
ICONSET_DIR="/tmp/claude-icon.iconset"
ICNS_FILE="/tmp/claude-icon.icns"

# --- Colours ----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!!]${NC} $1"; }
error() { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

# --- Preflight checks -------------------------------------------------------
echo ""
echo "Claude Code macOS Notifications — Setup"
echo "========================================"
echo ""

if [[ "$(uname)" != "Darwin" ]]; then
  error "This script is macOS only."
fi

if ! command -v brew &>/dev/null; then
  error "Homebrew is required. Install from https://brew.sh"
fi

if ! command -v claude &>/dev/null; then
  warn "Claude Code CLI not found on PATH — hooks will still be configured."
fi

# --- Step 1: Install terminal-notifier --------------------------------------
echo ""
echo "Step 1: Install terminal-notifier"
echo "----------------------------------"

if command -v terminal-notifier &>/dev/null; then
  info "terminal-notifier already installed."
else
  echo "Installing terminal-notifier via Homebrew..."
  brew install terminal-notifier
  info "terminal-notifier installed."
fi

# Find terminal-notifier app bundle (works across versions)
TN_APP=$(brew --prefix terminal-notifier 2>/dev/null)/terminal-notifier.app
if [ ! -d "$TN_APP" ]; then
  # Fallback: search Cellar
  TN_APP=$(find "$(brew --cellar terminal-notifier)" -name "terminal-notifier.app" -maxdepth 2 2>/dev/null | head -1)
fi
if [ ! -d "$TN_APP" ]; then
  error "Could not locate terminal-notifier.app bundle."
fi
APP_RESOURCES="$TN_APP/Contents/Resources"
info "App bundle: $TN_APP"

# --- Step 2: Create custom icon ---------------------------------------------
echo ""
echo "Step 2: Custom notification icon"
echo "---------------------------------"

if [ -f "$ICON_FILE" ]; then
  info "Icon already exists at $ICON_FILE — using it."
else
  # Generate a pixel-art robot icon (orange space invader style)
  # Users can replace ~/.claude/claude-icon.png with any 512x512+ PNG
  echo "No icon found at $ICON_FILE."
  echo "Please place a 512x512 (or larger) PNG at:"
  echo "  $ICON_FILE"
  echo ""
  echo "Then re-run this script to apply it."
  echo ""
  warn "Skipping icon replacement — notifications will use the default icon."
  SKIP_ICON=true
fi

if [ -z "$SKIP_ICON" ]; then
  echo "Converting PNG to ICNS..."
  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"

  for size in 16 32 64 128 256 512; do
    sips -z $size $size "$ICON_FILE" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null 2>&1
  done
  for size in 16 32 64 128 256; do
    double=$((size * 2))
    sips -z $double $double "$ICON_FILE" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null 2>&1
  done

  iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"
  info "ICNS created at $ICNS_FILE"

  # Backup original icon (once)
  if [ -f "$APP_RESOURCES/Terminal.icns" ] && [ ! -f "$APP_RESOURCES/Terminal.icns.bak" ]; then
    cp "$APP_RESOURCES/Terminal.icns" "$APP_RESOURCES/Terminal.icns.bak"
    info "Original icon backed up as Terminal.icns.bak"
  fi

  cp "$ICNS_FILE" "$APP_RESOURCES/Terminal.icns"
  info "Custom icon applied to terminal-notifier app bundle."

  # Clear icon cache
  echo "Clearing macOS icon cache (may require sudo)..."
  sudo rm -rf /Library/Caches/com.apple.iconservices.store 2>/dev/null || true
  sudo find /private/var/folders/ -name com.apple.iconservices -exec rm -rf {} \; 2>/dev/null || true
  sudo killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
  info "Icon cache cleared."
fi

# --- Step 3: Configure Claude Code hooks ------------------------------------
echo ""
echo "Step 3: Configure Claude Code hooks"
echo "-------------------------------------"

mkdir -p "$CLAUDE_DIR"

# Build the hooks JSON
HOOKS_JSON=$(cat <<'HOOKEOF'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "terminal-notifier -title \"Claude Code\" -message \"Task complete\" -appIcon ~/.claude/claude-icon.png -sound Glass",
            "timeout": 10
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "terminal-notifier -title \"Claude Code\" -message \"Pending question\" -appIcon ~/.claude/claude-icon.png -sound Purr",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
HOOKEOF
)

if [ -f "$SETTINGS_FILE" ]; then
  # Check if hooks already exist
  if grep -q '"hooks"' "$SETTINGS_FILE" 2>/dev/null; then
    warn "Hooks already configured in $SETTINGS_FILE — skipping."
    echo "    To reconfigure, remove the \"hooks\" key from settings.json and re-run."
  else
    # Merge hooks into existing settings using python (available on macOS)
    python3 -c "
import json, sys
with open('$SETTINGS_FILE') as f:
    settings = json.load(f)
hooks = json.loads('''$HOOKS_JSON''')
settings.update(hooks)
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
"
    info "Hooks added to existing $SETTINGS_FILE"
  fi
else
  echo "$HOOKS_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
  info "Created $SETTINGS_FILE with notification hooks."
fi

# --- Step 4: Test -----------------------------------------------------------
echo ""
echo "Step 4: Test notification"
echo "--------------------------"

terminal-notifier -title "Claude Code" -message "Notifications are working!" -appIcon "$ICON_FILE" -sound Glass
info "Test notification sent — check your Notification Centre."

# --- Done -------------------------------------------------------------------
echo ""
echo "========================================"
echo "Setup complete!"
echo "========================================"
echo ""
echo "Sounds:"
echo "  Task complete  — Glass"
echo "  Pending input  — Purr"
echo ""
echo "To customise sounds, change the -sound flag in ~/.claude/settings.json"
echo "To disable sounds: System Settings > Notifications > terminal-notifier"
echo ""
if [ -z "$SKIP_ICON" ]; then
  echo "IMPORTANT: Log out and back in (or restart) for the custom"
  echo "           icon to appear in notification banners."
  echo ""
fi
echo "After a 'brew upgrade terminal-notifier', re-run this script to"
echo "restore the custom icon."
