#!/usr/bin/env node
"use strict";

/**
 * x-post-v2.js — Tweet posting script with OAuth 2.0 support
 *
 * Automatically uses OAuth 2.0 if available, falls back to OAuth 1.0a.
 *
 * Usage:
 *   node x-post-v2.js tweet "Hello world"
 *   node x-post-v2.js tweet "Hello world" --media /path/to/image.png
 *   node x-post-v2.js reply <tweet_id> "Your reply"
 *   node x-post-v2.js quote <tweet_id> "Your quote"
 *   node x-post-v2.js like <tweet_id>
 *
 * OAuth 2.0 env vars (preferred):
 *   X_OAUTH2_CLIENT_ID, X_OAUTH2_CLIENT_SECRET, X_OAUTH2_REFRESH_TOKEN
 *
 * OAuth 1.0a env vars (fallback):
 *   X_CONSUMER_KEY, X_CONSUMER_SECRET, X_ACCESS_TOKEN, X_ACCESS_TOKEN_SECRET
 *
 * Optional:
 *   WATSON_API_KEY, MISSION_CONTROL_URL
 */

const fs = require("fs");
const path = require("path");

// --- Configuration ---

const POSTS_LOG = path.join(__dirname, "..", "x-posts-log.json");
const MISSION_CONTROL_URL =
  process.env.MISSION_CONTROL_URL || "https://watson-mission-control.vercel.app";
const WATSON_API_KEY = process.env.WATSON_API_KEY;
const TWEETS_ENDPOINT = "https://api.x.com/2/tweets";

const MEDIA_TYPES = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".webp": "image/webp",
  ".mp4": "video/mp4",
};

const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
const MAX_VIDEO_SIZE = 512 * 1024 * 1024; // 512MB

// --- Auth Module Selection ---

let authModule;
let authMethod;

if (process.env.X_OAUTH2_REFRESH_TOKEN) {
  // OAuth 2.0 available
  authModule = require("./x-oauth2-manager.js");
  authMethod = "OAuth 2.0";
  console.error("Using OAuth 2.0 authentication");
} else if (process.env.X_ACCESS_TOKEN) {
  // OAuth 1.0a fallback
  authModule = require("./x-token-manager.js");
  authMethod = "OAuth 1.0a";
  console.error("Using OAuth 1.0a authentication (consider upgrading to OAuth 2.0)");
} else {
  console.error("❌ No authentication credentials found!");
  console.error("");
  console.error("Set OAuth 2.0 credentials (recommended):");
  console.error("  X_OAUTH2_CLIENT_ID, X_OAUTH2_CLIENT_SECRET, X_OAUTH2_REFRESH_TOKEN");
  console.error("");
  console.error("OR set OAuth 1.0a credentials (legacy):");
  console.error("  X_CONSUMER_KEY, X_CONSUMER_SECRET, X_ACCESS_TOKEN, X_ACCESS_TOKEN_SECRET");
  process.exit(1);
}

const { authenticatedFetch, uploadMedia } = authModule;

// --- CLI Parsing ---

const args = process.argv.slice(2);
const command = args[0];

function usage() {
  console.error("Usage:");
  console.error('  node x-post-v2.js tweet "text" [--media /path/to/file]');
  console.error('  node x-post-v2.js reply <tweet_id> "text" [--media /path/to/file]');
  console.error('  node x-post-v2.js quote <tweet_id> "text" [--media /path/to/file]');
  console.error('  node x-post-v2.js like <tweet_id>');
  console.error("\nSupported media: PNG, JPG, GIF, WEBP (max 5MB), MP4 (max 512MB)");
  process.exit(1);
}

if (!command || !["tweet", "reply", "quote", "like"].includes(command)) usage();

// Parse positional args and --media flag
let tweetId, text, mediaPath;

function extractMedia(argList) {
  const mediaIdx = argList.indexOf("--media");
  if (mediaIdx === -1) return argList;
  mediaPath = argList[mediaIdx + 1];
  if (!mediaPath) {
    console.error("Error: --media requires a file path");
    process.exit(1);
  }
  return [...argList.slice(0, mediaIdx), ...argList.slice(mediaIdx + 2)];
}

const positionalArgs = extractMedia(args.slice(1));

if (command === "tweet") {
  text = positionalArgs[0];
  if (!text) usage();
} else if (command === "like") {
  tweetId = positionalArgs[0];
  if (!tweetId) usage();
} else {
  tweetId = positionalArgs[0];
  text = positionalArgs[1];
  if (!tweetId || !text) usage();
}

// Validate media file if provided
if (mediaPath) {
  if (!fs.existsSync(mediaPath)) {
    console.error("Error: Media file not found: " + mediaPath);
    process.exit(1);
  }
  const ext = path.extname(mediaPath).toLowerCase();
  if (!MEDIA_TYPES[ext]) {
    console.error("Error: Unsupported media type: " + ext + ". Supported: " + Object.keys(MEDIA_TYPES).join(", "));
    process.exit(1);
  }
  const stat = fs.statSync(mediaPath);
  const isVideo = ext === ".mp4";
  const maxSize = isVideo ? MAX_VIDEO_SIZE : MAX_IMAGE_SIZE;
  if (stat.size > maxSize) {
    console.error("Error: File too large (" + (stat.size / 1024 / 1024).toFixed(1) + "MB). Max: " + (maxSize / 1024 / 1024) + "MB");
    process.exit(1);
  }
}

