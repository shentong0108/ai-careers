# Reddit launch-week posts

Three drafts, one per subreddit. Post each on a **different day** (spread
the bandwidth so mods don't pattern-match this as a coordinated drop).

## UTM convention

Every outbound link uses UTM params so Beehiiv attribution.js tags
new subscribers by source. Convention:

| Param | Value |
|---|---|
| `utm_source` | `reddit` (channel family) |
| `utm_medium` | `social` |
| `utm_campaign` | `launch-<sub>` — `launch-sidep`, `launch-nursing`, `launch-ece` |

After a post lands, check Beehiiv → Audience → Subscribers → filter
by `utm_campaign` to see exactly which sub converted readers to
subscribers. Without this you cannot distinguish a Reddit subscriber
from a direct-traffic one.

For future channels: keep `utm_source` semantic (`reddit`, `hn`,
`twitter`, `newsletter-swap`) and put the specific origin in
`utm_campaign` (`launch-sidep`, `show-hn-2026-06-02`,
`swap-with-<other-newsletter>`).

## Anti-spam rules every Reddit promo MUST follow

1. **Lead with the lesson, not the URL.** The post body must be useful
   even if the reader never clicks through.
2. **Self-link only if rules allow.** Check each sub's wiki for a
   self-promotion policy. Some require 9:1 (nine non-promo
   contributions for every one self-promo).
3. **Disclose.** First-time poster + own-blog link → say so in the
   body. Pretending to be a neutral reader is the fastest ban path.
4. **Reply for 24h.** If the post lands, mods judge engagement.
   Schedule the post for a time you can sit on comments for the
   first day.

---

## Post 1 — r/nursing (Stone)

**Subreddit**: r/nursing (1.6M members, US-heavy but AU/UK welcome)
**Best window**: Tue-Thu 7-9pm EST (peak US shift change)
**Account requirement**: 30+ days old, 100+ comment karma. If new
account, post in r/auscare or r/AusNursing first to build karma.
**Self-promo rule**: r/nursing allows links if discussion is the
primary point. Put the blog link in a comment, not the body.

### Title

How I decide whether the AI is safe to use on a clinical task (a 3-question test that has saved me twice)

### Body

I'm an AHPRA-registered RN in Sydney primary care. I started using an
AI assistant about 6 months ago for documentation and patient handout
drafting. After two near-misses I built a 3-question rule I run in my
head before letting the model touch anything.

**1. Would a missing detail change clinical management?**

If yes → I write it myself, full stop. The AI is allowed to draft
patient education, post-procedure handouts, chronic disease
literacy — but not anything where omission of a single detail
(batch number on an iron infusion record, allergy on a med chart,
red-flag warning on a wound discharge sheet) changes what someone
does next.

**2. Is this evergreen clinical guidance, or moves year to year?**

The most dangerous AI use I've found is asking it for stepwise
management of common conditions. Asked for asthma stepwise and got
a SABA-only pathway — that was current 5 years ago, not now (GINA
2024 / Australian Asthma Handbook both lead with anti-inflammatory
reliever). Anything in this bucket gets cross-checked against the
current Australian source before I touch it.

**3. Am I at the bedside in the first 5 minutes of something acute?**

If yes, the AI doesn't exist. Pulling ECG leads onto a chest-pain
walk-in is 10x faster than typing a prompt. The AI lives in the
documentation and patient-education layers, not at the bedside.

Curious whether other nurses here have a similar rule, and what
your specific near-misses have been. The two that shaped mine:
the asthma one above, and a draft handout that omitted "return
immediately if dressing shows heavy bleeding" on a wound care
sheet — caught in cross-read.

### Comment-1 (top reply from yourself, where the link lives)

I've been writing the longer version of these as a small blog over
the past couple of weeks — happy to share the link if anyone wants
it, but the rule above is the whole gist of it.

(If a commenter asks → reply with link: https://stonemegan.dev/nurse-ai/?utm_source=reddit&utm_medium=social&utm_campaign=launch-nursing)

---

## Post 2 — r/ECEProfessionals (Megan)

**Subreddit**: r/ECEProfessionals (47k members, ECE educators
worldwide; AU/UK/US/NZ mix)
**Best window**: Sun-Mon 7-9pm AEST (weekend planning, before
Monday rush)
**Self-promo rule**: Self-promo allowed if 90% of activity is
genuine discussion. Same rule: link in a comment, not the body.

### Title

The AI wrote "the child demonstrated emerging self-regulation strategies." What I had seen was a kid saying "you can have it after I count to five." How are you using AI for observations?

### Body

I'm an early childhood teacher in Sydney (ACECQA-registered, 5
years across baby/toddler/pre-school rooms). I tried using an AI
assistant for individual learning observations and deleted the
first three drafts.

The example that stuck with me: I asked it to write up a 4-year-old
who'd just resolved a peer conflict over a toy in outdoor play,
aligned to EYLF Outcome 1. The AI gave me:

> "The child demonstrated an emerging capacity for self-regulation
> and prosocial negotiation strategies."

What I had actually watched happen was: the child looked their
friend in the eye and said "you can have it after I count to
five," then counted on their fingers out loud.

The AI wrote the **conclusion**. The observation is the **moment**.

Where I've ended up:
- AI is fine for newsletter framing, parent communication tone
  smoothing, curriculum-planning brainstorm (5 angles → I pick
  the one tied to our actual yard)
- AI is not fine for observations, learning stories, or anything
  that goes into a child's portfolio in my name

What's working / not working for you? Particularly curious about
people using AI for EYLF Outcome alignment — I have not found a
prompt that produces something I'd actually file.

### Comment-1 (top reply from yourself)

If anyone wants the longer write-up with the actual prompts I
ended up using vs deleting, I've been collecting them on a small
blog: https://stonemegan.dev/ece-ai/?utm_source=reddit&utm_medium=social&utm_campaign=launch-ece — happy to share specific
prompts in this thread too.

---

## Post 3 — r/SideProject (Stone, dev-diary niche)

**Subreddit**: r/SideProject (340k members, indie dev culture)
**Best window**: Tue 8-10am PT (Show HN window, captures same
"morning coffee" audience)
**Self-promo rule**: Show HN-style posts welcomed. Link in body.

### Title

Show r/SideProject: I built an AI-content blog that auto-publishes daily — and the agent fabricated my co-author's credentials. What I changed.

### Body

Built a small Astro + Cloudflare Pages blog (stonemegan.dev) with
a sub-agent pipeline that auto-publishes one article a day via a
local launchd cron. The pipeline is six agents: keyword research →
content writer → humanizer → fact-checker → SEO optimizer → deploy
verifier.

Three days in, the content-writer agent invented a UK NMC-registered
nurse persona for a dev-diary article. The topic line said "nurse
tooling" and the agent inferred the wrong persona from surface
words — it relocated my actual co-author (an Australian early
childhood teacher) into a different country and a different
profession to fit the topic.

Two fixes that stopped the bleed:

1. **Explicit `author` field on every content-queue entry**, not
   inferred from the niche or topic. The author binding is now data,
   not a prompt-time judgment.
2. **HARD RULE section in the content-writer agent contract**
   forbidding persona inference from topic strings. "Author is X.
   Do not invent a different author, even if the topic surface
   words suggest one."

The post itself: https://stonemegan.dev/dev-diary/?utm_source=reddit&utm_medium=social&utm_campaign=launch-sidep

Stack: Astro + MDX, content collections with Zod schema, Cloudflare
Pages, macOS launchd (not GitHub Actions — runs on Claude Code
subscription quota instead of API credits). Anonymous authors
because the day-job constraints don't allow attaching a real name
to AI-experimentation posts.

Happy to share the agent contracts or the pipeline shape if anyone
wants to copy the structure. The biggest lesson is the one above:
when you let an agent infer a persona from a topic, it will, and
the result is fluent and wrong.

### Comment-1

(Wait for comments before adding anything — Show r/SideProject lands
better when the OP isn't seen pushing the link further.)

---

## Posting schedule (suggested)

| Day | Sub | Post | Why this day |
|---|---|---|---|
| Tue | r/SideProject | Post 3 | Tue 8-10am PT = peak dev attention |
| Wed | r/nursing | Post 1 | Mid-week, US shift change peak |
| Sun (next) | r/ECEProfessionals | Post 2 | Sunday planning window for educators |

Space out by 24-48h. Posting all three same day = pattern-recognised
by Reddit's anti-spam fingerprinting (same IP, same posting cadence,
same outbound domain) → throttled or removed.

## What success looks like

| Metric | Day-1 | Week-1 |
|---|---|---|
| Upvotes | ≥10 | ≥30 |
| Comments | ≥3 substantive | ≥10 |
| Plausible referrals | ≥20 from reddit.com | ≥100 |
| Subscribes | ≥1 | ≥5 |

If a post is removed by mods: don't argue, don't repost. Read the
sub's wiki for what triggered it (usually account-age + karma) and
build karma in the sub for 2-4 weeks before trying again with a
different angle.
