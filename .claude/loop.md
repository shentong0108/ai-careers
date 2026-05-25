# /loop — Autonomous Pipeline Runner

This project supports two automation modes:

## Mode 1: Cloud Cron (Primary — Recommended)

GitHub Actions runs `.github/workflows/auto-content.yml` every 2 days at 09:00 UTC.
No local Claude required. Runs even when your laptop is closed.

**Setup:**
1. Push repo to GitHub.
2. Add secrets in `Settings → Secrets and variables → Actions`:
   - `ANTHROPIC_API_KEY`
   - `ZEROGPT_API_KEY` (or originality.ai key — for AI-detection)
   - `PLAUSIBLE_API_KEY`
   - `GSC_SERVICE_ACCOUNT` (Google Search Console service account JSON, base64)
   - `CF_ANALYTICS_TOKEN`
3. Push to main — first cron fires within 48h.

PRs auto-open under `auto/<slug>` branch. Human reviews + merges. Cloudflare Pages auto-deploys merged main.

## Mode 2: Local /loop (Backup — When You Want to Babysit)

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
