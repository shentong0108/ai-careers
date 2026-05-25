#!/usr/bin/env bash
# PreToolUse hook for Bash.
# Blocks destructive commands not already in deny list (defense-in-depth).
# Also blocks publish commands unless deploy-verifier receipt exists.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

if [[ -z "$CMD" ]]; then exit 0; fi

# Defense-in-depth deny patterns (settings.json deny is primary)
DENY_PATTERNS=(
  '\brm -rf /\b'
  '\bgit push --force\b'
  '\bgit push -f\b'
  '\bgit reset --hard\b'
  '\bgit clean -fd\b'
  '\bdrop database\b'
)

for pat in "${DENY_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE "$pat"; then
    echo "BLOCKED — matched deny pattern: $pat" >&2
    exit 2
  fi
done

# Publish gate — require recent deploy-verifier receipt
if echo "$CMD" | grep -qE '\b(wrangler pages deploy|vercel --prod|npm publish)\b'; then
  RECEIPT=".claude/cache/deploy-verifier-latest.txt"
  if [[ ! -f "$RECEIPT" ]]; then
    echo "BLOCKED — no deploy-verifier receipt. Run deploy-verifier agent first." >&2
    exit 2
  fi
  AGE=$(( $(date +%s) - $(stat -f %m "$RECEIPT" 2>/dev/null || stat -c %Y "$RECEIPT") ))
  if (( AGE > 1800 )); then
    echo "BLOCKED — deploy-verifier receipt stale (${AGE}s old, max 1800s)." >&2
    exit 2
  fi
  if ! grep -q "Overall: READY TO DEPLOY" "$RECEIPT"; then
    echo "BLOCKED — deploy-verifier did not return READY." >&2
    exit 2
  fi
fi

exit 0
