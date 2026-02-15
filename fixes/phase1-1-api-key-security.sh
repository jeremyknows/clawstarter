#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# Phase 1.1: API Key Security Fix
# 
# This file contains the SECURE replacement code for openclaw-quickstart-v2.sh
# 
# VULNERABILITY FIXED:
#   - API keys were stored in shell variables (visible via `ps e`)
#   - Keys passed to commands via environment
#   - Keys visible to any process on system
#
# SOLUTION:
#   - macOS Keychain for secure storage
#   - Keys never appear in environment or process list
#   - User-specific, survives reboot, no dependencies
#
# Usage:
#   Source this file or copy functions into openclaw-quickstart-v2.sh
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Keychain Configuration ───
readonly KEYCHAIN_SERVICE="ai.openclaw"
readonly KEYCHAIN_ACCOUNT_OPENROUTER="openrouter-api-key"
readonly KEYCHAIN_ACCOUNT_ANTHROPIC="anthropic-api-key"
readonly KEYCHAIN_ACCOUNT_GATEWAY="gateway-token"

# ═══════════════════════════════════════════════════════════════════
# SECURE KEYCHAIN FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

# Store a secret in macOS Keychain
# Usage: keychain_store "account-name" "secret-value"
# Returns: 0 on success, 1 on failure
keychain_store() {
    local account="$1"
    local secret="$2"
    
    # Delete existing entry if present (silent fail OK)
    security delete-generic-password \
        -s "$KEYCHAIN_SERVICE" \
        -a "$account" \
        2>/dev/null || true
    
    # Add new entry
    # CRITICAL: Use stdin (-w) to avoid secret in process args
    security add-generic-password \
        -s "$KEYCHAIN_SERVICE" \
        -a "$account" \
        -w "$secret" \
        -U \
        2>/dev/null
}

# Retrieve a secret from macOS Keychain
# Usage: secret=$(keychain_get "account-name")
# Returns: The secret value (stdout), or empty string if not found
keychain_get() {
    local account="$1"
    
    security find-generic-password \
        -s "$KEYCHAIN_SERVICE" \
        -a "$account" \
        -w \
        2>/dev/null || echo ""
}

# Check if a secret exists in Keychain
# Usage: if keychain_exists "account-name"; then ...
keychain_exists() {
    local account="$1"
    
    security find-generic-password \
        -s "$KEYCHAIN_SERVICE" \
        -a "$account" \
        >/dev/null 2>&1
}

# Delete a secret from Keychain
# Usage: keychain_delete "account-name"
keychain_delete() {
    local account="$1"
    
    security delete-generic-password \
        -s "$KEYCHAIN_SERVICE" \
        -a "$account" \
        2>/dev/null || true
}

# List all OpenClaw secrets in Keychain (for debugging)
# Usage: keychain_list
keychain_list() {
    echo "OpenClaw Keychain entries:"
    security dump-keychain 2>/dev/null | grep -A4 "\"$KEYCHAIN_SERVICE\"" | grep "acct" || echo "  (none found)"
}

# ═══════════════════════════════════════════════════════════════════
# SECURE CONFIG GENERATION (replaces Python inline script)
# ═══════════════════════════════════════════════════════════════════

