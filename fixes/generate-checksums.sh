#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# Template Checksum Generator
# Generate SHA256 checksums for all OpenClaw templates
# ═══════════════════════════════════════════════════════════════════
#
# Usage:
#   bash generate-checksums.sh > checksums.txt
#   bash generate-checksums.sh --update  # Update phase1-4-template-checksums.sh
#
# Run this when:
#   - Adding new templates
#   - Updating existing templates
#   - Verifying current checksums
#
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Configuration ───
readonly TEMPLATE_BASE_URL="https://raw.githubusercontent.com/jeremyknows/clawstarter/main"
readonly CHECKSUM_FILE="phase1-4-template-checksums.sh"
readonly TEMP_DIR=$(mktemp -d)

# ─── Colors ───
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# ─── Template List ───
# Add new templates here when they're added to the repository
TEMPLATES=(
    "workflows/content-creator/AGENTS.md"
    "workflows/content-creator/GETTING-STARTED.md"
    "workflows/workflow-optimizer/AGENTS.md"
    "workflows/workflow-optimizer/GETTING-STARTED.md"
    "workflows/app-builder/AGENTS.md"
    "workflows/app-builder/GETTING-STARTED.md"
)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# ─── Download and Hash Template ───
hash_template() {
    local template_path="$1"
    local url="${TEMPLATE_BASE_URL}/${template_path}"
    local temp_file="${TEMP_DIR}/$(basename "$template_path")"
    
    # Download
    if ! curl -fsSL "$url" -o "$temp_file" 2>/dev/null; then
        echo -e "${RED}ERROR${NC}: Failed to download $template_path" >&2
        echo "DOWNLOAD_FAILED"
        return 1
    fi
    
    # Calculate SHA256
    local checksum
    if command -v shasum &>/dev/null; then
        checksum=$(shasum -a 256 "$temp_file" | awk '{print $1}')
    elif command -v sha256sum &>/dev/null; then
        checksum=$(sha256sum "$temp_file" | awk '{print $1}')
    else
        echo -e "${RED}ERROR${NC}: No SHA256 utility found" >&2
        echo "NO_HASH_UTILITY"
        return 1
    fi
    
    echo "$checksum"
}

# ─── Generate All Checksums ───
generate_checksums() {
    echo "# Template SHA256 Checksums"
    echo "# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo "# Source: ${TEMPLATE_BASE_URL}"
    echo ""
    echo "declare -A TEMPLATE_CHECKSUMS=("
    
    for template in "${TEMPLATES[@]}"; do
        echo -ne "${DIM}Hashing $template...${NC} " >&2
        
        local checksum
        checksum=$(hash_template "$template")
        
        if [ "$checksum" != "DOWNLOAD_FAILED" ] && [ "$checksum" != "NO_HASH_UTILITY" ]; then
            echo -e "${GREEN}✓${NC}" >&2
            echo "    [\"${template}\"]=\"${checksum}\""
        else
            echo -e "${RED}✗${NC}" >&2
            echo "    # [\"${template}\"]=\"ERROR: $checksum\""
        fi
    done
    
    echo ")"
}

# ─── Update Script in Place ───
update_checksum_file() {
    local new_checksums
    new_checksums=$(generate_checksums 2>&1 | grep -v "Hashing\|✓\|✗" || true)
    
    if [ ! -f "$CHECKSUM_FILE" ]; then
        echo -e "${RED}ERROR:${NC} $CHECKSUM_FILE not found in current directory" >&2
        echo "Run this script from ~/Downloads/openclaw-setup/fixes/" >&2
        return 1
    fi
    
    # Create backup
    cp "$CHECKSUM_FILE" "${CHECKSUM_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${GREEN}✓${NC} Backed up $CHECKSUM_FILE" >&2
    
    # Replace checksums in file using awk
    awk -v new_checksums="$new_checksums" '
        /^declare -A TEMPLATE_CHECKSUMS=/ {
            print new_checksums
            in_checksums=1
            next
        }
        in_checksums && /^\)/ {
            in_checksums=0
            next
        }
        !in_checksums {
            print
        }
    ' "$CHECKSUM_FILE" > "${CHECKSUM_FILE}.tmp"
    
    mv "${CHECKSUM_FILE}.tmp" "$CHECKSUM_FILE"
    echo -e "${GREEN}✓${NC} Updated $CHECKSUM_FILE with fresh checksums" >&2
    echo "" >&2
    echo "Review changes with: diff ${CHECKSUM_FILE}.backup-* $CHECKSUM_FILE" >&2
}

