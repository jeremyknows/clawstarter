# ═══════════════════════════════════════════════════════════════════
# SECURITY FUNCTIONS - Extracted from Phase 1.2 & 1.5 fixes
# These functions provide input validation and output encoding
# to prevent injection attacks.
# ═══════════════════════════════════════════════════════════════════

# ─── Allowed Values (STRICT ALLOWLISTS) ───
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

# ═══════════════════════════════════════════════════════════════════
# INPUT VALIDATION FUNCTIONS
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
    if ! [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        echo "ERROR: Bot name must start with a letter and contain only letters, numbers, hyphens, and underscores"
        return 1
    fi
    
    # Additional blocklist for shell metacharacters (defense in depth)
    if [[ "$name" == *"'"* ]] || [[ "$name" == *'"'* ]] || [[ "$name" == *'`'* ]] || \
       [[ "$name" == *'$'* ]] || [[ "$name" == *';'* ]] || [[ "$name" == *'|'* ]] || \
       [[ "$name" == *'&'* ]] || [[ "$name" == *'>'* ]] || [[ "$name" == *'<'* ]] || \
       [[ "$name" == *'('* ]] || [[ "$name" == *')'* ]] || [[ "$name" == *'{'* ]] || \
       [[ "$name" == *'}'* ]] || [[ "$name" == *'['* ]] || [[ "$name" == *']'* ]] || \
       [[ "$name" == *'\'* ]] || [[ "$name" == *'!'* ]] || [[ "$name" == *'#'* ]] || \
       [[ "$name" == *'*'* ]] || [[ "$name" == *'?'* ]] || [[ "$name" == *'~'* ]]; then
        echo "ERROR: Bot name contains forbidden character"
        return 1
    fi
    
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

# Validate API key format (block dangerous chars)
validate_api_key() {
    local key="$1"
    
    # Allow empty (guided signup)
    if [ -z "$key" ]; then
        echo "OK"
        return 0
    fi
    
    # Block shell metacharacters
    if [[ "$key" == *"'"* ]] || [[ "$key" == *'"'* ]] || [[ "$key" == *'`'* ]] || \
       [[ "$key" == *'$'* ]] || [[ "$key" == *';'* ]] || [[ "$key" == *'|'* ]] || \
       [[ "$key" == *'&'* ]] || [[ "$key" == *'>'* ]] || [[ "$key" == *'<'* ]] || \
       [[ "$key" == *'('* ]] || [[ "$key" == *')'* ]] || [[ "$key" == *'{'* ]] || \
       [[ "$key" == *'}'* ]] || [[ "$key" == *'['* ]] || [[ "$key" == *']'* ]] || \
       [[ "$key" == *'\'* ]]; then
        echo "ERROR: API key contains invalid characters"
        return 1
    fi
    
    # Length check
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

# ═══════════════════════════════════════════════════════════════════
# OUTPUT ENCODING FUNCTIONS (XML/Plist)
# ═══════════════════════════════════════════════════════════════════

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
    
    # Must start with /Users/
    if [[ ! "$home_path" =~ ^/Users/ ]]; then
        echo "ERROR: HOME must start with /Users/ (got: $home_path)" >&2
        return 1
    fi
    
    # Extract and validate username
    local username="${home_path#/Users/}"
    username="${username%%/*}"
    
    if [[ ! "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid username format: $username" >&2
        return 1
    fi
    
    # Block dangerous characters
    if [[ "$home_path" =~ \$ ]] || [[ "$home_path" =~ \` ]] || \
       [[ "$home_path" =~ \< ]] || [[ "$home_path" =~ \> ]] || \
       [[ "$home_path" =~ \( ]] || [[ "$home_path" =~ \) ]] || \
       [[ "$home_path" =~ \{ ]] || [[ "$home_path" =~ \} ]] || \
       [[ "$home_path" =~ \; ]] || [[ "$home_path" =~ \| ]] || \
       [[ "$home_path" =~ \& ]] || [[ "$home_path" =~ \' ]] || \
       [[ "$home_path" =~ \" ]]; then
        echo "ERROR: HOME contains forbidden characters" >&2
        return 1
    fi
    
    return 0
}

# Escape string for safe inclusion in shell context
escape_for_shell() {
    local input="$1"
    printf '%s' "${input//\'/\'\\\'\'}"
}

# Secure prompt with validation loop
prompt_validated() {
    local question="$1"
    local default="${2:-}"
    local validator="$3"
    local validator_arg="${4:-}"
    local response
    local result
    
    while true; do
        if [ -n "$default" ]; then
            echo -en "\n  ${CYAN:-}?${NC:-} ${question} [${default}]: "
        else
            echo -en "\n  ${CYAN:-}?${NC:-} ${question}: "
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
            echo -e "  ${YELLOW:-}!${NC:-} $result" >&2
            echo -e "  ${YELLOW:-}!${NC:-} Please try again." >&2
        fi
    done
}
