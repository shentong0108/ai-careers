# ai-careers — Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a fully automated AI-content blog at stonemegan.dev — Astro + Cloudflare Pages + GitHub Actions cron + Claude API agent pipeline + dashboard.

**Architecture:** Astro static site with MDX content collections. GitHub Actions cron every 2 days picks next topic from `content-queue.json`, runs the sub-agent pipeline (keyword → write → humanize → fact-check → SEO → verify), opens PR for human review. Merged main auto-deploys to Cloudflare Pages. Analytics pulled from Plausible + Cloudflare + GSC into `docs/dashboard/`.

**Tech Stack:** Astro 5, MDX, TypeScript strict, Cloudflare Pages, GitHub Actions, Anthropic SDK (claude-opus-4-7), Plausible, Cloudflare Web Analytics.

---

## File Structure (Already Created)

- `CLAUDE.md` — project rules
- `.claude/agents/*.md` — 7 sub-agent contracts (writer, humanizer, SEO, keyword, fact-checker, debugger, deploy-verifier, analytics-reader)
- `.claude/hooks/*.sh` — 5 hooks (prompt-injector, pre-edit-fix, pre-bash-guard, post-bash-log, stop-verify)
- `.claude/settings.json` — permissions + hooks wiring
- `.claude/commands/*.md` — slash commands (run-daily-ops, generate-article, watch-dashboard)
- `.claude/loop.md` — loop documentation
- `.github/workflows/auto-content.yml` — cloud cron
- `scripts/run-agent.ts` — universal sub-agent runner
- `scripts/pick-next-topic.ts` — content queue rotator
- `content-queue.json` — seed topics
- `src/content/config.ts` — Zod schema for posts
- `astro.config.mjs`, `tsconfig.json`, `package.json`

## File Structure (To Create In This Plan)

- `src/layouts/BaseLayout.astro`, `src/layouts/BlogPost.astro`
- `src/pages/index.astro`, `src/pages/blog/[...slug].astro`, `src/pages/[category]/index.astro`
- `src/pages/about.astro`, `src/pages/privacy.astro`, `src/pages/contact.astro`, `src/pages/disclaimer.astro`
- `src/components/Schema.astro`, `src/components/AuthorByline.astro`
- `scripts/detect-ai.ts`, `scripts/validate-frontmatter.ts`, `scripts/validate-jsonld.ts`, `scripts/fetch-analytics.ts`
- `tests/unit/pick-next-topic.test.ts`, `tests/unit/detect-ai.test.ts`
- `.eslintrc.json`, `.prettierrc.json`
- 3 seed articles (one per niche, written by Stone/Megan, NOT auto-generated — these are the human anchor posts)

---

## Task 1: Install Dependencies

**Files:**
- Verify: `package.json` exists
- Create: `pnpm-lock.yaml` (via install)

- [ ] **Step 1: Install pnpm if missing**

```bash
which pnpm || npm install -g pnpm@9
```

- [ ] **Step 2: Install dependencies**

```bash
cd "/Volumes/Studio work/blog-site"
pnpm install
```

Expected: `pnpm-lock.yaml` created, `node_modules/` populated, no errors.

- [ ] **Step 3: Verify TypeScript resolves**

```bash
pnpm exec tsc --noEmit
```

Expected: zero errors (or only "no input files" if no .ts files yet — acceptable).

- [ ] **Step 4: Commit**

```bash
git add package.json pnpm-lock.yaml
git commit -m "chore: install dependencies"
```

---

## Task 2: Base Layout + Homepage

**Files:**
- Create: `src/layouts/BaseLayout.astro`
- Create: `src/pages/index.astro`

- [ ] **Step 1: Write BaseLayout**

