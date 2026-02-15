#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# OpenClaw Quickstart v2 — SECURITY HARDENED
# Phase 1.2: Command Injection Prevention
#
# Fixes Applied:
# 1. Input validation functions for all user input
# 2. Strict allowlist for model selection
# 3. Alphanumeric-only validation for bot names
# 4. Numeric-only validation for menu selections
# 5. Quoted heredocs to prevent shell expansion
# 6. No eval or unescaped interpolation
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# ─── Constants ───
readonly SCRIPT_VERSION="2.3.1-secure"
readonly MIN_NODE_VERSION="22"
readonly DEFAULT_GATEWAY_PORT=18789

# ─── Allowed Models (STRICT ALLOWLIST) ───
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

# ─── Security Levels (STRICT ALLOWLIST) ───
readonly -a ALLOWED_SECURITY_LEVELS=("low" "medium" "high")

# ─── Personalities (STRICT ALLOWLIST) ───
readonly -a ALLOWED_PERSONALITIES=("casual" "professional" "direct")

# ─── Colors ───
GREEN='\033[0;32m'
DIM='\033[2m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"
INFO="${CYAN}→${NC}"
STEP="${BOLD}${CYAN}>>>${NC}"

pass()   { echo -e "  ${PASS} $1"; }
fail()   { echo -e "  ${FAIL} $1"; }
info()   { echo -e "  ${INFO} $1"; }
warn()   { echo -e "  ${YELLOW}!${NC} $1"; }

die() {
    echo -e "\n  ${FAIL} ${RED}ERROR:${NC} $1" >&2
    exit 1
}

# ═══════════════════════════════════════════════════════════════════
# SECURITY: Input Validation Functions
# ═══════════════════════════════════════════════════════════════════

