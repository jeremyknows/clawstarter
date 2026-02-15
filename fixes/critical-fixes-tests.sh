#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Critical Fixes Tests - Prism Cycle 2 Verification
# Tests for all 4 critical issues fixed in v2.5
# ═══════════════════════════════════════════════════════════════════

set -uo pipefail
# Note: -e removed to allow grep to return non-zero without exiting

# ─── Colors ───
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

PASS="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"
INFO="${CYAN}→${NC}"

pass()   { echo -e "  ${PASS} $1"; ((TESTS_PASSED++)); }
fail()   { echo -e "  ${FAIL} $1"; ((TESTS_FAILED++)); FAILED_TESTS+=("$1"); }
info()   { echo -e "  ${INFO} $1"; }
skip()   { echo -e "  ${YELLOW}⊘${NC} SKIP: $1"; ((TESTS_SKIPPED++)); }

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
FAILED_TESTS=()

SCRIPT_PATH="$HOME/Downloads/openclaw-setup/openclaw-quickstart-v2.5-SECURE.sh"

# ═══════════════════════════════════════════════════════════════════
# TEST SETUP
# ═══════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Critical Fixes Tests - v2.5 Verification${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${FAIL} Script not found: $SCRIPT_PATH"
    exit 1
fi

info "Testing: $SCRIPT_PATH"
echo ""

# ═══════════════════════════════════════════════════════════════════
# TEST 0: Syntax Validation
# ═══════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 0: Syntax Validation${NC}"

if bash -n "$SCRIPT_PATH" 2>/dev/null; then
    pass "Script has valid bash syntax"
else
    fail "Script has syntax errors"
    bash -n "$SCRIPT_PATH"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# TEST 1: Keychain Isolation Undermined (CRITICAL FIX 2.1)
# ═══════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 1: Keychain Isolation (Fix 2.1)${NC}"
echo -e "${DIM}Verifying keys never appear in shell variables during config generation${NC}"
echo ""

# Test 1.1: Check that step3_start doesn't assign keys to shell variables
if grep -E '^\s*(openrouter_key|anthropic_key|gateway_token)=\$\(keychain_get' "$SCRIPT_PATH" >/dev/null 2>&1; then
    fail "step3_start still retrieves keys into shell variables"
else
    pass "step3_start does NOT retrieve keys into shell variables"
fi

# Test 1.2: Check that Python heredoc uses Keychain directly
if grep "def keychain_get" "$SCRIPT_PATH" >/dev/null 2>&1; then
    if grep -A10 "def keychain_get" "$SCRIPT_PATH" | grep -q "subprocess"; then
        pass "Python has keychain_get function using subprocess"
    else
        fail "Python keychain_get doesn't use subprocess"
    fi
else
    fail "Python missing keychain_get function"
fi

# Test 1.3: Check that Python retrieves keys via its own keychain_get
if grep -E "openrouter_key = keychain_get\(KEYCHAIN_SERVICE" "$SCRIPT_PATH" >/dev/null 2>&1; then
    pass "Python retrieves openrouter_key via keychain_get()"
else
    fail "Python doesn't retrieve keys via its own keychain_get()"
fi

if grep -E "anthropic_key = keychain_get\(KEYCHAIN_SERVICE" "$SCRIPT_PATH" >/dev/null 2>&1; then
    pass "Python retrieves anthropic_key via keychain_get()"
else
    fail "Python doesn't retrieve anthropic_key via its own keychain_get()"
fi

# Test 1.4: Ensure no shell variable substitution in Python code section
# The heredoc should be quoted, so there should be no $openrouter_key etc in heredoc-style shell vars
if grep "openrouter_key = '''" "$SCRIPT_PATH" >/dev/null 2>&1; then
    fail "Shell variable substitution still present for openrouter_key"
else
    pass "No shell variable substitution for keys in Python"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# TEST 2: Unquoted Python Heredoc (CRITICAL FIX 2.2)
# ═══════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 2: Quoted Heredoc (Fix 2.2)${NC}"
echo -e "${DIM}Verifying Python heredoc is quoted to prevent command injection${NC}"
echo ""

# Test 2.1: Check that PYEOF is quoted
if grep -E "<<\s*'PYEOF'" "$SCRIPT_PATH" >/dev/null 2>&1; then
    pass "Python heredoc uses quoted delimiter ('PYEOF')"
else
    fail "Python heredoc NOT quoted (vulnerable to injection)"
fi

# Test 2.2: Check there's no unquoted PYEOF  
# Count lines with unquoted heredoc (PYEOF not preceded by quote)
unquoted_lines=$(grep -E "<<[[:space:]]*PYEOF" "$SCRIPT_PATH" 2>/dev/null | grep -v "'" || true)
if [ -z "$unquoted_lines" ]; then
    pass "No unquoted Python heredocs found"
