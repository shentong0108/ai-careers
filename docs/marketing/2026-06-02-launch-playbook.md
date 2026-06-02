# Launch promotion playbook — stonemegan.dev

Five concrete moves to get the first 100-1000 readers. Pick 1-2 per week. Each one is **copy-paste + go**, no thinking required.

The base URL we're driving traffic to: `https://stonemegan.dev`.

---

## 1. Hacker News — Show HN (one-shot, highest ceiling)

Best vehicle: a dev-diary post. HN audience loves transparent indie-dev failure stories. One front-page hit = 2,000-20,000 visitors in 24h. Risk: zero (if it flops, nothing happens; if it pops, free traffic).

**When to post:** Tuesday or Wednesday, 09:00-11:00 US Pacific (= Wednesday 02:00-04:00 AEST, OR Thursday for Australia daytime). Aim for the Australian morning post = US evening readership.

**URL to submit:** https://news.ycombinator.com/submit

**Title (under 80 chars):**
```
Show HN: I rebuilt my Sydney nursing clinic's notes with an AI tool — what failed
```

OR

```
Show HN: 2 weeks of AI-pair-programming as a nurse-turned-indie-dev
```

**URL field:** https://stonemegan.dev/blog/aura-week-1-with-an-ai-coding-tool

**Text (only if "ask" type, skip if you submitted URL):** leave blank.

After posting: do NOT ask for upvotes. Reply to first 3-5 comments within an hour (HN ranks comment activity heavily).

---

## 2. Reddit — niche subs, real comments first

Reddit bans link-droppers. The pattern that works: **build karma by answering 5-10 real questions in target subs FIRST**, then your eventual post lands without being filtered as spam.

**Target subs (in order of fit):**

| Sub | Best article to share | Why |
|---|---|---|
| r/nursing (350k) | `/blog/ai-assisted-nursing-handoff-notes` | RNs hungry for AI-tooling reality from peers |
| r/AustralianNursing (smaller, very engaged) | any nurse-ai | AHPRA-specific framing = native |
| r/EarlyChildhoodEducation | `/blog/ai-parent-newsletter-iteration` | ECT-specific AI use case is rare |
| r/indiehackers | `/blog/aura-week-1-with-an-ai-coding-tool` | Failure stories perform well |
| r/learnprogramming | `/blog/why-i-killed-my-first-nurse-tooling-project-before-i-wrote-a` | Privacy-driven-product-kill story |
| r/AskAcademia (if ECT angle) | EYLF article (next) | AU education + AI |

**Submission title template (Reddit hates clickbait):**

```
I'm an AHPRA-registered RN — wrote up the 4 things I check before any AI-drafted note gets in the record. Wanted to share in case it helps anyone else who has gotten burned by an AI summary.
```

(Notice: no "I wrote a blog post" framing. Just the substance + the link in a comment if asked, OR in the body as a sub-link.)

**Body pattern:**
- 2-3 sentences of the actual story (the near-miss)
- 4-5 short bullet checklist
- One line: "Wrote it up in detail here if it's useful: [link]"
- One line: "Curious what other primary-care nurses actually check — would love a sanity check."

This is **content first, link second**. Reddit upvotes substance.

---

## 3. LinkedIn — Stone's personal post, 1× per week

LinkedIn rewards original-voice posts from real practitioners with credentials. AHPRA-registered Sydney RN is an unusually scarce voice in the AI-in-nursing conversation. Even with a small following you can hit 1,000-10,000 impressions per post if it ships at the right moment.

**Cadence:** Sunday 19:00-21:00 AEST (Monday morning AU/UK feed).

**Template per post:**

