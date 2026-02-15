#!/usr/bin/env bash
# Reproduction test for stdin starvation bug
# This demonstrates the difference between prompt() and confirm()

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=================================="
echo "stdin Starvation Bug Reproduction"
echo "=================================="
echo ""

# Simulate the BROKEN prompt() function
prompt_broken() {
    local question="$1"
    local default="${2:-}"
    local response
    
    if [ -n "$default" ]; then
        echo -en "${CYAN}?${NC} ${question} [${default}]: "
    else
        echo -en "${CYAN}?${NC} ${question}: "
    fi
    
    # BUG: No /dev/tty fallback!
    read -r response
    
    if [ -z "$response" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$response"
    fi
}

# Simulate the FIXED prompt() function (like confirm())
prompt_fixed() {
    local question="$1"
    local default="${2:-}"
    local response
    
    if [ -n "$default" ]; then
        echo -en "${CYAN}?${NC} ${question} [${default}]: "
    else
        echo -en "${CYAN}?${NC} ${question}: "
    fi
    
    # FIX: Use /dev/tty for piped execution
    if [ -t 0 ]; then
        read -r response
    else
        read -r response < /dev/tty 2>/dev/null || response=""
    fi
    
    if [ -z "$response" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$response"
    fi
}

echo "Test 1: Check if stdin is a TTY"
if [ -t 0 ]; then
    echo -e "  ${GREEN}✓ stdin is a TTY (normal execution)${NC}"
    echo "    Bug will NOT reproduce in this mode."
    echo ""
else
    echo -e "  ${RED}✗ stdin is NOT a TTY (piped execution)${NC}"
    echo "    Bug WILL reproduce!"
    echo ""
fi

echo "Test 2: BROKEN prompt() - will hang or consume stdin"
echo "  (Type something or hit Ctrl+C to skip)"
echo ""

name=$(prompt_broken "What's your name?" "TestUser")
echo ""
echo "  You entered: '$name'"
echo ""

echo "Test 3: FIXED prompt() - works even when piped"
echo ""

email=$(prompt_fixed "What's your email?" "test@example.com")
echo ""
echo "  You entered: '$email'"
echo ""

echo -e "${GREEN}All tests completed!${NC}"
echo ""
echo "To test piped execution:"
echo "  cat $0 | bash"
echo ""
echo "Expected:"
echo "  - Broken version will hang or consume script source"
echo "  - Fixed version will prompt correctly via /dev/tty"
