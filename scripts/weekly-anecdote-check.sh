#!/usr/bin/env bash
# Weekly anecdote-queue health check + brainstorm + email reminder.
# Runs every Friday at 18:00 local time via launchd.
#
# Behavior:
#   1. Read content-queue.json, count entries by (niche, status, has-anecdote).
#   2. Dispatch a brainstorm prompt to claude -p to generate 3-5 NEW topic
#      ideas + sketch anecdotes based on the published articles' patterns.
#      Output goes to docs/brainstorm/<YYYY-MM-DD>.md.
#   3. Open a mailto: draft in the default mail client with the queue
#      summary, the brainstorm doc location, and a request to fill 3-5
#      anecdotes over the weekend.
#
# The brainstorm only produces topic ideas + suggested anecdote PROMPTS
# (questions that, if Stone or Megan recall a real moment, fit the topic).
# It does NOT invent first-person clinical scenarios — that would violate
# the project's evidence-based rule.

set -uo pipefail

PROJECT_ROOT="/Volumes/Studio work/blog-site"
NOTIFY_EMAIL="shentong940108@hotmail.com"
cd "$PROJECT_ROOT"

LOG_DIR=".claude/logs"
BRAINSTORM_DIR="docs/brainstorm"
mkdir -p "$LOG_DIR" "$BRAINSTORM_DIR"

TS=$(date +%Y%m%d-%H%M%S)
DATE=$(date +%Y-%m-%d)
LOG="$LOG_DIR/weekly-${TS}.log"
BRAINSTORM_FILE="${BRAINSTORM_DIR}/${DATE}.md"

# Resolve claude binary
CLAUDE_BIN=""
for p in /opt/homebrew/bin/claude /usr/local/bin/claude "$HOME/.local/bin/claude"; do
  if [[ -x "$p" ]]; then CLAUDE_BIN="$p"; break; fi
done
if [[ -z "$CLAUDE_BIN" ]]; then
  echo "claude not found" | tee -a "$LOG"
  exit 127
fi

# Queue health summary (one-line per niche)
SUMMARY=$(/usr/bin/python3 <<'PYEOF'
import json
d = json.load(open("content-queue.json"))
buckets = {}
for e in d:
    key = (e["niche"], e["status"], bool(e.get("anecdote")))
    buckets[key] = buckets.get(key, 0) + 1
out = []
for niche in ("nurse-ai", "ece-ai", "dev-diary"):
    pub = sum(v for (n, s, _), v in buckets.items() if n == niche and s == "published")
    pend_yes = sum(v for (n, s, a), v in buckets.items() if n == niche and s == "pending" and a)
    pend_no  = sum(v for (n, s, a), v in buckets.items() if n == niche and s == "pending" and not a)
    out.append(f"{niche}: {pub} published; pending {pend_yes} with anecdote, {pend_no} without")
print("\n".join(out))
PYEOF
)

# Run brainstorm. The prompt is intentionally narrow — propose TOPIC ideas
# and ANECDOTE PROMPTS (open questions) but do NOT invent first-person
# scenarios. Stone or Megan must supply real recollections.
{
  echo "=== Weekly anecdote check started $(date) ==="
  echo "queue summary:"
  echo "$SUMMARY"
  echo
  echo "--- brainstorm dispatch ---"
} >> "$LOG"

BRAINSTORM_PROMPT="Read the published articles under src/content/posts/ and the current content-queue.json. Propose 5 new article topics (mixed across nurse-ai, ece-ai, dev-diary) that would fit the established voice and would naturally invite Stone or Megan to share a specific real moment from their work. For each topic, provide: (1) a one-line headline candidate, (2) the niche it belongs to, (3) an anecdote PROMPT — a specific question that, if answered with a real recollection, would anchor the article. Do NOT invent first-person anecdotes yourself; the author must supply real material. Save the output to ${BRAINSTORM_FILE} as markdown. Brief intro paragraph at top, then five numbered topics."

