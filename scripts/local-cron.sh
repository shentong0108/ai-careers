#!/usr/bin/env bash
# Local cron driver — runs the article pipeline using your Claude Code
# subscription quota (not API credits). Triggered by launchd plist at
# ~/Library/LaunchAgents/dev.stonemegan.aicareers.plist.
#
# Behavior:
#   1. Throttle: skips if last successful run was < 46h ago.
#   2. Holds the Mac awake for up to 30 min via `caffeinate`.
#   3. Executes `/generate-article` slash command via headless claude.
#   4. Pipeline (keyword → write → humanize → fact-check → SEO → verify)
#      dispatches sub-agents from .claude/agents/ natively.
#   5. On success, commits + pushes; CF Pages auto-deploys merged main.
#
# Manual test:
#   /Volumes/Studio\ work/blog-site/scripts/local-cron.sh

set -euo pipefail

PROJECT_ROOT="/Volumes/Studio work/blog-site"
cd "$PROJECT_ROOT"

LOG_DIR=".claude/logs"
CACHE_DIR=".claude/cache"
mkdir -p "$LOG_DIR" "$CACHE_DIR"

TS=$(date +%Y%m%d-%H%M%S)
LOG="$LOG_DIR/cron-$TS.log"
LAST_RUN_FILE="$CACHE_DIR/local-cron-last-run"

# Throttle — skip if last successful run < 46h ago (slack for ~2-day cadence)
if [[ -f "$LAST_RUN_FILE" ]]; then
  LAST=$(cat "$LAST_RUN_FILE")
  NOW=$(date +%s)
  ELAPSED=$(( NOW - LAST ))
  if (( ELAPSED < 165600 )); then
    echo "$(date) — skip, last run ${ELAPSED}s ago (need >=165600s)" | tee -a "$LOG"
    exit 0
  fi
fi

# Keep Mac awake for up to 30 min during run
caffeinate -i -t 1800 &
CAFF_PID=$!
trap "kill $CAFF_PID 2>/dev/null || true" EXIT

# Resolve claude binary (launchd PATH is minimal)
CLAUDE_BIN="$(command -v claude || true)"
if [[ -z "$CLAUDE_BIN" ]]; then
  for p in /opt/homebrew/bin/claude /usr/local/bin/claude "$HOME/.local/bin/claude"; do
    if [[ -x "$p" ]]; then CLAUDE_BIN="$p"; break; fi
  done
fi
if [[ -z "$CLAUDE_BIN" ]]; then
  echo "$(date) — FATAL: claude CLI not found in PATH or common locations" | tee -a "$LOG"
  exit 127
fi

{
  echo "=== Local cron run started $(date) ==="
  echo "claude: $CLAUDE_BIN"
  echo "cwd: $(pwd)"
  echo "branch: $(git rev-parse --abbrev-ref HEAD)"

  # Pull latest main so we don't fork from stale state
  git fetch origin main --quiet
  git checkout main --quiet
  git pull --ff-only origin main --quiet

  # Dispatch pipeline via slash command. Uses subscription, not API.
  "$CLAUDE_BIN" -p "/generate-article" --dangerously-skip-permissions

  echo "=== Completed $(date) ==="
} >> "$LOG" 2>&1

# Mark success
date +%s > "$LAST_RUN_FILE"
