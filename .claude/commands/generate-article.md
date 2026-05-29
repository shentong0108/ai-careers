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
   - `content-humanizer` → deterministic humanise + AI-detect score
     (degraded mode if no API key)
   - `fact-checker` → only if niche is `nurse-ai` or `ece-ai`
   - `voice-polisher` → REQUIRED for every article. Loads same-author
     published anchor articles as voice samples, rewrites the worst
     3-5 paragraphs to match the author's actual rhythm and voice
     quirks. Last anti-AI-smell pass before publish. Adds
     `voicePolisherPasses: N` to frontmatter.
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

6. **Auto-merge** the PR via `gh pr merge <number> --squash --delete-branch`.

   This is unconditional per user direction ("直接发布", option B). Safety
   reasoning: skeleton articles (those generated when no `anecdote` field
   exists in the queue entry) are forced to `draft: true` by the
   content-writer in skeleton mode, and the homepage / category /
   blog-post routes all filter `!data.draft` via `getCollection`. So a
   skeleton merged to `main` lives in the repo but is **not** publicly
   visible until a human flips `draft` to `false`. Filled articles
   (anecdote present) end with `draft: false` and publish immediately
   on the Cloudflare Pages auto-deploy that follows the merge.

   If any agent earlier in the pipeline returned `status: blocked`, the
   pipeline must abort BEFORE step 5 — no PR is opened and no merge
   happens. Failure handling below.

7. **Cleanup worktree**:
   ```bash
   cd "$OLDPWD"
   git worktree remove ../blog-site-$SLUG
   ```

8. **Mark queue entry published** by editing `content-queue.json`,
   flipping the entry's `status` from `in-flight` to `published` and
   adding `mergedAt`. Commit + push as `chore: mark <slug> published`.

9. **Stop.**

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
