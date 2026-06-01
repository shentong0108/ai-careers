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

# Load PLAUSIBLE_API_KEY from .env if present (cron runs without shell env).
if [ -f .env ]; then
  set -a
  # shellcheck source=/dev/null
  . .env
  set +a
fi

# Plausible Stats API autofill. If no key, leave Q1/Q2/Q4 blank for
# manual fill (matches the original behaviour) and write a note in
# the report explaining the fallback.
PLAUSIBLE_BASE="https://plausible.io/api/v1/stats"
SITE="stonemegan.dev"
PLAUSIBLE_MODE="unset"
GSC_MODE="unset"
Q_TOTALS="" Q1_TOP_SOURCE="" Q2_TOP_ENTRY="" Q3_TOP_QUERY="" Q4_TOP_BOUNCE=""

# GSC Search Analytics autofill via service-account JWT (scripts/lib/gsc-query.mjs).
# Requires .gsc-service-account.json at repo root + the service account
# added as a user on the GSC property (propagation can take up to ~24h
# after the SA is created).
if [ -f .gsc-service-account.json ]; then
  GSC_RAW=$(/usr/bin/env node scripts/lib/gsc-query.mjs --days 7 --limit 5 2>/dev/null || echo "")
  if [ -n "$GSC_RAW" ] && echo "$GSC_RAW" | /usr/bin/jq -e '.rows' >/dev/null 2>&1; then
    ROW_COUNT=$(echo "$GSC_RAW" | /usr/bin/jq -r '.rows | length')
    if [ "$ROW_COUNT" -gt 0 ]; then
      GSC_MODE="autofill"
      Q3_TOP_QUERY=$(echo "$GSC_RAW" | /usr/bin/jq -r '.rows | map("- \"" + .query + "\" — " + (.impressions|tostring) + " impressions, " + (.clicks|tostring) + " clicks, position " + (.position|tostring|.[0:4])) | join("\n")')
    else
      GSC_MODE="autofill"
      Q3_TOP_QUERY="_GSC returned 0 rows for the last 7 days (no impressions yet — expected for a < 30-day-old site)._"
    fi
  else
    GSC_MODE="error"
    GSC_ERR=$(echo "$GSC_RAW" | /usr/bin/jq -r '.error // "unknown error"' 2>/dev/null || echo "unknown")
    Q3_TOP_QUERY="_Autofill blocked — GSC API error: ${GSC_ERR}._"
  fi
else
  Q3_TOP_QUERY="_Autofill blocked — no .gsc-service-account.json at repo root._"
fi

if [ -n "${PLAUSIBLE_API_KEY:-}" ]; then
  PLAUSIBLE_MODE="autofill"
  AUTH="Authorization: Bearer ${PLAUSIBLE_API_KEY}"
  # Aggregate totals
  AGG=$(/usr/bin/curl -fsS -H "$AUTH" "${PLAUSIBLE_BASE}/aggregate?site_id=${SITE}&period=7d&metrics=visitors,pageviews,bounce_rate,visit_duration" 2>/dev/null || echo "")
  if [ -n "$AGG" ]; then
    VISITORS=$(echo "$AGG" | /usr/bin/jq -r '.results.visitors.value')
    PAGEVIEWS=$(echo "$AGG" | /usr/bin/jq -r '.results.pageviews.value')
    BOUNCE=$(echo "$AGG" | /usr/bin/jq -r '.results.bounce_rate.value')
    DUR=$(echo "$AGG" | /usr/bin/jq -r '.results.visit_duration.value')
    Q_TOTALS="- **Unique visitors (7d):** ${VISITORS}
- **Pageviews (7d):** ${PAGEVIEWS}
- **Bounce rate:** ${BOUNCE}%
- **Avg visit duration:** ${DUR}s"
  fi
  # Q1 — top source (drop Direct/None per the existing rubric)
  SRC=$(/usr/bin/curl -fsS -H "$AUTH" "${PLAUSIBLE_BASE}/breakdown?site_id=${SITE}&period=7d&property=visit:source&limit=10" 2>/dev/null || echo "")
  if [ -n "$SRC" ]; then
    Q1_TOP_SOURCE=$(echo "$SRC" | /usr/bin/jq -r '.results | map(select(.source != "Direct / None")) | (if length == 0 then "_All traffic is Direct/None — promo channels not delivering yet._" else (map("- " + .source + " — " + (.visitors|tostring) + " visitors") | .[0:3] | join("\n")) end)')
  fi
  # Q2 — top entry page
  ENT=$(/usr/bin/curl -fsS -H "$AUTH" "${PLAUSIBLE_BASE}/breakdown?site_id=${SITE}&period=7d&property=visit:entry_page&limit=5" 2>/dev/null || echo "")
  if [ -n "$ENT" ]; then
    Q2_TOP_ENTRY=$(echo "$ENT" | /usr/bin/jq -r '.results | map("- " + .entry_page + " — " + (.visitors|tostring) + " visitors") | join("\n")')
  fi
  # Q4 — highest-bounce page (filter pages with >=2 visitors so a single bounce on 1 visit doesn't dominate)
  BNC=$(/usr/bin/curl -fsS -H "$AUTH" "${PLAUSIBLE_BASE}/breakdown?site_id=${SITE}&period=7d&property=event:page&metrics=bounce_rate,visitors&limit=10" 2>/dev/null || echo "")
  if [ -n "$BNC" ]; then
    Q4_TOP_BOUNCE=$(echo "$BNC" | /usr/bin/jq -r '.results | map(select(.visitors >= 2)) | sort_by(-.bounce_rate) | (if length == 0 then "_Not enough traffic to identify a high-bounce page yet (need pages with 2+ visitors)._" else (map("- " + .page + " — " + (.bounce_rate|tostring) + "% bounce (" + (.visitors|tostring) + " visitors)") | .[0:3] | join("\n")) end)')
  fi
