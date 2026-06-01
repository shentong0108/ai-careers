# Next actions — Stone, 2026-06-01

Three things blocking faster site growth. Tackle in this order.

---

## 1. Enable Plausible public dashboard (60 seconds)

Why: weekly analytics report (`docs/marketing/weekly-analytics/*.md`) can autofill
Q1 (top source), Q2 (top entry page), and Q4 (highest-bounce page) once Plausible is
public. Right now the agent gets a 404 because the dashboard is private.

Steps:

1. Go to https://plausible.io/sites
2. Click **stonemegan.dev**
3. Top-right gear icon → **Site Settings**
4. Left sidebar → **Visibility**
5. Toggle **Public dashboard** to ON
6. Copy the share link (looks like `https://plausible.io/share/stonemegan.dev?auth=<token>`)
7. Paste the share link in `.env`:

```
PLAUSIBLE_PUBLIC_URL=https://plausible.io/share/stonemegan.dev?auth=<token>
```

Once set, the next Monday-9am analytics cron picks it up and prefills Q1/Q2/Q4.

Alternative if you'd rather not make stats public: provision a `PLAUSIBLE_API_KEY`
(Plausible account → API keys → Create key → paste into `.env`). Slightly more setup,
same autofill outcome.

---

## 2. Refill content-queue (queue starves ~2026-06-03)

Current state: 2 pending entries left (1 nurse-ai, 1 ece-ai), 0 dev-diary. Cron
runs daily at 7am; you'll get 2 more articles then we hit empty.

Candidates below are ordered by SEO + cross-link leverage. **Pick the ones that ring
true and add an anecdote.** Topics without anecdotes generate skeleton drafts (the
pipeline tags them `needs-anecdote`, keeps `draft: true`, leaves `[NEEDS ANECDOTE —
...]` markers in the body for you to fill before they go live).

### nurse-ai candidates (pick 2-3)

| # | Topic angle | SEO rationale | Anecdote slot |
|---|---|---|---|
| N1 | The one prompt change that made AI handouts safer for low-literacy patients | Long-tail off your existing patient-education post; teaches teach-back specifically | "I tested teach-back on a patient and what came back" |
| N2 | What I check on every AI-drafted note before the GP signs it | High intent for primary-care RNs; cross-links to handoff-notes article | "The line I almost missed and why I now have a checklist" |
| N3 | When AI summarised a patient note wrong — and how I caught it | YMYL safety angle; ranks well, cites real near-miss | "Specific note, specific summary error, specific catch" |
| N4 | Patient-facing AI tools nurses get asked about — what I actually say | Conversational; quote-worthy in newsletters | "A patient asked me about a chatbot at clinic on [day]" |

### ece-ai candidates (pick 2-3)

| # | Topic angle | SEO rationale | Anecdote slot |
|---|---|---|---|
| E1 | Drafting EYLF learning stories with AI — the structure I keep, the voice I rewrite | Highly searched; EYLF is AU-specific so low-comp | "A specific story you redrafted — what AI did well, what you rewrote" |
| E2 | AI for parent comms in a 0-2 room — what changes when families don't read English at home | Strong AU/NZ niche; almost zero competition | "A family situation where translation + AI had to work together" |
| E3 | The observation an AI couldn't help me write (and why) | Counter-niche post; pairs with N3 for cross-link | "A specific child moment that wouldn't fit any AI prompt" |
| E4 | OWNA / Storypark templates I use AI alongside (not inside) | Affiliate-adjacent; AU platform names readers search | "A template you actually use weekly" |

### dev-diary candidates (pick 1-2)

| # | Topic angle | SEO rationale | Anecdote slot |
|---|---|---|---|
| D1 | The first time the AI coding tool lied to me about an API surface | Conversational, shareable on HN/Reddit | "Specific function/library + how you found the lie" |
| D2 | What I throw away after a week of AI-assisted coding (and why) | Reflective, evergreen | "A specific feature or file deleted last week" |
| D3 | Aura week 3 — the bug I couldn't even describe to the AI | Continues your existing Aura series | "Specific bug + what made it indescribable" |

---

## 3. SEO + mobile bucket already in flight

Iter 20 (next) will tackle: sitemap audit (hreflang for UK/AU/NZ split-locale),
robots.txt review, footer mobile-stack check, plus any low-cost mobile-reading gaps
still open. Continuing the /loop without you needing to authorise per-iter.

---

## How to add a queue entry once you have an anecdote

Edit `content-queue.json` — append an object like:

```json
{
  "niche": "nurse-ai",
  "author": "stone",
  "topic": "What I check on every AI-drafted note before the GP signs it",
  "anecdote": "On Tuesday a draft note was missing the patient's allergy disclosure. I now have a five-point checklist I scan before the doctor sees it.",
  "status": "pending"
}
```

That's it. The 7am cron picks it up at the next run. Niche author binding:
`nurse-ai` → `stone`, `ece-ai` → `megan`, `dev-diary` → `stone`. Never cross-wire.
