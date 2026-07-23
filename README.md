# Claude Code Usage-Window Warmup

Automation that wakes a sleeping Mac every morning and fires one cheap Haiku
request to start Claude Code's 5-hour usage window early — so the window is
already "warm" by the time you actually start working.

## Why

Claude Code's rate limits run on a rolling 5-hour window that starts on the
**first** request. Kicking it off automatically (with a minimal Haiku call)
means the window opens without manual effort. The MacBook can stay asleep with
the lid closed — `pmset` wakes it just for this.

## How it works

Two pieces cooperate, because a scheduler alone cannot wake a sleeping Mac:

1. **`pmset`** — schedules a daily RTC wake a couple of minutes before the run.
   `wakeorpoweron` works even with the lid closed, **as long as the Mac is on
   AC power**.
2. **LaunchAgent** (`com.claude-usage-warmup`) — fires the warmup script at the
   configured time, a short buffer after wake.

The script runs `claude -p` in headless mode on the Haiku model and appends the
result to `~/.claude/warmup.log`. Defaults: wake at **10:28**, run at **10:30**.

```
10:28  pmset RTC wake  ──►  10:30  LaunchAgent  ──►  claude -p (Haiku)  ──►  ~/.claude/warmup.log
```

## Files

| File | Purpose |
|------|---------|
| `claude-warmup.sh` | Runs the headless Haiku request; logs to `~/.claude/warmup.log` |
| `com.claude-usage-warmup.plist.template` | LaunchAgent template; the installer fills in absolute paths |
| `install-warmup.sh` | One-time installer: schedules the wake and loads the agent |
| `uninstall-warmup.sh` | Removes the agent and cancels the wake |
| `Makefile` | Convenience targets wrapping the scripts (`make help`) |

> `launchd` does not expand `$HOME` or `~`, so the plist ships as a template
> with `__PLACEHOLDER__` tokens. The installer renders it with absolute paths
> for the current user into `~/Library/LaunchAgents/`.

## Install

```bash
bash install-warmup.sh   # prompts for sudo (needed by pmset)
```

This schedules the daily wake and loads the LaunchAgent. That's it.

Or use the `Makefile` for a tidier command surface:

```bash
make help       # list all targets
make install    # same as bash install-warmup.sh (RUN_TIME=HH:MM to override)
make uninstall  # remove the agent and cancel the wake
make test       # run the warmup once and show the log
make status     # show the pmset schedule and LaunchAgent state
make logs       # tail the warmup log
```

### Custom time

The run time lives in a single place — `RUN_TIME` (24-hour `HH:MM`) in the
config block at the top of `install-warmup.sh`. The wake is derived from it
automatically as `WAKE_LEAD_MIN` minutes earlier (2 by default), so the two can
never drift out of sync. Edit those values and re-run the installer, or
override them via environment variables without touching the file:

```bash
RUN_TIME=09:00 bash install-warmup.sh                    # run at 09:00, wake 08:58
RUN_TIME=07:15 WAKE_LEAD_MIN=5 bash install-warmup.sh    # run at 07:15, wake 07:10
```

Re-running the installer just overwrites the previous schedule — no need to
uninstall first.

### Model

The warmup uses the cheapest model (Haiku) by default. It lives in one place —
`MODEL` at the top of `claude-warmup.sh`. Edit that line to change the installed
default (the LaunchAgent runs the script as-is). For a manual run you can also
override it via an environment variable:

```bash
CLAUDE_WARMUP_MODEL=claude-sonnet-5 bash claude-warmup.sh
```

## Uninstall

```bash
bash uninstall-warmup.sh   # prompts for sudo to cancel the wake
```

## Requirements & caveats

- **AC power.** With the lid closed on battery, macOS often ignores scheduled
  wakes, so the automation may not run. Keep the Mac plugged in overnight.
- **Keychain / lock screen.** If Claude Code stores its token in the Keychain
  and the Mac wakes with the screen locked, the request could fail on auth.
  Verified working in practice, but re-test if you change the auth setup.
- **Dark wake.** The wake is silent (display stays off); the CPU still runs and
  the LaunchAgent fires normally. The Mac returns to sleep on its own once the
  script finishes — no need to sleep it explicitly.
- Requires the [Claude Code CLI](https://claude.com/claude-code) (`claude`) on
  `PATH`, already authenticated.

## Coexistence with other pmset schedules

macOS keeps only **one** repeating `pmset` schedule for the whole system (a
single slot), while `launchd` agents are independent. So:

- **The LaunchAgent is fully isolated** — its unique `Label` never collides
  with other agents.
- **The repeating wake is a shared, single slot.** Setting one replaces any
  existing repeating schedule, and `pmset repeat cancel` clears *all* of it.

To stay a good citizen, the scripts guard this slot:

- `install-warmup.sh` detects an existing repeating schedule that isn't ours
  and asks before overwriting it.
- `uninstall-warmup.sh` shows the current repeating schedule and asks before
  cancelling, since cancel is all-or-nothing.

If you need wakes at **several different times**, note that one repeating slot
cannot express that — you would use one-time `pmset schedule` entries (which do
stack) and re-arm them, at the cost of the "set and forget" reliability the
repeating slot gives.

## Verify / test

Run the script by hand:

```bash
bash claude-warmup.sh && tail ~/.claude/warmup.log
```

Full lid-closed test — schedule a wake a few minutes out, close the lid, then
check the log after reopening (adjust the timestamp):

```bash
sudo pmset schedule wakeorpoweron "MM/DD/YYYY HH:MM:00"
tail ~/.claude/warmup.log
```

## Management

```bash
# Check what's scheduled
pmset -g sched

# Inspect the LaunchAgent
launchctl print "gui/$(id -u)/com.claude-usage-warmup"

# Read the log
tail ~/.claude/warmup.log
```

## License

[MIT](LICENSE) © Borys Oliinyk