fi

cat > "$REPORT_FILE" <<EOF
# Weekly analytics review — ${DATE} (week ${WEEK})

Stop. Open both dashboards before answering. Five-minute job, do not skip.

- **Plausible**: https://plausible.io/stonemegan.dev?period=7d
- **Google Search Console**: https://search.google.com/search-console?resource_id=sc-domain:stonemegan.dev
  (filter: last 7 days)

Site state:
- ${PUBLISHED_COUNT} published mdx articles in the repo
- Most recent: ${LAST_SLUG}
- Plausible autofill: **$( [ "$PLAUSIBLE_MODE" = "autofill" ] && echo "enabled" || echo "off (set PLAUSIBLE_API_KEY in .env)" )**
- GSC autofill: **$( if [ "$GSC_MODE" = "autofill" ]; then echo "enabled"; elif [ "$GSC_MODE" = "error" ]; then echo "error (see Q3)"; else echo "off (drop .gsc-service-account.json at repo root)"; fi )**

${Q_TOTALS:+## 7-day totals (Plausible)

${Q_TOTALS}

}---

## The 5 questions (answer in this file, commit it)

### 1. Top non-direct source this week

Plausible → Sources tab. Ignore Direct/None.

${Q1_TOP_SOURCE:->_Autofill blocked — no PLAUSIBLE_API_KEY in .env._}

> Comment:

If still 100% Direct, the promo channels are not delivering yet —
that's the next-week priority, not a metric problem.

### 2. Top entry page

Plausible → Top Pages → Entry Pages. Note the path.

${Q2_TOP_ENTRY:->_Autofill blocked — no PLAUSIBLE_API_KEY in .env._}

> Comment:

If \`/\` dominates, SEO is not landing people on long-tail articles
yet (expected for a < 30-day-old site). If a niche page or specific
article ranks #1, that's a SEO win — note which.

### 3. Top GSC query (impressions, last 7d)

GSC → Performance → Queries.

${Q3_TOP_QUERY:->_Autofill blocked — see GSC autofill status above._}

> Comment:

Note the top 3 queries by impressions. The query Google is showing
your site for is the topic to write the next piece about — even if
CTR is currently 0%.

### 4. Highest bounce + reason

Plausible → Top Pages → click the page → see bounce rate.

${Q4_TOP_BOUNCE:->_Autofill blocked — no PLAUSIBLE_API_KEY in .env._}

Page with highest bounce:
> Comment:

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

MAIL_RC=0
# Auto-send via Outlook AppleScript (no manual click). Falls back to a
# mailto: draft if the AppleScript send fails — better a draft Stone has
# to open than a silently-dropped weekly prompt.
# shellcheck source=lib/send-outlook.sh
. "$(dirname "$0")/lib/send-outlook.sh"
if ! send_outlook "$NOTIFY_EMAIL" "ai-careers weekly analytics — ${DATE}" "$MAIL_BODY" >> "$LOG" 2>&1; then
  MAIL_RC=$?
  echo "send_outlook failed (rc=$MAIL_RC); falling back to mailto draft" >> "$LOG"
  ENC_SUBJECT=$(/usr/bin/python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "ai-careers weekly analytics — ${DATE}")
  ENC_BODY=$(/usr/bin/python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$MAIL_BODY")
  /usr/bin/open -b com.microsoft.Outlook "mailto:${NOTIFY_EMAIL}?subject=${ENC_SUBJECT}&body=${ENC_BODY}" >> "$LOG" 2>&1 || true
fi

/usr/bin/osascript -e "display notification \"Weekly analytics review. Open ${REPORT_FILE}\" with title \"stonemegan analytics ✓\" sound name \"Glass\"" >> "$LOG" 2>&1 || true

{
  echo "=== Weekly analytics check $(date) ==="
  echo "report: $REPORT_FILE"
  echo "mailto rc: $MAIL_RC"
  echo "=== done ==="
} >> "$LOG"

exit 0