# ─── Verify Checksums Against Live ───
verify_checksums() {
    local script_path="$1"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}ERROR:${NC} File not found: $script_path" >&2
        return 1
    fi
    
    # Source the script to load checksums
    source "$script_path"
    
    echo "Verifying checksums against live templates..."
    echo ""
    
    local failed=0
    for template in "${TEMPLATES[@]}"; do
        local expected="${TEMPLATE_CHECKSUMS[$template]:-MISSING}"
        local actual
        actual=$(hash_template "$template" 2>/dev/null || echo "ERROR")
        
        if [ "$expected" = "MISSING" ]; then
            echo -e "${RED}✗${NC} $template: No checksum in script"
            ((failed++))
        elif [ "$actual" = "ERROR" ] || [ "$actual" = "DOWNLOAD_FAILED" ]; then
            echo -e "${RED}✗${NC} $template: Download failed"
            ((failed++))
        elif [ "$expected" = "$actual" ]; then
            echo -e "${GREEN}✓${NC} $template"
        else
            echo -e "${RED}✗${NC} $template: MISMATCH"
            echo "    Expected: $expected"
            echo "    Got:      $actual"
            ((failed++))
        fi
    done
    
    echo ""
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}✓ All checksums valid!${NC}"
        return 0
    else
        echo -e "${RED}✗ $failed checksum(s) failed${NC}"
        return 1
    fi
}

# ─── Test with Tampered Template ───
test_tampered_detection() {
    echo "Testing tampered template detection..."
    echo ""
    
    # Create a test file
    local test_file="${TEMP_DIR}/test-template.md"
    echo "Original content" > "$test_file"
    local original_checksum
    original_checksum=$(shasum -a 256 "$test_file" | awk '{print $1}')
    
    echo "Original checksum: $original_checksum"
    
    # Tamper with it
    echo "Tampered content" > "$test_file"
    local tampered_checksum
    tampered_checksum=$(shasum -a 256 "$test_file" | awk '{print $1}')
    
    echo "Tampered checksum: $tampered_checksum"
    
    if [ "$original_checksum" != "$tampered_checksum" ]; then
        echo -e "${GREEN}✓${NC} Checksums differ (tampering would be detected)"
    else
        echo -e "${RED}✗${NC} Checksums match (ERROR: tampering not detected)"
    fi
}

# ─── Main ───
case "${1:-}" in
    --update)
        update_checksum_file
        ;;
    --verify)
        verify_checksums "${2:-phase1-4-template-checksums.sh}"
        ;;
    --test)
        test_tampered_detection
        ;;
    --help|-h)
        cat << 'EOF'
Template Checksum Generator

Usage:
  bash generate-checksums.sh                  # Print checksums to stdout
  bash generate-checksums.sh --update         # Update phase1-4-template-checksums.sh
  bash generate-checksums.sh --verify [file]  # Verify checksums in script
  bash generate-checksums.sh --test           # Test tampering detection

Examples:
  # Generate checksums for documentation
  bash generate-checksums.sh > checksums.txt

  # Update the verification script with fresh checksums
  bash generate-checksums.sh --update

  # Verify current checksums against live templates
  bash generate-checksums.sh --verify phase1-4-template-checksums.sh

Workflow for Template Updates:
  1. Edit template on GitHub
  2. Run: bash generate-checksums.sh --update
  3. Review changes with git diff
  4. Commit updated phase1-4-template-checksums.sh
EOF
        ;;
    *)
        generate_checksums
        ;;
esac
