# Sub-Agent Registry

Every sub-agent must have an `.md` file here defining role, scope, constraints, output format, and verification.

## Agent Pipeline

```
keyword-researcher  →  research brief (JSON)
       ↓
content-writer      →  draft MDX (frontmatter draft:true)
       ↓
content-humanizer   →  rewrite for human voice + AI-detect < 30%
       ↓
fact-checker        →  YMYL gate (nurse-ai + ece-ai only)
       ↓
seo-optimizer       →  schema, internal links, OG meta
       ↓
deploy-verifier     →  9 gates, blocks bad deploys
```

Side agents (not in pipeline):

- `debug-investigator` — root cause first, no fix applied
- `analytics-reader` — dashboard reads + suggestions

## Adding a New Agent

1. Write `<name>.md` with frontmatter: `name`, `description`, `tools`.
2. Sections: Role, Inputs, Hard Constraints (NEVER + MUST), Workflow, Output Format, Verification Before Return.
3. Add to pipeline diagram above if it fits a pipeline slot.
4. Reference from CLAUDE.md.

## Hard Rules (apply to ALL agents)

- ONE responsibility per agent. If you need to do two things, dispatch two agents.
- Output a structured receipt — no prose summaries that hide what changed.
- Verification block before return — explicit checklist.
- Refuse out-of-scope work. Don't expand.
