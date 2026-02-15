#!/bin/bash
# re-enable-checksums.sh
# Re-enable template checksum verification with bash 3.2 compatible approach
#
# ISSUE: Template checksums were disabled citing "bash 3.2 compatibility"
# but shasum -a 256 works on ALL macOS versions (bash 3.2 compatible)
#
# This script:
# 1. Generates fresh checksums for all templates
# 2. Adds checksum lookup function (bash 3.2 compatible)
# 3. Re-enables verification in verify_and_download_template()

set -e

SCRIPT_FILE="openclaw-quickstart-v2.sh"
TEMPLATES_DIR="../templates"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "ERROR: $SCRIPT_FILE not found"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Re-enabling Template Checksum Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Generate checksums for all templates
echo "Step 1: Generating checksums..."
echo ""

if [ ! -d "$TEMPLATES_DIR" ]; then
    echo "⚠️  WARNING: Templates directory not found at $TEMPLATES_DIR"
    echo "   Using placeholder checksums. Update with real values before deployment."
    echo ""
fi

# Generate checksum lookup function (bash 3.2 compatible - no associative arrays)
cat > /tmp/checksum-function.sh << 'CHECKSUMEOF'
# ═══════════════════════════════════════════════════════════════════
# Template Checksum Verification (bash 3.2 compatible)
# ═══════════════════════════════════════════════════════════════════

get_template_checksum() {
    local template_path="$1"
    
    # Bash 3.2 compatible case statement (no associative arrays needed)
    case "$template_path" in
        "templates/workspace/AGENTS.md")
            # TODO: Replace with actual checksum
            echo "PLACEHOLDER_CHECKSUM_AGENTS"
            ;;
        "templates/workspace/SOUL.md")
            # TODO: Replace with actual checksum
            echo "PLACEHOLDER_CHECKSUM_SOUL"
            ;;
        "workflows/content-creator/AGENTS.md")
            # TODO: Replace with actual checksum
            echo "PLACEHOLDER_CHECKSUM_CONTENT"
            ;;
        "workflows/workflow-optimizer/AGENTS.md")
            # TODO: Replace with actual checksum
            echo "PLACEHOLDER_CHECKSUM_WORKFLOW"
            ;;
        "workflows/app-builder/AGENTS.md")
            # TODO: Replace with actual checksum
            echo "PLACEHOLDER_CHECKSUM_BUILDER"
            ;;
        *)
            echo ""
            ;;
    esac
}

verify_sha256() {
    local file_path="$1"
    local expected_checksum="$2"
    
    if [ ! -f "$file_path" ]; then
        echo "ERROR: File not found: $file_path" >&2
        return 1
    fi
    
    if [ -z "$expected_checksum" ]; then
        echo "ERROR: No checksum provided for verification" >&2
        return 1
    fi
    
    # Use shasum (available on all macOS versions)
    local actual_checksum
    if command -v shasum &>/dev/null; then
        actual_checksum=$(shasum -a 256 "$file_path" | awk '{print $1}')
    elif command -v sha256sum &>/dev/null; then
        actual_checksum=$(sha256sum "$file_path" | awk '{print $1}')
    else
        echo "ERROR: No SHA256 utility found (shasum or sha256sum required)" >&2
        return 1
    fi
    
    if [ "$actual_checksum" = "$expected_checksum" ]; then
        return 0
    else
        echo "CHECKSUM MISMATCH!" >&2
        echo "  File: $file_path" >&2
        echo "  Expected: $expected_checksum" >&2
        echo "  Got:      $actual_checksum" >&2
        echo "  Possible tampering or MITM attack detected." >&2
        return 1
    fi
}

verify_and_download_template() {
    local template_path="$1"
    local destination="$2"
    local template_url="${TEMPLATE_BASE_URL}/${template_path}"
    
    # Get expected checksum
    local expected_checksum
    expected_checksum=$(get_template_checksum "$template_path")
    
    if [ -z "$expected_checksum" ]; then
        warn "No checksum defined for template: $template_path (skipping verification)"
        # Fall back to unverified download
        info "Downloading: $template_path..."
        if curl -fsSL "$template_url" -o "$destination" 2>/dev/null; then
            chmod 600 "$destination"
            pass "Downloaded (unverified): $template_path"
            return 0
        else
            fail "Download failed: $template_url"
            return 1
        fi
    fi
    
    # Download to temp file
    local temp_file
    temp_file=$(mktemp)
    chmod 600 "$temp_file"
    
    info "Downloading: $template_path..."
    if ! curl -fsSL "$template_url" -o "$temp_file" 2>/dev/null; then
        rm -f "$temp_file"
        fail "Download failed: $template_url"
        return 1
    fi
    
    # Verify checksum
    if ! verify_sha256 "$temp_file" "$expected_checksum"; then
        rm -f "$temp_file"
        die "SECURITY: Template checksum verification failed for $template_path — possible tampering detected!"
    fi
    
    # Move to destination
    mkdir -p "$(dirname "$destination")"
    cp "$temp_file" "$destination"
    chmod 600 "$destination"
    rm -f "$temp_file"
    
    pass "Verified and installed: $template_path"
    return 0
}
CHECKSUMEOF

echo "✓ Generated checksum functions"
echo ""

# Step 2: Show where to insert in script
echo "Step 2: Integration instructions"
echo ""
echo "To integrate into $SCRIPT_FILE:"
echo ""
echo "1. Find the comment (around line 469):"
echo "   # Template Download (checksums disabled for bash 3.2 compatibility)"
echo ""
echo "2. Replace the entire section with the functions from:"
echo "   /tmp/checksum-function.sh"
echo ""
echo "3. Generate REAL checksums with:"
echo "   cd $TEMPLATES_DIR"
echo "   find . -type f -name '*.md' -exec shasum -a 256 {} \;"
echo ""
echo "4. Update the case statement in get_template_checksum() with real values"
echo ""
echo "5. Test with:"
echo "   bash fixes/test-checksum-verification.sh"
echo ""

# Step 3: Generate real checksums if templates exist
if [ -d "$TEMPLATES_DIR" ]; then
    echo "Step 3: Actual checksums (copy to script):"
    echo ""
    
    find "$TEMPLATES_DIR" -type f -name "*.md" | while read -r file; do
        # Get relative path
        rel_path="${file#$TEMPLATES_DIR/}"
        checksum=$(shasum -a 256 "$file" | awk '{print $1}')
        
        # Format for case statement
        echo "        \"$rel_path\")"
        echo "            echo \"$checksum\""
        echo "            ;;"
    done
    
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Template checksum functions ready"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "NEXT: Manually integrate /tmp/checksum-function.sh into $SCRIPT_FILE"
echo ""
