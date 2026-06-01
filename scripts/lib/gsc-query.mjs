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

import { readFileSync } from 'node:fs';
import { createSign } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

// fileURLToPath decodes %20 etc — the repo root has a space in its path.
const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const KEY_FILE = `${REPO_ROOT}/.gsc-service-account.json`;
const SITE_URL = 'https://stonemegan.dev/'; // URL-prefix property in GSC

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

let creds;
try {
  creds = JSON.parse(readFileSync(KEY_FILE, 'utf8'));
} catch (e) {
  die(`gsc-service-account.json missing or unreadable: ${e.message}`);
}
if (!creds.client_email || !creds.private_key) {
  die('gsc-service-account.json malformed (missing client_email or private_key)');
}

// Build + sign JWT
const now = Math.floor(Date.now() / 1000);
const header = { alg: 'RS256', typ: 'JWT' };
const claim = {
  iss: creds.client_email,
  scope: 'https://www.googleapis.com/auth/webmasters.readonly',
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

// Exchange JWT for access token
const tokenResp = await fetch('https://oauth2.googleapis.com/token', {
  method: 'POST',
  headers: { 'content-type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion: jwt,
  }),
});
if (!tokenResp.ok) {
  const text = await tokenResp.text();
  die(`token exchange failed (${tokenResp.status}): ${text.slice(0, 200)}`);
}
const { access_token } = await tokenResp.json();

// Date range
const fmt = (d) => d.toISOString().slice(0, 10);
const endDate = fmt(new Date(now * 1000 - 1 * 24 * 3600 * 1000)); // yesterday (GSC lags ~2d)
const startDate = fmt(new Date(now * 1000 - DAYS * 24 * 3600 * 1000));

// Query GSC
const siteResource = encodeURIComponent(SITE_URL);
const gscResp = await fetch(
  `https://searchconsole.googleapis.com/v1/sites/${siteResource}/searchAnalytics/query`,
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
  // GSC's 404 page is verbose HTML; collapse to a short reason.
  let reason = text.slice(0, 200).replace(/\s+/g, ' ').trim();
  if (gscResp.status === 404) {
    reason =
      'service account has no access to the GSC property yet — add the SA email as a user on the GSC property (propagation can take ~24h after creation)';
  } else if (gscResp.status === 403) {
    reason = 'permission denied — SA added but probably without read access; check GSC Users page';
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
