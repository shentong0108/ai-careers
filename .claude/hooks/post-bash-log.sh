#!/usr/bin/env bash
# PostToolUse hook for Bash.
# Captures build/test/lint output to .claude/logs/ for later inspection.
# Non-blocking — always exits 0.

set -uo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
OUTPUT=$(echo "$INPUT" | jq -r '.tool_response.output // empty' 2>/dev/null || echo "")
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // 0' 2>/dev/null || echo "0")

if [[ -z "$CMD" ]]; then exit 0; fi

# Only log meaningful commands
if echo "$CMD" | grep -qE '\b(npm run build|npm test|astro check|eslint|lighthouse|wrangler pages deploy)\b'; then
  mkdir -p .claude/logs
  TS=$(date +%Y%m%d-%H%M%S)
  SLUG=$(echo "$CMD" | tr -c 'a-zA-Z0-9' '-' | cut -c1-40)
  LOG=".claude/logs/${TS}-${SLUG}.log"
  {
    echo "# Command: $CMD"
    echo "# Exit: $EXIT_CODE"
    echo "# Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "---"
    echo "$OUTPUT"
  } > "$LOG"
fi

exit 0
