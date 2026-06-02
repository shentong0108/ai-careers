#!/usr/bin/env tsx
/**
 * lint-brand-leaks — HARD gate against reader-visible AI brand-name leaks.
 *
 * Why this exists: 2026-06-02's pipeline shipped "The Clinical Topic Where
 * AI Was a Year Behind" with 6 ChatGPT mentions across description /
 * keywords / H2 / body / Schema.org. The brand-neutrality rule existed in
 * content-writer.md but no automated check enforced it. Manual fixup
 * pre-publish is fragile.
 *
 * What it scans:
 *   - src/content/posts/<niche>/*.mdx (frontmatter + body)
 *   - src/pages/**\/*.astro (page templates that emit reader-visible text)
 *
 * What it ignores (by design):
 *   - HTML comments <!-- ... -->
 *   - MDX/JSX comments {/* ... *\/}
 *   - voicePolisherSamples lines (internal frontmatter, never rendered)
 *   - import statements (file paths under .claude/ may contain brand names)
 *   - lines that include the literal marker "affiliate-disclosure"
 *
 * Output: one error per leak with file:line and suggested replacement.
 * Exit non-zero if any leak found. Wired into `npm run build` so the
 * cron pipeline can never auto-merge a brand-leaking article.
 */

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const BLOCKLIST_FILE = join(REPO_ROOT, '.claude', 'brand-blocklist.txt');
const SCAN_GLOBS = [
  join(REPO_ROOT, 'src', 'content', 'posts'),
  join(REPO_ROOT, 'src', 'pages'),
];

interface Leak {
  file: string;
  line: number;
  brand: string;
  excerpt: string;
}

function loadBlocklist(): string[] {
  return readFileSync(BLOCKLIST_FILE, 'utf8')
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith('#'));
}

function walk(dir: string, exts: string[]): string[] {
  const out: string[] = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    const st = statSync(full);
    if (st.isDirectory()) out.push(...walk(full, exts));
    else if (exts.some((e) => entry.endsWith(e))) out.push(full);
  }
  return out;
}

function isIgnorableLine(line: string | undefined): boolean {
  if (!line) return true;
  // voicePolisherSamples line — internal audit trail, never rendered
  if (/^\s*voicePolisherSamples\s*:/.test(line)) return true;
  // mdx/JSX import statement
  if (/^\s*import\s+/.test(line)) return true;
  // HTML / MDX comment lines (heuristic — full-line comment)
  if (/^\s*<!--/.test(line) || /-->\s*$/.test(line.trim())) return true;
  if (/^\s*\{\/\*/.test(line) || /\*\/\}\s*$/.test(line.trim())) return true;
  // affiliate-disclosure block marker
  if (/affiliate-disclosure/i.test(line)) return true;
  return false;
}

function scanFile(file: string, brands: string[]): Leak[] {
  const leaks: Leak[] = [];
  const lines = readFileSync(file, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    if (raw === undefined) continue;
    if (isIgnorableLine(raw)) continue;
    for (const brand of brands) {
      // word-boundary regex, case-insensitive. "claude.ai" treated as token.
      const escaped = brand.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const re = new RegExp(`(^|[^a-zA-Z0-9-])${escaped}([^a-zA-Z0-9-]|$)`, 'i');
      if (re.test(raw)) {
        leaks.push({
          file: relative(REPO_ROOT, file),
          line: i + 1,
          brand,
          excerpt: raw.trim().slice(0, 140),
        });
      }
    }
  }
  return leaks;
}

const brands = loadBlocklist();
const files: string[] = [];
for (const dir of SCAN_GLOBS) {
  files.push(...walk(dir, ['.mdx', '.astro']));
}

const allLeaks: Leak[] = [];
for (const f of files) {
  allLeaks.push(...scanFile(f, brands));
}

if (allLeaks.length === 0) {
  console.log(`lint-brand-leaks: 0 leaks across ${files.length} files ✓`);
  process.exit(0);
}

console.error(`\n❌ lint-brand-leaks: ${allLeaks.length} brand-name leak${allLeaks.length === 1 ? '' : 's'} found:\n`);
for (const l of allLeaks) {
  console.error(`  ${l.file}:${l.line}  [${l.brand}]`);
  console.error(`    ${l.excerpt}`);
}
console.error(`\nFix: replace each occurrence with brand-neutral phrasing ("the AI", "an AI assistant", "the model"). See .claude/brand-blocklist.txt for full list.`);
process.exit(1);