# Retry up to 3 times — known intermittent 400 "thinking blocks ... cannot be
# modified" from claude -p when retried mid-tool-use. Fresh invocation each time.
RC=1
for attempt in 1 2 3; do
  echo "--- brainstorm attempt $attempt ---" >> "$LOG"
  "$CLAUDE_BIN" -p "$BRAINSTORM_PROMPT" --dangerously-skip-permissions >> "$LOG" 2>&1
  RC=$?
  if [[ $RC -eq 0 && -f "$BRAINSTORM_FILE" ]]; then break; fi
  echo "--- attempt $attempt failed rc=$RC, sleeping 10s ---" >> "$LOG"
  sleep 10
done

# Fallback brainstorm doc so weekend action is never blocked by API hiccup.
if [[ ! -f "$BRAINSTORM_FILE" ]]; then
  cat > "$BRAINSTORM_FILE" <<EOF
# Weekly brainstorm — $(date +%Y-%m-%d) (fallback)

Automated brainstorm failed after 3 attempts (claude -p API error).
Manual prompt below — fill 2-3 anecdotes from real recall this weekend.

## Queue status

\`\`\`
${SUMMARY}
\`\`\`

## Prompts to consider

**nurse-ai (Stone):**
- A specific patient interaction this week where you used (or chose NOT to use) the AI assistant. What was the moment?
- A handout / note you rewrote because the AI version was clinically wrong or unsafe. What did it miss?

**ece-ai (Megan):**
- A learning observation this week where the AI's wording would have lost the moment. What did the child actually do/say?
- A parent communication you drafted with AI assist. What did you change before sending?

**dev-diary (Stone):**
- A build/refactor decision this week. What did you keep, what did you throw away?
- A bug you debugged. Trigger + root cause + fix in 3 sentences.

Drop answers into \`content-queue.json\` as new entries with \`anecdote\` filled.
EOF
fi

# Compose mail body
MAIL_BODY="Hi,

Weekly anecdote-queue health check for stonemegan.

Queue status as of $(date '+%Y-%m-%d %H:%M %Z'):

${SUMMARY}

Brainstorm doc just generated at:
${PROJECT_ROOT}/${BRAINSTORM_FILE}

Action this weekend (15-30 minutes total):
  1. Open the brainstorm doc.
  2. For each suggested topic, either dismiss it or jot 2-3
     sentences of a real moment that fits the prompt.
  3. Drop anything that lands into content-queue.json as a new
     entry with an 'anecdote' field. The daily 7am cron will
     pick them up over the following week.

The pipeline is currently auto-publishing daily. When the
queue runs dry of anecdotes, it still generates 'skeleton'
drafts that land in the repo as draft: true (invisible on
the site) until a human fills them in.

— ai-careers cron

Log: ${LOG}"

# Always write an INBOX.md so user has a guaranteed file to read even if
# mailto open fails (launchd Background sessions can't always launch GUI).
INBOX_FILE="${BRAINSTORM_DIR}/INBOX.md"
{
  echo "# Latest weekly check — $(date '+%Y-%m-%d %H:%M %Z')"
  echo
  echo "$MAIL_BODY"
} > "$INBOX_FILE"

# URL-encode for mailto:
ENC_SUBJECT=$(/usr/bin/python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "ai-careers weekly anecdote check — $(date +%Y-%m-%d)")
ENC_BODY=$(/usr/bin/python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$MAIL_BODY")
MAIL_RC=0
/usr/bin/open -b com.microsoft.Outlook "mailto:${NOTIFY_EMAIL}?subject=${ENC_SUBJECT}&body=${ENC_BODY}" >> "$LOG" 2>&1 || MAIL_RC=$?
echo "mailto open rc=$MAIL_RC" >> "$LOG"

# macOS notification — works even from Background ProcessType.
/usr/bin/osascript -e "display notification \"Weekly anecdote check complete. See docs/brainstorm/INBOX.md\" with title \"ai-careers weekly ✓\" sound name \"Glass\"" >> "$LOG" 2>&1 || true

echo "=== Completed $(date) (rc=$RC) ===" >> "$LOG"
exit "$RC"
