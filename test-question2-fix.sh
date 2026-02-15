#!/usr/bin/env bash
# Fixed version using if/then
# Run with: bash test-question2-fix.sh

set -euo pipefail

echo "Testing: set -e + if/then pattern (FIXED)"
echo "=========================================="
echo ""

# Simulate Question 2 scenario
use_case_input="4"  # User pressed Enter for default

echo "User input: '$use_case_input' (default choice)"
echo ""

has_content=false
has_workflow=false  
has_builder=false

echo "Attempting fixed pattern:"
echo "  if [[ \"\$use_case_input\" == *\"1\"* ]]; then has_content=true; fi"
echo ""

# This works correctly with set -e
if [[ "$use_case_input" == *"1"* ]]; then has_content=true; fi
if [[ "$use_case_input" == *"2"* ]]; then has_workflow=true; fi
if [[ "$use_case_input" == *"3"* ]]; then has_builder=true; fi

echo "✓ Reached this line (CORRECT behavior)"
echo "  has_content=$has_content"
echo "  has_workflow=$has_workflow"
echo "  has_builder=$has_builder"
echo ""
echo "SUCCESS: Script continues normally"
