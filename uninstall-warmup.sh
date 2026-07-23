#!/bin/bash
#
# Removes the Claude Code usage-window warmup automation:
#   1. unloads the LaunchAgent and deletes its plist
#   2. cancels the daily pmset wake
#
# Run:  bash uninstall-warmup.sh
set -euo pipefail

LABEL="com.claude-usage-warmup"
PLIST_DST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_NUM="$(id -u)"

# 1) Unload and remove the LaunchAgent.
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
rm -f "$PLIST_DST"
echo "LaunchAgent removed."

# 2) Cancel the repeating wake (needs sudo).
echo "Cancelling the daily wake (needs sudo)..."
sudo pmset repeat cancel

echo
echo "Done. Current schedule:"
pmset -g sched
