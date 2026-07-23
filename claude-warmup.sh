#!/bin/bash
#
# Fires a cheap Haiku request to start the 5-hour usage window.
# Invoked by the com.claude-usage-warmup LaunchAgent shortly after
# pmset wakes the machine from sleep.

# Model for the warmup ping. Haiku is the cheapest choice. To change the
# installed default, edit this line — the LaunchAgent runs the script as-is.
# The env var lets manual runs (e.g. `make test`) override it.
MODEL="${CLAUDE_WARMUP_MODEL:-claude-haiku-4-5-20251001}"

# LaunchAgents get a minimal PATH; add the locations claude may live in.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

LOG="$HOME/.claude/warmup.log"
mkdir -p "$HOME/.claude"

echo "$(date '+%Y-%m-%d %H:%M:%S') --- warmup start (model: $MODEL)" >> "$LOG"

claude -p "Reply with the single word: ok" \
  --model "$MODEL" \
  >> "$LOG" 2>&1
status=$?

echo "$(date '+%Y-%m-%d %H:%M:%S') --- warmup done (exit $status)" >> "$LOG"
exit "$status"
