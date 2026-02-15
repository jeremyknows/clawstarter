#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# Template Download Verification Functions
# Phase 1.4: SHA256 Checksum Verification for Template Downloads
# ═══════════════════════════════════════════════════════════════════
#
# These functions replace the vulnerable template download pattern
# with secure SHA256 verification.
#
# Usage:
#   1. Source this file in openclaw-quickstart-v2.sh
#   2. Replace direct curl downloads with verify_and_download_template()
#
# ═══════════════════════════════════════════════════════════════════

# Disable unbound variable check for array declaration (bash associative array quirk)
set +u

# ─── Template SHA256 Checksums ───
# These checksums are stored IN the script (not fetched from the same source)
# Update these when templates change using generate-checksums.sh --update
#
# Generated: 2026-02-11 20:49:23 UTC
# Format: [template_path]="sha256_checksum"
declare -A TEMPLATE_CHECKSUMS=(
    # Workflow Templates
    ["workflows/content-creator/AGENTS.md"]="1d8513f149d635f69f5475da2861a896add0b30824374a4782ceabdc5ae09448"
    ["workflows/content-creator/GETTING-STARTED.md"]="c73f1514e26a1912f8df5403555b051707b81629548de74278e6cd0d443a54d7"
    ["workflows/workflow-optimizer/AGENTS.md"]="da75bbf0ab2d34da0351228290708bb704cad9937f0746f4f1bc94c19ae55019"
    ["workflows/workflow-optimizer/GETTING-STARTED.md"]="b6af4dae46415ea455be3b8a9ea0a9d1808758a2d3ebd5b4382a614be6a00104"
    ["workflows/app-builder/AGENTS.md"]="efebf563c01c50d452db6e09440a9c4bea8630702eaaaceb534ae78956c12f0e"
    ["workflows/app-builder/GETTING-STARTED.md"]="0aa9079a39b50747dbf35b0147fe82cdf18eaa3ddc469d36d45f457edbdeafd0"
)

# ─── Configuration ───
readonly TEMPLATE_BASE_URL="https://raw.githubusercontent.com/jeremyknows/clawstarter/main"
readonly CACHE_DIR="$HOME/.openclaw/cache/templates"
readonly VERIFICATION_LOG="$HOME/.openclaw/logs/template-verification.log"

# ─── Output Functions (for standalone mode) ───
if ! command -v pass &>/dev/null; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    pass() { echo -e "  ${GREEN}✓${NC} $1"; }
    fail() { echo -e "  ${RED}✗${NC} $1"; }
    info() { echo -e "  ${CYAN}→${NC} $1"; }
    warn() { echo -e "  ${RED}!${NC} $1"; }
fi

# ─── Logging ───
log_verification() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    mkdir -p "$(dirname "$VERIFICATION_LOG")"
    echo "[$timestamp] $1" >> "$VERIFICATION_LOG"
}

# ─── SHA256 Verification Function ───
verify_sha256() {
    local file_path="$1"
    local expected_checksum="$2"
    
    if [ ! -f "$file_path" ]; then
        return 1
    fi
    
    # Calculate SHA256 (macOS uses shasum -a 256)
    local actual_checksum
    if command -v shasum &>/dev/null; then
        actual_checksum=$(shasum -a 256 "$file_path" | awk '{print $1}')
    elif command -v sha256sum &>/dev/null; then
        actual_checksum=$(sha256sum "$file_path" | awk '{print $1}')
    else
        echo "ERROR: No SHA256 utility found (need shasum or sha256sum)" >&2
        return 1
    fi
    
    if [ "$actual_checksum" = "$expected_checksum" ]; then
        return 0
    else
        echo "CHECKSUM MISMATCH!" >&2
        echo "  Expected: $expected_checksum" >&2
        echo "  Got:      $actual_checksum" >&2
        return 1
    fi
}

