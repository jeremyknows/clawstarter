#!/bin/bash
echo "Testing SHA256 verification..."

# Test checksum function
verify_sha256_test() {
    local file_path="$1"
    local expected_checksum="$2"
    
    if [ ! -f "$file_path" ]; then
        return 1
    fi
    
    local actual_checksum
    actual_checksum=$(shasum -a 256 "$file_path" | awk '{print $1}')
    
    if [ "$actual_checksum" = "$expected_checksum" ]; then
        return 0
    else
        echo "CHECKSUM MISMATCH!"
        echo "  Expected: $expected_checksum"
        echo "  Got:      $actual_checksum"
        return 1
    fi
}

# Test 1: Create file and verify correct checksum
echo ""
echo "Test 1: Valid checksum"
TEST_FILE=$(mktemp)
echo "test content for demo" > "$TEST_FILE"
CORRECT_CHECKSUM=$(shasum -a 256 "$TEST_FILE" | awk '{print $1}')

if verify_sha256_test "$TEST_FILE" "$CORRECT_CHECKSUM" 2>&1 > /dev/null; then
    echo "  ✅ PASS: Valid checksum accepted"
else
    echo "  ❌ FAIL: Valid checksum rejected"
fi

# Test 2: Tamper with file and verify detection
echo ""
echo "Test 2: Tampered file detection"
echo "tampered content" > "$TEST_FILE"

if verify_sha256_test "$TEST_FILE" "$CORRECT_CHECKSUM" 2>&1 > /dev/null; then
    echo "  ❌ FAIL: Tampered file accepted (security vulnerability!)"
else
    echo "  ✅ PASS: Tampered file correctly rejected"
    echo ""
    echo "Checksum mismatch details:"
    verify_sha256_test "$TEST_FILE" "$CORRECT_CHECKSUM" 2>&1 | head -3
fi

rm -f "$TEST_FILE"

echo ""
echo "Done!"
