#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Phase 3 Critical Fixes - Test Suite
# Tests for Fix #2 (Disk Space) and Fix #3 (Locked Keychain)
# Generated: 2026-02-11
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"
SKIP="${YELLOW}⊘${NC}"

pass() { echo -e "  ${PASS} $1"; PASSED=$((PASSED+1)); }
fail() { echo -e "  ${FAIL} $1"; FAILED=$((FAILED+1)); }
skip() { echo -e "  ${SKIP} $1 (manual test)"; SKIPPED=$((SKIPPED+1)); }

PASSED=0
FAILED=0
SKIPPED=0

SCRIPT_PATH="${HOME}/Downloads/openclaw-setup/openclaw-quickstart-v2.6-SECURE.sh"

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Phase 3 Critical Fixes - Test Suite${NC}"
echo -e "${BOLD}  Testing: openclaw-quickstart-v2.6-SECURE.sh${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

# ─────────────────────────────────────────────────────────────
# Pre-flight checks
# ─────────────────────────────────────────────────────────────
echo -e "${CYAN}Pre-flight Checks${NC}"
echo ""

if [ -f "$SCRIPT_PATH" ]; then
    pass "Script exists at expected path"
else
    fail "Script not found at: $SCRIPT_PATH"
    echo -e "\n${RED}Cannot continue without script. Exiting.${NC}"
    exit 1
fi

# Verify syntax
if bash -n "$SCRIPT_PATH" 2>/dev/null; then
    pass "Bash syntax validation passes"
else
    fail "Bash syntax validation failed"
fi

# Check version
if grep -q 'SCRIPT_VERSION="2.6.0-secure"' "$SCRIPT_PATH"; then
    pass "Version is 2.6.0-secure"
else
    fail "Version not updated to 2.6.0-secure"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Fix #2: Disk Space Check Tests
# ─────────────────────────────────────────────────────────────
echo -e "${CYAN}Fix #2: Disk Space Check${NC}"
echo ""

# Test: check_disk_space function exists
if grep -q "check_disk_space()" "$SCRIPT_PATH"; then
    pass "check_disk_space() function exists"
else
    fail "check_disk_space() function not found"
fi

# Test: Function uses df -k command
if grep -A10 "check_disk_space()" "$SCRIPT_PATH" | grep -q 'df -k /'; then
    pass "Uses df -k / to check available space"
else
    fail "Does not use df -k / for disk check"
fi

# Test: 500MB threshold
if grep -A5 "check_disk_space()" "$SCRIPT_PATH" | grep -q 'required_mb=500'; then
    pass "500MB threshold set correctly"
else
    fail "500MB threshold not found"
fi

# Test: check_disk_space called in step1_install
if grep -A20 "step1_install()" "$SCRIPT_PATH" | grep -q "check_disk_space"; then
    pass "check_disk_space called in step1_install()"
else
    fail "check_disk_space not called in step1_install()"
fi