```astro
---
// src/layouts/BaseLayout.astro
export interface Props {
  title: string;
  description: string;
  canonical?: string;
  ogImage?: string;
}
const { title, description, canonical, ogImage = '/og-default.png' } = Astro.props;
const fullCanonical = canonical ?? new URL(Astro.url.pathname, Astro.site).toString();
---
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{title}</title>
    <meta name="description" content={description} />
    <link rel="canonical" href={fullCanonical} />
    <meta property="og:title" content={title} />
    <meta property="og:description" content={description} />
    <meta property="og:image" content={ogImage} />
    <meta property="og:type" content="website" />
    <meta property="og:url" content={fullCanonical} />
    <meta name="twitter:card" content="summary_large_image" />
    <link rel="sitemap" href="/sitemap-index.xml" />
  </head>
  <body>
    <header><nav><a href="/">ai-careers</a> · <a href="/nurse-ai">Nurse + AI</a> · <a href="/ece-ai">ECE + AI</a> · <a href="/dev-diary">Dev Diary</a></nav></header>
    <main><slot /></main>
    <footer><p>© stonemegan.dev · <a href="/about">About</a> · <a href="/privacy">Privacy</a> · <a href="/contact">Contact</a></p></footer>
  </body>
</html>
```

- [ ] **Step 2: Write homepage**

```astro
---
// src/pages/index.astro
import BaseLayout from '@/layouts/BaseLayout.astro';
import { getCollection } from 'astro:content';
const posts = (await getCollection('posts', ({ data }) => !data.draft))
  .sort((a, b) => b.data.publishedAt.valueOf() - a.data.publishedAt.valueOf())
  .slice(0, 10);
---
<BaseLayout title="ai-careers — nurse + ECE + AI" description="Real stories from a nurse and an ECT using AI in their jobs. No hype. Some failures.">
  <h1>What AI actually does in our jobs</h1>
  <p>Stone (nurse) and Megan (ECT) writing about AI tools we use day to day. Plus dev diary of building Aura app.</p>
  <ul>
    {posts.map((p) => (
      <li>
        <a href={`/blog/${p.slug}`}>{p.data.title}</a>
        <small>{p.data.category} · {p.data.publishedAt.toISOString().slice(0,10)}</small>
      </li>
    ))}
  </ul>
</BaseLayout>
```

- [ ] **Step 3: Run dev server, verify in browser**

```bash
pnpm dev
# open http://localhost:4321
```

Expected: homepage renders, nav links present, no errors in console.

- [ ] **Step 4: Commit**

```bash
git add src/
git commit -m "feat: base layout + homepage"
```

---

## Task 3: Blog Post Route + BlogPost Layout

**Files:**
- Create: `src/layouts/BlogPost.astro`
- Create: `src/pages/blog/[...slug].astro`
- Create: `src/components/AuthorByline.astro`
- Create: `src/components/Schema.astro`

- [ ] **Step 1: AuthorByline component**

Read `.claude/authors.json` at build time, render byline with credential + sameAs links.

```astro
---
// src/components/AuthorByline.astro
import authors from '../../.claude/authors.json';
const { authorKey } = Astro.props as { authorKey: 'stone' | 'megan' };
const a = authors[authorKey];
---
<div class="byline">
  <img src={a.image} alt={a.name} width="48" height="48" />
  <div>
    <p><strong>{a.name}</strong> · {a.jobTitle}</p>
    <p><small>{a.credential}</small></p>
  </div>
</div>
```

- [ ] **Step 2: Schema component (JSON-LD)**

```astro
---
// src/components/Schema.astro
const { type, data } = Astro.props as { type: string; data: Record<string, unknown> };
const ld = { '@context': 'https://schema.org', '@type': type, ...data };
---
<script type="application/ld+json" set:html={JSON.stringify(ld)} />
```

- [ ] **Step 3: BlogPost layout**

```astro
---
// src/layouts/BlogPost.astro
import BaseLayout from './BaseLayout.astro';
import AuthorByline from '@/components/AuthorByline.astro';
import Schema from '@/components/Schema.astro';
import authorsJson from '../../.claude/authors.json';
import type { CollectionEntry } from 'astro:content';

export interface Props { entry: CollectionEntry<'posts'> }
const { entry } = Astro.props;
const { Content } = await entry.render();
const fm = entry.data;
const author = authorsJson[fm.author];
---
<BaseLayout title={fm.title} description={fm.description} canonical={fm.canonical} ogImage={fm.ogImage ?? fm.heroImage}>
  <article>
    <h1>{fm.title}</h1>
    <AuthorByline authorKey={fm.author} />
    <time datetime={fm.publishedAt.toISOString()}>{fm.publishedAt.toISOString().slice(0,10)}</time>
    <img src={fm.heroImage} alt={fm.title} />
    <Content />
  </article>
  <Schema type="Article" data={{
    headline: fm.title,
    description: fm.description,
    datePublished: fm.publishedAt.toISOString(),
    dateModified: fm.updatedAt.toISOString(),
    image: fm.heroImage,
    author: { '@type': 'Person', name: author.name, jobTitle: author.jobTitle, url: author.url, sameAs: author.sameAs },
    publisher: { '@type': 'Organization', name: 'stonemegan.dev', logo: { '@type': 'ImageObject', url: '/logo.png' } }
  }} />
</BaseLayout>
```

