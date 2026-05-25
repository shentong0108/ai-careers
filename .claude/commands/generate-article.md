# /generate-article

Full article-generation pipeline. Runs all sub-agents in sequence. Opens PR. Stops.

Uses local Claude Code subscription (sub-agents dispatched via Task tool).
Does NOT call the Anthropic API directly — no API credits consumed.

## Inputs (optional)

- `niche` — `nurse-ai` | `ece-ai` | `dev-diary` (default: pick from queue)
- `topic` — override topic (default: pick from `content-queue.json`)

## Steps

1. **Pick topic** — run `node scripts/pick-next-topic.ts` to read
   `content-queue.json`, rotate niches, return `{ niche, slug, topic }`.
   This script also marks the entry `status: in-flight`.

2. **Create worktree**:
   ```bash
   git worktree add ../blog-site-$SLUG -b auto/$SLUG
   cd ../blog-site-$SLUG
   ```

3. **Dispatch sub-agents in order** via the Task tool. Each agent is defined
   under `.claude/agents/<name>.md`; the body of that file is the agent's
   system contract. Abort the pipeline if any agent returns `status: blocked`.

   Order:

   - `keyword-researcher` → writes `docs/research/keywords/$NICHE/$SLUG.json`
   - `content-writer` → writes `src/content/posts/$NICHE/$SLUG.mdx`
   - `content-humanizer` → rewrites the file until AI-detection < 30%
   - `fact-checker` → only if niche is `nurse-ai` or `ece-ai`
   - `seo-optimizer` → adds JSON-LD, internal links, OG meta
   - `deploy-verifier` → runs all 9 gates; must return `Overall: READY`

4. **Commit + push**:
   ```bash
   git add src/ docs/research/
   git commit -m "content: $TOPIC"
   git push -u origin auto/$SLUG
   ```

5. **Open PR**:
   ```bash
   gh pr create --label auto-content \
     --title "content: $TOPIC" \
     --body-file .claude/templates/pr-body.md
   ```

6. **Cleanup worktree**:
   ```bash
   cd "$OLDPWD"
   git worktree remove ../blog-site-$SLUG
   ```

7. **Stop.** Do NOT merge. Human reviews.

## Boundaries

- One article per invocation. No batch.
- Hard time cap: 30 minutes from start. If `deploy-verifier` is still running
  past that, abort and write `docs/blocked/<date>-<slug>.md` with timing.
- If any agent returns `status: blocked`: write blocked report, no PR, exit
  non-zero.
- No edits to existing articles. New article only.
- No `git push --force`, no `git reset --hard`, no merge to `main`.

## Failure handling

If pipeline aborts at any step:

1. Reset the queue entry — read `content-queue.json`, find the in-flight
   entry, set `status` back to `pending`. Save.
2. Remove the worktree if it exists.
3. Write `docs/blocked/<YYYY-MM-DD>-<slug>.md` summarizing where it failed
   and the agent's blocked receipt.
4. Exit non-zero so the cron driver logs the failure.
