#!/bin/bash
# Quick verification of checksums against live templates

BASE_URL="https://raw.githubusercontent.com/jeremyknows/clawstarter/main"

# Expected checksums
declare -A EXPECTED=(
    ["workflows/content-creator/AGENTS.md"]="1d8513f149d635f69f5475da2861a896add0b30824374a4782ceabdc5ae09448"
    ["workflows/content-creator/GETTING-STARTED.md"]="c73f1514e26a1912f8df5403555b051707b81629548de74278e6cd0d443a54d7"
    ["workflows/workflow-optimizer/AGENTS.md"]="da75bbf0ab2d34da0351228290708bb704cad9937f0746f4f1bc94c19ae55019"
    ["workflows/workflow-optimizer/GETTING-STARTED.md"]="b6af4dae46415ea455be3b8a9ea0a9d1808758a2d3ebd5b4382a614be6a00104"
    ["workflows/app-builder/AGENTS.md"]="efebf563c01c50d452db6e09440a9c4bea8630702eaaaceb534ae78956c12f0e"
    ["workflows/app-builder/GETTING-STARTED.md"]="0aa9079a39b50747dbf35b0147fe82cdf18eaa3ddc469d36d45f457edbdeafd0"
)

echo "Verifying checksums against live templates..."
echo ""

FAILED=0
for template in "${!EXPECTED[@]}"; do
    TEMP_FILE=$(mktemp)
    if curl -fsSL "${BASE_URL}/${template}" -o "$TEMP_FILE" 2>/dev/null; then
        ACTUAL=$(shasum -a 256 "$TEMP_FILE" | awk '{print $1}')
        EXPECTED_CHECKSUM="${EXPECTED[$template]}"
        
        if [ "$ACTUAL" = "$EXPECTED_CHECKSUM" ]; then
            echo "✅ $template"
        else
            echo "❌ $template MISMATCH"
            echo "   Expected: $EXPECTED_CHECKSUM"
            echo "   Got:      $ACTUAL"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "❌ $template DOWNLOAD FAILED"
        FAILED=$((FAILED + 1))
    fi
    rm -f "$TEMP_FILE"
done

echo ""
if [ $FAILED -eq 0 ]; then
    echo "✅ All checksums match!"
else
    echo "❌ $FAILED verification(s) failed"
    exit 1
fi