# Validate bot name: alphanumeric, hyphens, underscores only (2-32 chars)
validate_bot_name() {
    local name="$1"
    local max_length=32
    local min_length=2
    
    # Check length
    if [ ${#name} -lt $min_length ] || [ ${#name} -gt $max_length ]; then
        echo "ERROR: Bot name must be ${min_length}-${max_length} characters"
        return 1
    fi
    
    # STRICT regex: only alphanumeric, hyphens, underscores
    # This blocks: quotes, backticks, $(), semicolons, pipes, etc.
    if ! [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        echo "ERROR: Bot name must start with a letter and contain only letters, numbers, hyphens, and underscores"
        return 1
    fi
    
    # Additional blocklist for shell metacharacters (defense in depth)
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

# Validate model against strict allowlist
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

# Validate numeric menu selection (only digits and optional commas)
validate_menu_selection() {
    local input="$1"
    local max_value="${2:-9}"
    
    # Allow empty (will use default)
    if [ -z "$input" ]; then
        echo "OK"
        return 0
    fi
    
    # STRICT: only digits and commas
    if ! [[ "$input" =~ ^[0-9,]+$ ]]; then
        echo "ERROR: Selection must contain only numbers and commas (e.g., '1' or '1,2,3')"
        return 1
    fi
    
    # Validate each number is within range
    IFS=',' read -ra NUMS <<< "$input"
    for num in "${NUMS[@]}"; do
        if [ -z "$num" ]; then
            continue  # Skip empty segments from ",,"
        fi
        if [ "$num" -gt "$max_value" ] || [ "$num" -lt 1 ]; then
            echo "ERROR: Selection '$num' is out of range (1-$max_value)"
            return 1
        fi
    done
    
    echo "OK"
    return 0
}

# Validate API key format (loose validation - just check for dangerous chars)
validate_api_key() {
    local key="$1"
    
    # Allow empty (guided signup)
    if [ -z "$key" ]; then
        echo "OK"
        return 0
    fi
    
    # Block shell metacharacters in API keys - use glob patterns for reliability
    if [[ "$key" == *"'"* ]] || [[ "$key" == *'"'* ]] || [[ "$key" == *'`'* ]] || \
       [[ "$key" == *'$'* ]] || [[ "$key" == *';'* ]] || [[ "$key" == *'|'* ]] || \
       [[ "$key" == *'&'* ]] || [[ "$key" == *'>'* ]] || [[ "$key" == *'<'* ]] || \
       [[ "$key" == *'('* ]] || [[ "$key" == *')'* ]] || [[ "$key" == *'{'* ]] || \
       [[ "$key" == *'}'* ]] || [[ "$key" == *'['* ]] || [[ "$key" == *']'* ]] || \
       [[ "$key" == *'\'* ]]; then
        echo "ERROR: API key contains invalid characters"
        return 1
    fi
    
    # Reasonable length check (API keys are typically 40-100 chars)
    if [ ${#key} -gt 200 ]; then
        echo "ERROR: API key is too long (max 200 characters)"
        return 1
    fi
    
    echo "OK"
    return 0
}

# Validate security level against allowlist
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
        echo "ERROR: Security level '$level' is not valid (use: low, medium, high)"
        return 1
    fi
    
    echo "OK"
    return 0
}

# Validate personality against allowlist
validate_personality() {
    local personality="$1"
    local valid=false
    
    for allowed in "${ALLOWED_PERSONALITIES[@]}"; do
        if [ "$personality" = "$allowed" ]; then
            valid=true
            break
        fi
    done
    
    if ! $valid; then
        echo "ERROR: Personality '$personality' is not valid"
        return 1
    fi
    
    echo "OK"
    return 0
}

# Escape string for safe inclusion in single-quoted context
# (Though we prefer to avoid interpolation entirely)
escape_for_shell() {
    local input="$1"
    # Replace single quotes with '\''
    printf '%s' "${input//\'/\'\\\'\'}"
}

prompt() {
    local question="$1"
    local default="${2:-}"
    local response
    
    if [ -n "$default" ]; then
        echo -en "\n  ${CYAN}?${NC} ${question} [${default}]: "
    else
        echo -en "\n  ${CYAN}?${NC} ${question}: "
    fi
    
    read -r response
    if [ -z "$response" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$response"
    fi
}

# Secure prompt with validation
prompt_validated() {
    local question="$1"
    local default="${2:-}"
    local validator="$3"
    local validator_arg="${4:-}"
    local response
    local result
    
    while true; do
        if [ -n "$default" ]; then
            echo -en "\n  ${CYAN}?${NC} ${question} [${default}]: "
        else
            echo -en "\n  ${CYAN}?${NC} ${question}: "
        fi
        
        read -r response
        if [ -z "$response" ] && [ -n "$default" ]; then
            response="$default"
        fi
        
        # Run validator
        if [ -n "$validator_arg" ]; then
            result=$($validator "$response" "$validator_arg")
        else
            result=$($validator "$response")
        fi
        
        if [ "$result" = "OK" ]; then
            echo "$response"
            return 0
        else
            warn "$result"
            warn "Please try again."
        fi
    done
}

confirm() {
    local question="$1"
    local response
    echo -en "\n  ${CYAN}?${NC} ${question} [y/N]: "
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# ═══════════════════════════════════════════════════════════════════
# STEP 1: Auto-Install Dependencies (unchanged from v1)
# ═══════════════════════════════════════════════════════════════════

step1_install() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "  ${STEP} ${BOLD}Step 1: Install${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Check macOS
    if [ "$(uname -s)" != "Darwin" ]; then
        die "This script is for macOS only."
    fi
    pass "macOS detected"
    
    # Check/install Homebrew
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || \
            die "Homebrew installation failed"
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        pass "Homebrew installed"
    else
        pass "Homebrew found"
    fi
    
    # Check/install Node.js
    local node_ok=false
    if command -v node &>/dev/null; then
        local node_ver
        node_ver=$(node --version | sed 's/v//' | cut -d. -f1)
        if [ "$node_ver" -ge "$MIN_NODE_VERSION" ] 2>/dev/null; then
            pass "Node.js $(node --version) found"
            node_ok=true
        fi
    fi
    
    if ! $node_ok; then
        info "Installing Node.js 22..."
        brew install node@22 &>/dev/null &
        spinner $!
        wait
        if ! command -v node &>/dev/null; then
            brew link --overwrite node@22 &>/dev/null || true
            export PATH="$(brew --prefix)/opt/node@22/bin:$PATH"
        fi
        pass "Node.js installed"
    fi
    
    # Check/install OpenClaw
    if command -v openclaw &>/dev/null; then
        pass "OpenClaw found"
    else
        info "Installing OpenClaw..."
        curl -fsSL https://openclaw.ai/install.sh | bash || \
            die "OpenClaw installation failed"
        export PATH="$HOME/.openclaw/bin:$PATH"
        pass "OpenClaw installed"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# Guided API Key Signup
# ═══════════════════════════════════════════════════════════════════

guided_api_signup() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Let's get you an API key (or use free tier)${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${BOLD}Option 1: OpenCode Free Tier${NC} (no signup)"
    echo -e "  • Kimi K2.5 Free — strong reasoning, long context"
    echo -e "  • No rate limits (for now)"
    echo -e "  • Just press Enter to use this"
    echo ""
    echo -e "  ${BOLD}Option 2: OpenRouter${NC} (requires signup, ~60 sec)"
    echo -e "  • Many models including paid Claude/GPT"
    echo -e "  • Free tier available"
    echo ""
    
    if confirm "Use OpenCode Free Tier? (no signup needed)"; then
        pass "Using OpenCode free tier (Kimi K2.5)"
        echo "OPENCODE_FREE"
        return 0
    fi
    
    echo ""
    info "Opening OpenRouter..."
    
    if command -v open &>/dev/null; then
        open "https://openrouter.ai/keys" 2>/dev/null
    elif command -v xdg-open &>/dev/null; then
        xdg-open "https://openrouter.ai/keys" 2>/dev/null
    else
        echo -e "  ${INFO} Open this URL: ${CYAN}https://openrouter.ai/keys${NC}"
    fi
    
    echo ""
    echo -e "  ${BOLD}Follow these steps:${NC}"
    echo -e "  1. Sign up (Google/GitHub = fastest)"
    echo -e "  2. Click ${CYAN}\"Create Key\"${NC}"
    echo -e "  3. Name it ${CYAN}\"OpenClaw\"${NC}"
    echo -e "  4. Copy the key (starts with ${DIM}sk-or-${NC})"
    echo -e "  5. Come back here and paste it"
    echo ""
    echo -e "  ${DIM}(No payment required — free tier available)${NC}"
    echo ""
    
    # Wait for key with validation
    local key=""
    while [ -z "$key" ]; do
        key=$(prompt "Paste your OpenRouter key")
        
        # Validate the key
        local validation_result
        validation_result=$(validate_api_key "$key")
        if [ "$validation_result" != "OK" ]; then
            warn "$validation_result"
            key=""
            continue
        fi
        
        if [ -z "$key" ]; then
            if confirm "Skip for now? (Will use OpenCode free tier)"; then
                pass "Using OpenCode free tier as fallback"
                echo "OPENCODE_FREE"
                return 0
            fi
        elif [[ ! "$key" == sk-or-* ]]; then
            warn "That doesn't look like an OpenRouter key (should start with sk-or-)"
            if ! confirm "Use it anyway?"; then
                key=""
            fi
        fi
    done
    
    pass "Got it!"
    echo "$key"
}

# ═══════════════════════════════════════════════════════════════════
# STEP 2: Configuration (3 Questions) - SECURITY HARDENED
# ═══════════════════════════════════════════════════════════════════

step2_configure() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "  ${STEP} ${BOLD}Step 2: Configure (2 questions)${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
    
    # ─── Question 1: API Key (with guided signup + validation) ───
    echo ""
    echo -e "${BOLD}Question 1: API Key${NC}"
    echo ""
    echo -e "  ${DIM}Have a key? Paste it below.${NC}"
    echo -e "  ${DIM}Need one? Press Enter — I'll help you get one (free, 60 seconds).${NC}"
    echo ""
    
    local api_key
    api_key=$(prompt "Paste API key (or Enter for guided signup)")
    
    # Validate API key before proceeding
    local key_validation
    key_validation=$(validate_api_key "$api_key")
    if [ "$key_validation" != "OK" ]; then
        die "$key_validation"
    fi
    
    # Auto-detect provider from key format
    local provider=""
    local openrouter_key=""
    local anthropic_key=""
    local default_model=""
    
    # Guided signup if empty
    if [ -z "$api_key" ]; then
        api_key=$(guided_api_signup)
    fi
    
    # Map key to provider and model (using ALLOWLISTED values only)
    if [[ "$api_key" == "OPENCODE_FREE" ]]; then
        provider="opencode"
        openrouter_key=""
        anthropic_key=""
        default_model="opencode/kimi-k2.5-free"
        pass "OpenCode free tier selected"
    elif [[ "$api_key" == sk-or-* ]]; then
        provider="openrouter"
        openrouter_key="$api_key"
        default_model="openrouter/moonshotai/kimi-k2.5"
        pass "OpenRouter key detected"
    elif [[ "$api_key" == sk-ant-* ]]; then
        provider="anthropic"
        anthropic_key="$api_key"
        default_model="anthropic/claude-sonnet-4-5"
        pass "Anthropic key detected"
    else
        # Assume OpenRouter for unknown formats
        provider="openrouter"
        openrouter_key="$api_key"
        default_model="openrouter/moonshotai/kimi-k2.5"
        if [ -n "$api_key" ]; then
            warn "Unknown key format — assuming OpenRouter"
        fi
    fi
    
    # SECURITY: Validate model is in allowlist
    local model_validation
    model_validation=$(validate_model "$default_model")
    if [ "$model_validation" != "OK" ]; then
        die "Internal error: default model not in allowlist"
    fi
    
    # ─── Question 2: Use Case (Multi-Select) - VALIDATED ───
    echo ""
    echo -e "${BOLD}Question 2: What do you want to do?${NC}"
    echo -e "${DIM}(Select all that apply — e.g., \"1,3\" for content + coding)${NC}"
    echo ""
    echo "  1. 📱 Create content (social media, podcasts, video)"
    echo "  2. 📅 Organize my life (email, calendar, tasks)"
    echo "  3. 🛠️  Build apps (coding, GitHub, APIs)"
    echo "  4. 🤷 Not sure yet (general assistant)"
    echo ""
    
    # SECURITY: Use validated prompt for menu selection
    local use_case_input
    use_case_input=$(prompt_validated "Choose (e.g., 1 or 1,2,3)" "4" validate_menu_selection "4")
    
    # Parse multi-select (safe now - validated to contain only digits/commas)
    local has_content=false
    local has_workflow=false
    local has_builder=false
    
    [[ "$use_case_input" == *"1"* ]] && has_content=true
    [[ "$use_case_input" == *"2"* ]] && has_workflow=true
    [[ "$use_case_input" == *"3"* ]] && has_builder=true
    
    # ─── Smart Inference (using ALLOWLISTED values only) ───
    local templates=""
    local bot_name=""
    local personality=""
    local spending_tier="balanced"
    
    # Collect templates (hardcoded allowlist)
    $has_content && templates="content-creator"
    $has_workflow && templates="${templates:+$templates,}workflow-optimizer"
    $has_builder && templates="${templates:+$templates,}app-builder"
    
    # Determine personality (MUST be from allowlist)
    if $has_builder; then
        personality="direct"
        spending_tier="premium"
        bot_name="Jarvis"
        # Upgrade to Sonnet for coding (from allowlist)
        if [ "$provider" = "openrouter" ]; then
            default_model="openrouter/anthropic/claude-sonnet-4-5"
        fi
    elif $has_workflow; then
        personality="professional"
        bot_name="Friday"
    elif $has_content; then
        personality="casual"
        bot_name="Muse"
    else
        personality="casual"
        bot_name="Atlas"
    fi
    
    # SECURITY: Validate personality is in allowlist
    local personality_validation
    personality_validation=$(validate_personality "$personality")
    if [ "$personality_validation" != "OK" ]; then
        die "Internal error: personality not in allowlist"
    fi
    
    # Count selections for messaging
    local count=0
    $has_content && ((count++)) || true
    $has_workflow && ((count++)) || true
    $has_builder && ((count++)) || true
    
    if [ "$count" -gt 1 ]; then
        info "Multi-mode: ${templates} → ${personality}, ${spending_tier}"
        bot_name="Atlas"  # Generic name for multi-mode
    elif [ "$count" -eq 1 ]; then
        info "Selected: ${templates} → ${personality}, ${spending_tier}"
    else
        info "General Assistant mode"
        templates=""
    fi
    
    # ─── Question 3: Setup Type - VALIDATED ───
    echo ""
    echo -e "${BOLD}Question 3: How will you run OpenClaw?${NC}"
    echo ""
    echo -e "  ${GREEN}1. 👤 New Mac User (Recommended)${NC}"
    echo "     → Create a separate user account on your Mac"
    echo "     → Best isolation without extra hardware"
    echo ""
    echo "  2. 💻 Your Mac User / VM"
    echo "     → Run under your current account (or in a VM)"
    echo "     → Simpler setup, less isolation"
    echo ""
    echo "  3. 🖥️  Dedicated Device"
    echo "     → A Mac just for OpenClaw (Mac Mini, always-on)"
    echo "     → Maximum isolation, relaxed permissions"
    echo ""
    
    # SECURITY: Use validated prompt
    local setup_choice
    setup_choice=$(prompt_validated "Choose 1-3" "2" validate_menu_selection "3")
    
    local setup_type="personal"
    local security_level="medium"
    
    # SECURITY: Map to allowlisted values only via case statement
    case "$setup_choice" in
        1)
            setup_type="new-user"
            security_level="high"
            info "New Mac User → high security, workspace-only sandbox"
            ;;
        2)
            setup_type="current-user"
            security_level="medium"
            info "Your Mac User → standard security"
            ;;
        3)
            setup_type="dedicated"
            security_level="low"
            info "Dedicated Device → relaxed permissions, full access"
            ;;
        *)
            # Fallback to safe default (should never hit due to validation)
            setup_type="current-user"
            security_level="medium"
            ;;
    esac
    
    # SECURITY: Validate security level
    local security_validation
    security_validation=$(validate_security_level "$security_level")
    if [ "$security_validation" != "OK" ]; then
        die "Internal error: security level not in allowlist"
    fi
    
    # ─── Optional: Customize name - VALIDATED ───
    echo ""
    echo -e "${DIM}Your bot will be called \"${bot_name}\". Press Enter to keep, or type a new name.${NC}"
    
    # SECURITY: Validate bot name with strict rules
    local custom_name
    custom_name=$(prompt_validated "Bot name" "$bot_name" validate_bot_name)
    bot_name="$custom_name"
    
    # Final validation of bot name
    local name_validation
    name_validation=$(validate_bot_name "$bot_name")
    if [ "$name_validation" != "OK" ]; then
        die "$name_validation"
    fi
    
    # Export for step 3 (all values have been validated)
    export QUICKSTART_OPENROUTER_KEY="$openrouter_key"
    export QUICKSTART_ANTHROPIC_KEY="$anthropic_key"
    export QUICKSTART_DEFAULT_MODEL="$default_model"
    export QUICKSTART_BOT_NAME="$bot_name"
    export QUICKSTART_PERSONALITY="$personality"
    export QUICKSTART_TEMPLATES="$templates"  # Comma-separated
    export QUICKSTART_SPENDING_TIER="$spending_tier"
    export QUICKSTART_SETUP_TYPE="$setup_type"
    export QUICKSTART_SECURITY_LEVEL="$security_level"
}

# ═══════════════════════════════════════════════════════════════════
# Skill Packs (Optional Add-ons) - SECURITY HARDENED
# ═══════════════════════════════════════════════════════════════════

offer_skill_packs() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "  ${STEP} ${BOLD}Bonus: Skill Packs${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${DIM}Your bot works great now! These optional packs add superpowers.${NC}"
    echo ""
    
    if ! confirm "Browse skill packs?"; then
        info "Skipped. Add later with: openclaw skills add <name>"
        return 0
    fi
    
    echo ""
    echo -e "${BOLD}Available Skill Packs:${NC}"
    echo ""
    echo "  1. 🔬 ${BOLD}Quality Pack${NC} — Better debugging & code review"
    echo "     ${DIM}systematic-debugging, TDD, verification, code-review${NC}"
    echo ""
    echo "  2. 🔍 ${BOLD}Research Pack${NC} — Deep research capabilities"
    echo "     ${DIM}x-research (Twitter), summarize, web scraping${NC}"
    echo ""
    echo "  3. 🎨 ${BOLD}Media Pack${NC} — Image & audio creation"
    echo "     ${DIM}image generation, whisper transcription, TTS${NC}"
    echo ""
    echo "  4. 🏠 ${BOLD}Home Pack${NC} — Personal automation"
    echo "     ${DIM}weather, iMessage, WhatsApp${NC}"
    echo ""
    echo "  5. ⏭️  ${BOLD}Skip${NC} — I'm good for now"
    echo ""
    
    # SECURITY: Validate pack selection
    local packs_input
    packs_input=$(prompt_validated "Add packs (e.g., 1,2 or Enter to skip)" "5" validate_menu_selection "5")
    
    # Skip logic: 5 or empty means skip ALL
    if [[ "$packs_input" == "5" ]] || [[ -z "$packs_input" ]]; then
        info "No additional packs. Add later with: openclaw skills add"
        return 0
    fi
    
    local workspace_dir="$HOME/.openclaw/workspace"
    
    # Safety check: Ensure AGENTS.md exists
    if [ ! -f "$workspace_dir/AGENTS.md" ]; then
        warn "AGENTS.md not found, creating minimal file"
        echo "# Agent Instructions" > "$workspace_dir/AGENTS.md"
    fi
    
    # Quality Pack - content is hardcoded, no user input
    if [[ "$packs_input" == *"1"* ]]; then
        echo ""
        info "Installing Quality Pack..."
        
        # Check for duplicate
        if grep -q "QUALITY_PACK_INSTALLED" "$workspace_dir/AGENTS.md" 2>/dev/null; then
            warn "Quality Pack already installed, skipping"
        else
            # SECURITY: Quoted heredoc prevents any expansion
            cat >> "$workspace_dir/AGENTS.md" << 'QUALITYEOF'

<!-- QUALITY_PACK_INSTALLED -->
## Quality Methodology (from Quality Pack)

These are thinking frameworks, not commands. Apply them when working:

| Methodology | When to Apply |
|-------------|---------------|
| systematic-debugging | Before proposing fixes — diagnose root cause first |
| verification-before-completion | Before claiming done — run tests, show proof |
| test-driven-development | Before implementation — write tests first |
| complete-code-review | When reviewing code — multiple passes |
| receiving-feedback | When getting review — verify suggestions before applying |

*These skills are auto-loaded. Just follow the approach.*
QUALITYEOF
            pass "Quality Pack added"
        fi
    fi
    
    # Research Pack - hardcoded content
    if [[ "$packs_input" == *"2"* ]]; then
        echo ""
        info "Installing Research Pack..."
        
        brew tap steipete/tap 2>/dev/null || true
        
        if brew install steipete/tap/summarize 2>/dev/null; then
            pass "summarize installed"
        else
            command -v summarize >/dev/null && pass "summarize already installed" || warn "summarize install failed"
        fi
        
        if grep -q "RESEARCH_PACK_INSTALLED" "$workspace_dir/AGENTS.md" 2>/dev/null; then
            warn "Research Pack already in AGENTS.md, skipping"
        else
            # SECURITY: Quoted heredoc
            cat >> "$workspace_dir/AGENTS.md" << 'RESEARCHEOF'

<!-- RESEARCH_PACK_INSTALLED -->
## Research Skills (from Research Pack)

| Skill | What It Does |
|-------|--------------|
| x-research-skill | Search X/Twitter for trends, takes, discourse |
| summarize | Summarize articles, YouTube videos, podcasts |
| web_fetch | Extract readable content from URLs (built-in) |

*For X research, just ask: "Research what people are saying about [topic] on X"*
RESEARCHEOF
            pass "Research Pack configured"
        fi
    fi
    
    # Media Pack - hardcoded content
    if [[ "$packs_input" == *"3"* ]]; then
        echo ""
        info "Installing Media Pack..."
        
        if brew install ffmpeg 2>/dev/null; then
            pass "ffmpeg installed"
        else
            command -v ffmpeg >/dev/null && pass "ffmpeg already installed" || warn "ffmpeg install failed"
        fi
        
        if grep -q "MEDIA_PACK_INSTALLED" "$workspace_dir/AGENTS.md" 2>/dev/null; then
            warn "Media Pack already in AGENTS.md, skipping"
        else
            # SECURITY: Quoted heredoc
            cat >> "$workspace_dir/AGENTS.md" << 'MEDIAEOF'

<!-- MEDIA_PACK_INSTALLED -->
## Media Skills (from Media Pack)

| Skill | What It Does | Needs |
|-------|--------------|-------|
| image | Generate images | Your AI provider |
| tts | Text-to-speech | Built-in |
| video-frames | Extract frames from video | ffmpeg (installed) |
| openai-whisper-api | Transcribe audio | OPENAI_API_KEY |

*Try: "Generate an image of..." or "Transcribe this audio file"*
MEDIAEOF
            pass "Media Pack configured"
        fi
        echo -e "  ${DIM}Whisper transcription requires OPENAI_API_KEY in your environment.${NC}"
    fi
    
    # Home Pack - hardcoded content
    if [[ "$packs_input" == *"4"* ]]; then
        echo ""
        info "Installing Home Pack..."
        
        brew tap steipete/tap 2>/dev/null || true
        
        if grep -q "HOME_PACK_INSTALLED" "$workspace_dir/AGENTS.md" 2>/dev/null; then
            warn "Home Pack already in AGENTS.md, skipping"
        else
            # SECURITY: Quoted heredoc
            cat >> "$workspace_dir/AGENTS.md" << 'HOMEEOF'

<!-- HOME_PACK_INSTALLED -->
## Home Automation Skills (from Home Pack)

| Skill | What It Does | Setup |
|-------|--------------|-------|
| weather | Weather lookups | None — just ask |
| imsg | iMessage automation | Needs permissions |
| wacli | WhatsApp messaging | Needs QR auth |

*Try: "What's the weather in NYC?" (works immediately)*

To enable iMessage: `brew install steipete/tap/imsg`
To enable WhatsApp: `brew install steipete/tap/wacli`
HOMEEOF
            pass "Home Pack configured"
        fi
        echo -e "  ${DIM}Weather works now. iMessage/WhatsApp need separate install.${NC}"
    fi
    
    echo ""
    pass "Skill packs configured!"
}

# ═══════════════════════════════════════════════════════════════════
# STEP 3: Start Bot - SECURITY HARDENED
# ═══════════════════════════════════════════════════════════════════

step3_start() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "  ${STEP} ${BOLD}Step 3: Launch${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    local config_file="$HOME/.openclaw/openclaw.json"
    local workspace_dir="$HOME/.openclaw/workspace"
    
    # Backup existing config
    if [ -f "$config_file" ]; then
        cp "$config_file" "${config_file}.backup-$(date +%Y%m%d-%H%M%S)"
        info "Backed up existing config"
    fi
    
    # SECURITY: Final validation before config generation
    local final_model_check
    final_model_check=$(validate_model "$QUICKSTART_DEFAULT_MODEL")
    if [ "$final_model_check" != "OK" ]; then
        die "Security check failed: invalid model"
    fi
    
    local final_security_check
    final_security_check=$(validate_security_level "$QUICKSTART_SECURITY_LEVEL")
    if [ "$final_security_check" != "OK" ]; then
        die "Security check failed: invalid security level"
    fi
    
    local final_name_check
    final_name_check=$(validate_bot_name "$QUICKSTART_BOT_NAME")
    if [ "$final_name_check" != "OK" ]; then
        die "Security check failed: invalid bot name"
    fi
    
    # SECURITY: Generate config via Python with proper argument passing
    # Python's sys.argv treats all inputs as strings, preventing shell injection
    # We still validate all inputs before passing them
    python3 << 'PYEOF' "$QUICKSTART_DEFAULT_MODEL" "$QUICKSTART_OPENROUTER_KEY" "$QUICKSTART_ANTHROPIC_KEY" "$config_file" "$QUICKSTART_BOT_NAME" "$QUICKSTART_SECURITY_LEVEL"
import json
import sys
import os
import secrets
import re

# Get arguments - Python treats these as safe strings
model = sys.argv[1] if len(sys.argv) > 1 else "opencode/kimi-k2.5-free"
openrouter_key = sys.argv[2] if len(sys.argv) > 2 else ""
anthropic_key = sys.argv[3] if len(sys.argv) > 3 else ""
config_path = sys.argv[4] if len(sys.argv) > 4 else os.path.expanduser("~/.openclaw/openclaw.json")
bot_name = sys.argv[5] if len(sys.argv) > 5 else "Atlas"
security_level = sys.argv[6] if len(sys.argv) > 6 else "medium"

# SECURITY: Validate inputs in Python too (defense in depth)
ALLOWED_MODELS = [
    "opencode/kimi-k2.5-free",
    "opencode/glm-4.7-free", 
    "openrouter/moonshotai/kimi-k2.5",
    "openrouter/anthropic/claude-sonnet-4-5",
    "openrouter/anthropic/claude-opus-4",
    "openrouter/openai/gpt-4o",
    "openrouter/google/gemini-pro",
    "anthropic/claude-sonnet-4-5",
    "anthropic/claude-opus-4",
]

ALLOWED_SECURITY_LEVELS = ["low", "medium", "high"]

# Validate model
if model not in ALLOWED_MODELS:
    print(f"ERROR: Model '{model}' not in allowed list", file=sys.stderr)
    sys.exit(1)

# Validate security level
if security_level not in ALLOWED_SECURITY_LEVELS:
    print(f"ERROR: Security level '{security_level}' not valid", file=sys.stderr)
    sys.exit(1)

# Validate bot name (alphanumeric + hyphens/underscores, starts with letter)
if not re.match(r'^[a-zA-Z][a-zA-Z0-9_-]{1,31}$', bot_name):
    print(f"ERROR: Invalid bot name format", file=sys.stderr)
    sys.exit(1)

# Validate API keys don't contain dangerous characters
dangerous_chars = set("'\"`$;|&><(){}[]\\")
if openrouter_key and any(c in dangerous_chars for c in openrouter_key):
    print("ERROR: OpenRouter key contains invalid characters", file=sys.stderr)
    sys.exit(1)
if anthropic_key and any(c in dangerous_chars for c in anthropic_key):
    print("ERROR: Anthropic key contains invalid characters", file=sys.stderr)
    sys.exit(1)

# Generate secure token
gateway_token = secrets.token_hex(32)

# Security settings based on setup type
tools_deny = ["browser"]
sandbox_mode = "off"

if security_level == "high":
    sandbox_mode = "workspace"
    tools_deny = ["browser"]
elif security_level == "low":
    sandbox_mode = "off"
    tools_deny = []

config = {
    "version": "2026.2.9",
    "model": model,
    "gateway": {
        "port": 18789,
        "auth": {"enabled": True, "token": gateway_token}
    },
    "auth": {},
    "workspace": {"path": os.path.expanduser("~/.openclaw/workspace")},
    "agents": {
        "defaults": {
            "sandbox": {"mode": sandbox_mode},
            "tools": {"deny": tools_deny} if tools_deny else {},
            "subagents": {"maxConcurrent": 8, "maxDepth": 1}
        }
    },
    "meta": {
        "security_level": security_level,
        "created_by": "clawstarter-v2-secure"
    }
}

if openrouter_key:
    config["auth"]["openrouter"] = {"apiKey": openrouter_key}
if anthropic_key:
    config["auth"]["anthropic"] = {"apiKey": anthropic_key}

# Add OpenCode provider if using free tier
if model.startswith("opencode/"):
    config["provider"] = {
        "opencode": {
            "baseURL": "https://opencode.ai/zen/v1",
            "models": {
                "kimi-k2.5-free": {
                    "enabled": True,
                    "displayName": "Kimi K2.5 Free"
                },
                "glm-4.7-free": {
                    "enabled": True,
                    "displayName": "GLM 4.7 Free"
                }
            }
        }
    }

os.makedirs(os.path.dirname(config_path), exist_ok=True)
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print(f"\n  Gateway Token: {gateway_token}")
print("  Save this — you need it for the dashboard.\n")
PYEOF
    
    if [ $? -ne 0 ]; then
        die "Config generation failed security validation"
    fi
    
    chmod 600 "$config_file"
    pass "Config created"
    
    # Create workspace + AGENTS.md
    mkdir -p "$workspace_dir/memory"
    
    # SECURITY: Generate AGENTS.md using a separate script to avoid any interpolation
    # Write the template with placeholders, then use sed for safe substitution
    cat > "$workspace_dir/AGENTS.md.template" << 'AGENTSTEMPLATE'
# __BOT_NAME__

You are __BOT_NAME__, a helpful AI assistant.

## Personality
Style: __PERSONALITY__

## Guidelines
- Be helpful, not performative
- Have opinions when asked
- Ask before taking external actions (emails, posts)
- If uncertain, ask

## First Run
Welcome! I'm __BOT_NAME__. Try asking me:
- "What can you help me with?"
- "Tell me about yourself"
- "What skills do you have?"
AGENTSTEMPLATE

    # SECURITY: Use sed with validated inputs for safe substitution
    # Bot name and personality have already been validated to be alphanumeric
    sed -e "s/__BOT_NAME__/${QUICKSTART_BOT_NAME}/g" \
        -e "s/__PERSONALITY__/${QUICKSTART_PERSONALITY}/g" \
        "$workspace_dir/AGENTS.md.template" > "$workspace_dir/AGENTS.md"
    
    rm -f "$workspace_dir/AGENTS.md.template"
    pass "Workspace created"
    
    # Install templates if selected (supports multiple, comma-separated)
    if [ -n "$QUICKSTART_TEMPLATES" ]; then
        local base_url="https://raw.githubusercontent.com/jeremyknows/clawstarter/main"
        
        # SECURITY: Validate template names are alphanumeric with hyphens only
        IFS=',' read -ra TEMPLATE_ARRAY <<< "$QUICKSTART_TEMPLATES"
        local first_template=true
        
        for template_name in "${TEMPLATE_ARRAY[@]}"; do
            # Validate template name format
            if ! [[ "$template_name" =~ ^[a-zA-Z][a-zA-Z0-9-]*$ ]]; then
                warn "Skipping invalid template name: $template_name"
                continue
            fi
            
            info "Installing ${template_name}..."
            
            if $first_template; then
                local agents_url="${base_url}/workflows/${template_name}/AGENTS.md"
                if curl -fsSL "$agents_url" -o "$workspace_dir/AGENTS.md" 2>/dev/null; then
                    pass "Downloaded AGENTS.md from ${template_name}"
                    first_template=false
                else
                    warn "Could not download ${template_name} template (continuing anyway)"
                fi
            fi
            
            pass "Configured: ${template_name}"
        done
        
        if [ "${#TEMPLATE_ARRAY[@]}" -gt 1 ]; then
            info "Multiple templates selected. AGENTS.md from ${TEMPLATE_ARRAY[0]}."
        fi
    fi
    
    # Create and load LaunchAgent
    local launch_agent="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    
    # SECURITY: LaunchAgent uses fixed paths, no user input interpolation
    local openclaw_bin="$HOME/.openclaw/bin/openclaw"
    local openclaw_home="$HOME/.openclaw"
    
    cat > "$launch_agent" << PLISTEOF
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
    <string>${openclaw_home}</string>
</dict>
</plist>
PLISTEOF
    
    # Start gateway
    launchctl unload "$launch_agent" 2>/dev/null || true
    launchctl load "$launch_agent" || die "Failed to start gateway"
    sleep 2
    
    if pgrep -f "openclaw" &>/dev/null; then
        pass "Gateway running"
    else
        die "Gateway failed. Check: tail /tmp/openclaw/gateway.log"
    fi
    
    # ─── Skill Packs (Optional) ───
    offer_skill_packs
    
    # ─── Success! ───
    echo ""
    echo -e "${BOLD}${GREEN}🎉 Done! ${QUICKSTART_BOT_NAME} is alive.${NC}"
    echo ""
    echo -e "  Dashboard: ${CYAN}http://127.0.0.1:${DEFAULT_GATEWAY_PORT}/${NC}"
    echo ""
    echo -e "  Try: \"Hello ${QUICKSTART_BOT_NAME}! What can you help me with?\""
    echo ""
    
    if [ -n "$QUICKSTART_TEMPLATES" ]; then
        echo -e "  ${DIM}Templates installed: ${QUICKSTART_TEMPLATES}${NC}"
        IFS=',' read -ra TEMPLATE_ARRAY <<< "$QUICKSTART_TEMPLATES"
        for t in "${TEMPLATE_ARRAY[@]}"; do
            echo -e "  ${DIM}  → workflows/${t}/GETTING-STARTED.md${NC}"
        done
    fi
    echo ""
    
    # Open dashboard
    if confirm "Open dashboard now?"; then
        open "http://127.0.0.1:${DEFAULT_GATEWAY_PORT}/" 2>/dev/null || true
    fi
}

# ═══════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════

main() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  OpenClaw Quickstart v${SCRIPT_VERSION}${NC}"
    echo -e "${BOLD}  3 Questions → Running Bot (Security Hardened)${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  This takes ~5 minutes:"
    echo -e "  ${INFO} Install dependencies (Node.js, OpenClaw)"
    echo -e "  ${INFO} Ask 3 questions + optional skill packs"
    echo -e "  ${INFO} Start your bot"
    echo ""
    
    if ! confirm "Ready?"; then
        echo "  Run again when ready."
        exit 0
    fi
    
    step1_install
    step2_configure
    step3_start
}

main "$@"
