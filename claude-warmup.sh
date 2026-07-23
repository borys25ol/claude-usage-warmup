#!/bin/bash
#
# Fires a cheap Haiku request to start the 5-hour usage window.
# Invoked by the com.claude-usage-warmup LaunchAgent shortly after
# pmset wakes the machine from sleep.

# LaunchAgents get a minimal PATH; add the locations claude may live in.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

LOG="$HOME/.claude/warmup.log"
mkdir -p "$HOME/.claude"

echo "$(date '+%Y-%m-%d %H:%M:%S') --- warmup start" >> "$LOG"

claude -p "Reply with the single word: ok" \
  --model claude-haiku-4-5-20251001 \
  >> "$LOG" 2>&1
status=$?

echo "$(date '+%Y-%m-%d %H:%M:%S') --- warmup done (exit $status)" >> "$LOG"
exit "$status"
