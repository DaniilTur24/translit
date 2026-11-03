#!/bin/bash
# Builds Translit.app, installs it to ~/Applications and registers a LaunchAgent (autostart at login).
# Everything is per-user: no sudo, nothing outside your home folder.
set -euo pipefail
cd "$(dirname "$0")"

LABEL="local.translit"
APP="$HOME/Applications/Translit.app"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

echo "Building..."
rm -rf build
mkdir -p build/Translit.app/Contents/MacOS
swiftc -O -swift-version 5 -o build/Translit.app/Contents/MacOS/Translit Sources/*.swift
cp Info.plist build/Translit.app/Contents/Info.plist
codesign --force --sign - --identifier "$LABEL" build/Translit.app

echo "Installing..."
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
mkdir -p "$HOME/Applications" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
rm -rf "$APP"
cp -R build/Translit.app "$APP"

cat > "$AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP/Contents/MacOS/Translit</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/Translit.log</string>
</dict>
</plist>
EOF

launchctl bootstrap "$DOMAIN" "$AGENT"

cat <<MSG

Installed and running. Hotkey: Control + Option + R.

One manual step: System Settings > Privacy & Security > Accessibility > enable "Translit"
(a system prompt about this appears on first start; if not, add $APP with the + button).
MSG
