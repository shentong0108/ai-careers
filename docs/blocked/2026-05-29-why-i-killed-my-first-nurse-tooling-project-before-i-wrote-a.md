# BLOCKED: why-i-killed-my-first-nurse-tooling-project-before-i-wrote-a

- **Date:** 2026-05-29
- **Niche:** dev-diary
- **Topic:** Why I killed my first nurse-tooling project before I wrote any code
- **Failed at step:** post-pipeline review, before PR (step 5). No PR opened, no merge.
- **Reason:** YMYL violation (Rule 5) — fabricated medical credential + wrong jurisdiction.

## Root cause

`content-writer` set `author: "megan"` and wrote the body as *"I am Megan, a
registered nurse (NMC PIN held)"*, with matching `jobTitle: Registered Nurse`
JSON-LD. The author registry (`.claude/authors.json`) defines:

- `stone` = Registered Nurse, **AHPRA-registered (Sydney, Australia)** — the real RN.
- `megan` = **Early Childhood Teacher**, ACECQA-registered — *not a nurse*.

So the draft attached a fabricated RN credential (UK "NMC PIN") to an Australian
ECT. The writer overrode the correct dev-diary→stone convention it had itself
flagged.

## Compounding problem

The entire article is built on **UK law** — NMC PIN, UK GDPR, ICO
controller/processor + DPIA citations. The only real nurse persona (`stone`) is
**AHPRA / Sydney → Australian** jurisdiction (Privacy Act 1988, APPs, OAIC).
Re-authoring to `stone` therefore requires re-localising the sourced YMYL legal
claims and swapping ICO citations for OAIC equivalents — work that must pass
`fact-checker`, which dev-diary normally skips.

## Pipeline agent receipts

- keyword-researcher: ready
- content-writer: ready_with_flag (self-flagged author byline as `megan`, needs review)
- content-humanizer: ready, degraded mode (no AI-detection API key), forced `draft: true`
- voice-polisher: ready (fell back to megan ece-ai anchors — no megan dev-diary anchor)
- seo-optimizer: ready_with_flags (raised the author-registry / YMYL E-E-A-T conflict; flagged `draft` flipped back to false; build not verifiable in worktree, no node_modules)
- deploy-verifier: NOT RUN (aborted first)

## Actions taken on abort

- Queue entry reset `in-flight` → `pending` (pickedAt removed).
- Worktree `../blog-site-...` removed; branch `auto/...` deleted (no commits).
- This report written.

## To unblock (decision needed from user)

1. **Re-author to Stone + re-localise to AU law** (most correct, most work):
   author=stone, NMC PIN→AHPRA, ICO/UK GDPR→OAIC/Privacy Act 1988/APPs, swap
   citations, run fact-checker + deploy-verifier, then merge.
2. **Abort and revisit** (current state): leave queue pending, decide
   author/jurisdiction strategy later.
3. **Keep UK framing**: requires adding a real UK-registered nurse persona
   (real NMC credential) to `authors.json` first.
