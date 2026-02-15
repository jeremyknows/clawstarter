#!/usr/bin/env node
"use strict";

/**
 * x-oauth2-manager.js — OAuth 2.0 token management for X API v2
 *
 * Handles access token refresh, storage, and authentication.
 *
 * Env vars required:
 *   X_OAUTH2_CLIENT_ID, X_OAUTH2_CLIENT_SECRET, X_OAUTH2_REFRESH_TOKEN
 *
 * Usage:
 *   const { getAccessToken, authenticatedFetch } = require('./x-oauth2-manager.js');
 *   
 *   // In your code:
 *   const result = await authenticatedFetch('POST', 'https://api.x.com/2/tweets', { text: 'Hello' });
 */

const fs = require('fs');
const path = require('path');

const TOKEN_FILE = path.join(__dirname, '..', '.x-oauth2-tokens.json');
const TOKEN_ENDPOINT = 'https://api.x.com/2/oauth2/token';

// --- Token Storage ---

function loadTokens() {
  try {
    return JSON.parse(fs.readFileSync(TOKEN_FILE, 'utf-8'));
  } catch {
    return null;
  }
}

function saveTokens(tokens) {
  const tmp = TOKEN_FILE + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(tokens, null, 2));
  fs.renameSync(tmp, TOKEN_FILE);
}

// --- Token Refresh ---

async function refreshAccessToken() {
  const clientId = process.env.X_OAUTH2_CLIENT_ID;
  const clientSecret = process.env.X_OAUTH2_CLIENT_SECRET;
  const refreshToken = process.env.X_OAUTH2_REFRESH_TOKEN;

  if (!clientId || !clientSecret || !refreshToken) {
    throw new Error('Missing OAuth 2.0 credentials: X_OAUTH2_CLIENT_ID, X_OAUTH2_CLIENT_SECRET, X_OAUTH2_REFRESH_TOKEN');
  }

  const auth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  const res = await fetch(TOKEN_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': `Basic ${auth}`,
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
    }),
  });

  if (!res.ok) {
    const error = await res.text();
    throw new Error(`Token refresh failed: HTTP ${res.status} — ${error.slice(0, 300)}`);
  }

  const data = await res.json();

  const tokens = {
    access_token: data.access_token,
    token_type: data.token_type,
    expires_at: Date.now() + (data.expires_in * 1000),
    scope: data.scope,
    // Update refresh token if rotated (some OAuth 2.0 implementations do this)
    refresh_token: data.refresh_token || refreshToken,
  };

  saveTokens(tokens);
  console.error('✅ Access token refreshed (expires in ' + data.expires_in + 's)');
  return tokens.access_token;
}

// --- Get Valid Access Token ---

async function getAccessToken() {
  const tokens = loadTokens();

  // Check if we have a valid token (with 1 minute buffer)
  if (tokens && tokens.access_token && tokens.expires_at > Date.now() + 60000) {
    return tokens.access_token;
  }

  // Need to refresh
  return await refreshAccessToken();
}

// --- Authenticated Fetch ---

async function authenticatedFetch(method, url, jsonBody) {
  const accessToken = await getAccessToken();

  const headers = {
    'Authorization': `Bearer ${accessToken}`,
    'User-Agent': 'WatsonBot/2.0',
  };

  const opts = { method, headers };

  if (jsonBody && method !== 'GET') {
    headers['Content-Type'] = 'application/json';
    opts.body = JSON.stringify(jsonBody);
  }

  const res = await fetch(url, opts);

  let data;
  const contentType = res.headers.get('content-type') || '';
  if (contentType.includes('json')) {
    data = await res.json();
  } else {
    data = await res.text();
  }

  return {
    status: res.status,
    ok: res.ok,
    data,
    headers: Object.fromEntries(res.headers),
  };
}

// --- Media Upload (OAuth 2.0) ---

async function uploadMedia(filePath) {
  const accessToken = await getAccessToken();
  const crypto = require('crypto');
  
  const ext = path.extname(filePath).toLowerCase();
  const MEDIA_TYPES = {
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".gif": "image/gif",
    ".webp": "image/webp",
    ".mp4": "video/mp4",
  };
  
  const mimeType = MEDIA_TYPES[ext];
  if (!mimeType) {
    throw new Error('Unsupported media type: ' + ext);
  }
  
  const fileData = fs.readFileSync(filePath);
  const base64Data = fileData.toString('base64');

  // Build multipart/form-data body
  const boundary = "----WatsonMedia" + crypto.randomBytes(8).toString("hex");
  const parts = [];

  parts.push(
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="media_data"\r\n\r\n` +
    base64Data + "\r\n"
  );

  const category = ext === ".mp4" ? "tweet_video" : ext === ".gif" ? "tweet_gif" : "tweet_image";
  parts.push(
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="media_category"\r\n\r\n` +
    category + "\r\n"
  );

  const bodyStr = parts.join("") + `--${boundary}--\r\n`;

  const res = await fetch('https://upload.twitter.com/1.1/media/upload.json', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'multipart/form-data; boundary=' + boundary,
      'User-Agent': 'WatsonBot/2.0',
    },
    body: bodyStr,
  });

  if (!res.ok) {
    const errBody = await res.text();
    throw new Error(`Media upload failed: HTTP ${res.status} — ${errBody.slice(0, 300)}`);
  }

  const data = await res.json();
  const mediaId = data.media_id_string;

  if (!mediaId) {
    throw new Error("Media upload returned no media_id: " + JSON.stringify(data).slice(0, 300));
  }

  console.error("Media uploaded: " + mediaId + " (" + mimeType + ", " + (fileData.length / 1024).toFixed(0) + "KB)");
  return mediaId;
}

// --- Verify Credentials ---

async function verifyCredentials() {
  try {
    const result = await authenticatedFetch('GET', 'https://api.x.com/2/users/me?user.fields=id,name,username');

    if (result.ok && result.data?.data) {
      return { valid: true, user: result.data.data };
    }

    return {
      valid: false,
      error: `HTTP ${result.status}: ${JSON.stringify(result.data).slice(0, 200)}`,
    };
  } catch (e) {
    return { valid: false, error: e.message };
  }
}

// --- Exports ---

module.exports = { getAccessToken, authenticatedFetch, uploadMedia, verifyCredentials, refreshAccessToken };

// --- CLI Mode ---

if (require.main === module) {
  const cmd = process.argv[2];

  if (cmd === 'verify') {
    verifyCredentials().then(result => {
      if (result.valid) {
        console.log('✅ OAuth 2.0 — Authenticated as @' + result.user.username + ' (ID: ' + result.user.id + ')');
      } else {
        console.error('❌ OAuth 2.0 FAIL — ' + result.error);
        process.exit(1);
      }
    });
  } else if (cmd === 'refresh') {
    refreshAccessToken().then(token => {
      console.log('✅ Access token refreshed');
      console.log('Token (first 20 chars): ' + token.slice(0, 20) + '...');
    }).catch(e => {
      console.error('❌ Refresh failed: ' + e.message);
      process.exit(1);
    });
  } else {
    console.log('Usage:');
    console.log('  node x-oauth2-manager.js verify   # Check auth & show username');
    console.log('  node x-oauth2-manager.js refresh  # Force token refresh');
  }
}
