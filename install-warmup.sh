#!/bin/bash
#
# One-time installer for the Claude Code usage-window warmup automation.
#   1. schedules a daily RTC wake a couple of minutes before the run
#   2. renders the LaunchAgent from the template with absolute paths
#   3. loads and enables the LaunchAgent
#
# Run once:  bash install-warmup.sh
set -euo pipefail

# ---- Configuration (edit to taste) -----------------------------------------
WAKE_TIME="10:28:00"   # pmset wake, a couple of minutes before the run
RUN_HOUR=10            # LaunchAgent run time — hour (0-23)
RUN_MINUTE=30          # LaunchAgent run time — minute (0-59)
LABEL="com.claude-usage-warmup"
# ----------------------------------------------------------------------------

DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/claude-warmup.sh"
TEMPLATE="$DIR/$LABEL.plist.template"
LOG="$HOME/.claude/warmup.launchd.log"
PLIST_DST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_NUM="$(id -u)"

chmod +x "$SCRIPT"
mkdir -p "$HOME/.claude" "$HOME/Library/LaunchAgents"

# 1) Wake (or power on) every day, so the Mac is awake before the run.
#    Requires sudo. wakeorpoweron works even with the lid closed on AC power.
#
#    macOS keeps only ONE repeating pmset schedule for the whole system, so
#    setting ours overwrites any existing one. Detect a schedule that isn't
#    ours and ask before clobbering it.
existing_repeat="$(pmset -g sched | awk '/Repeating power events/{f=1;next} /Scheduled power events/{f=0} f')"

# Expected pmset display form of WAKE_TIME, e.g. "10:28:00" -> "10:28AM".
h=$((10#${WAKE_TIME%%:*}))
m="${WAKE_TIME#*:}"; m="${m%%:*}"
if   [ "$h" -eq 0 ];  then wake_disp="12:${m}AM"
elif [ "$h" -lt 12 ]; then wake_disp="${h}:${m}AM"
elif [ "$h" -eq 12 ]; then wake_disp="12:${m}PM"
else                       wake_disp="$((h - 12)):${m}PM"; fi

if [ -n "$existing_repeat" ] && ! echo "$existing_repeat" | grep -q "$wake_disp"; then
    echo "WARNING: a different repeating power schedule already exists:"
    echo "$existing_repeat" | sed 's/^/    /'
    echo
    echo "macOS allows only one repeating schedule, so installing REPLACES it."
    printf "Overwrite it? [y/N] "
    read -r reply
    case "$reply" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborted. Existing schedule left untouched."; exit 1 ;;
    esac
fi

echo "Scheduling daily wake at $WAKE_TIME (needs sudo)..."
sudo pmset repeat wakeorpoweron MTWRFSU "$WAKE_TIME"

# 2) Render the LaunchAgent from the template with absolute paths.
sed -e "s|__SCRIPT_PATH__|$SCRIPT|g" \
    -e "s|__LOG_PATH__|$LOG|g" \
    -e "s|__RUN_HOUR__|$RUN_HOUR|g" \
    -e "s|__RUN_MINUTE__|$RUN_MINUTE|g" \
    "$TEMPLATE" > "$PLIST_DST"

# 3) (Re)load and enable the LaunchAgent.
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST_DST"
launchctl enable "gui/$UID_NUM/$LABEL"

echo
echo "Installed. Current schedule:"
pmset -g sched
echo
echo "Test the script now with:  bash $SCRIPT && tail $HOME/.claude/warmup.log"