- [ ] **Step 4: Dynamic route**

```astro
---
// src/pages/blog/[...slug].astro
import { getCollection } from 'astro:content';
import BlogPost from '@/layouts/BlogPost.astro';

export async function getStaticPaths() {
  const posts = await getCollection('posts', ({ data }) => !data.draft);
  return posts.map((p) => ({ params: { slug: p.slug }, props: { entry: p } }));
}

const { entry } = Astro.props;
---
<BlogPost entry={entry} />
```

- [ ] **Step 5: Build verification**

```bash
pnpm build
```

Expected: build passes. Empty collection OK (no posts yet).

- [ ] **Step 6: Commit**

```bash
git add src/
git commit -m "feat: blog post route + layout with schema"
```

---

## Task 4: AdSense Required Pages

**Files:**
- Create: `src/pages/about.astro`, `src/pages/privacy.astro`, `src/pages/contact.astro`, `src/pages/disclaimer.astro`

- [ ] **Step 1: about.astro** — Stone + Megan bios (real, not AI-generated). Credentials.
- [ ] **Step 2: privacy.astro** — mention Google AdSense, Plausible, Cloudflare Analytics + opt-out links. Use a real privacy template (link `iubenda` or `termly` later).
- [ ] **Step 3: contact.astro** — email form (Cloudflare Pages Forms or Formspree) or just `mailto:`.
- [ ] **Step 4: disclaimer.astro** — "not medical advice", "personal experience", affiliate disclosure.
- [ ] **Step 5: Commit**

```bash
git add src/pages/
git commit -m "feat: AdSense-required pages (about/privacy/contact/disclaimer)"
```

---

## Task 5: Three Human-Written Seed Articles

These are NOT auto-generated. They establish voice + topical authority + AdSense approval signal. Stone writes 1, Megan writes 2.

**Files:**
- Create: `src/content/posts/dev-diary/aura-week-1-claude-code.mdx`
- Create: `src/content/posts/nurse-ai/handoff-notes-with-claude.mdx`
- Create: `src/content/posts/ece-ai/parent-newsletter-claude-iteration.mdx`

- [ ] **Step 1-3: Write each article** — real anecdote, 1500-2000 words, 2+ citations, frontmatter complete, schema valid.
- [ ] **Step 4: Add hero images** to `public/images/`.
- [ ] **Step 5: Build + check**

```bash
pnpm build
pnpm exec linkinator dist --silent
```

- [ ] **Step 6: Commit**

```bash
git add src/content/ public/images/
git commit -m "content: 3 human-written seed articles"
```

---

## Task 6: Detection + Validation Helper Scripts

**Files:**
- Create: `scripts/detect-ai.ts`, `scripts/validate-frontmatter.ts`, `scripts/validate-jsonld.ts`
- Create: `tests/unit/pick-next-topic.test.ts`

- [ ] **Step 1: Write failing test for pick-next-topic rotation**

```ts
// tests/unit/pick-next-topic.test.ts
import { describe, it, expect } from 'vitest';
// will test the rotation logic — refactor pick-next-topic to export pure functions
```

