#!/bin/bash
# test-stdin-fix.sh
# Verify stdin/TTY fix works in all execution contexts

set -e

SCRIPT="openclaw-quickstart-v2.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "stdin/TTY Fix Verification Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -f "$SCRIPT" ]; then
    echo "✗ ERROR: $SCRIPT not found"
    echo "  Run from clawstarter directory"
    exit 1
fi

# Test 1: Syntax check
echo "Test 1: Syntax validation"
if bash -n "$SCRIPT"; then
    echo "  ✓ PASS: No syntax errors"
else
    echo "  ✗ FAIL: Syntax errors detected"
    exit 1
fi
echo ""

# Test 2: Verify prompt() has /dev/tty handling
echo "Test 2: Check prompt() function has fix"
if grep -A 5 "^prompt()" "$SCRIPT" | grep -q "/dev/tty"; then
    echo "  ✓ PASS: prompt() has /dev/tty handling"
else
    echo "  ✗ FAIL: prompt() missing /dev/tty handling"
    exit 1
fi
echo ""

# Test 3: Verify prompt_validated() has /dev/tty handling
echo "Test 3: Check prompt_validated() function has fix"
if grep -A 10 "^prompt_validated()" "$SCRIPT" | grep -q "/dev/tty"; then
    echo "  ✓ PASS: prompt_validated() has /dev/tty handling"
else
    echo "  ✗ FAIL: prompt_validated() missing /dev/tty handling"
    exit 1
fi
echo ""

# Test 4: Verify confirm() still has /dev/tty handling
echo "Test 4: Check confirm() function (should already be fixed)"
if grep -A 10 "^confirm()" "$SCRIPT" | grep -q "/dev/tty"; then
    echo "  ✓ PASS: confirm() has /dev/tty handling"
else
    echo "  ✗ FAIL: confirm() missing /dev/tty handling"
    exit 1
fi
echo ""

# Test 5: Count occurrences of "read -r response" without /dev/tty check
echo "Test 5: Check for remaining unprotected read statements"
UNPROTECTED=$(grep -n "read -r response" "$SCRIPT" | grep -v "if \[ -t 0 \]" | grep -v "/dev/tty" | grep -v "^[[:space:]]*#" | wc -l | tr -d ' ')

if [ "$UNPROTECTED" -eq 0 ]; then
    echo "  ✓ PASS: All read statements protected with /dev/tty check"
else
    echo "  ✗ FAIL: Found $UNPROTECTED unprotected read statements:"
    grep -n "read -r response" "$SCRIPT" | grep -v "if \[ -t 0 \]" | grep -v "/dev/tty" | grep -v "^[[:space:]]*#" || true
    exit 1
fi
echo ""

# Test 6: Manual inspection prompt
echo "Test 6: Manual verification (requires user interaction)"
echo ""
echo "  The following tests require running the script interactively."
echo "  Please run these commands manually:"
echo ""
echo "  A. Direct execution (normal mode):"
echo "     bash $SCRIPT"
echo "     → Prompts should appear normally"
echo ""
echo "  B. Piped execution (critical test):"
echo "     cat $SCRIPT | bash"
echo "     → Prompts should still work via /dev/tty"
echo ""
echo "  C. Non-interactive mode:"
echo "     echo '' | bash $SCRIPT"
echo "     → Should fail gracefully with clear error"
echo ""
echo "  ⚠️  Test B is CRITICAL — piped execution was previously broken"
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Automated Tests: ✓ PASSED (5/5)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "NEXT STEP: Run manual verification tests above"
echo ""