# Test: Called BEFORE macOS check (position verification)
DISK_CHECK_LINE=$(grep -n "check_disk_space" "$SCRIPT_PATH" | grep -v "^[0-9]*:.*#" | grep -v "function" | head -1 | cut -d: -f1)
MACOS_CHECK_LINE=$(grep -n 'uname -s' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
if [ -n "$DISK_CHECK_LINE" ] && [ -n "$MACOS_CHECK_LINE" ]; then
    if [ "$DISK_CHECK_LINE" -lt "$MACOS_CHECK_LINE" ]; then
        pass "Disk space check runs BEFORE other operations"
    else
        fail "Disk space check should run before macOS check"
    fi
else
    fail "Could not verify check order"
fi

# Test: Error message includes clear guidance
if grep -A20 "check_disk_space()" "$SCRIPT_PATH" | grep -q "Free up disk space"; then
    pass "Error message includes actionable guidance"
else
    fail "Error message missing user guidance"
fi

# Test: Exits with code 1 on failure
if grep -A20 "check_disk_space()" "$SCRIPT_PATH" | grep -q "exit 1"; then
    pass "Exits with code 1 on insufficient space"
else
    fail "Does not exit on insufficient space"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Fix #3: Locked Keychain Handling Tests
# ─────────────────────────────────────────────────────────────
echo -e "${CYAN}Fix #3: Locked Keychain Handling (Python heredoc)${NC}"
echo ""

# Test: Python keychain_get has timeout
if grep -A50 'def keychain_get' "$SCRIPT_PATH" | grep -q 'timeout=5'; then
    pass "Python keychain_get() has 5-second timeout"
else
    fail "Python keychain_get() missing timeout"
fi

# Test: max_retries = 3
if grep -A10 'def keychain_get' "$SCRIPT_PATH" | grep -q 'max_retries = 3'; then
    pass "Max retries set to 3"
else
    fail "Max retries not set to 3"
fi

# Test: Handles returncode 51 (locked keychain)
if grep -A80 'def keychain_get' "$SCRIPT_PATH" | grep -q 'returncode == 51'; then
    pass "Handles return code 51 (Keychain locked)"
else
    fail "Does not handle return code 51"
fi

# Test: Handles TimeoutExpired exception
if grep -A80 'def keychain_get' "$SCRIPT_PATH" | grep -q 'subprocess.TimeoutExpired'; then
    pass "Catches subprocess.TimeoutExpired exception"
else
    fail "Does not catch TimeoutExpired"
fi

# Test: Retry loop with user prompt
if grep -A80 'def keychain_get' "$SCRIPT_PATH" | grep -q 'Please unlock your Mac and press Enter to retry'; then
    pass "Includes user-friendly retry prompt"
else
    fail "Missing retry prompt message"
fi

# Test: Handles non-interactive mode (EOFError)
if grep -A80 'def keychain_get' "$SCRIPT_PATH" | grep -q 'except EOFError'; then
    pass "Handles non-interactive mode (EOFError)"
else
    fail "Does not handle non-interactive mode"
fi

# Test: Falls back gracefully on max retries
if grep -A80 'def keychain_get' "$SCRIPT_PATH" | grep -q 'max retries reached'; then
    pass "Clear message on max retries reached"
else
    fail "Missing max retries message"
fi

# Test: Returns None on failure (not empty string)
if grep -A80 'def keychain_get' "$SCRIPT_PATH" | grep -q 'return None'; then
    pass "Returns None on failure (distinguishes from empty key)"
else
    fail "Should return None on failure"
fi

# Test: Caller checks for None
if grep -A10 'openrouter_key = keychain_get' "$SCRIPT_PATH" | grep -q 'if openrouter_key is None'; then
    pass "Caller checks for None return value"
else
    fail "Caller does not check for None"
fi

# Test: Manual .env fallback message
if grep -A120 'def keychain_get' "$SCRIPT_PATH" | grep -q 'manual .env setup'; then
    pass "Manual .env setup fallback mentioned"
else
    fail "Missing manual .env fallback guidance"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Preservation Tests (Existing Fixes Still Present)
# ─────────────────────────────────────────────────────────────
echo -e "${CYAN}Preservation Tests (Existing Fixes)${NC}"
echo ""

# Phase 1 fixes
if grep -q "KEYCHAIN_SERVICE" "$SCRIPT_PATH"; then
    pass "Phase 1.1: Keychain configuration preserved"
else
    fail "Phase 1.1: Keychain configuration missing"
fi

if grep -q "validate_bot_name" "$SCRIPT_PATH"; then
    pass "Phase 1.2: Input validation preserved"
else
    fail "Phase 1.2: Input validation missing"
fi

# Check for touch + chmod 600 pattern (may be on separate lines)
if grep -q 'touch "\$' "$SCRIPT_PATH" && grep -q "chmod 600" "$SCRIPT_PATH"; then
    pass "Phase 1.3: Secure file creation preserved"
else
    fail "Phase 1.3: Secure file creation missing"
fi

if grep -q "TEMPLATE_CHECKSUMS" "$SCRIPT_PATH"; then
    pass "Phase 1.4: Template checksums preserved"
else
    fail "Phase 1.4: Template checksums missing"
fi

if grep -q "escape_xml" "$SCRIPT_PATH"; then
    pass "Phase 1.5: Plist escaping preserved"
else
    fail "Phase 1.5: Plist escaping missing"
fi

# Phase 2 fixes
if grep -q "'PYEOF'" "$SCRIPT_PATH"; then
    pass "Phase 2.1-2.2: Quoted Python heredoc preserved"
else
    fail "Phase 2.1-2.2: Quoted Python heredoc missing"
fi

if grep -q "check_port_available" "$SCRIPT_PATH"; then
    pass "Phase 2.3: Port conflict detection preserved"
else
    fail "Phase 2.3: Port conflict detection missing"
fi

if grep -q "keychain_store_with_recovery" "$SCRIPT_PATH"; then
    pass "Phase 2.4: Keychain recovery options preserved"
else
    fail "Phase 2.4: Keychain recovery options missing"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Manual Test Reminders
# ─────────────────────────────────────────────────────────────
echo -e "${CYAN}Manual Tests Required${NC}"
echo ""

skip "Low disk space: Create near-full disk image and run script"
skip "Locked Keychain: Lock keychain via 'security lock-keychain' and run"
skip "Keychain timeout: Test with 'security set-keychain-settings -t 1' (1-second timeout)"
skip "Retry success: Lock keychain, start script, unlock during retry prompt"
skip "Max retries: Keep keychain locked through all 3 retries"

echo ""

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Test Summary${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC}  $PASSED"
echo -e "  ${RED}Failed:${NC}  $FAILED"
echo -e "  ${YELLOW}Skipped:${NC} $SKIPPED (manual tests)"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✅ All automated tests passed!${NC}"
    echo ""
    echo -e "  ${CYAN}Next steps:${NC}"
    echo "  1. Run manual tests listed above"
    echo "  2. Test full script flow: bash openclaw-quickstart-v2.6-SECURE.sh"
    echo "  3. Verify gateway starts: curl http://127.0.0.1:18789/health"
    echo ""
    exit 0
else
    echo -e "  ${RED}${BOLD}❌ Some tests failed. Review above.${NC}"
    echo ""
    exit 1
fi
