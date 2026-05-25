#!/usr/bin/env bash
# UserPromptSubmit hook — injects project rules into every prompt.
# Output goes to stdout, captured as additional context for the model.

set -euo pipefail

cat <<'EOF'
PROJECT RULES (ai-careers — stonemegan.dev):
1. Root cause before fix — no symptom patches. Use debug-investigator agent.
2. Verify before claim — run npm run build + npm test, paste output.
3. Worktree per feature — never hack main.
4. Sub-agent .md required — check .claude/agents/<name>.md exists before dispatch.
5. YMYL gate — nurse-ai + ece-ai need fact-checker pass before publish.
6. No AI smell — humanizer pass required, AI-detection < 30%.
EOF
