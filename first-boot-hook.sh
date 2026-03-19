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
echo "═══════════════════════════════════════════════════════════════" >> "$LOG_FILE"
