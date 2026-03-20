#!/bin/bash

#############################################################################
# first-boot-hook.sh
#############################################################################
# 
# Gateway startup hook — runs when OpenClaw service starts for the first time.
# 
# Responsibility:
#  1. Check if seed-package.zip exists at ~/.openclaw/
#  2. If yes: unzip, install each cron job via 'openclaw cron add'
#  3. Delete the seed-package.zip (cleanup)
#  4. Log success/failure
# 
# Called by: systemd service ExecStartPost (Linux) or LaunchAgent (macOS)
# 
# Idempotency: Safe to run multiple times. Jobs are only installed if they don't exist.
#

set -euo pipefail

WORKSPACE="${HOME}/.openclaw"
SEED_PACKAGE="${WORKSPACE}/seed-package.zip"
SEED_PACKAGE_TAR="${WORKSPACE}/seed-package.tar.gz"
TEMP_DIR=$(mktemp -d)
LOG_FILE="${WORKSPACE}/logs/first-boot-hook.log"

cleanup() {
  rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

log() {
  local level="$1"
  shift
  local msg="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[${timestamp}] [${level}] ${msg}" >> "$LOG_FILE"
}

echo "═══════════════════════════════════════════════════════════════" >> "$LOG_FILE"
log INFO "first-boot-hook started"

# Check if seed package exists
if [[ -f "$SEED_PACKAGE" ]]; then
  log INFO "Seed package found: $SEED_PACKAGE"
  
  # Unzip
  if unzip -q "$SEED_PACKAGE" -d "$TEMP_DIR"; then
    log SUCCESS "Unzipped seed package"
    
    # Install each job
    for job_file in "$TEMP_DIR"/*.json; do
      if [[ -f "$job_file" ]]; then
        local job_name
        job_name=$(grep -o '"name":"[^"]*"' "$job_file" | head -1 | cut -d'"' -f4)
        
        log INFO "Installing cron job: $job_name"
        
        if openclaw cron add "$job_file" 2>> "$LOG_FILE"; then
          log SUCCESS "Installed: $job_name"
        else
          log WARN "Failed to install: $job_name (may already exist)"
        fi
      fi
    done
    
    # Cleanup seed package
    rm -f "$SEED_PACKAGE"
    log SUCCESS "Cleaned up seed package"
  else
    log ERROR "Failed to unzip seed package"
  fi
  
elif [[ -f "$SEED_PACKAGE_TAR" ]]; then
  log INFO "Seed package found: $SEED_PACKAGE_TAR (tar format)"
  
  # Extract tar
  if tar -xzf "$SEED_PACKAGE_TAR" -C "$TEMP_DIR"; then
    log SUCCESS "Extracted seed package"
    
    # Install each job
    for job_file in "$TEMP_DIR"/*.json; do
      if [[ -f "$job_file" ]]; then
        local job_name
        job_name=$(grep -o '"name":"[^"]*"' "$job_file" | head -1 | cut -d'"' -f4)
        
        log INFO "Installing cron job: $job_name"
        
        if openclaw cron add "$job_file" 2>> "$LOG_FILE"; then
          log SUCCESS "Installed: $job_name"
        else
          log WARN "Failed to install: $job_name (may already exist)"
        fi
      fi
    done
    
    # Cleanup seed package
    rm -f "$SEED_PACKAGE_TAR"
    log SUCCESS "Cleaned up seed package"
  else
    log ERROR "Failed to extract seed package (tar)"
  fi
else
  log INFO "No seed package found (first-boot-hook will skip installation)"
fi

log INFO "first-boot-hook completed"

#############################################################################
# D7 RETENTION SURVEY
# Fires once, 7 days after first boot, via Telegram.
# Requires TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID in environment.
#############################################################################

D7_SENTINEL="${WORKSPACE}/.d7-survey-sent"
INSTALL_TIMESTAMP_FILE="${WORKSPACE}/.install-timestamp"

# Record install timestamp if not already set
if [[ ! -f "$INSTALL_TIMESTAMP_FILE" ]]; then
  date +%s > "$INSTALL_TIMESTAMP_FILE"
  log INFO "Recorded install timestamp for D7 survey"
fi

INSTALL_TS=$(cat "$INSTALL_TIMESTAMP_FILE" 2>/dev/null || echo "0")
NOW_TS=$(date +%s)
ELAPSED=$(( NOW_TS - INSTALL_TS ))
SEVEN_DAYS=604800

# Only run if: 7 days have passed AND survey hasn't been sent yet
if [[ "$ELAPSED" -ge "$SEVEN_DAYS" ]] && [[ ! -f "$D7_SENTINEL" ]]; then
  log INFO "D7 survey: 7 days elapsed, sending retention survey..."

  # Load user name from workspace if available
  D7_NAME=""
  if [[ -f "${WORKSPACE}/workspace/USER.md" ]]; then
    D7_NAME=$(grep -m1 '^\*\*Name:\*\*' "${WORKSPACE}/workspace/USER.md" 2>/dev/null | sed 's/\*\*Name:\*\* *//' | tr -dc '[:alnum:] _-' | cut -c1-30)
  fi
  [[ -z "$D7_NAME" ]] && D7_NAME="hey"

  D7_MESSAGE="Hey ${D7_NAME} — quick check-in from your assistant setup.

It's been about a week. Is your assistant actually being useful?

Reply with one of:
  great — working well, using it regularly
  okay — using it sometimes, could be better
  not really — haven't used it much

Your answer helps improve the experience. No wrong answers."

  if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]] && [[ -n "${TELEGRAM_CHAT_ID:-}" ]]; then
    local d7_response
    d7_response=$(curl -s --max-time 15 -X POST \
      "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
      --data-urlencode "text=${D7_MESSAGE}" 2>/dev/null)

    if echo "$d7_response" | grep -q '"ok":true'; then
      touch "$D7_SENTINEL"
      log INFO "D7 survey sent successfully"
    else
      log WARN "D7 survey send failed (will retry on next boot)"
    fi
  else
    log WARN "D7 survey: TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set — skipping"
  fi
fi

echo "═══════════════════════════════════════════════════════════════" >> "$LOG_FILE"