else
    unquoted_count=$(echo "$unquoted_lines" | wc -l | tr -d ' ')
    fail "Found $unquoted_count unquoted Python heredocs"
fi

# Test 2.3: Verify all heredocs in Python section are safe
# Check that any key-containing heredocs are quoted
if grep -E "<<\s*PYEOF" "$SCRIPT_PATH" | grep -v "'" >/dev/null 2>&1; then
    fail "Some Python heredocs may be unquoted"
else
    pass "All Python heredocs appear properly quoted"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# TEST 3: Port Conflicts Unchecked (CRITICAL FIX 2.3)
# ═══════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 3: Port Conflict Detection (Fix 2.3)${NC}"
echo -e "${DIM}Verifying port 18789 is checked before gateway start${NC}"
echo ""

# Test 3.1: Check that check_port_available function exists
if grep -E "^check_port_available\(\)" "$SCRIPT_PATH" >/dev/null 2>&1; then
    pass "check_port_available() function exists"
else
    fail "check_port_available() function missing"
fi

# Test 3.2: Check that function uses lsof
if grep -A10 "check_port_available\(\)" "$SCRIPT_PATH" | grep -E "lsof.*-ti" >/dev/null 2>&1; then
    pass "check_port_available uses lsof -ti"
else
    fail "check_port_available doesn't use lsof properly"
fi

# Test 3.3: Check that handle_port_conflict function exists
if grep -E "^handle_port_conflict\(\)" "$SCRIPT_PATH" >/dev/null 2>&1; then
    pass "handle_port_conflict() function exists"
else
    fail "handle_port_conflict() function missing"
fi

# Test 3.4: Check that step3_start calls check_port_available
if grep "check_port_available" "$SCRIPT_PATH" | grep -v "^check_port_available" >/dev/null 2>&1; then
    pass "step3_start() calls check_port_available"
else
    fail "step3_start() does NOT check port availability"
fi

