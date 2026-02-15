#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# Phase 1.2: Injection Prevention Test Suite
# Tests all validation functions with malicious inputs
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"

passed=0
failed=0

# ═══════════════════════════════════════════════════════════════════
# Validation Functions (copied from fixed script for testing)
# ═══════════════════════════════════════════════════════════════════

readonly -a ALLOWED_MODELS=(
    "opencode/kimi-k2.5-free"
    "opencode/glm-4.7-free"
    "openrouter/moonshotai/kimi-k2.5"
    "openrouter/anthropic/claude-sonnet-4-5"
    "openrouter/anthropic/claude-opus-4"
    "openrouter/openai/gpt-4o"
    "openrouter/google/gemini-pro"
    "anthropic/claude-sonnet-4-5"
    "anthropic/claude-opus-4"
)
readonly -a ALLOWED_SECURITY_LEVELS=("low" "medium" "high")
readonly -a ALLOWED_PERSONALITIES=("casual" "professional" "direct")

validate_bot_name() {
    local name="$1"
    local max_length=32
    local min_length=2
    
    if [ ${#name} -lt $min_length ] || [ ${#name} -gt $max_length ]; then
        echo "ERROR: Bot name must be ${min_length}-${max_length} characters"
        return 1
    fi
    
    if ! [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        echo "ERROR: Bot name must start with a letter and contain only letters, numbers, hyphens, and underscores"
        return 1
    fi
    
    local dangerous_patterns=(
        "'" '"' '`' '$' ';' '|' '&' '>' '<' '(' ')' '{' '}' '[' ']'
        '\' '!' '#' '*' '?' '~' '%' '^' '=' '+' '@' ':'
    )
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$name" == *"$pattern"* ]]; then
            echo "ERROR: Bot name contains forbidden character: $pattern"
            return 1
        fi
    done
    
    echo "OK"
    return 0
}

validate_model() {
    local model="$1"
    local valid=false
    
    for allowed in "${ALLOWED_MODELS[@]}"; do
        if [ "$model" = "$allowed" ]; then
            valid=true
            break
        fi
    done
    
    if ! $valid; then
        echo "ERROR: Model '$model' is not in the allowed list"
        return 1
    fi
    
    echo "OK"
    return 0
}

validate_menu_selection() {
    local input="$1"
    local max_value="${2:-9}"
    
    if [ -z "$input" ]; then
        echo "OK"
        return 0
    fi
    
    if ! [[ "$input" =~ ^[0-9,]+$ ]]; then
        echo "ERROR: Selection must contain only numbers and commas"
        return 1
    fi
    
    IFS=',' read -ra NUMS <<< "$input"
    for num in "${NUMS[@]}"; do
        if [ -z "$num" ]; then
            continue
        fi
        if [ "$num" -gt "$max_value" ] || [ "$num" -lt 1 ]; then
            echo "ERROR: Selection '$num' is out of range (1-$max_value)"
            return 1
        fi
    done
    
    echo "OK"
    return 0
}

validate_api_key() {
    local key="$1"
    
    if [ -z "$key" ]; then
        echo "OK"
        return 0
    fi
    
    # Block shell metacharacters - use character class without escaping
    if [[ "$key" == *"'"* ]] || [[ "$key" == *'"'* ]] || [[ "$key" == *'`'* ]] || \
       [[ "$key" == *'$'* ]] || [[ "$key" == *';'* ]] || [[ "$key" == *'|'* ]] || \
       [[ "$key" == *'&'* ]] || [[ "$key" == *'>'* ]] || [[ "$key" == *'<'* ]] || \
       [[ "$key" == *'('* ]] || [[ "$key" == *')'* ]] || [[ "$key" == *'{'* ]] || \
       [[ "$key" == *'}'* ]] || [[ "$key" == *'['* ]] || [[ "$key" == *']'* ]] || \
       [[ "$key" == *'\'* ]]; then
        echo "ERROR: API key contains invalid characters"
        return 1
    fi
    
    if [ ${#key} -gt 200 ]; then
        echo "ERROR: API key is too long"
        return 1
    fi
    
    echo "OK"
    return 0
}

validate_security_level() {
    local level="$1"
    local valid=false
    
    for allowed in "${ALLOWED_SECURITY_LEVELS[@]}"; do
        if [ "$level" = "$allowed" ]; then
            valid=true
            break
        fi
    done
    
    if ! $valid; then
        echo "ERROR: Security level '$level' is not valid"
        return 1
    fi
    
    echo "OK"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Test Helpers
# ═══════════════════════════════════════════════════════════════════

test_should_fail() {
    local test_name="$1"
    local validator="$2"
    local input="$3"
    local extra_arg="${4:-}"
    
    local result
    if [ -n "$extra_arg" ]; then
        result=$($validator "$input" "$extra_arg" 2>/dev/null) || true
    else
        result=$($validator "$input" 2>/dev/null) || true
    fi
    
    if [[ "$result" == ERROR* ]] || [[ "$result" != "OK" ]]; then
        echo -e "  ${PASS} BLOCKED: ${test_name}"
        ((passed++)) || true
    else
        echo -e "  ${FAIL} NOT BLOCKED: ${test_name}"
        echo -e "    ${RED}Input:${NC} ${input}"
        ((failed++)) || true
    fi
}

test_should_pass() {
    local test_name="$1"
    local validator="$2"
    local input="$3"
    local extra_arg="${4:-}"
    
    local result
    if [ -n "$extra_arg" ]; then
        result=$($validator "$input" "$extra_arg" 2>/dev/null) || true
    else
        result=$($validator "$input" 2>/dev/null) || true
    fi
    
    if [ "$result" = "OK" ]; then
        echo -e "  ${PASS} ALLOWED: ${test_name}"
        ((passed++)) || true
    else
        echo -e "  ${FAIL} INCORRECTLY BLOCKED: ${test_name}"
        echo -e "    ${RED}Input:${NC} ${input}"
        echo -e "    ${RED}Result:${NC} ${result}"
        ((failed++)) || true
    fi
}

# ═══════════════════════════════════════════════════════════════════
# RUN TESTS
# ═══════════════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Phase 1.2: Command Injection Prevention Test Suite${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# ─── TEST 1: Bot Name Validation ───
echo -e "${CYAN}━━━ TEST 1: Bot Name Injection Attempts ━━━${NC}"
echo ""

# Required test cases from spec
test_should_fail "Shell injection with semicolon" validate_bot_name "watson'; rm -rf /tmp/test; echo 'pwned"
test_should_fail "Command substitution \$()" validate_bot_name '$(whoami)'
test_should_fail "Backtick command substitution" validate_bot_name '`cat /etc/passwd`'

# Additional injection attempts
test_should_fail "Pipe injection" validate_bot_name "watson|cat /etc/passwd"
test_should_fail "Ampersand injection" validate_bot_name "watson&whoami"
test_should_fail "Redirect injection" validate_bot_name "watson>/tmp/pwned"
test_should_fail "Quote escape attempt" validate_bot_name 'watson"rm -rf /"'
test_should_fail "Single quote escape" validate_bot_name "watson'rm -rf /'"
test_should_fail "Curly brace injection" validate_bot_name 'watson${IFS}id'
test_should_fail "Square bracket glob" validate_bot_name "watson[0-9]"
test_should_fail "Asterisk glob" validate_bot_name "watson*"
test_should_fail "Question mark glob" validate_bot_name "watson?"
test_should_fail "Tilde expansion" validate_bot_name "~watson"
test_should_fail "Hash comment" validate_bot_name "watson#comment"
test_should_fail "Equals assignment" validate_bot_name "PATH=watson"
test_should_fail "Python injection attempt" validate_bot_name 'watson"; import os; os.system("id"); "'
test_should_fail "Too short (1 char)" validate_bot_name "W"
test_should_fail "Too long (33 chars)" validate_bot_name "ThisNameIsWayTooLongForABotName12"
test_should_fail "Starts with number" validate_bot_name "123Watson"
test_should_fail "Starts with hyphen" validate_bot_name "-Watson"
test_should_fail "Empty string" validate_bot_name ""

echo ""
echo -e "${CYAN}  Valid names (should pass):${NC}"
test_should_pass "Simple name" validate_bot_name "Watson"
test_should_pass "Name with underscore" validate_bot_name "Watson_AI"
test_should_pass "Name with hyphen" validate_bot_name "My-Bot"
test_should_pass "Name with numbers" validate_bot_name "Bot123"
test_should_pass "Lowercase" validate_bot_name "jarvis"

# ─── TEST 2: Model Validation ───
echo ""
echo -e "${CYAN}━━━ TEST 2: Model Injection Attempts ━━━${NC}"
echo ""

test_should_fail "Python injection in model" validate_model 'sonnet"; import os; os.system("touch /tmp/pwned"); "'
test_should_fail "Shell injection in model" validate_model "claude-sonnet; rm -rf /"
test_should_fail "Command substitution in model" validate_model '$(touch /tmp/pwned)'
test_should_fail "Arbitrary model name" validate_model "my-custom-model"
test_should_fail "Path traversal" validate_model "../../../etc/passwd"

echo ""
echo -e "${CYAN}  Valid models (should pass):${NC}"
test_should_pass "OpenCode free model" validate_model "opencode/kimi-k2.5-free"
test_should_pass "OpenRouter Kimi" validate_model "openrouter/moonshotai/kimi-k2.5"
test_should_pass "Anthropic Sonnet" validate_model "anthropic/claude-sonnet-4-5"

# ─── TEST 3: Menu Selection Validation ───
echo ""
echo -e "${CYAN}━━━ TEST 3: Menu Selection Injection Attempts ━━━${NC}"
echo ""

test_should_fail "Shell command in selection" validate_menu_selection "1;rm -rf /" "4"
test_should_fail "Letters in selection" validate_menu_selection "1a" "4"
test_should_fail "Special chars" validate_menu_selection '1$(whoami)' "4"
test_should_fail "Out of range" validate_menu_selection "5" "4"
test_should_fail "Negative number" validate_menu_selection "-1" "4"
test_should_fail "Zero" validate_menu_selection "0" "4"

echo ""
echo -e "${CYAN}  Valid selections (should pass):${NC}"
test_should_pass "Single digit" validate_menu_selection "1" "4"
test_should_pass "Multiple digits" validate_menu_selection "1,2,3" "4"
test_should_pass "Max value" validate_menu_selection "4" "4"
test_should_pass "Empty (uses default)" validate_menu_selection "" "4"

# ─── TEST 4: API Key Validation ───
echo ""
echo -e "${CYAN}━━━ TEST 4: API Key Injection Attempts ━━━${NC}"
echo ""

test_should_fail "Shell injection in key" validate_api_key "sk-or-abc123; rm -rf /"
test_should_fail "Command substitution" validate_api_key 'sk-or-$(whoami)'
test_should_fail "Backticks" validate_api_key 'sk-or-`id`'
test_should_fail "Quotes in key" validate_api_key 'sk-or-abc"def'
test_should_fail "Single quotes" validate_api_key "sk-or-abc'def"

echo ""
echo -e "${CYAN}  Valid API keys (should pass):${NC}"
test_should_pass "OpenRouter key format" validate_api_key "sk-or-v1-abc123def456ghi789"
test_should_pass "Anthropic key format" validate_api_key "sk-ant-api03-abc123def456"
test_should_pass "Empty (guided signup)" validate_api_key ""

# ─── TEST 5: Security Level Validation ───
echo ""
echo -e "${CYAN}━━━ TEST 5: Security Level Validation ━━━${NC}"
echo ""

test_should_fail "Invalid level" validate_security_level "ultra"
test_should_fail "Injection attempt" validate_security_level "high;rm -rf /"
test_should_fail "Empty" validate_security_level ""

test_should_pass "Low" validate_security_level "low"
test_should_pass "Medium" validate_security_level "medium"
test_should_pass "High" validate_security_level "high"

# ═══════════════════════════════════════════════════════════════════
# RESULTS
# ═══════════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TEST RESULTS${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC} $passed"
echo -e "  ${RED}Failed:${NC} $failed"
echo ""

if [ $failed -eq 0 ]; then
    echo -e "  ${GREEN}✓ ALL TESTS PASSED${NC}"
    echo ""
    exit 0
else
    echo -e "  ${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    exit 1
fi
