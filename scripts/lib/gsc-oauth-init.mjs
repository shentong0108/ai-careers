#!/usr/bin/env node
// gsc-oauth-init.mjs — one-shot OAuth desktop flow for GSC read access.
//
// Why: the service-account path failed because GSC's "Add user" UI
// rejects the SA email with "email not found" — a long-running Google
// bug that affects fresh service accounts. OAuth flow with a Desktop
// client bypasses the GSC permission UI entirely; the user grants
// access in the browser using their existing GSC owner account, and
// we save the refresh_token so future cron runs can mint access tokens
// without re-prompting.
//
// Usage: node scripts/lib/gsc-oauth-init.mjs
//
// What it does:
//   1. Reads .gsc-oauth-client.json (downloaded from GCP Credentials)
//   2. Starts a tiny HTTP server on 127.0.0.1:<random port>
//   3. Opens the OAuth consent URL in the user's default browser
//   4. Receives the auth code on the loopback, exchanges for tokens
//   5. Appends GSC_OAUTH_REFRESH_TOKEN=<token> to .env
//   6. Exits.

import { readFileSync, appendFileSync, existsSync } from 'node:fs';
import { createServer } from 'node:http';
import { exec } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const CLIENT_FILE = `${REPO_ROOT}/.gsc-oauth-client.json`;
const ENV_FILE = `${REPO_ROOT}/.env`;
const SCOPE = 'https://www.googleapis.com/auth/webmasters.readonly';

if (!existsSync(CLIENT_FILE)) {
  console.error(`Missing ${CLIENT_FILE}. Download the OAuth client JSON from GCP Credentials first.`);
  process.exit(1);
}
const raw = JSON.parse(readFileSync(CLIENT_FILE, 'utf8'));
const creds = raw.installed || raw.web;
if (!creds?.client_id || !creds?.client_secret) {
  console.error('OAuth client JSON missing client_id / client_secret (looked under .installed and .web).');
  process.exit(1);
}

let serverPort;
const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${serverPort}`);
  if (url.pathname !== '/' && url.pathname !== '/oauth2callback') {
    res.statusCode = 404;
    res.end('not found');
    return;
  }
  const code = url.searchParams.get('code');
  const error = url.searchParams.get('error');
  if (error) {
    res.end(`OAuth error: ${error}. Close this tab.`);
    console.error(`OAuth error from Google: ${error}`);
    server.close();
    process.exit(1);
  }
  if (!code) {
    res.statusCode = 400;
    res.end('no code in callback');
    return;
  }
  try {
    const tokResp = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: creds.client_id,
        client_secret: creds.client_secret,
        redirect_uri: `http://127.0.0.1:${serverPort}`,
        grant_type: 'authorization_code',
      }),
    });
    const tok = await tokResp.json();
    if (!tok.refresh_token) {
      res.end(`Token exchange returned no refresh_token. Response: ${JSON.stringify(tok)}`);
      console.error('No refresh_token in response:', tok);
      server.close();
      process.exit(1);
    }
    // Append to .env (idempotent: if line already present, remove old first via the bash caller — here we just append; user can dedupe later)
    appendFileSync(ENV_FILE, `\nGSC_OAUTH_REFRESH_TOKEN=${tok.refresh_token}\n`);
    res.end('Refresh token saved to .env. You can close this tab.');
    console.log('✓ refresh_token saved to .env');
    console.log('✓ done — auth complete');
    server.close();
    process.exit(0);
  } catch (e) {
    res.end(`Error: ${e.message}`);
    console.error(e);
    server.close();
    process.exit(1);
  }
});

server.listen(0, '127.0.0.1', () => {
  serverPort = server.address().port;
  const authUrl =
    'https://accounts.google.com/o/oauth2/v2/auth?' +
    new URLSearchParams({
      client_id: creds.client_id,
      redirect_uri: `http://127.0.0.1:${serverPort}`,
      response_type: 'code',
      scope: SCOPE,
      access_type: 'offline',
      prompt: 'consent', // force refresh_token return even on repeat
    }).toString();
  console.log(`\nLoopback server listening on http://127.0.0.1:${serverPort}`);
  console.log('Opening browser for consent...');
  console.log('If browser does not open, paste this URL manually:\n', authUrl, '\n');
  exec(`open "${authUrl}"`);
});

// Safety net: kill after 5 minutes if user never completes consent
setTimeout(() => {
  console.error('\nTimed out after 5 minutes — no consent received. Re-run when ready.');
  server.close();
  process.exit(2);
}, 5 * 60 * 1000);
