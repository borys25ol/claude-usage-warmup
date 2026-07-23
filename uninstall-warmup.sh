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
#    macOS keeps a single repeating slot and `pmset repeat cancel` clears ALL
#    of it, so show what will be removed and confirm before wiping it — the
#    schedule might belong to another tool, not this one.
existing_repeat="$(pmset -g sched | awk '/Repeating power events/{f=1;next} /Scheduled power events/{f=0} f')"
if [ -z "$existing_repeat" ]; then
    echo "No repeating wake schedule found — nothing to cancel."
else
    echo "The current repeating power schedule is:"
    echo "$existing_repeat" | sed 's/^/    /'
    echo
    echo "'pmset repeat cancel' removes ALL of the above, not just this tool's wake."
    printf "Cancel it? [y/N] "
    read -r reply
    case "$reply" in
        [yY]|[yY][eE][sS])
            echo "Cancelling the daily wake (needs sudo)..."
            sudo pmset repeat cancel ;;
        *) echo "Left the wake schedule untouched." ;;
    esac
fi

echo
echo "Done. Current schedule:"
pmset -g sched
