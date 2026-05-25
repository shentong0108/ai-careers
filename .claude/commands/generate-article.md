# /generate-article

Full article-generation pipeline. Runs all agents in sequence. Opens PR. Stops.

## Inputs (optional)

- `niche` — `nurse-ai` | `ece-ai` | `dev-diary` (default: pick from queue)
- `topic` — override topic (default: pick from `content-queue.json`)

## Steps

1. **Pick topic** — `node scripts/pick-next-topic.ts` reads `content-queue.json`, rotates niches, returns `{ niche, slug, topic }`.

2. **Create worktree**:
   ```bash
   git worktree add ../blog-site-$SLUG -b auto/$SLUG
   cd ../blog-site-$SLUG
   ```

3. **Run pipeline** — dispatch agents in order, abort on any blocked status:
   - `keyword-researcher` → `docs/research/keywords/$NICHE/$SLUG.json`
   - `content-writer` → `src/content/posts/$NICHE/$SLUG.mdx`
   - `content-humanizer` → same file, score < 30
   - `fact-checker` (if YMYL) → frontmatter `factChecked: true`
   - `seo-optimizer` → final MDX with JSON-LD
   - `deploy-verifier` → all 9 gates pass

4. **Commit + push**:
   ```bash
   git add src/ docs/research/
   git commit -m "content: $TOPIC"
   git push -u origin auto/$SLUG
   ```

5. **Open PR**:
   ```bash
   gh pr create --label auto-content --title "content: $TOPIC" --body "$(cat .claude/templates/pr-body.md)"
   ```

6. **Cleanup worktree**:
   ```bash
   cd ..
   git worktree remove ../blog-site-$SLUG
   ```

7. **Stop.** Do NOT merge. Human reviews.

## Boundaries

- One article per invocation. No batch.
- Hard cost cap: $5 Claude API spend per invocation (track tokens).
- If any agent returns `status: blocked`: write `docs/blocked/<date>-<slug>.md` with reason, no PR, exit.
- No edits to existing articles. New article only.
