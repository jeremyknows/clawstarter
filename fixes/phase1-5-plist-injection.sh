#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# PHASE 1.5 FIX: LaunchAgent Plist XML Injection Protection
# ═══════════════════════════════════════════════════════════════════
#
# This file contains the FIXED version of the LaunchAgent plist generation
# from openclaw-quickstart-v2.sh with proper validation and escaping.
#
# VULNERABILITIES FIXED:
# 1. XML injection via $HOME variable
# 2. Command substitution attacks
# 3. Invalid path manipulation
#
# SECURITY MEASURES:
# - Path validation (must be /Users/[valid-username])
# - XML entity escaping
# - plutil validation
# - Safe heredoc construction
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── XML Security Functions ───

# Escape XML special characters to prevent injection
# Handles: < > & " '
escape_xml() {
    local input="$1"
    # Replace special XML characters with entities
    input="${input//&/&amp;}"   # Must be first!
    input="${input//</&lt;}"
    input="${input//>/&gt;}"
    input="${input//\"/&quot;}"
    input="${input//\'/&apos;}"
    echo "$input"
}

# Validate $HOME path for LaunchAgent usage
# Returns: 0 if valid, 1 if invalid
validate_home_path() {
    local home_path="$1"
    
    # Rule 1: Must start with /Users/
    if [[ ! "$home_path" =~ ^/Users/ ]]; then
        echo "ERROR: HOME must start with /Users/ (got: $home_path)" >&2
        return 1
    fi
    
    # Rule 2: Extract username and validate format
    # Valid: alphanumeric, hyphens, underscores (common macOS usernames)
    local username="${home_path#/Users/}"
    username="${username%%/*}"  # Strip anything after first slash
    
    if [[ ! "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid username format: $username" >&2
        echo "  Must contain only: letters, numbers, hyphens, underscores" >&2
        return 1
    fi
    
    # Rule 3: Path must not contain suspicious characters
    # Block: command substitution, XML tags, null bytes, newlines
    # Use explicit character matching to avoid regex escaping issues
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
    
    # Rule 4: Must be exactly /Users/username (no trailing path components for safety)
    if [[ "$home_path" != "/Users/$username" ]]; then
        echo "ERROR: HOME must be exactly /Users/username (got: $home_path)" >&2
        return 1
    fi
    
    # Rule 5: Path should exist (optional warning, not failure)
    if [ ! -d "$home_path" ]; then
        echo "WARNING: HOME directory does not exist: $home_path" >&2
        # Continue anyway - might be creating new user
    fi
    
    return 0
}

# ─── FIXED: Safe LaunchAgent Plist Creation ───

create_launch_agent_safe() {
    local home_path="$1"
    local output_file="$2"
    
    # STEP 1: Validate $HOME before using it
    if ! validate_home_path "$home_path"; then
        echo "FATAL: Unsafe HOME value rejected" >&2
        return 1
    fi
    
    # STEP 2: Escape XML entities (defense-in-depth)
    local home_escaped
    home_escaped=$(escape_xml "$home_path")
    
    # STEP 3: Build paths with escaped values
    local openclaw_bin="${home_escaped}/.openclaw/bin/openclaw"
    local working_dir="${home_escaped}/.openclaw"
    
    # STEP 4: Generate plist using printf (safer than heredoc for variables)
    # Note: We still use heredoc but with validated/escaped variables only
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
    
    # STEP 5: Validate generated plist with Apple's plutil
    if ! plutil -lint "$output_file" >/dev/null 2>&1; then
        echo "ERROR: Generated plist failed validation" >&2
        echo "  File: $output_file" >&2
        plutil -lint "$output_file" 2>&1 | head -5 >&2
        rm -f "$output_file"
        return 1
    fi
    
    echo "SUCCESS: Safe plist created and validated: $output_file"
    return 0
}

# ─── ALTERNATIVE: Use plutil to generate plist programmatically ───
# This is the SAFEST approach - no string interpolation at all

create_launch_agent_plutil() {
    local home_path="$1"
    local output_file="$2"
    
    # Validate $HOME
    if ! validate_home_path "$home_path"; then
        echo "FATAL: Unsafe HOME value rejected" >&2
        return 1
    fi
    
    # Create empty plist
    plutil -create xml1 "$output_file" || return 1
    
    # Build plist using plutil commands (no string interpolation!)
    plutil -insert Label -string "ai.openclaw.gateway" "$output_file"
    plutil -insert RunAtLoad -bool true "$output_file"
    plutil -insert KeepAlive -bool true "$output_file"
    plutil -insert StandardErrorPath -string "/tmp/openclaw/gateway.log" "$output_file"
    plutil -insert WorkingDirectory -string "${home_path}/.openclaw" "$output_file"
    
    # ProgramArguments array
    plutil -insert ProgramArguments -array "$output_file"
    plutil -insert ProgramArguments.0 -string "${home_path}/.openclaw/bin/openclaw" "$output_file"
    plutil -insert ProgramArguments.1 -string "gateway" "$output_file"
    plutil -insert ProgramArguments.2 -string "start" "$output_file"
    
    # Validate
    if ! plutil -lint "$output_file" >/dev/null 2>&1; then
        echo "ERROR: Generated plist failed validation" >&2
        rm -f "$output_file"
        return 1
    fi
    
    echo "SUCCESS: Safe plist created with plutil: $output_file"
    return 0
}

# ─── Integration into openclaw-quickstart-v2.sh ───
# Replace lines 554-577 in step3_start() with:

step3_start_FIXED_EXCERPT() {
    # ... (previous code) ...
    
    # Create and load LaunchAgent (FIXED VERSION)
    local launch_agent="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    
    # METHOD 1: Safe heredoc with validation + escaping
    if ! create_launch_agent_safe "$HOME" "$launch_agent"; then
        die "Failed to create LaunchAgent plist (security validation failed)"
    fi
    
    # OR METHOD 2: Ultra-safe plutil approach (uncomment to use)
    # if ! create_launch_agent_plutil "$HOME" "$launch_agent"; then
    #     die "Failed to create LaunchAgent plist"
    # fi
    
    # Start gateway (unchanged)
    launchctl unload "$launch_agent" 2>/dev/null || true
    launchctl load "$launch_agent" || die "Failed to start gateway"
    sleep 2
    
    # ... (rest of function) ...
}

# ─── Demonstration Functions ───

demo_vulnerable_vs_safe() {
    echo "════════════════════════════════════════════════════════"
    echo "DEMONSTRATION: Vulnerable vs Safe Implementation"
    echo "════════════════════════════════════════════════════════"
    echo ""
    
    local test_home="/Users/testuser"
    local safe_output="/tmp/safe-plist-demo.plist"
    
    echo "Creating SAFE plist with HOME=$test_home..."
    if create_launch_agent_safe "$test_home" "$safe_output"; then
        echo "✓ Created successfully"
        echo ""
        echo "Generated plist:"
        cat "$safe_output"
        echo ""
        echo "Validation:"
        plutil -lint "$safe_output"
        rm -f "$safe_output"
    else
        echo "✗ Creation failed (as expected for invalid inputs)"
    fi
}

# ─── Main: Run demo if executed directly ───
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    demo_vulnerable_vs_safe
fi
