#!/usr/bin/env bash
# Installs the local cron LaunchAgent for ai-careers.
# Idempotent — safe to re-run.
#
# What it does:
#   1. Renders LaunchAgent plist with absolute paths to this checkout.
#   2. Installs to ~/Library/LaunchAgents/dev.stonemegan.aicareers.plist
#   3. Loads it into launchd (will run at next 9am local time).
#
# Uninstall:
#   launchctl unload ~/Library/LaunchAgents/dev.stonemegan.aicareers.plist
#   rm ~/Library/LaunchAgents/dev.stonemegan.aicareers.plist

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_LABEL="dev.stonemegan.aicareers"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"
SCRIPT_PATH="${PROJECT_ROOT}/scripts/local-cron.sh"

WEEKLY_LABEL="dev.stonemegan.aicareers-weekly"
WEEKLY_PLIST_PATH="$HOME/Library/LaunchAgents/${WEEKLY_LABEL}.plist"
WEEKLY_SCRIPT_PATH="${PROJECT_ROOT}/scripts/weekly-anecdote-check.sh"

# launchd cannot open StandardOutPath/StandardErrorPath on external
# volumes (/Volumes/...) — macOS TCC restricts launchd's file access
# in a way the user shell does not see. Symptom: exit code 78
# (EX_CONFIG) before the script even runs. Workaround: route
# launchd's own stdout/stderr to ~/Library/Logs/, which is always
# accessible to launchd in the user's GUI domain. The script
# continues to write its own detailed log to .claude/logs/ inside
# the project (which works fine because the script itself runs with
# the user's full TCC permissions).
LAUNCHD_LOG_DIR="$HOME/Library/Logs/stonemegan"
mkdir -p "$LAUNCHD_LOG_DIR"
mkdir -p "$HOME/Library/LaunchAgents"

chmod +x "$SCRIPT_PATH" "$WEEKLY_SCRIPT_PATH"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${PLIST_LABEL}</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${SCRIPT_PATH}</string>
  </array>

  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>7</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>

  <key>WorkingDirectory</key>
  <string>${PROJECT_ROOT}</string>

  <key>StandardOutPath</key>
  <string>${LAUNCHD_LOG_DIR}/launchd-stdout.log</string>

  <key>StandardErrorPath</key>
  <string>${LAUNCHD_LOG_DIR}/launchd-stderr.log</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    <key>HOME</key>
    <string>${HOME}</string>
  </dict>

  <key>RunAtLoad</key>
  <false/>

  <key>ProcessType</key>
  <string>Background</string>
</dict>
</plist>
EOF

echo "wrote $PLIST_PATH"

# Weekly anecdote check — Friday 18:00 local
cat > "$WEEKLY_PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${WEEKLY_LABEL}</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${WEEKLY_SCRIPT_PATH}</string>
  </array>

  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key>
    <integer>5</integer>
    <key>Hour</key>
    <integer>18</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>

  <key>WorkingDirectory</key>
  <string>${PROJECT_ROOT}</string>

  <key>StandardOutPath</key>
  <string>${LAUNCHD_LOG_DIR}/weekly-stdout.log</string>

  <key>StandardErrorPath</key>
  <string>${LAUNCHD_LOG_DIR}/weekly-stderr.log</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    <key>HOME</key>
    <string>${HOME}</string>
  </dict>

  <key>RunAtLoad</key>
  <false/>

  <key>ProcessType</key>
  <string>Background</string>
</dict>
</plist>
EOF
echo "wrote $WEEKLY_PLIST_PATH"

# Unload if already loaded (idempotent reinstall)
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl unload "$WEEKLY_PLIST_PATH" 2>/dev/null || true

launchctl load "$PLIST_PATH"
echo "loaded $PLIST_LABEL"
launchctl load "$WEEKLY_PLIST_PATH"
echo "loaded $WEEKLY_LABEL"

echo ""
echo "Daily article cron: 07:00 local time."
echo "Weekly anecdote check: Friday 18:00 local time."
echo ""
echo "Manual test (runs now, ignores throttle):"
echo "  rm -f ${PROJECT_ROOT}/.claude/cache/local-cron-last-run"
echo "  launchctl start ${PLIST_LABEL}"
echo ""
echo "Watch logs:"
echo "  tail -f ${PROJECT_ROOT}/.claude/logs/cron-*.log"
echo ""
echo "Unload (stop the cron):"
echo "  launchctl unload ${PLIST_PATH}"