```
Three years ago I would have laughed if you told me I'd be drafting clinical notes with an AI assistant.

This week I almost signed an iron-infusion record that the AI summarised without the batch number. Caught it on cross-check.

Here's the 4-point checklist I now run on every AI-drafted clinical note before it goes anywhere near a patient record:

1. Identifiers verified (name, DOB, MRN)
2. Drug-specific data complete (batch, expiry, dose, lot)
3. Timestamps right (when ≠ when documented)
4. What-was-done vs what-was-planned

The AI's structure is fast. The safety net is still mine to weave.

Wrote it up in full → stonemegan.dev/blog/...

#AHPRA #PrimaryCare #AIinNursing
```

(Replace with the article you're actually promoting that week.)

**Engagement booster:** post the link in the FIRST COMMENT, not in the post body — LinkedIn deboost external-link posts. Keep links in comments.

---

## 4. Beehiiv Boosts — paid newsletter swap ($)

Once you have 50+ subscribers, enroll in Beehiiv's Boost marketplace. You pay $0.50-1.50 per net new subscriber. For a $50-100 budget: 50-200 subscribers in 1-2 weeks. These are higher quality than Reddit/HN drive-bys because they opted into your specific niche.

**Setup:** Beehiiv dashboard → Grow → Boosts → Create campaign. Target: AU/UK/NZ, interests "Healthcare" / "Education" / "AI tools".

**When to start:** after you cross 50 subs organically (first 50 must be authentic — Beehiiv's algorithm checks engagement before allowing Boosts).

---

## 5. Direct outreach — 5 people who would actually share it

This always outperforms shotgun social.

**Who:**
1. Any RN/ECT colleague who knows what an AI tool is. Send them ONE specific article via DM/email with: "I'd love your eyes on this — am I missing anything? You'd know better than me." (Activates them as a reviewer, not a promoter — but they'll often share if it's good.)
2. Any indie-dev friend who blogs/X-posts. "Spent a week stripping AI brand names out of my blog after launch — wrote it up. Curious if you've thought about this differently." Article: `/blog/why-i-stripped-every-ai-brand-name-out-of-my-own-blog-after-`.
3. An AHPRA-registered nurse-influencer (look on Instagram or LinkedIn for #AHPRA, #PrimaryCareNursing).
4. An ACECQA ECT in your network.
5. A friend who works in healthcare-adjacent ML / AI-safety.

**Pattern:** specific article (matched to their interest), one specific question they're qualified to answer, no ask to share.

People share things they feel ownership over. Asking their opinion creates a tiny stake.

---

## What NOT to do (anti-spam-trap)

- ❌ Drop links in dozens of subs without comment context — gets you shadowbanned in 48h
- ❌ Submit your own articles to HN repeatedly (rate-limit kicks in fast)
- ❌ Buy traffic from Fiverr / cheap traffic services — Plausible will show real numbers but AdSense reviewers can see "bot signature" and reject you
- ❌ Email RN colleagues a cold pitch with "subscribe here" — that's the colleague-burning move
- ❌ Post in /r/AdSense or "AdSense approval tips" subs — those are full of low-quality reviewers gaming each other

---

## Tracking what works

Plausible already segments by referrer. Check **Sources** tab (now public per iter 26):
https://plausible.io/stonemegan.dev?period=7d

If a Reddit post lands: source shows "reddit.com".
If HN front-pages: source shows "news.ycombinator.com" with a visible visitor spike.
If LinkedIn pulls: source shows "lnkd.in" or "linkedin.com".

Whatever surfaces non-Direct = double down on next week.

---

## This week's specific pick

You're 5 days in with 14 pending articles + AdSense in review. Don't try all 5 moves at once. **Pick 1:**

1. **Recommended now:** LinkedIn post (#3). Lowest effort, highest brand-building value for a credentialed practitioner. Stone's existing LinkedIn (if any) is the natural surface.
2. If you have 30 min: Reddit comment-and-build-karma in r/nursing or r/EarlyChildhoodEducation. Don't post a link yet — just be useful in 3 threads. The post comes next week.
3. Don't do HN yet — wait until article #15-20 ships so the homepage doesn't look thin if 1k people show up.
