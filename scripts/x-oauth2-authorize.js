#!/usr/bin/env node
"use strict";

/**
 * x-oauth2-authorize.js — OAuth 2.0 initial authorization helper
 *
 * Interactive script to get OAuth 2.0 refresh token for X API.
 *
 * Steps:
 * 1. Generates authorization URL with PKCE
 * 2. Opens browser for user to authorize
 * 3. Waits for user to paste callback URL
 * 4. Extracts authorization code
 * 5. Exchanges code for tokens
 * 6. Saves refresh token
 *
 * Env vars required:
 *   X_OAUTH2_CLIENT_ID, X_OAUTH2_CLIENT_SECRET
 *
 * Usage:
 *   node x-oauth2-authorize.js
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { exec } = require('child_process');

const CLIENT_ID = process.env.X_OAUTH2_CLIENT_ID;
const CLIENT_SECRET = process.env.X_OAUTH2_CLIENT_SECRET;
const REDIRECT_URI = 'http://localhost:3000/callback';
const TOKEN_ENDPOINT = 'https://api.x.com/2/oauth2/token';
const ENV_FILE = path.join(process.env.HOME, '.openclaw', 'workspace', '.env');

if (!CLIENT_ID || !CLIENT_SECRET) {
  console.error('❌ Missing credentials!');
  console.error('');
  console.error('Set these environment variables:');
  console.error('  export X_OAUTH2_CLIENT_ID="your_client_id"');
  console.error('  export X_OAUTH2_CLIENT_SECRET="your_client_secret"');
  console.error('');
  console.error('Get them from: https://console.x.com');
  process.exit(1);
}

// --- PKCE Challenge ---

function generateCodeVerifier() {
  return crypto.randomBytes(32).toString('base64url');
}

function generateCodeChallenge(verifier) {
  return crypto.createHash('sha256').update(verifier).digest('base64url');
}

// --- Authorization URL ---

function buildAuthUrl(codeChallenge) {
  const scopes = [
    'tweet.read',
    'tweet.write',
    'users.read',
    'dm.read',
    'dm.write',
    'offline.access', // Get refresh token
  ];

  const params = new URLSearchParams({
    response_type: 'code',
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    scope: scopes.join(' '),
    state: crypto.randomBytes(16).toString('hex'),
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
  });

  return `https://x.com/i/oauth2/authorize?${params.toString()}`;
}

// --- Token Exchange ---

async function exchangeCodeForTokens(code, codeVerifier) {
  const auth = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');

  const res = await fetch(TOKEN_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': `Basic ${auth}`,
    },
    body: new URLSearchParams({
      code,
      grant_type: 'authorization_code',
      redirect_uri: REDIRECT_URI,
      code_verifier: codeVerifier,
    }),
  });

  if (!res.ok) {
    const error = await res.text();
    throw new Error(`Token exchange failed: HTTP ${res.status} — ${error}`);
  }

  return await res.json();
}

// --- Save to .env ---

function saveRefreshToken(refreshToken) {
  const line = `X_OAUTH2_REFRESH_TOKEN="${refreshToken}"`;
  
  let envContent = '';
  if (fs.existsSync(ENV_FILE)) {
    envContent = fs.readFileSync(ENV_FILE, 'utf-8');
  }

  // Remove old refresh token line if exists
  const lines = envContent.split('\n').filter(l => !l.startsWith('X_OAUTH2_REFRESH_TOKEN='));
  lines.push(line);

  fs.writeFileSync(ENV_FILE, lines.join('\n').trim() + '\n');
  console.log('✅ Refresh token saved to: ' + ENV_FILE);
}

// --- Interactive Prompt ---

function prompt(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise(resolve => {
    rl.question(question, answer => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

// --- Main ---

async function main() {
  console.log('🎩 Watson OAuth 2.0 Authorization Helper');
  console.log('');

  const codeVerifier = generateCodeVerifier();
  const codeChallenge = generateCodeChallenge(codeVerifier);
  const authUrl = buildAuthUrl(codeChallenge);

  console.log('Step 1: Open this URL in your browser:');
  console.log('');
  console.log(authUrl);
  console.log('');

  // Try to open browser automatically
  const platform = process.platform;
  const openCmd = platform === 'darwin' ? 'open' : platform === 'win32' ? 'start' : 'xdg-open';
  
  try {
    exec(`${openCmd} "${authUrl}"`);
    console.log('✅ Browser opened automatically');
  } catch {
    console.log('⚠️  Could not open browser automatically');
  }

  console.log('');
  console.log('Step 2: Authorize the app');
  console.log('');
  console.log('Step 3: After authorization, you\'ll be redirected to:');
  console.log(`  ${REDIRECT_URI}?code=...&state=...`);
  console.log('');
  console.log('The page will show an error (that\'s OK - we just need the URL)');
  console.log('');

  const callbackUrl = await prompt('Paste the full callback URL here: ');

  // Extract code from URL
  let code;
  try {
    const url = new URL(callbackUrl);
    code = url.searchParams.get('code');
  } catch {
    // Fallback: try to extract code parameter manually
    const match = callbackUrl.match(/[?&]code=([^&]+)/);
    if (match) {
      code = match[1];
    }
  }

  if (!code) {
    console.error('❌ Could not extract authorization code from URL');
    process.exit(1);
  }

  console.log('');
  console.log('✅ Authorization code extracted');
  console.log('');
  console.log('Exchanging code for tokens...');

  const tokens = await exchangeCodeForTokens(code, codeVerifier);

  console.log('');
  console.log('✅ Tokens received!');
  console.log('');
  console.log('Access Token (first 20 chars): ' + tokens.access_token.slice(0, 20) + '...');
  console.log('Expires in: ' + tokens.expires_in + ' seconds');
  console.log('Scope: ' + tokens.scope);
  console.log('');

  // Save refresh token
  saveRefreshToken(tokens.refresh_token);

  // Also save initial access token
  const tokenFile = path.join(__dirname, '..', '.x-oauth2-tokens.json');
  const tokenData = {
    access_token: tokens.access_token,
    token_type: tokens.token_type,
    expires_at: Date.now() + (tokens.expires_in * 1000),
    scope: tokens.scope,
    refresh_token: tokens.refresh_token,
  };
  
  fs.writeFileSync(tokenFile, JSON.stringify(tokenData, null, 2));
  console.log('✅ Initial tokens saved to: ' + tokenFile);

  console.log('');
  console.log('🎉 Setup complete!');
  console.log('');
  console.log('Next steps:');
  console.log('  1. Load credentials: source ' + ENV_FILE);
  console.log('  2. Test auth: node scripts/x-oauth2-manager.js verify');
  console.log('  3. Post a tweet: node scripts/x-post.js tweet "Hello OAuth 2.0"');
  console.log('');
}

main().catch(err => {
  console.error('❌ Error: ' + err.message);
  process.exit(1);
});
