#!/usr/bin/env node
/**
 * Queue janitor — revert silently-stalled in-flight entries to pending.
 *
 * Run BEFORE pick-next-topic in every cron/manual pipeline invocation.
 *
 * Why this exists:
 *   pick-next-topic flips an entry to status=in-flight + writes pickedAt.
 *   If the pipeline then dies for any reason (process killed, OS reboot,
 *   network outage, claude -p 400 mid-run, user Ctrl+C the launchd job),
 *   the entry stays in-flight forever and blocks rotation. There's no
 *   shell signal-trap reliable enough to clean up across all kill paths
 *   (SIGKILL bypasses traps; the user kill of a launchd job via the UI
 *   is SIGKILL).
 *
 *   This script is the reliable cleanup: scan for in-flight older than
 *   the stale threshold and demote them back to pending. The next
 *   pick-next-topic call will then re-pick them in the normal rotation.
 *
 * Threshold:
 *   A real pipeline run takes 15–45 minutes end to end. 90 minutes is
 *   a safe stale-marker: long enough not to interrupt a slow-but-still-
 *   running pipeline, short enough that a killed pipeline is recovered
 *   before the next 24h cron cycle.
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

interface QueueEntry {
  niche: 'nurse-ai' | 'ece-ai' | 'dev-diary';
  slug?: string;
  topic: string;
  status?: 'pending' | 'in-flight' | 'published';
  pickedAt?: string;
}

const QUEUE_PATH = join(process.cwd(), 'content-queue.json');
const STALE_MINUTES = 90;

function main() {
  if (!existsSync(QUEUE_PATH)) {
    process.exit(0);
  }

  const queue: QueueEntry[] = JSON.parse(readFileSync(QUEUE_PATH, 'utf8'));
  const now = Date.now();
  const cutoff = now - STALE_MINUTES * 60 * 1000;
  const reverted: string[] = [];

  for (const entry of queue) {
    if (entry.status !== 'in-flight') continue;
    if (!entry.pickedAt) {
      // in-flight with no pickedAt is malformed — clear it
      entry.status = 'pending';
      reverted.push(`(no pickedAt) "${entry.topic.slice(0, 60)}"`);
      continue;
    }
    const pickedMs = new Date(entry.pickedAt).getTime();
    if (Number.isNaN(pickedMs)) {
      entry.status = 'pending';
      delete entry.pickedAt;
      reverted.push(`(bad date) "${entry.topic.slice(0, 60)}"`);
      continue;
    }
    if (pickedMs < cutoff) {
      const ageMin = Math.round((now - pickedMs) / 60000);
      entry.status = 'pending';
      delete entry.pickedAt;
      // keep slug — if pick-next-topic re-picks this, the slug carries over
      reverted.push(`(${ageMin}min stale) "${entry.topic.slice(0, 60)}"`);
    }
  }

  if (reverted.length > 0) {
    writeFileSync(QUEUE_PATH, JSON.stringify(queue, null, 2) + '\n');
    console.error(`queue-janitor: reverted ${reverted.length} stalled in-flight entr${reverted.length === 1 ? 'y' : 'ies'}:`);
    for (const r of reverted) console.error(`  - ${r}`);
  } else {
    console.error('queue-janitor: no stalled entries');
  }
}

main();
