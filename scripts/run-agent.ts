#!/usr/bin/env node
/**
 * Universal sub-agent runner.
 *
 * Reads .claude/agents/<name>.md (the agent's constraint contract),
 * sends to Claude API as system prompt + user task,
 * captures structured receipt to .claude/cache/<name>-latest.txt,
 * exits non-zero on agent block / verification fail.
 *
 * Usage:
 *   node scripts/run-agent.ts <agent-name> [--key=value ...]
 *
 * Examples:
 *   node scripts/run-agent.ts keyword-researcher --niche=nurse-ai --topic="..."
 *   node scripts/run-agent.ts content-writer --niche=nurse-ai --slug=handoff-notes
 *   node scripts/run-agent.ts deploy-verifier --branch=auto/foo --articles=src/...
 */

import Anthropic from '@anthropic-ai/sdk';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const MODEL = 'claude-opus-4-7';
const PROJECT_ROOT = process.cwd();
const AGENTS_DIR = join(PROJECT_ROOT, '.claude/agents');
const CACHE_DIR = join(PROJECT_ROOT, '.claude/cache');

function parseArgs(argv: string[]): { agentName: string; params: Record<string, string> } {
  const agentName = argv[2];
  if (!agentName) {
    console.error('Usage: run-agent.ts <agent-name> [--key=value ...]');
    process.exit(64);
  }
  const params: Record<string, string> = {};
  for (const arg of argv.slice(3)) {
    const match = arg.match(/^--([^=]+)=(.*)$/);
    if (match) params[match[1]] = match[2];
  }
  return { agentName, params };
}

function loadAgentContract(name: string): string {
  const path = join(AGENTS_DIR, `${name}.md`);
  if (!existsSync(path)) {
    console.error(`No agent contract at ${path}.`);
    console.error('Every sub-agent must have a .md file under .claude/agents/.');
    process.exit(65);
  }
  return readFileSync(path, 'utf8');
}

async function runAgent(agentName: string, params: Record<string, string>): Promise<string> {
  const contract = loadAgentContract(agentName);
  const client = new Anthropic();

  const systemPrompt = `You are the "${agentName}" sub-agent for the ai-careers project. Read and strictly follow the contract below. Refuse out-of-scope work. Return the structured receipt format defined at the bottom of the contract.\n\n--- CONTRACT ---\n${contract}\n--- END CONTRACT ---`;

  const userPrompt = `Run with these inputs:\n${JSON.stringify(params, null, 2)}\n\nExecute the workflow defined in the contract. Run the verification block before returning. Output the receipt.`;

  const response = await client.messages.create({
    model: MODEL,
    max_tokens: 8000,
    system: systemPrompt,
    messages: [{ role: 'user', content: userPrompt }],
  });

  const text = response.content
    .filter((b): b is Anthropic.TextBlock => b.type === 'text')
    .map((b) => b.text)
    .join('\n');

  return text;
}

function saveReceipt(agentName: string, receipt: string): void {
  mkdirSync(CACHE_DIR, { recursive: true });
  const path = join(CACHE_DIR, `${agentName}-latest.txt`);
  writeFileSync(path, receipt);
}

function checkBlocked(receipt: string): boolean {
  return /status:\s*blocked/i.test(receipt);
}

async function main() {
  const { agentName, params } = parseArgs(process.argv);
  console.log(`[run-agent] dispatching ${agentName}…`);

  const receipt = await runAgent(agentName, params);
  saveReceipt(agentName, receipt);

  console.log(receipt);

  if (checkBlocked(receipt)) {
    console.error(`[run-agent] ${agentName} returned status: blocked`);
    process.exit(1);
  }
  console.log(`[run-agent] ${agentName} OK`);
}

main().catch((err) => {
  console.error('[run-agent] fatal:', err);
  process.exit(2);
});
