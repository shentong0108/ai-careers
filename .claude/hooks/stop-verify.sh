#!/usr/bin/env bash
# Stop hook — runs when Claude finishes a turn.
# If the turn modified source files (not docs), remind to run build + tests.
# Non-blocking — emits reminder context only.

set -uo pipefail

if [[ ! -d .git ]]; then exit 0; fi

# Check if working tree has source changes uncommitted
CHANGED_SRC=$(git diff --name-only HEAD 2>/dev/null | grep -E '^(src/|scripts/|astro\.config\.|package\.json)' || true)

if [[ -n "$CHANGED_SRC" ]]; then
  cat <<EOF
VERIFY REMINDER — source files modified this turn:
$CHANGED_SRC

Before claiming done:
  npm run build   # exit 0
  npx astro check # 0 errors
  npm test        # if tests exist
EOF
fi

exit 0
