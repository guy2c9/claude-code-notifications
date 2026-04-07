# Claude Code macOS Notifications

Native macOS Notification Centre banners when Claude Code finishes a task or needs your input.

![Notification preview](docs/notification-preview.png)

## What you get

| Event | Banner message | Sound |
|-------|---------------|-------|
| Task complete | "Task complete" | Glass |
| Needs your input | "Pending question" | Purr |

## Requirements

- macOS
- [Homebrew](https://brew.sh)
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)

## Setup

### 1. Clone this repo

```bash
git clone https://github.com/guy2c9/claude-code-notifications.git
cd claude-code-notifications
```

### 2. Run the setup script

```bash
./scripts/setup-notifications.sh
```

The script will:

1. Install `terminal-notifier` via Homebrew
2. Copy the bundled Claude Code icon to `~/.claude/claude-icon.png` (if you don't already have one)
3. Convert your icon and apply it to the app bundle
4. Add notification hooks to `~/.claude/settings.json`
5. Send a test notification

You'll be prompted for your password once (to clear the macOS icon cache).

> **Important:** When the test notification fires, a notification permission alert will appear in the **top-right corner** of your screen. You **must click it and select "Allow"** to enable notifications. If you dismiss or deny it, notifications won't work — you can re-enable them later in **System Settings > Notifications > terminal-notifier**.

### 3. Clear the macOS icon cache

macOS aggressively caches app icons, so the custom icon **won't appear until you clear the cache**. Run these commands in order:

```bash
sudo rm -rf /Library/Caches/com.apple.iconservices.store
sudo find /private/var/folders/ -name com.apple.iconservices -exec rm -rf {} \; 2>/dev/null
sudo killall Dock
killall Finder
```

> The setup script attempts this automatically, but it doesn't always take effect until you complete step 4.

### 4. Log out and back in

**Apple menu > Log Out**, then log back in. This is required for macOS to pick up the new icon. You only have to do this once.

### 5. Verify the icon

```bash
terminal-notifier -title "Claude Code" -message "Icon test" -appIcon ~/.claude/claude-icon.png -sound Glass
```

You should see a notification banner with the Claude Code icon. If it still shows the default terminal icon, **restart your Mac** and test again.

That's it! You'll now get notification banners whenever Claude Code completes a task or needs your input.

## Customisation

### Use a different icon

Replace `~/.claude/claude-icon.png` with any 512x512+ PNG, then re-run the setup script.

### Change notification sounds

Edit `~/.claude/settings.json` and change the `-sound` value in each hook. macOS built-in sounds include:

`Basso` `Blow` `Bottle` `Frog` `Funk` `Glass` `Hero` `Morse` `Ping` `Pop` `Purr` `Sosumi` `Submarine` `Tink`

### Disable sounds entirely

**System Settings > Notifications > terminal-notifier** — toggle off "Play sound for notifications".

## After Homebrew upgrades

If you run `brew upgrade terminal-notifier`, the icon resets to the default. Re-run the setup script:

```bash
./scripts/setup-notifications.sh
```

## Manual setup

If you'd rather not run the script, see the [detailed setup guide](docs/setup-guide.md) for step-by-step manual instructions.

## Troubleshooting

### Custom icon not showing

macOS aggressively caches app icons. If the notification still shows the default icon after running the setup script:

1. **Clear the icon cache manually:**

   ```bash
   sudo rm -rf /Library/Caches/com.apple.iconservices.store
   sudo find /private/var/folders/ -name com.apple.iconservices -exec rm -rf {} \; 2>/dev/null
   sudo killall Dock
   killall Finder
   ```

2. **Log out and back in** (or restart your Mac).

3. **Send a test notification** to confirm:

   ```bash
   terminal-notifier -title "Claude Code" -message "Icon test" -appIcon ~/.claude/claude-icon.png -sound Glass
   ```

If the icon still doesn't appear after a restart, re-run the full setup script — this re-applies the icon to the app bundle and clears the cache again.

### Other issues

| Problem | Solution |
|---------|----------|
| No notifications appear | Check **System Settings > Notifications > terminal-notifier** is enabled |
| Icon reset after upgrade | Re-run `./scripts/setup-notifications.sh` |
| Notifications too noisy | Disable sounds in System Settings (see above) |

## How it works

Claude Code supports [hooks](https://docs.anthropic.com/en/docs/claude-code) — shell commands that run in response to events. This project configures two hooks in `~/.claude/settings.json`:

- **Stop** — fires when Claude Code finishes a task
- **Notification** — fires when Claude Code needs your input

Each hook calls `terminal-notifier` to send a native macOS notification banner with a custom icon and sound.

## Licence

MIT
