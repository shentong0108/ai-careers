#!/usr/bin/env node
/**
 * Picks the next topic for the auto-content pipeline.
 *
 * Reads content-queue.json, rotates niches (nurse-ai → ece-ai → dev-diary → repeat),
 * picks the first unprocessed topic in the rotation's niche, marks it in-flight,
 * outputs { niche, slug, topic } JSON to stdout.
 *
 * Run by .github/workflows/auto-content.yml.
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

interface QueueEntry {
  niche: 'nurse-ai' | 'ece-ai' | 'dev-diary';
  slug: string;
  topic: string;
  anecdote?: string;
  status?: 'pending' | 'in-flight' | 'published';
  pickedAt?: string;
}

const QUEUE_PATH = join(process.cwd(), 'content-queue.json');
const ROTATION: QueueEntry['niche'][] = ['nurse-ai', 'ece-ai', 'dev-diary'];

function lastPublishedNiche(queue: QueueEntry[]): QueueEntry['niche'] | null {
  for (let i = queue.length - 1; i >= 0; i--) {
    if (queue[i].status === 'published' || queue[i].status === 'in-flight') {
      return queue[i].niche;
    }
  }
  return null;
}

function nextNiche(last: QueueEntry['niche'] | null): QueueEntry['niche'] {
  if (!last) return ROTATION[0];
  const idx = ROTATION.indexOf(last);
  return ROTATION[(idx + 1) % ROTATION.length];
}

function slugify(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60);
}

function main() {
  if (!existsSync(QUEUE_PATH)) {
    console.error('No content-queue.json. Create one with at least 5 pending entries per niche.');
    process.exit(1);
  }

  const queue: QueueEntry[] = JSON.parse(readFileSync(QUEUE_PATH, 'utf8'));
  const last = lastPublishedNiche(queue);
  const target = nextNiche(last);

  const pick = queue.find((e) => e.niche === target && (!e.status || e.status === 'pending'));
  if (!pick) {
    console.error(`Queue empty for niche "${target}". Add topics to content-queue.json.`);
    process.exit(2);
  }

  pick.status = 'in-flight';
  pick.pickedAt = new Date().toISOString();
  if (!pick.slug) pick.slug = slugify(pick.topic);

  writeFileSync(QUEUE_PATH, JSON.stringify(queue, null, 2) + '\n');

  process.stdout.write(JSON.stringify({ niche: pick.niche, slug: pick.slug, topic: pick.topic }) + '\n');
}

main();
