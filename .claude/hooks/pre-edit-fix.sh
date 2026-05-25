#!/usr/bin/env bash
# PreToolUse hook for Edit/Write/MultiEdit.
# On bug-fix branches (fix/* or hotfix/*), block edits unless ROOT_CAUSE.md exists
# or the most recent commit message contains "root-cause:" line.
# Exits 0 to allow, exits 2 to block with reason on stderr.

set -euo pipefail

# Read hook input JSON from stdin
INPUT=$(cat)

# Extract file path being edited (Claude Code passes tool args in JSON)
TARGET=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")

# Only enforce inside the project root
if [[ ! -d .git ]]; then exit 0; fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# Only enforce on fix/hotfix branches
if [[ ! "$BRANCH" =~ ^(fix|hotfix)/ ]]; then exit 0; fi

# Skip if editing the analysis doc itself
if [[ "$TARGET" =~ docs/debug/ ]] || [[ "$TARGET" =~ \.test\.(ts|js)$ ]] || [[ "$TARGET" =~ \.spec\.(ts|js)$ ]]; then
  exit 0
fi

# Check for ROOT_CAUSE.md in branch root OR docs/debug/ with today's date
TODAY=$(date +%Y-%m-%d)
if [[ -f ROOT_CAUSE.md ]] || ls docs/debug/${TODAY}-*.md >/dev/null 2>&1; then
  exit 0
fi

# Check most recent commit for root-cause: line
if git log -1 --pretty=%B 2>/dev/null | grep -qiE '^root-cause:'; then
  exit 0
fi

cat >&2 <<EOF
BLOCKED — bug-fix branch '$BRANCH' requires root cause analysis before editing source.

Required (one of):
  1. docs/debug/${TODAY}-<slug>.md  (run debug-investigator agent first)
  2. ROOT_CAUSE.md in repo root
  3. Most recent commit message starts with 'root-cause: <one sentence>'

Editing test files (*.test.ts, *.spec.ts) is allowed without this.
Editing docs/debug/* is allowed.
EOF
exit 2