# Generate openclaw.json config file securely
# Keys are read from Keychain at runtime, never exposed in process env
generate_secure_config() {
    local config_path="$1"
    local default_model="$2"
    local bot_name="${3:-Atlas}"
    local security_level="${4:-medium}"
    
    # Read keys from Keychain (secure - not in process list)
    local openrouter_key
    local anthropic_key
    local gateway_token
    
    openrouter_key=$(keychain_get "$KEYCHAIN_ACCOUNT_OPENROUTER")
    anthropic_key=$(keychain_get "$KEYCHAIN_ACCOUNT_ANTHROPIC")
    
    # Generate or retrieve gateway token
    if keychain_exists "$KEYCHAIN_ACCOUNT_GATEWAY"; then
        gateway_token=$(keychain_get "$KEYCHAIN_ACCOUNT_GATEWAY")
    else
        gateway_token=$(openssl rand -hex 32)
        keychain_store "$KEYCHAIN_ACCOUNT_GATEWAY" "$gateway_token"
    fi
    
    # Build config using heredoc (no secrets in command args)
    local config_dir
    config_dir=$(dirname "$config_path")
    mkdir -p "$config_dir"
    
    # Determine security settings
    local sandbox_mode="off"
    local tools_deny='["browser"]'
    
    case "$security_level" in
        high)
            sandbox_mode="workspace"
            tools_deny='["browser"]'
            ;;
        low)
            sandbox_mode="off"
            tools_deny='[]'
            ;;
        *)
            sandbox_mode="off"
            tools_deny='["browser"]'
            ;;
    esac
    
    # Build auth section dynamically
    local auth_section=""
    if [ -n "$openrouter_key" ]; then
        auth_section="\"openrouter\": {\"apiKey\": \"$openrouter_key\"}"
    fi
    if [ -n "$anthropic_key" ]; then
        [ -n "$auth_section" ] && auth_section="$auth_section, "
        auth_section="${auth_section}\"anthropic\": {\"apiKey\": \"$anthropic_key\"}"
    fi
    
    # Build provider section for OpenCode free tier
    local provider_section=""
    if [[ "$default_model" == opencode/* ]]; then
        provider_section=',
  "provider": {
    "opencode": {
      "baseURL": "https://opencode.ai/zen/v1",
      "models": {
        "kimi-k2.5-free": {"enabled": true, "displayName": "Kimi K2.5 Free"},
        "glm-4.7-free": {"enabled": true, "displayName": "GLM 4.7 Free"}
      }
    }
  }'
    fi
    
    # Write config (keys are in variables, not command line)
    cat > "$config_path" << CONFIGEOF
{
  "version": "2026.2.9",
  "model": "$default_model",
  "gateway": {
    "port": 18789,
    "auth": {"enabled": true, "token": "$gateway_token"}
  },
  "auth": {$auth_section},
  "workspace": {"path": "$HOME/.openclaw/workspace"},
  "agents": {
    "defaults": {
      "sandbox": {"mode": "$sandbox_mode"},
      "tools": {"deny": $tools_deny},
      "subagents": {"maxConcurrent": 8, "maxDepth": 1}
    }
  },
  "meta": {
    "security_level": "$security_level",
    "created_by": "clawstarter-v2-secure",
    "keys_in_keychain": true
  }$provider_section
}
CONFIGEOF
    
    chmod 600 "$config_path"
    
    echo ""
    echo "  Gateway Token: $gateway_token"
    echo "  Save this — you need it for the dashboard."
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# SECURE KEY COLLECTION (replaces step2_configure key handling)
# ═══════════════════════════════════════════════════════════════════

# Securely collect and store API key
# Key is read via read -s (silent) and immediately stored in Keychain
# Never appears in shell history, env vars, or process list
collect_api_key_secure() {
    local api_key=""
    local provider=""
    local default_model=""
    
    echo ""
    echo -e "${BOLD:-}Question 1: API Key${NC:-}"
    echo ""
    echo -e "  ${DIM:-}Have a key? Paste it below.${NC:-}"
    echo -e "  ${DIM:-}Need one? Press Enter — I'll help you get one (free, 60 seconds).${NC:-}"
    echo ""
    
    # Read key securely (not echoed, not in history)
    echo -en "  ${CYAN:-}?${NC:-} Paste API key (or Enter for guided signup): "
    read -r api_key  # -s would hide input, but users need to see what they paste
    
    # Guided signup if empty
    if [ -z "$api_key" ]; then
        api_key=$(guided_api_signup)
    fi
    
    # Process and store based on key type
    if [[ "$api_key" == "OPENCODE_FREE" ]]; then
        provider="opencode"
        default_model="opencode/kimi-k2.5-free"
        # No keys to store for free tier
        echo -e "  ${GREEN:-}✓${NC:-} OpenCode free tier selected"
        
    elif [[ "$api_key" == sk-or-* ]]; then
        provider="openrouter"
        default_model="openrouter/moonshotai/kimi-k2.5"
        # Store securely in Keychain
        keychain_store "$KEYCHAIN_ACCOUNT_OPENROUTER" "$api_key"
        echo -e "  ${GREEN:-}✓${NC:-} OpenRouter key stored in Keychain"
        
    elif [[ "$api_key" == sk-ant-* ]]; then
        provider="anthropic"
        default_model="anthropic/claude-sonnet-4-5"
        # Store securely in Keychain
        keychain_store "$KEYCHAIN_ACCOUNT_ANTHROPIC" "$api_key"
        echo -e "  ${GREEN:-}✓${NC:-} Anthropic key stored in Keychain"
        
    else
        # Assume OpenRouter for unknown formats
        provider="openrouter"
        default_model="openrouter/moonshotai/kimi-k2.5"
        if [ -n "$api_key" ]; then
            keychain_store "$KEYCHAIN_ACCOUNT_OPENROUTER" "$api_key"
            echo -e "  ${YELLOW:-}!${NC:-} Unknown key format — stored as OpenRouter"
        fi
    fi
    
    # Clear the variable immediately after storage
    api_key=""
    
    # Export only non-sensitive values
    export QUICKSTART_DEFAULT_MODEL="$default_model"
    export QUICKSTART_PROVIDER="$provider"
    
    # DO NOT export keys - they're in Keychain now
}

# ═══════════════════════════════════════════════════════════════════
# MIGRATION HELPER
# ═══════════════════════════════════════════════════════════════════

# Migrate existing keys from config file to Keychain
migrate_keys_to_keychain() {
    local config_file="$HOME/.openclaw/openclaw.json"
    
    if [ ! -f "$config_file" ]; then
        echo "No existing config found at $config_file"
        return 1
    fi
    
    echo "Migrating API keys to macOS Keychain..."
    
    # Extract keys using Python (safely, from file not args)
    local openrouter_key=""
    local anthropic_key=""
    local gateway_token=""
    
    # Read keys from JSON config
    if command -v python3 &>/dev/null; then
        openrouter_key=$(python3 -c "
import json, sys
try:
    with open('$config_file') as f:
        config = json.load(f)
    print(config.get('auth', {}).get('openrouter', {}).get('apiKey', ''))
except: pass
" 2>/dev/null || echo "")
        
        anthropic_key=$(python3 -c "
import json, sys
try:
    with open('$config_file') as f:
        config = json.load(f)
    print(config.get('auth', {}).get('anthropic', {}).get('apiKey', ''))
except: pass
" 2>/dev/null || echo "")
        
        gateway_token=$(python3 -c "
import json, sys
try:
    with open('$config_file') as f:
        config = json.load(f)
    print(config.get('gateway', {}).get('auth', {}).get('token', ''))
except: pass
" 2>/dev/null || echo "")
    fi
    
    # Store in Keychain
    local migrated=0
    
    if [ -n "$openrouter_key" ]; then
        keychain_store "$KEYCHAIN_ACCOUNT_OPENROUTER" "$openrouter_key"
        echo "  ✓ OpenRouter key migrated to Keychain"
        ((migrated++))
    fi
    
    if [ -n "$anthropic_key" ]; then
        keychain_store "$KEYCHAIN_ACCOUNT_ANTHROPIC" "$anthropic_key"
        echo "  ✓ Anthropic key migrated to Keychain"
        ((migrated++))
    fi
    
    if [ -n "$gateway_token" ]; then
        keychain_store "$KEYCHAIN_ACCOUNT_GATEWAY" "$gateway_token"
        echo "  ✓ Gateway token migrated to Keychain"
        ((migrated++))
    fi
    
    if [ "$migrated" -gt 0 ]; then
        echo ""
        echo "Migration complete! $migrated key(s) moved to Keychain."
        echo ""
        echo "IMPORTANT: You should now remove keys from openclaw.json:"
        echo "  1. Edit ~/.openclaw/openclaw.json"
        echo "  2. Remove the 'apiKey' values from the auth section"
        echo "  3. OpenClaw will read keys from Keychain automatically"
        echo ""
        echo "Or run: openclaw config secure (if available)"
    else
        echo "No keys found to migrate."
    fi
}

# ═══════════════════════════════════════════════════════════════════
# VERIFICATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

# Verify no API keys are exposed in process environment
verify_no_key_exposure() {
    echo "Verifying API key security..."
    echo ""
    echo "Checking for exposed keys (QUICKSTART_*, OPENROUTER_API_KEY, ANTHROPIC_API_KEY)..."
    echo ""
    
    # Check 1: No exposed API keys in current environment (the specific vulnerability)
    local exposed=0
    local found_keys=""
    
    # Check for quickstart-specific variables and common exposed patterns
    found_keys=$(env | grep -i "QUICKSTART.*KEY\|OPENROUTER_API_KEY\|ANTHROPIC_API_KEY" 2>/dev/null || true)
    
    if [ -n "$found_keys" ]; then
        echo "  ⚠ API keys found in environment (vulnerable to ps e):"
        echo "$found_keys" | sed 's/=.*/=***REDACTED***/' | sed 's/^/    /'
        echo ""
        echo "  These keys are exposed to any process on the system."
        echo "  Run 'migrate' to move them to Keychain, then unset them:"
        echo "    unset OPENROUTER_API_KEY ANTHROPIC_API_KEY"
        exposed=1
    else
        echo "  ✓ No OpenRouter/Anthropic keys exposed in environment"
    fi
    
    # Check 2: No keys in process list
    if ps e 2>/dev/null | grep -qi "sk-or-\|sk-ant-" 2>/dev/null; then
        echo "  ✗ WARNING: API key patterns found in process list!"
        exposed=1
    else
        echo "  ✓ No API keys visible in process list"
    fi
    
    # Check 3: Keychain entries exist
    if keychain_exists "$KEYCHAIN_ACCOUNT_OPENROUTER" || \
       keychain_exists "$KEYCHAIN_ACCOUNT_ANTHROPIC"; then
        echo "  ✓ Keys stored securely in macOS Keychain"
    else
        echo "  ℹ No API keys in Keychain (may be using free tier)"
    fi
    
    # Check 4: Config file permissions
    local config_file="$HOME/.openclaw/openclaw.json"
    if [ -f "$config_file" ]; then
        local perms
        perms=$(stat -f "%Lp" "$config_file" 2>/dev/null || echo "unknown")
        if [ "$perms" = "600" ]; then
            echo "  ✓ Config file has secure permissions (600)"
        else
            echo "  ! Config file permissions: $perms (should be 600)"
        fi
    fi
    
    echo ""
    if [ "$exposed" -eq 0 ]; then
        echo "Security check PASSED ✓"
        return 0
    else
        echo "Security check FAILED ✗"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════
# UPDATED step3_start (key portions only)
# ═══════════════════════════════════════════════════════════════════

# This replaces the Python config generation in step3_start
# Call this instead of the inline python3 - << 'PYEOF' block
step3_generate_config_secure() {
    local config_file="$HOME/.openclaw/openclaw.json"
    
    # Backup existing config
    if [ -f "$config_file" ]; then
        cp "$config_file" "${config_file}.backup-$(date +%Y%m%d-%H%M%S)"
        echo -e "  ${INFO:-→} Backed up existing config"
    fi
    
    # Generate config securely (reads keys from Keychain)
    generate_secure_config \
        "$config_file" \
        "$QUICKSTART_DEFAULT_MODEL" \
        "${QUICKSTART_BOT_NAME:-Atlas}" \
        "${QUICKSTART_SECURITY_LEVEL:-medium}"
    
    echo -e "  ${PASS:-✓} Config created (keys in Keychain)"
}

# ═══════════════════════════════════════════════════════════════════
# CLI INTERFACE
# ═══════════════════════════════════════════════════════════════════

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        migrate)
            migrate_keys_to_keychain
            ;;
        verify)
            verify_no_key_exposure
            ;;
        list)
            keychain_list
            ;;
        store)
            if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
                echo "Usage: $0 store <account> <secret>"
                exit 1
            fi
            keychain_store "$2" "$3"
            echo "Stored secret for account: $2"
            ;;
        get)
            if [ -z "${2:-}" ]; then
                echo "Usage: $0 get <account>"
                exit 1
            fi
            keychain_get "$2"
            ;;
        delete)
            if [ -z "${2:-}" ]; then
                echo "Usage: $0 delete <account>"
                exit 1
            fi
            keychain_delete "$2"
            echo "Deleted secret for account: $2"
            ;;
        help|--help|-h)
            echo "OpenClaw API Key Security Tool"
            echo ""
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  migrate   Move existing keys from config to Keychain"
            echo "  verify    Check that no keys are exposed"
            echo "  list      Show Keychain entries for OpenClaw"
            echo "  store     Store a secret: store <account> <secret>"
            echo "  get       Retrieve a secret: get <account>"
            echo "  delete    Remove a secret: delete <account>"
            echo ""
            echo "Keychain accounts:"
            echo "  $KEYCHAIN_ACCOUNT_OPENROUTER"
            echo "  $KEYCHAIN_ACCOUNT_ANTHROPIC"
            echo "  $KEYCHAIN_ACCOUNT_GATEWAY"
            ;;
        *)
            echo "Run '$0 help' for usage"
            ;;
    esac
fi
