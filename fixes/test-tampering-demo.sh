#!/bin/bash
# Demonstration: Template Tampering Detection

echo "=================================="
echo "Template Tampering Detection Demo"
echo "=================================="
echo ""

# Source the verification functions
source "$(dirname "$0")/phase1-4-template-checksums.sh"

echo "Test 1: Download and verify legitimate template"
echo "================================================"
echo ""

# Create temp destination
TEMP_DEST=$(mktemp)

# Try to download a real template
if verify_and_download_template "workflows/content-creator/AGENTS.md" "$TEMP_DEST" true; then
    echo ""
    echo "✅ SUCCESS: Legitimate template verified and downloaded"
    echo ""
    echo "First 5 lines of verified template:"
    head -5 "$TEMP_DEST"
else
    echo "❌ FAILED: Could not verify template"
    rm -f "$TEMP_DEST"
    exit 1
fi

echo ""
echo "Test 2: Detect tampered template"
echo "================================="
echo ""

# Create a tampered template
TAMPERED_FILE=$(mktemp)
echo "MALICIOUS CONTENT - This is a tampered template!" > "$TAMPERED_FILE"
echo "Evil code here..." >> "$TAMPERED_FILE"

# Try to verify it with the expected checksum
echo "Attempting to verify tampered file against legitimate checksum..."
echo ""

if verify_sha256 "$TAMPERED_FILE" "1d8513f149d635f69f5475da2861a896add0b30824374a4782ceabdc5ae09448" 2>&1; then
    echo ""
    echo "❌ SECURITY FAILURE: Tampered file was accepted!"
    rm -f "$TEMP_DEST" "$TAMPERED_FILE"
    exit 1
else
    echo ""
    echo "✅ SUCCESS: Tampered file was correctly rejected!"
fi

# Cleanup
rm -f "$TEMP_DEST" "$TAMPERED_FILE"

echo ""
echo "=================================="
echo "All security tests passed!"
echo "=================================="
