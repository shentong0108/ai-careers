**Auto-generated draft from the local launchd cron pipeline.** Human review required before merge.

This PR was produced by the six-agent pipeline (`keyword-researcher` → `content-writer` → `content-humanizer` → `fact-checker` (YMYL niches only) → `seo-optimizer` → `deploy-verifier`). The pipeline runs against the user's Claude Code subscription, not the Anthropic API.

## Pre-merge checklist

Voice
- [ ] Read the article end-to-end. Does it sound like Stone (dev-diary, nurse-ai) or Megan (ece-ai)?
- [ ] Run a hard ear check on the intro paragraph. If it sounds AI, send back.
- [ ] Are the anecdotes specific enough? No vague "many nurses experience..." filler?

Safety & privacy
- [ ] No registration numbers in body or schema
- [ ] No real surnames, no employer name, no centre name
- [ ] No patient or child names
- [ ] No specific competitor company names (generic descriptors only)
- [ ] If nurse-ai or ece-ai: `fact-checker` agent passed and `factChecked: true` in frontmatter

Quality gates
- [ ] AI-detection score in frontmatter is below 30%
- [ ] Banlist scan clean (no "delve", "tapestry", "moreover", "ever-evolving", "robust", "leverage", etc.)
- [ ] Em-dash count reasonable (under 1 per 150 words)
- [ ] All cited URLs return 200 — open each one
- [ ] Schema.org JSON-LD validates (run `node scripts/validate-jsonld.ts` if it exists)
- [ ] `pnpm build` passes locally if you pull the branch

Hero image
- [ ] Hero image exists at the path in `heroImage`
- [ ] Hero image is licensed for commercial use (Unsplash / Pexels / your own photo)
- [ ] No identifiable faces (especially: no children's faces)

Closing
- [ ] If you reject the article, comment why so the agent contracts can be tightened
- [ ] If you accept with edits, commit the edits on this branch before merging
