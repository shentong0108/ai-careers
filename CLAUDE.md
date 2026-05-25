# ai-careers — Project Rules

> AI-content blog. Niche: nurse + AI, ECE + AI, Claude Code dev diary, Aura app build experiences.
> Target: UK / AU / NZ English audience. Revenue: AdSense + affiliate + digital products.

## Stack

- **Astro** (static SSG) + MDX content collections
- **Cloudflare Pages** (hosting, free tier)
- **macOS launchd cron** — primary automation, every ~2 days, uses Claude
  Code subscription quota via `claude -p "/generate-article"`
- **GitHub Actions** — disabled by default, manual-dispatch backup that
  consumes API credits if used
- **Plausible** + Cloudflare Web Analytics — dashboard
- **TypeScript** strict mode
- LSP: `astro check` + `eslint` + `prettier`

## Non-Negotiable Rules

### 1. Root Cause Before Fix

NEVER patch a symptom. Process:

1. Reproduce bug locally with exact steps
2. Isolate failing layer (build / content schema / API call / hook / runtime)
3. Write a failing test that captures the bug
4. State the root cause in one sentence in commit body
5. Fix at root
6. Test passes
7. Verify no regression: `npm run build && npm test`

If you can't reproduce → don't fix. Ask user for repro steps.

If symptom and root cause feel far apart → invoke `systematic-debugging` skill.

### 2. Verify Before Claim

NEVER claim "fixed" / "done" / "passing" without running the verifying command and pasting its output.

Required before merging any branch:
- `npm run build` exits 0
- `npm test` exits 0 (when tests exist)
- `npx astro check` exits 0
- New content: AI-detection score < 30% (ZeroGPT or Originality.ai)

Invoke `verification-before-completion` skill before marking any task done.

### 3. Worktree Per Feature

NEVER hack on `main`. Workflow:

```bash
git worktree add ../blog-site-<slug> -b feat/<slug>
cd ../blog-site-<slug>
# work
git push -u origin feat/<slug>
gh pr create
# after merge:
git worktree remove ../blog-site-<slug>
git branch -d feat/<slug>
```

Auto-content generation uses its own worktree per article. See `scripts/generate-article.ts`.

Invoke `using-git-worktrees` skill at start of any feature.

### 4. Sub-Agents Locked by .md

Every sub-agent dispatched has a corresponding `.claude/agents/<name>.md` defining:
- Role + scope
- Allowed tools
- Hard constraints (must-do / never-do)
- Output format
- Verification step before returning

NEVER dispatch an agent without checking its `.md` exists.
NEVER let an agent expand scope beyond its `.md`.
If the work doesn't match any agent's `.md` → main thread does it, or write a new agent first.

### 5. YMYL Discipline (Nurse + ECE Content)

These categories are Your-Money-Your-Life. Google demotes weak E-E-A-T.

Every nurse-ai / ece-ai article requires:
- Real author byline with credential (RN reg # / ECT Cert)
- 1+ citation to PubMed / .gov / .edu / official guideline
- "Last reviewed" date
- Schema.org `Article` + `Person` author markup
- No medical advice phrasing — frame as "in my practice" / "ask your supervisor"

`fact-checker` agent runs before publish.

### 6. No AI Smell

Every Claude-generated draft passes through `content-humanizer` agent before commit. Drop banned tokens:

> delve, tapestry, in today's fast-paced world, moreover, furthermore, it's important to note, navigate the landscape, ever-evolving, robust, leverage (as verb), seamless, treasure trove, em-dash overuse, "not only X but also Y" pattern

Each article must have:
- First-person concrete anecdote (real shift / real bug)
- 1+ original screenshot
- ≥1 specific number ("23 min" not "significant time")
- ≥1 opinion paragraph
- Sentence rhythm: 5-word + 25-word mix

## Code Conventions

- TypeScript strict. No `any` — use `unknown` + narrow.
- Imports: absolute via `@/` alias.
- Content collections: Zod schema in `src/content/config.ts`. Build fails on schema drift.
- Commits: Conventional Commits (`feat:`, `fix:`, `chore:`, `content:`).
- One concern per commit. No mega-commits.

## Hook Behavior

`.claude/hooks/` enforces:
- `pre-edit-fix.sh` — Edit/Write on bug-fix branches require ROOT_CAUSE.md or commit body line `root-cause: ...`
- `post-build.sh` — captures `npm run build` output to `.claude/logs/`
- `pre-publish.sh` — blocks deploy if AI-detection score > 30% or `astro check` non-zero
- `prompt-injector.sh` — appends current rules to every user prompt

## Skills to Invoke

| Situation | Skill |
|---|---|
| Starting feature | `using-git-worktrees` |
| Bug encountered | `systematic-debugging` |
| Before "done" | `verification-before-completion` |
| Code review | `caveman-review` |
| Commit msg | `caveman-commit` |
| Spawning agent | `cavecrew` (decide which) |
| Multi-step impl | `executing-plans` or `subagent-driven-development` |

## Reference Files

- `docs/superpowers/plans/` — implementation plans
- `.claude/agents/` — sub-agent constraint files
- `.claude/hooks/` — automation hooks
- `scripts/generate-article.ts` — Claude API article generator
- `src/content/config.ts` — content schema (Zod)
