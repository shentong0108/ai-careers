#!/usr/bin/env bash
# send-outlook.sh — send a message via Microsoft Outlook on macOS using AppleScript.
#
# Why this helper exists: cron-side scripts originally opened a mailto:
# draft via `open` and waited for the user to click Send. Stone uses
# Outlook (not Apple Mail) and asked for these to auto-send so they
# actually reach his inbox without manual interaction. Outlook for Mac
# supports AppleScript for composing + sending; we use that path.
#
# Usage:
#   . scripts/lib/send-outlook.sh
#   send_outlook "to@example.com" "Subject line" "Body of the email"
#
# Returns 0 on send, non-zero on AppleScript failure. On failure the
# caller should fall back to writing a draft to disk or `open -b
# com.microsoft.Outlook mailto:...` so the message is not silently lost.

send_outlook() {
  local to="$1"
  local subject="$2"
  local body="$3"
  if [ -z "$to" ] || [ -z "$subject" ]; then
    echo "send_outlook: missing required to/subject" >&2
    return 2
  fi
  # AppleScript needs " escaped to \". Run the body through sed before
  # interpolation. Newlines stay newlines — Outlook accepts them.
  local s_subject s_body
  s_subject=$(printf '%s' "$subject" | /usr/bin/sed 's/"/\\"/g')
  s_body=$(printf '%s' "$body" | /usr/bin/sed 's/"/\\"/g')

  /usr/bin/osascript \
    -e 'on run argv' \
    -e '  set theTo to item 1 of argv' \
    -e '  set theSubject to item 2 of argv' \
    -e '  set theBody to item 3 of argv' \
    -e '  tell application "Microsoft Outlook"' \
    -e '    set newMsg to make new outgoing message with properties {subject:theSubject, content:theBody}' \
    -e '    tell newMsg' \
    -e '      make new recipient with properties {email address:{address:theTo}}' \
    -e '    end tell' \
    -e '    send newMsg' \
    -e '  end tell' \
    -e 'end run' \
    -- "$to" "$s_subject" "$s_body"
}
