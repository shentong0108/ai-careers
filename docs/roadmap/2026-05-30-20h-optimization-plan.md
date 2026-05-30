# 20-hour optimization plan — stonemegan.dev

Generated 2026-05-30. Auto-executed by Claude in `/loop` mode.
Each iteration appends to `progress.log` in this directory.

## Goal

Make stonemegan.dev production-grade by the end of the 20-hour window:
- Zero broken assets / 404s on internal links
- All YMYL articles fact-check-enforced
- Pipeline doesn't silently stall
- Content queue never starves
- SEO surface (titles, meta, sitemap, RSS) clean

## Source of findings

Two parallel audits ran 2026-05-30 (Sat). See:
- Site-bug audit: 8 missing assets, no 404 page, no RSS
- Pipeline audit: stalled in-flight entry, dev-diary niche empty,
  factChecked never enforced for YMYL

## Buckets, in priority order

### Bucket 1 — CRITICAL (must fix in first 2h)

| # | Item | Why critical |
|---|---|---|
| 1 | Recover stalled in-flight queue entry (`writing-better-patient-education-handouts...`, picked 18h ago, no mdx written) | Pipeline silently stuck; blocks rotation |
| 2 | Add 2+ dev-diary anecdotes to queue | dev-diary slot empty; next rotation halts |
| 3 | Create `public/favicon.svg` + `apple-touch-icon.png` | Browser tab shows broken icon |
| 4 | Create `public/og-default.png` | Social shares render broken thumbnail |
| 5 | Create 3 missing per-article hero images or fallback to OG default | 404s on `<img>` in article hero |
| 6 | Create `src/pages/404.astro` | Default Astro 404 is ugly + off-brand |

### Bucket 2 — HIGH (next 4h)

| # | Item | Reason |
|---|---|---|
| 7 | RSS feed at `src/pages/rss.xml.ts` via `@astrojs/rss` | Subscribers can't follow without it |
| 8 | Enforce `factChecked: true` for nurse-ai/ece-ai in deploy-verifier (HARD gate) | YMYL articles shipped without fact-check |
| 9 | Trim 2 titles >60 chars | SERP truncation |
| 10 | Fix slug trim — trailing dash bug | Ugly URLs |
| 11 | Add `factCheckedAt`/`factCheckedBy` to schema | Audit trail |

### Bucket 3 — MEDIUM (next 4h)

| # | Item | Reason |
|---|---|---|
| 12 | voice-polisher numeric metric ("passable" → ai_tells_remaining < 2) | Subjective skip risk |
| 13 | Pipeline: emit structured status on ANY exit path | Silent stalls invisible |
| 14 | Document deploy-verifier gate-override policy | Confusing signal |
| 15 | Provision AI-detection API key OR remove the requirement from contract | Gate 8 never runs |
| 16 | Beehiiv publication timezone Sydney (currently US/Eastern) | Send time wrong for AU readers |

### Bucket 4 — Continuous loop (remaining ~10h)

Each loop iteration (~60-90min cadence):

1. **Audit** — re-run site bug + pipeline audit, diff vs previous
2. **Pick** — top finding by severity × leverage
3. **Investigate** — root cause, NOT symptom (per CLAUDE.md rule)
4. **Fix** — minimal diff, no scope creep
5. **Verify** — `npm run build` exit 0 + visual check if applicable
6. **Commit** — caveman-commit style, root cause in body
7. **Log** — append to `progress.log` with timestamp + change
8. **Schedule next wake** — until budget exhausts

Loop exits when:
- 20h elapsed (~2026-05-31 18:00 AEST)
- OR no new findings for 2 consecutive iterations
- OR user interrupts

## Anti-scope-creep guardrails

- No new features (only bug fixes + optimization)
- No new pages or sections without user ack
- No content edits to published articles unless fixing factual error
- No commits to a branch other than main
- Push after every commit (CF Pages auto-deploys)
- Never `--no-verify`, never `--force`, never destructive git

## What I will NOT do autonomously

- Apply for new affiliate programs
- Post to Reddit / HN / Twitter on user's behalf
- Change Beehiiv settings (user-only)
- Change CF Pages env vars (user-only)
- Edit user identity / authorship metadata
- Spend Anthropic API credits (only Claude Code subscription)

## Progress

See `progress.log` in this directory.