// --- Audit Logging ---

function logPost(entry) {
  let logs = [];
  try {
    logs = JSON.parse(fs.readFileSync(POSTS_LOG, "utf-8"));
  } catch {}
  logs.push(entry);
  const tmp = POSTS_LOG + ".tmp";
  fs.writeFileSync(tmp, JSON.stringify(logs, null, 2));
  fs.renameSync(tmp, POSTS_LOG);
}

// --- Mission Control Logging ---

async function logToMissionControl(eventType, title, metadata) {
  if (!WATSON_API_KEY) return;

  try {
    const res = await fetch(MISSION_CONTROL_URL + "/api/events", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer " + WATSON_API_KEY,
      },
      body: JSON.stringify({
        event_type: eventType,
        title,
        category: "social",
        source: "x-post",
        project: "watson-x",
        importance: "normal",
        metadata: { ...metadata, auth_method: authMethod },
      }),
    });

    if (!res.ok) {
      console.error("Mission Control log failed: HTTP " + res.status);
    }
  } catch (e) {
    console.error("Mission Control log error: " + e.message);
  }
}

// --- Post Tweet ---

async function postTweet() {
  const body = { text };

  if (command === "reply") {
    body.reply = { in_reply_to_tweet_id: tweetId };
  } else if (command === "quote") {
    body.quote_tweet_id = tweetId;
  }

  // Upload media if provided
  if (mediaPath) {
    try {
      const mediaId = await uploadMedia(mediaPath);
      body.media = { media_ids: [mediaId] };
    } catch (e) {
      console.error("Media upload error: " + e.message);
      process.exit(1);
    }
  }

  const result = await authenticatedFetch("POST", TWEETS_ENDPOINT, body);

  if (!result.ok) {
    const errorMsg = JSON.stringify(result.data).slice(0, 500);
    console.error("Post failed: HTTP " + result.status + " — " + errorMsg);

    logPost({
      timestamp: new Date().toISOString(),
      command,
      in_reply_to: tweetId || null,
      text,
      status: "failed",
      error: errorMsg,
      auth_method: authMethod,
    });

    process.exit(1);
  }

  const posted = result.data.data;
  const tweetUrl = `https://x.com/askwatson/status/${posted.id}`;

  console.log(JSON.stringify({ id: posted.id, text: posted.text, url: tweetUrl }));

  // Audit trail
  const logEntry = {
    timestamp: new Date().toISOString(),
    command,
    tweet_id: posted.id,
    in_reply_to: tweetId || null,
    text: posted.text,
    url: tweetUrl,
    media: mediaPath ? path.basename(mediaPath) : null,
    status: "posted",
    auth_method: authMethod,
  };
  logPost(logEntry);

  // Mission Control event
  const mcEventType = command === "reply" ? "x.reply_posted" : command === "quote" ? "x.quote_posted" : "x.tweet_posted";
  const mcTitle = command === "reply"
    ? `Watson replied to tweet ${tweetId}`
    : command === "quote"
    ? `Watson quoted tweet ${tweetId}`
    : "Watson posted a tweet";

  await logToMissionControl(mcEventType, mcTitle, {
    tweet_id: posted.id,
    in_reply_to: tweetId || null,
    text: posted.text,
    url: tweetUrl,
  });
}

// --- Like Tweet ---

async function likeTweet() {
  // Get authenticated user's ID
  const meRes = await authenticatedFetch("GET", "https://api.x.com/2/users/me");

  if (!meRes.ok) {
    console.error("Failed to get user ID: HTTP " + meRes.status + " - " + JSON.stringify(meRes.data));
    process.exit(1);
  }

  const userId = meRes.data.data.id;

  // Like the tweet
  const likeRes = await authenticatedFetch(
    "POST",
    `https://api.x.com/2/users/${userId}/likes`,
    { tweet_id: tweetId }
  );

  if (!likeRes.ok) {
    // 403 often means already liked — treat as success
    const errorData = JSON.stringify(likeRes.data);
    if (likeRes.status === 403 || errorData.includes("already liked")) {
      console.log(JSON.stringify({ liked: true, tweet_id: tweetId, note: "already liked" }));
      return;
    }
    console.error("Failed to like tweet: HTTP " + likeRes.status + " - " + errorData);
    process.exit(1);
  }

  console.log(JSON.stringify({ liked: likeRes.data.data.liked, tweet_id: tweetId }));

  // Log to Mission Control
  await logToMissionControl("x.tweet_liked", `Watson liked tweet ${tweetId}`, {
    tweet_id: tweetId,
    url: `https://x.com/i/status/${tweetId}`,
  });
}

// --- Main ---

if (command === "like") {
  likeTweet();
} else {
  postTweet();
}
