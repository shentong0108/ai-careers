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
# Notifications:
#   - macOS notification on success + failure
#   - On failure: opens a mailto: draft in your default mail client
#
# Manual test:
#   /Volumes/Studio\ work/blog-site/scripts/local-cron.sh

set -uo pipefail

PROJECT_ROOT="/Volumes/Studio work/blog-site"
NOTIFY_EMAIL="shentong940108@hotmail.com"
cd "$PROJECT_ROOT"

LOG_DIR=".claude/logs"
CACHE_DIR=".claude/cache"
mkdir -p "$LOG_DIR" "$CACHE_DIR"

TS=$(date +%Y%m%d-%H%M%S)
LOG="$LOG_DIR/cron-$TS.log"
LAST_RUN_FILE="$CACHE_DIR/local-cron-last-run"

# ---- Notification helpers ----------------------------------------------------

notify_success() {
  local body="$1"
  /usr/bin/osascript -e "display notification \"${body//\"/\\\"}\" with title \"ai-careers cron ✓\" sound name \"Glass\"" >/dev/null 2>&1 || true
}

notify_failure() {
  local title="$1"
  local body="$2"
  local log_path="$3"
  /usr/bin/osascript -e "display notification \"${body//\"/\\\"}\" with title \"ai-careers cron ✗ ${title//\"/\\\"}\" sound name \"Basso\"" >/dev/null 2>&1 || true
  # Open a mailto: draft so it appears in the user's default mail client.
  local subject="ai-careers cron failed: ${title}"
  local mail_body="Pipeline failed at $(date -u +%Y-%m-%dT%H:%M:%SZ)
Reason: ${body}

Log: ${log_path}
Tail:

$(/usr/bin/tail -40 "${log_path}" 2>/dev/null || echo "(log not available)")"
  # URL-encode subject + body via python (always available on macOS).
  local enc_subject enc_body
  enc_subject=$(/usr/bin/python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$subject")
  enc_body=$(/usr/bin/python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$mail_body")
  /usr/bin/open "mailto:${NOTIFY_EMAIL}?subject=${enc_subject}&body=${enc_body}" >/dev/null 2>&1 || true
}

# ---- Throttle ---------------------------------------------------------------

if [[ -f "$LAST_RUN_FILE" ]]; then
  LAST=$(cat "$LAST_RUN_FILE")
  NOW=$(date +%s)
  ELAPSED=$(( NOW - LAST ))
  if (( ELAPSED < 165600 )); then
    echo "$(date) — skip, last run ${ELAPSED}s ago (need >=165600s)" | tee -a "$LOG"
    exit 0
  fi
fi

# ---- Keep awake during run ---------------------------------------------------

/usr/bin/caffeinate -i -t 1800 &
CAFF_PID=$!
trap "kill $CAFF_PID 2>/dev/null || true" EXIT

# ---- Resolve claude binary ---------------------------------------------------

CLAUDE_BIN=""
for p in /opt/homebrew/bin/claude /usr/local/bin/claude "$HOME/.local/bin/claude"; do
  if [[ -x "$p" ]]; then CLAUDE_BIN="$p"; break; fi
done
if [[ -z "$CLAUDE_BIN" ]]; then
  CLAUDE_BIN="$(command -v claude || true)"
fi
if [[ -z "$CLAUDE_BIN" ]]; then
  MSG="claude CLI not found in PATH or known locations"
  echo "$(date) — FATAL: $MSG" | tee -a "$LOG"
  notify_failure "claude not found" "$MSG" "$LOG"
  exit 127
fi

# ---- Run pipeline ------------------------------------------------------------

{
  echo "=== Local cron run started $(date) ==="
  echo "claude: $CLAUDE_BIN"
  echo "cwd: $(pwd)"
  echo "branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no git')"

  # Sync main so we don't fork from stale state
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git fetch origin main --quiet || echo "(fetch failed, continuing)"
    git checkout main --quiet 2>/dev/null || true
    git pull --ff-only origin main --quiet 2>/dev/null || echo "(pull failed, continuing)"
  fi
} >> "$LOG" 2>&1

# Run the slash command; capture exit + tail
"$CLAUDE_BIN" -p "/generate-article" --dangerously-skip-permissions >> "$LOG" 2>&1
RC=$?

# ---- Decide outcome ---------------------------------------------------------

if [[ $RC -eq 0 ]]; then
  echo "=== Completed $(date) (rc=0) ===" >> "$LOG"
  date +%s > "$LAST_RUN_FILE"
  TAIL=$(/usr/bin/tail -3 "$LOG" | /usr/bin/head -c 200)
  notify_success "Pipeline finished. Check open PRs on GitHub."
  exit 0
else
  echo "=== FAILED $(date) (rc=$RC) ===" >> "$LOG"
  # Diagnose reason from log tail
  REASON=$(/usr/bin/tail -20 "$LOG" | /usr/bin/grep -iE "error|fatal|blocked|failed|abort" | /usr/bin/tail -1 | /usr/bin/head -c 180)
  if [[ -z "$REASON" ]]; then REASON="see log tail"; fi
  notify_failure "rc=$RC" "$REASON" "$(/usr/bin/realpath "$LOG")"
  exit "$RC"
fi
