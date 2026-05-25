# ai-careers · stonemegan.dev

Real stories from a nurse and an ECT using AI in their jobs. Plus dev diary of building Aura app.

## Stack

Astro 5 + MDX · Cloudflare Pages · GitHub Actions cron · Anthropic Claude API (claude-opus-4-7).

## Quick start

```bash
pnpm install
cp .env.example .env  # fill in keys
pnpm dev              # http://localhost:4321
```

## Automation

- **Every 2 days**: GH Actions cron picks topic from `content-queue.json`, runs the agent pipeline, opens a PR.
- **Pipeline**: `keyword-researcher` → `content-writer` → `content-humanizer` → `fact-checker` (YMYL) → `seo-optimizer` → `deploy-verifier`.
- **Human review required** before merge. No auto-merge.
- **Cloudflare Pages** auto-deploys merged `main`.

See `.claude/loop.md` for full pipeline doc and local `/loop` alternatives.

## Project rules

See `CLAUDE.md`. Highlights:

1. Root cause before fix (no symptom patches).
2. Verify before claiming done.
3. Worktree per feature.
4. Every sub-agent has a `.md` constraint contract.
5. YMYL fact-check required for nurse-ai + ece-ai.
6. No AI smell — humanizer pass + detection < 30%.

## Layout

```
.claude/
  agents/       sub-agent contract .md files
  hooks/        UserPromptSubmit/PreToolUse/Stop hooks
  commands/     slash commands for /loop
src/
  content/posts/{nurse-ai,ece-ai,dev-diary}/
  layouts/  pages/  components/
scripts/        run-agent.ts, pick-next-topic.ts, detect-ai.ts
docs/
  superpowers/plans/   implementation plans
  dashboard/           analytics reports
  research/keywords/   keyword research JSON
  debug/               root-cause analysis docs
```

## Next steps after clone

See `docs/superpowers/plans/2026-05-25-ai-careers-bootstrap.md`.
