#!/usr/bin/env bash
# Monday-morning analytics review prompt.
#
# Does NOT pull data from Plausible/GSC APIs yet (would need API key
# + OAuth scaffolding). Instead, writes a structured checklist to
# docs/marketing/weekly-analytics/<YYYY-MM-DD>.md and opens a mailto
# draft so Stone gets a guaranteed prompt every Monday to actually
# look at the dashboards and answer the 5 questions that matter.
#
# When PLAUSIBLE_API_KEY is later added to ~/.env-stonemegan, this
# script can be upgraded to pre-fill the answers from the API.
#
# Triggered by ~/Library/LaunchAgents/dev.stonemegan.aicareers-analytics.plist
# at Monday 09:00 local time.

set -uo pipefail

PROJECT_ROOT="/Volumes/Studio work/blog-site"
NOTIFY_EMAIL="shentong940108@hotmail.com"
cd "$PROJECT_ROOT"

REPORT_DIR="docs/marketing/weekly-analytics"
LOG_DIR=".claude/logs"
mkdir -p "$REPORT_DIR" "$LOG_DIR"

DATE=$(date +%Y-%m-%d)
WEEK=$(date +%V)
TS=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="${REPORT_DIR}/${DATE}.md"
LOG="${LOG_DIR}/analytics-${TS}.log"

# Article count + most-recent slug from the live site
PUBLISHED_COUNT=$(/usr/bin/find src/content/posts -name '*.mdx' 2>/dev/null | /usr/bin/wc -l | /usr/bin/tr -d ' ')
LAST_SLUG=$(/bin/ls -t src/content/posts/*/*.mdx 2>/dev/null | /usr/bin/head -1 | /usr/bin/sed 's|.*/||; s|\.mdx$||')

cat > "$REPORT_FILE" <<EOF
# Weekly analytics review — ${DATE} (week ${WEEK})

Stop. Open both dashboards before answering. Five-minute job, do not skip.

- **Plausible**: https://plausible.io/stonemegan.dev?period=7d
- **Google Search Console**: https://search.google.com/search-console?resource_id=sc-domain:stonemegan.dev
  (filter: last 7 days)

Site state:
- ${PUBLISHED_COUNT} published mdx articles in the repo
- Most recent: ${LAST_SLUG}

---

## The 5 questions (answer in this file, commit it)

### 1. Top non-direct source this week

Plausible → Sources tab. Ignore Direct/None.

> Answer:

If still 100% Direct, the promo channels are not delivering yet —
that's the next-week priority, not a metric problem.

### 2. Top entry page

Plausible → Top Pages → Entry Pages. Note the path.

> Answer:

If \`/\` dominates, SEO is not landing people on long-tail articles
yet (expected for a < 30-day-old site). If a niche page or specific
article ranks #1, that's a SEO win — note which.

### 3. Top GSC query (impressions, last 7d)

GSC → Performance → Queries.

> Answer:

Note the top 3 queries by impressions. The query Google is showing
your site for is the topic to write the next piece about — even if
CTR is currently 0%.

### 4. Highest bounce + reason

Plausible → Top Pages → click the page → see bounce rate.

Page with highest bounce:
> Answer:

Hypothesis for why:

- [ ] Long load time
- [ ] First paragraph buries the lede
- [ ] No clear next-action (read next / subscribe)
- [ ] Mismatch with what the inbound source promised
- [ ] Other:

### 5. Subscribes this week

Beehiiv dashboard → Audience growth → Last 7 days.

> Count:

If 0: the SubscribeForm wiring (\`PUBLIC_BEEHIIV_PUB_URL\` in .env)
may still be unset, or the form is not converting. Open one article
in an incognito browser and check the embed renders.

---

## Action for next week

Based on the answers above, pick ONE thing to do this week:

- [ ] Write a new article targeting the top GSC query from Q3
- [ ] Drop a Reddit post in the sub that drove most traffic from Q1
- [ ] Fix the page with highest bounce from Q4
- [ ] Wire up missing Beehiiv embed if Q5 was 0
- [ ] Other:

Commit this file when answered:

\`\`\`bash
git add docs/marketing/weekly-analytics/${DATE}.md
git commit -m "analytics: week ${WEEK} review"
\`\`\`
EOF

# Mail draft so the prompt actually reaches Stone's inbox.
MAIL_BODY="Weekly analytics prompt for ${DATE}.

Open both dashboards (5 minutes):
- Plausible: https://plausible.io/stonemegan.dev?period=7d
- GSC: https://search.google.com/search-console?resource_id=sc-domain:stonemegan.dev

Answer the 5 questions in:
${PROJECT_ROOT}/${REPORT_FILE}

This is the only weekly task that compounds. Skip it and you fly
blind. The 5 questions are designed to take 5 minutes total — not
to produce a report, just to keep you looking at the same numbers
every week so you spot trends.

— ai-careers cron
Log: ${LOG}"

ENC_SUBJECT=$(/usr/bin/python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "ai-careers weekly analytics — ${DATE}")
ENC_BODY=$(/usr/bin/python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$MAIL_BODY")
MAIL_RC=0
/usr/bin/open "mailto:${NOTIFY_EMAIL}?subject=${ENC_SUBJECT}&body=${ENC_BODY}" >> "$LOG" 2>&1 || MAIL_RC=$?

/usr/bin/osascript -e "display notification \"Weekly analytics review. Open ${REPORT_FILE}\" with title \"stonemegan analytics ✓\" sound name \"Glass\"" >> "$LOG" 2>&1 || true

{
  echo "=== Weekly analytics check $(date) ==="
  echo "report: $REPORT_FILE"
  echo "mailto rc: $MAIL_RC"
  echo "=== done ==="
} >> "$LOG"

exit 0
