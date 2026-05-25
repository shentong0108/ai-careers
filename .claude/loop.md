# /loop — Autonomous Pipeline Runner

This project supports two automation modes:

## Mode 1: Local launchd Cron (Primary — Recommended)

Uses your Claude Code subscription quota (Pro/Max plan) — no API credits
consumed. A macOS launchd LaunchAgent fires `scripts/local-cron.sh` daily
at 09:00 local time. The script throttles to one successful run per 46
hours, so the effective cadence is ~every 2 days.

**Install:**

```bash
cd "/Volumes/Studio work/blog-site"
./scripts/install-launchd.sh
```

This writes `~/Library/LaunchAgents/dev.stonemegan.aicareers.plist` and
loads it. Next run fires at the next 09:00 local time.

**What it does each run:**

1. `git fetch && git pull --ff-only origin main` — sync latest
2. `caffeinate -i` — keep Mac awake during the run
3. `claude -p "/generate-article" --dangerously-skip-permissions`
   - This dispatches sub-agents natively via the Task tool, reading
     contracts from `.claude/agents/<name>.md`
4. Pipeline opens a PR; Cloudflare Pages auto-deploys when you merge.

**Throttle:** if `.claude/cache/local-cron-last-run` is < 46h old, the
script no-ops. Delete that file to force-run.

**Force run now (ignores throttle):**

```bash
rm -f .claude/cache/local-cron-last-run
launchctl start dev.stonemegan.aicareers
tail -f .claude/logs/cron-*.log
```

**Constraints:**

- Mac must be on (sleep is OK — launchd queues missed runs on wake).
- Claude Code CLI must be authenticated (`claude auth status`).
- Cloud workflow `.github/workflows/auto-content.yml` is **disabled** by
  default (schedule trigger commented out). Manual dispatch still works
  but consumes API credits.

## Mode 2: Cloud Cron (Backup — When Mac Unavailable)

GitHub Actions can run the pipeline if your laptop will be unreachable
for many days. **Consumes API credits**, not subscription.

To enable:

1. Uncomment the `schedule:` block in `.github/workflows/auto-content.yml`.
2. Add `ANTHROPIC_API_KEY` secret with sufficient balance.
3. Add `ZEROGPT_API_KEY` (or Originality) for AI-detection.

To trigger one-off without enabling schedule:

```bash
gh workflow run auto-content.yml -f niche=dev-diary
```

## Mode 3: Local /loop (Manual Babysit)

Use `/loop` skill when you want to run Claude locally on interval.

### Daily ops loop (recommended local cadence)

```
/loop 6h /run-daily-ops
```

`/run-daily-ops` is defined in `.claude/commands/run-daily-ops.md` — runs:
1. Check inbox PRs from auto-content workflow
2. Read fresh analytics from `analytics-reader`
3. Surface action items (top/bottom 5 posts, striking-distance keywords)
4. If a PR is ready and AI-detection passed, post review checklist

### Article generation loop (only if GH Actions disabled)

```
/loop 48h /generate-article
```

`/generate-article` is defined in `.claude/commands/generate-article.md` — runs the full agent pipeline locally and opens PR.

### Dynamic loop (Claude self-paces)

```
/loop /watch-dashboard
```

Claude chooses next wake interval based on what it observes (busy = check sooner, quiet = check less).

## How the Agent Pipeline Runs Inside the Loop

Both modes call `scripts/run-agent.ts <agent-name>` which:
1. Reads the agent's `.md` constraint file from `.claude/agents/`.
2. Invokes Claude API with the agent prompt + constraints.
3. Captures structured receipt.
4. Writes receipt to `.claude/cache/<agent>-latest.txt`.
5. Exits non-zero on agent block / verification fail.

If any agent returns `status: blocked` — pipeline stops. PR is NOT opened. Human is notified via the workflow failure (GH email) or terminal output (local).

## Kill Switch

Stop the loop: `stop loop` or kill the schedule via `/schedule` skill.
Disable GH Actions cron: comment out `schedule:` block in `auto-content.yml`.

## What the Loop Will NOT Do Automatically

Hardcoded boundaries — manual confirmation required:
- Merge PR to main
- Deploy to production
- Run `wrangler pages deploy` (pre-bash-guard blocks)
- Push force / reset hard (denied)
- Edit YMYL articles after publish without fact-checker re-run