# ─── Secure Template Download Function ───
# Replaces: curl -fsSL "$url" -o "$destination"
# With: verify_and_download_template "$template_path" "$destination"
verify_and_download_template() {
    local template_path="$1"      # e.g., "workflows/content-creator/AGENTS.md"
    local destination="$2"         # e.g., "$workspace_dir/AGENTS.md"
    local force_download="${3:-false}"  # Skip cache if true
    
    local expected_checksum="${TEMPLATE_CHECKSUMS[$template_path]}"
    local template_url="${TEMPLATE_BASE_URL}/${template_path}"
    
    # Check if checksum is defined
    if [ -z "$expected_checksum" ] || [ "$expected_checksum" = "PLACEHOLDER_CHECKSUM_"* ]; then
        warn "⚠️  No checksum defined for: $template_path"
        warn "   This template cannot be verified securely."
        warn "   Run: bash generate-checksums.sh"
        log_verification "FAILED: No checksum for $template_path"
        return 1
    fi
    
    # Create cache directory
    mkdir -p "$CACHE_DIR"
    local cache_file="${CACHE_DIR}/${template_path//\//_}"
    
    # Check cache first (unless force_download)
    if [ "$force_download" != "true" ] && [ -f "$cache_file" ]; then
        if verify_sha256 "$cache_file" "$expected_checksum" 2>/dev/null; then
            info "✓ Using cached template: $template_path"
            cp "$cache_file" "$destination"
            log_verification "SUCCESS: Cached $template_path → $destination"
            return 0
        else
            warn "⚠️  Cached template corrupted, re-downloading..."
            rm -f "$cache_file"
        fi
    fi
    
    # Download to temporary location
    local temp_file
    temp_file=$(mktemp)
    
    info "Downloading: $template_path..."
    if ! curl -fsSL "$template_url" -o "$temp_file" 2>/dev/null; then
        rm -f "$temp_file"
        fail "❌ Download failed: $template_url"
        log_verification "FAILED: Download error for $template_path"
        return 1
    fi
    
    # Verify SHA256
    if ! verify_sha256 "$temp_file" "$expected_checksum"; then
        rm -f "$temp_file"
        fail "❌ SECURITY ERROR: Checksum verification failed for $template_path"
        fail "   Template may have been modified or tampered with."
        fail "   Manual verification instructions:"
        fail "   1. Visit: https://github.com/jeremyknows/clawstarter/blob/main/$template_path"
        fail "   2. Download manually and verify SHA256:"
        fail "      shasum -a 256 $template_path"
        fail "   3. Compare with expected: $expected_checksum"
        log_verification "FAILED: Checksum mismatch for $template_path"
        return 1
    fi
    
    # Verification passed — move to destination and cache
    mkdir -p "$(dirname "$destination")"
    mkdir -p "$(dirname "$cache_file")"
    
    cp "$temp_file" "$destination"
    cp "$temp_file" "$cache_file"
    rm -f "$temp_file"
    
    pass "✓ Verified and installed: $template_path"
    log_verification "SUCCESS: Verified $template_path → $destination"
    return 0
}

