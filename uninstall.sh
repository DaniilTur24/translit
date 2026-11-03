#!/bin/bash
# Stops Translit and removes everything install.sh created.
set -euo pipefail

LABEL="local.translit"
DOMAIN="gui/$(id -u)"

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Applications/Translit.app"
rm -f "$HOME/Library/Logs/Translit.log"
# Drops the Accessibility entry for this app only.
tccutil reset Accessibility "$LABEL" >/dev/null 2>&1 || true

echo "Translit removed. The project folder is untouched; delete it yourself if you no longer need it."
