# /run-daily-ops

Daily babysitter loop. Reviews state of project and surfaces action items. Does NOT modify content.

## Steps

1. **Check open PRs** from auto-content workflow:
   ```bash
   gh pr list --label auto-content --json number,title,headRefName,createdAt
   ```
   For each PR > 24h old: flag for review.

2. **Read latest dashboard**: read newest file in `docs/dashboard/`. If none from last 7d, dispatch `analytics-reader` agent.

3. **Read CI status**: `gh run list --limit 5 --json status,conclusion,name`. Flag any `failure`.

4. **Surface action items** — output table:
   ```
   | Type | Item | Action |
   |---|---|---|
   | PR waiting | #42 nurse-handoff | Review + merge or send back |
   | Dashboard | rank-11 keyword X | Add internal links |
   | CI fail | workflow run #99 | Investigate |
   ```

5. **Do nothing else.** Output summary + actions. User decides next move.

## Boundaries

- Read-only. No edits. No PR merges. No deploys.
- If anything looks broken: dispatch `debug-investigator` agent and stop.
- Time budget: 5 minutes max per loop tick.
