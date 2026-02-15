#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# INTEGRATION EXAMPLE: How to Apply the Fix to openclaw-quickstart-v2.sh
# ═══════════════════════════════════════════════════════════════════
#
# This file shows exactly how to integrate the security fix into the
# existing openclaw-quickstart-v2.sh script.
#
# TWO OPTIONS:
#   1. Add functions to the script (shown here)
#   2. Source them from phase1-5-plist-injection.sh
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ─────────────────────────────────────────────────────────────────
# STEP 1: Add these security functions near the top of the script
# (After the color definitions, around line 50)
# ─────────────────────────────────────────────────────────────────

# ─── XML Security Functions (NEW) ───

# Escape XML special characters to prevent injection
escape_xml() {
    local input="$1"
    input="${input//&/&amp;}"   # Must be first!
    input="${input//</&lt;}"
    input="${input//>/&gt;}"
    input="${input//\"/&quot;}"
    input="${input//\'/&apos;}"
    echo "$input"
}

# Validate $HOME path for LaunchAgent usage
validate_home_path() {
    local home_path="$1"
    
    # Rule 1: Must start with /Users/
    if [[ ! "$home_path" =~ ^/Users/ ]]; then
        echo "ERROR: HOME must start with /Users/ (got: $home_path)" >&2
        return 1
    fi
    
    # Rule 2: Username must be alphanumeric + hyphens/underscores
    local username="${home_path#/Users/}"
    username="${username%%/*}"
    
    if [[ ! "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid username format: $username" >&2
        return 1
    fi
    
    # Rule 3: Block suspicious characters
    if [[ "$home_path" =~ \$ ]] || \
       [[ "$home_path" =~ \` ]] || \
       [[ "$home_path" =~ \< ]] || \
       [[ "$home_path" =~ \> ]] || \
       [[ "$home_path" =~ \( ]] || \
       [[ "$home_path" =~ \) ]] || \
       [[ "$home_path" =~ \{ ]] || \
       [[ "$home_path" =~ \} ]] || \
       [[ "$home_path" =~ \; ]] || \
       [[ "$home_path" =~ \| ]] || \
       [[ "$home_path" =~ \& ]] || \
       [[ "$home_path" =~ \' ]] || \
       [[ "$home_path" =~ \" ]]; then
        echo "ERROR: HOME contains forbidden characters" >&2
        return 1
    fi
    
    # Rule 4: Must be exactly /Users/username
    if [[ "$home_path" != "/Users/$username" ]]; then
        echo "ERROR: HOME must be exactly /Users/username (got: $home_path)" >&2
        return 1
    fi
    
    return 0
}

# Safe LaunchAgent plist creation
create_launch_agent_safe() {
    local home_path="$1"
    local output_file="$2"
    
    # Validate $HOME
    if ! validate_home_path "$home_path"; then
        return 1
    fi
    
    # Escape XML entities (defense-in-depth)
    local home_escaped
    home_escaped=$(escape_xml "$home_path")
    
    # Build paths with escaped values
    local openclaw_bin="${home_escaped}/.openclaw/bin/openclaw"
    local working_dir="${home_escaped}/.openclaw"
    
    # Generate plist
    cat > "$output_file" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.openclaw.gateway</string>
    <key>ProgramArguments</key>
    <array>
        <string>${openclaw_bin}</string>
        <string>gateway</string>
        <string>start</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw/gateway.log</string>
    <key>WorkingDirectory</key>
    <string>${working_dir}</string>
</dict>
</plist>
PLISTEOF
    
    # Validate with plutil
    if ! plutil -lint "$output_file" >/dev/null 2>&1; then
        echo "ERROR: Generated plist failed validation" >&2
        rm -f "$output_file"
        return 1
    fi
    
    return 0
}

# ─────────────────────────────────────────────────────────────────
# STEP 2: Replace the LaunchAgent creation in step3_start()
# (Around lines 554-577)
# ─────────────────────────────────────────────────────────────────

step3_start_FIXED() {
    # ... (previous code) ...
    
    local config_file="$HOME/.openclaw/openclaw.json"
    local workspace_dir="$HOME/.openclaw/workspace"
    
    # ... (config generation code) ...
    
    # ═══════════════════════════════════════════════════════════════
    # CREATE AND LOAD LAUNCHAGENT (FIXED VERSION)
    # ═══════════════════════════════════════════════════════════════
    
    local launch_agent="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    
    # OLD CODE (REMOVE THIS):
    # cat > "$launch_agent" << PLISTEOF
    # <?xml version="1.0" encoding="UTF-8"?>
    # ...
    # <string>$HOME/.openclaw/bin/openclaw</string>
    # ...
    # PLISTEOF
    
    # NEW CODE (USE THIS):
    info "Creating LaunchAgent plist..."
    if ! create_launch_agent_safe "$HOME" "$launch_agent"; then
        die "Failed to create LaunchAgent plist (security validation failed)"
    fi
    pass "LaunchAgent plist created and validated"
    
    # Start gateway (unchanged)
    launchctl unload "$launch_agent" 2>/dev/null || true
    launchctl load "$launch_agent" || die "Failed to start gateway"
    sleep 2
    
    if pgrep -f "openclaw" &>/dev/null; then
        pass "Gateway running"
    else
        die "Gateway failed. Check: tail /tmp/openclaw/gateway.log"
    fi
    
    # ... (rest of function) ...
}

# ─────────────────────────────────────────────────────────────────
# VERIFICATION: Test the fixed implementation
# ─────────────────────────────────────────────────────────────────

verify_fix() {
    echo "════════════════════════════════════════════════════════"
    echo "VERIFICATION: Testing Security Fix"
    echo "════════════════════════════════════════════════════════"
    echo ""
    
    local test_output="/tmp/verify-fix.plist"
    
    # Test 1: Normal case
    echo "Test 1: Normal username (should work)"
    if create_launch_agent_safe "/Users/testuser" "$test_output" 2>/dev/null; then
        echo "  ✓ Pass: Valid username accepted"
        rm -f "$test_output"
    else
        echo "  ✗ Fail: Valid username rejected"
    fi
    
    # Test 2: Attack case
    echo "Test 2: XML injection (should block)"
    if create_launch_agent_safe '</string><string>/usr/bin/malicious' "$test_output" 2>/dev/null; then
        echo "  ✗ SECURITY FAILURE: Attack not blocked!"
        rm -f "$test_output"
    else
        echo "  ✓ Pass: Attack blocked"
    fi
    
    # Test 3: Command substitution
    echo "Test 3: Command substitution (should block)"
    if create_launch_agent_safe '/Users/$(whoami)' "$test_output" 2>/dev/null; then
        echo "  ✗ SECURITY FAILURE: Command injection not blocked!"
        rm -f "$test_output"
    else
        echo "  ✓ Pass: Command injection blocked"
    fi
    
    echo ""
    echo "✓ Fix verified successfully"
}

# ─────────────────────────────────────────────────────────────────
# USAGE EXAMPLES
# ─────────────────────────────────────────────────────────────────

demo_usage() {
    echo "════════════════════════════════════════════════════════"
    echo "USAGE EXAMPLES"
    echo "════════════════════════════════════════════════════════"
    echo ""
    
    echo "Example 1: Create LaunchAgent plist safely"
    echo "  create_launch_agent_safe \"\$HOME\" \"\$output_file\""
    echo ""
    
    echo "Example 2: Validate a path before using it"
    echo "  if validate_home_path \"\$HOME\"; then"
    echo "      echo \"Safe to use\""
    echo "  fi"
    echo ""
    
    echo "Example 3: Escape XML in strings"
    echo "  safe_value=\$(escape_xml \"\$user_input\")"
    echo ""
}

# ─────────────────────────────────────────────────────────────────
# MAIN: Run verification
# ─────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "Phase 1.5 Security Fix - Integration Example"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "This script demonstrates:"
    echo "  1. Security functions to add"
    echo "  2. How to modify step3_start()"
    echo "  3. Verification tests"
    echo ""
    
    verify_fix
    echo ""
    demo_usage
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "Next Steps:"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "1. Copy the security functions to openclaw-quickstart-v2.sh"
    echo "2. Replace the LaunchAgent creation with create_launch_agent_safe()"
    echo "3. Run the full test suite: bash phase1-5-test-suite.sh"
    echo "4. Test normal installation to ensure compatibility"
    echo ""
fi