# ─── Offline Mode Check ───
# Returns true if cached templates are available
can_work_offline() {
    local template_path="$1"
    local cache_file="${CACHE_DIR}/${template_path//\//_}"
    local expected_checksum="${TEMPLATE_CHECKSUMS[$template_path]}"
    
    if [ -f "$cache_file" ] && verify_sha256 "$cache_file" "$expected_checksum" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ─── Manual Verification Helper ───
# Prints instructions for manual template verification
print_manual_verification() {
    local template_path="$1"
    local expected_checksum="${TEMPLATE_CHECKSUMS[$template_path]}"
    
    cat << EOF

═══════════════════════════════════════════════════════════════════
MANUAL TEMPLATE VERIFICATION
═══════════════════════════════════════════════════════════════════

Template: $template_path
Expected SHA256: $expected_checksum

Steps to manually verify:

1. Visit GitHub:
   https://github.com/jeremyknows/clawstarter/blob/main/$template_path

2. Download the raw file:
   curl -o temp-template.md \\
     https://raw.githubusercontent.com/jeremyknows/clawstarter/main/$template_path

3. Calculate SHA256:
   shasum -a 256 temp-template.md

4. Compare the output with expected checksum above.
   They should match exactly.

5. If they match, the template is safe to use.
   If they don't match:
   - The template may have been updated (check GitHub commit history)
   - The download may have been tampered with
   - Contact the OpenClaw maintainers

═══════════════════════════════════════════════════════════════════
EOF
}

# ─── Example: Replace vulnerable code in step3_start() ───
# OLD CODE (VULNERABLE):
#   local agents_url="${base_url}/workflows/${template_name}/AGENTS.md"
#   if curl -fsSL "$agents_url" -o "$workspace_dir/AGENTS.md" 2>/dev/null; then
#       pass "Downloaded AGENTS.md from ${template_name}"
#   else
#       warn "Could not download ${template_name} template (continuing anyway)"
#   fi
#
# NEW CODE (SECURE):
#   local template_path="workflows/${template_name}/AGENTS.md"
#   if verify_and_download_template "$template_path" "$workspace_dir/AGENTS.md"; then
#       pass "Downloaded and verified AGENTS.md from ${template_name}"
#   else
#       fail "Could not verify ${template_name} template (aborting for security)"
#       print_manual_verification "$template_path"
#       return 1
#   fi

# ─── Checksum Update Helper ───
# This function generates checksums for maintainers
# NOT for end users — maintainers run this when templates change
generate_checksums_for_update() {
    echo "Generating fresh checksums for all templates..."
    echo ""
    echo "# Add these to TEMPLATE_CHECKSUMS array:"
    echo ""
    
    local templates=(
        "workflows/content-creator/AGENTS.md"
        "workflows/content-creator/GETTING-STARTED.md"
        "workflows/workflow-optimizer/AGENTS.md"
        "workflows/workflow-optimizer/GETTING-STARTED.md"
        "workflows/app-builder/AGENTS.md"
        "workflows/app-builder/GETTING-STARTED.md"
        "skills/systematic-debugging/install.sh"
        "skills/x-research-skill/install.sh"
    )
    
    for template in "${templates[@]}"; do
        local url="${TEMPLATE_BASE_URL}/${template}"
        local temp_file
        temp_file=$(mktemp)
        
        if curl -fsSL "$url" -o "$temp_file" 2>/dev/null; then
            local checksum
            checksum=$(shasum -a 256 "$temp_file" | awk '{print $1}')
            echo "    [\"${template}\"]=\"${checksum}\""
        else
            echo "    # [\"${template}\"]=\"ERROR: Could not download\""
        fi
        
        rm -f "$temp_file"
    done
    
    echo ""
    echo "Copy these into the TEMPLATE_CHECKSUMS array in this script."
}

# ─── Self-Test Function ───
test_verification() {
    echo "Running verification self-test..."
    echo ""
    
    # Test 1: Good checksum
    echo "Test 1: Valid checksum"
    local test_file
    test_file=$(mktemp)
    echo "test content" > "$test_file"
    local test_checksum
    test_checksum=$(shasum -a 256 "$test_file" | awk '{print $1}')
    
    if verify_sha256 "$test_file" "$test_checksum" 2>/dev/null; then
        pass "✓ Valid checksum verification works"
    else
        fail "✗ Valid checksum verification FAILED"
    fi
    
    # Test 2: Bad checksum
    echo "Test 2: Tampered file detection"
    if verify_sha256 "$test_file" "0000000000000000000000000000000000000000000000000000000000000000" 2>/dev/null; then
        fail "✗ Tampered file detection FAILED (false positive)"
    else
        pass "✓ Tampered file detected correctly"
    fi
    
    rm -f "$test_file"
    
    echo ""
    echo "Self-test complete!"
}

# ─── Export Functions ───
# If this script is sourced, these functions are available
export -f verify_and_download_template
export -f verify_sha256
export -f can_work_offline
export -f print_manual_verification
export -f generate_checksums_for_update
export -f test_verification

# ─── Standalone Execution ───
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-}" in
        --test)
            test_verification
            ;;
        --generate)
            generate_checksums_for_update
            ;;
        *)
            echo "Template Download Verification System"
            echo ""
            echo "Usage:"
            echo "  source $0          # Load functions for use in other scripts"
            echo "  bash $0 --test     # Run self-test"
            echo "  bash $0 --generate # Generate checksums (maintainers only)"
            echo ""
            echo "Functions available after sourcing:"
            echo "  verify_and_download_template <path> <destination>"
            echo "  can_work_offline <path>"
            echo "  print_manual_verification <path>"
            ;;
    esac
fi