- [ ] **Step 2: Refactor `pick-next-topic.ts` to export `nextNiche()` + `lastPublishedNiche()`** (currently they're internal). Add test imports. Run test — verify passes.

- [ ] **Step 3: `detect-ai.ts`** — calls ZeroGPT API, outputs JSON `{ score: number, perParagraph: {idx,score}[] }`.

- [ ] **Step 4: `validate-frontmatter.ts`** — runs Zod schema against any MDX file. CLI: `node scripts/validate-frontmatter.ts <file>`. Exits non-zero on schema fail.

- [ ] **Step 5: `validate-jsonld.ts`** — parses `<script type="application/ld+json">` from built HTML, validates against schema.org via `schema-dts` types.

- [ ] **Step 6: Run all tests**

```bash
pnpm test
```

- [ ] **Step 7: Commit**

```bash
git add scripts/ tests/
git commit -m "feat: AI-detection + frontmatter validation scripts"
```

---

## Task 7: GitHub Repo + Cloudflare Pages

**Files:** none new, configuration only.

- [ ] **Step 1: Create GitHub public repo**

```bash
gh repo create ai-careers --public --source=. --remote=origin --description="nurse + ECE + AI blog at stonemegan.dev"
git push -u origin main
```

- [ ] **Step 2: Add GH secrets**

```bash
gh secret set ANTHROPIC_API_KEY < /dev/stdin    # paste key
gh secret set ZEROGPT_API_KEY < /dev/stdin
# repeat for PLAUSIBLE_API_KEY, GSC_SERVICE_ACCOUNT, CF_ANALYTICS_TOKEN, CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID
```

- [ ] **Step 3: Cloudflare Pages — connect repo**

UI step: dash.cloudflare.com → Pages → Create → Connect to Git → pick `ai-careers` → build command `pnpm build` → output `dist` → save.

- [ ] **Step 4: Point stonemegan.dev DNS at Cloudflare Pages**

UI step (Cloudflare DNS): add CNAME `stonemegan.dev` → `<project>.pages.dev` (or use full Cloudflare nameservers if registered with CF).

- [ ] **Step 5: Verify production deploy**

```bash
curl -I https://stonemegan.dev
```

Expected: HTTP 200, served from CF.

---

## Task 8: First Cron Run (Smoke Test)

- [ ] **Step 1: Manually trigger workflow**

```bash
gh workflow run auto-content.yml -f niche=dev-diary
```

- [ ] **Step 2: Watch run**

```bash
gh run watch
```

Expected: pipeline completes, PR opened under `auto/<slug>`.

- [ ] **Step 3: Review PR manually** — verify article quality, schema, AI-detection score in frontmatter.

- [ ] **Step 4: Iterate** on agent prompts in `.claude/agents/*.md` if quality is off. Re-run.

---

## Task 9: Analytics + Search Console

- [ ] **Step 1: Sign up Plausible**, add stonemegan.dev, copy site ID.
- [ ] **Step 2: Add Plausible script** to `BaseLayout.astro` `<head>`.
- [ ] **Step 3: Enable Cloudflare Web Analytics** in CF dash.
- [ ] **Step 4: Submit sitemap to Google Search Console** — `https://stonemegan.dev/sitemap-index.xml`.
- [ ] **Step 5: Submit to Bing Webmaster Tools**.

---

## Task 10: AdSense Application

Pre-req: ≥15 published articles, all required pages present, 30+ days domain age.

- [ ] **Step 1: Apply at google.com/adsense.**
- [ ] **Step 2: Wait 1-4 weeks.** Don't refresh obsessively.
- [ ] **Step 3: Once approved, add ad unit code** to `BaseLayout.astro` (one in-article, one sidebar). Use `<ins class="adsbygoogle">`.

---

## Self-Review Checklist

- [ ] Every spec requirement (auto every 2 days, dashboard, SEO, revenue) covered by a task above.
- [ ] No placeholders, TODOs, or "TBD" — every step has executable content.
- [ ] Frontmatter schema in `src/content/config.ts` matches what `content-writer` agent writes.
- [ ] Each sub-agent has `.md` contract under `.claude/agents/`.
- [ ] Hook scripts executable.
- [ ] Root-cause-before-fix enforced by `pre-edit-fix.sh` for fix/* branches.
- [ ] Deploy gated by `deploy-verifier` receipt via `pre-bash-guard.sh`.

---

## Execution

**Recommendation:** Inline execution for Task 1 (deps + lockfile — fast, must precede everything). Subagent-driven for Tasks 2-6 (parallel-friendly). User-driven for Tasks 7-10 (require credentials + UI clicks).