# Test 3.5: Check that port check happens BEFORE launchctl load
# Use line numbers from the actual file
port_check_line=$(grep -n "check_port_available.*DEFAULT_GATEWAY_PORT" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
launchctl_line=$(grep -n "launchctl load" "$SCRIPT_PATH" | head -1 | cut -d: -f1)

if [ -n "$port_check_line" ] && [ -n "$launchctl_line" ]; then
    if [ "$port_check_line" -lt "$launchctl_line" ]; then
        pass "Port check occurs BEFORE launchctl load (line $port_check_line < $launchctl_line)"
    else
        fail "Port check does NOT occur before launchctl load"
    fi
else
    fail "Could not determine order of port check and launchctl"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# TEST 4: Keychain Error Handling (CRITICAL FIX 2.4)
# ═══════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 4: Keychain Error Handling (Fix 2.4)${NC}"
echo -e "${DIM}Verifying user warning before Keychain and recovery options on failure${NC}"
echo ""

# Test 4.1: Check that keychain_warn_user function exists
if grep -E "^keychain_warn_user\(\)" "$SCRIPT_PATH" >/dev/null 2>&1; then
    pass "keychain_warn_user() function exists"
else
    fail "keychain_warn_user() function missing"
fi

# Test 4.2: Check warning mentions Keychain access
if grep -A10 "keychain_warn_user\(\)" "$SCRIPT_PATH" | grep -E "Keychain Access" >/dev/null 2>&1; then
    pass "Warning message mentions Keychain Access"
else
    fail "Warning message doesn't explain Keychain access"
fi

# Test 4.3: Check that keychain_store_with_recovery function exists
if grep -E "^keychain_store_with_recovery\(\)" "$SCRIPT_PATH" >/dev/null 2>&1; then
    pass "keychain_store_with_recovery() function exists"
else
    fail "keychain_store_with_recovery() function missing"
fi

# Test 4.4: Check recovery options include retry, skip, cancel
recovery_func=$(awk '/^keychain_store_with_recovery\(\)/,/^}/' "$SCRIPT_PATH")
if echo "$recovery_func" | grep -q "Try again"; then
    pass "Recovery includes retry option"
else
    fail "Recovery missing retry option"
fi

if echo "$recovery_func" | grep -q "Skip Keychain\|manual"; then
    pass "Recovery includes manual .env fallback"
else
    fail "Recovery missing manual .env fallback"
fi

if echo "$recovery_func" | grep -q "Cancel"; then
    pass "Recovery includes cancel option"
else
    fail "Recovery missing cancel option"
fi

# Test 4.5: Check that keychain_store returns specific error codes
store_func=$(awk '/^keychain_store\(\)/,/^}/' "$SCRIPT_PATH")
if echo "$store_func" | grep -q "KEYCHAIN_DENIED"; then
    pass "keychain_store returns KEYCHAIN_DENIED on access denial"
else
    fail "keychain_store doesn't return KEYCHAIN_DENIED"
fi

# Test 4.6: Check that step2_configure calls keychain_warn_user before storage
step2_content=$(awk '/^step2_configure\(\)/,/^}/' "$SCRIPT_PATH")
if echo "$step2_content" | grep -q "keychain_warn_user"; then
    pass "step2_configure calls keychain_warn_user"
else
    fail "step2_configure doesn't warn user before Keychain"
fi

# Test 4.7: Check that step2_configure uses keychain_store_with_recovery
if echo "$step2_content" | grep -q "keychain_store_with_recovery"; then
    pass "step2_configure uses keychain_store_with_recovery"
else
    fail "step2_configure doesn't use recovery-enabled storage"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# TEST 5: Version Bump
# ═══════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 5: Version Bump${NC}"
echo ""

if grep -E 'SCRIPT_VERSION="2\.5\.0' "$SCRIPT_PATH" >/dev/null 2>&1; then
    pass "Version bumped to 2.5.0"
else
    fail "Version NOT bumped to 2.5.0"
fi

if grep -E "clawstarter-v2\.5-secure" "$SCRIPT_PATH" >/dev/null 2>&1; then
    pass "Meta created_by updated to v2.5"
else
    fail "Meta created_by not updated"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# TEST 6: No Regressions
# ═══════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 6: No Regressions${NC}"
echo ""

# Phase 1 fixes still present
if grep -q "validate_bot_name\(\)" "$SCRIPT_PATH"; then
    pass "Input validation (1.2) still present"
else
    fail "Input validation (1.2) MISSING - regression!"
fi

if grep -q "verify_sha256\(\)" "$SCRIPT_PATH"; then
    pass "SHA256 verification (1.4) still present"
else
    fail "SHA256 verification (1.4) MISSING - regression!"
fi

if grep -q "escape_xml\(\)" "$SCRIPT_PATH"; then
    pass "XML escaping (1.5) still present"
else
    fail "XML escaping (1.5) MISSING - regression!"
fi

if grep -q "validate_home_path\(\)" "$SCRIPT_PATH"; then
    pass "Path validation (1.5) still present"
else
    fail "Path validation (1.5) MISSING - regression!"
fi

# Check secure file creation pattern (touch followed by chmod 600 on consecutive lines)
touch_count=$(grep -c 'touch "\$' "$SCRIPT_PATH" 2>/dev/null | tr -d '[:space:]')
chmod_count=$(grep -c 'chmod 600' "$SCRIPT_PATH" 2>/dev/null | tr -d '[:space:]')
touch_count=${touch_count:-0}
chmod_count=${chmod_count:-0}
if [ "$touch_count" -ge 3 ] && [ "$chmod_count" -ge 5 ]; then
    pass "Secure file creation (1.3) still present (touch: $touch_count, chmod 600: $chmod_count)"
else
    fail "Secure file creation (1.3) pattern MISSING - touch=$touch_count chmod=$chmod_count"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# TEST 7: Injection Safety Verification
# ═══════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 7: Injection Safety${NC}"
echo -e "${DIM}Verifying malicious Keychain values can't execute commands${NC}"
echo ""

# Check that all other heredocs are also quoted (skill packs, etc)
unquoted_heredocs=$(grep -E "<<\s*[A-Z]+[^']" "$SCRIPT_PATH" | grep -v "PLISTEOF" | wc -l || echo "0")
# PLISTEOF is OK to be unquoted since it only contains static plist content

# Count total heredocs vs quoted ones
total_heredocs=$(grep -cE "<<\s*[A-Z']+" "$SCRIPT_PATH" || echo "0")
quoted_heredocs=$(grep -cE "<<\s*'[A-Z]+'" "$SCRIPT_PATH" || echo "0")

if [ "$quoted_heredocs" -ge 5 ]; then
    pass "Found $quoted_heredocs quoted heredocs (good protection)"
else
    fail "Only $quoted_heredocs quoted heredocs (expected more)"
fi

# Verify no eval of untrusted input
if grep -E "eval.*\\\$" "$SCRIPT_PATH" | grep -v "brew shellenv" >/dev/null 2>&1; then
    fail "Found potentially dangerous eval usage"
else
    pass "No dangerous eval of variables"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Test Summary${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
echo -e "  ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
echo ""

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed Tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${FAIL} $test"
    done
    echo ""
    echo -e "${RED}❌ VERIFICATION FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}✅ ALL CRITICAL FIXES VERIFIED${NC}"
    echo ""
    echo -e "${DIM}Ready for Prism Cycle 2 review.${NC}"
    exit 0
fi
