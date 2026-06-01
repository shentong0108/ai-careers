#!/usr/bin/env node
// gsc-query.mjs — fetch top GSC queries for stonemegan.dev (last N days).
//
// Why: the Monday weekly-analytics cron wants to autofill Q3 (top
// search queries by impressions). GSC's Search Analytics API is the
// source. This script:
//   1. Reads .gsc-service-account.json at repo root
//   2. Signs an RS256 JWT (no external deps — Node crypto)
//   3. Exchanges JWT for an OAuth access token
//   4. POSTs to searchAnalytics/query
//   5. Prints the top queries as JSON
//
// Output: JSON to stdout, suitable for jq parsing.
// On error (no key file, GSC permission missing, API failure): prints
// {"error":"<reason>"} and exits non-zero so the caller can fall back
// to the manual-fill template.
//
// Usage: node scripts/lib/gsc-query.mjs [--days 7] [--limit 5]

import { readFileSync, existsSync } from 'node:fs';
import { createSign } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

// fileURLToPath decodes %20 etc — the repo root has a space in its path.
const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const SA_KEY_FILE = `${REPO_ROOT}/.gsc-service-account.json`;
const OAUTH_CLIENT_FILE = `${REPO_ROOT}/.gsc-oauth-client.json`;
const ENV_FILE = `${REPO_ROOT}/.env`;
const SITE_URL = 'https://stonemegan.dev/'; // URL-prefix property in GSC
const SCOPE = 'https://www.googleapis.com/auth/webmasters.readonly';

// Parse --days N --limit N
const args = process.argv.slice(2);
const argOf = (flag, fallback) => {
  const i = args.indexOf(flag);
  return i >= 0 && args[i + 1] ? Number(args[i + 1]) : fallback;
};
const DAYS = argOf('--days', 7);
const LIMIT = argOf('--limit', 5);

function die(msg, code = 1) {
  process.stdout.write(JSON.stringify({ error: msg }) + '\n');
  process.exit(code);
}

// Read GSC_OAUTH_REFRESH_TOKEN from .env without polluting process.env.
function readEnvVar(name) {
  if (!existsSync(ENV_FILE)) return null;
  const lines = readFileSync(ENV_FILE, 'utf8').split('\n');
  for (let i = lines.length - 1; i >= 0; i--) {
    const m = lines[i].match(new RegExp(`^${name}=(.+)$`));
    if (m) return m[1].trim();
  }
  return null;
}

let access_token;

// Prefer OAuth refresh-token flow (works on this user account because
// the GSC "Add user" UI rejects service-account emails). Fall back to
// service-account JWT only if the OAuth path isn't configured.
const refreshToken = process.env.GSC_OAUTH_REFRESH_TOKEN || readEnvVar('GSC_OAUTH_REFRESH_TOKEN');

if (refreshToken && existsSync(OAUTH_CLIENT_FILE)) {
  const oauthClient = JSON.parse(readFileSync(OAUTH_CLIENT_FILE, 'utf8'));
  const creds = oauthClient.installed || oauthClient.web;
  if (!creds?.client_id || !creds?.client_secret) {
    die('gsc-oauth-client.json malformed (missing client_id / client_secret)');
  }
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: creds.client_id,
      client_secret: creds.client_secret,
      refresh_token: refreshToken,
      grant_type: 'refresh_token',
    }),
  });
  if (!r.ok) {
    die(`oauth refresh failed (${r.status}): ${(await r.text()).slice(0, 200)}`);
  }
  ({ access_token } = await r.json());
} else if (existsSync(SA_KEY_FILE)) {
  // Service-account JWT fallback (kept for completeness; currently blocked
  // by GSC "email not found" UI bug on this user's account).
  let creds;
  try {
    creds = JSON.parse(readFileSync(SA_KEY_FILE, 'utf8'));
  } catch (e) {
    die(`gsc-service-account.json unreadable: ${e.message}`);
  }
  if (!creds.client_email || !creds.private_key) {
    die('gsc-service-account.json malformed');
  }
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: creds.client_email,
    scope: SCOPE,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const b64url = (obj) =>
    Buffer.from(JSON.stringify(obj))
      .toString('base64')
      .replace(/=+$/, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');
  const signingInput = `${b64url(header)}.${b64url(claim)}`;
  const signer = createSign('RSA-SHA256');
  signer.update(signingInput);
  const signature = signer
    .sign(creds.private_key, 'base64')
    .replace(/=+$/, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  const jwt = `${signingInput}.${signature}`;
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!r.ok) {
    die(`token exchange failed (${r.status}): ${(await r.text()).slice(0, 200)}`);
  }
  ({ access_token } = await r.json());
} else {
  die('no GSC credentials — set GSC_OAUTH_REFRESH_TOKEN (run scripts/lib/gsc-oauth-init.mjs) or drop .gsc-service-account.json at repo root');
}

const now = Math.floor(Date.now() / 1000);

// Date range
const fmt = (d) => d.toISOString().slice(0, 10);
const endDate = fmt(new Date(now * 1000 - 1 * 24 * 3600 * 1000)); // yesterday (GSC lags ~2d)
const startDate = fmt(new Date(now * 1000 - DAYS * 24 * 3600 * 1000));

// Query GSC
const siteResource = encodeURIComponent(SITE_URL);
const gscResp = await fetch(
  `https://searchconsole.googleapis.com/webmasters/v3/sites/${siteResource}/searchAnalytics/query`,
  {
    method: 'POST',
    headers: {
      authorization: `Bearer ${access_token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      startDate,
      endDate,
      dimensions: ['query'],
      rowLimit: LIMIT,
    }),
  }
);
if (!gscResp.ok) {
  const text = await gscResp.text();
  let reason = text.slice(0, 200).replace(/\s+/g, ' ').trim();
  // List sites accessible to this credential so the 404 message can name them.
  let sitesHint = '';
  try {
    const sitesResp = await fetch('https://searchconsole.googleapis.com/webmasters/v3/sites', {
      headers: { authorization: `Bearer ${access_token}` },
    });
    if (sitesResp.ok) {
      const sj = await sitesResp.json();
      const urls = (sj.siteEntry || []).map((s) => s.siteUrl).join(', ');
      sitesHint = urls ? ` Accessible properties: [${urls}]` : ' No properties accessible to this credential.';
    }
  } catch {}
  if (gscResp.status === 404) {
    reason = `property ${SITE_URL} not visible to this credential.${sitesHint}`;
  } else if (gscResp.status === 403) {
    reason = `permission denied for ${SITE_URL}. ${sitesHint}`;
  }
  die(`gsc query failed (${gscResp.status}): ${reason}`);
}
const data = await gscResp.json();

// Normalised output
const out = {
  startDate,
  endDate,
  rows: (data.rows || []).map((r) => ({
    query: r.keys[0],
    impressions: r.impressions,
    clicks: r.clicks,
    ctr: r.ctr,
    position: r.position,
  })),
};
process.stdout.write(JSON.stringify(out) + '\n');
