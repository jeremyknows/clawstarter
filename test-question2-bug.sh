#!/usr/bin/env bash
# Minimal reproduction of Question 2 bug
# Run with: bash test-question2-bug.sh

set -euo pipefail

echo "Testing: set -e + [[ ... ]] && command pattern"
echo "=============================================="
echo ""

# Simulate Question 2 scenario
use_case_input="4"  # User pressed Enter for default

echo "User input: '$use_case_input' (default choice)"
echo ""

has_content=false
has_workflow=false  
has_builder=false

echo "Attempting bash 3.2 pattern (BROKEN):"
echo "  [[ \"\$use_case_input\" == *\"1\"* ]] && has_content=true"
echo ""

# This WILL exit the script with set -e when test fails
[[ "$use_case_input" == *"1"* ]] && has_content=true
[[ "$use_case_input" == *"2"* ]] && has_workflow=true
[[ "$use_case_input" == *"3"* ]] && has_builder=true

echo "✓ Reached this line (should NOT happen with input='4')"
echo "  has_content=$has_content"
echo "  has_workflow=$has_workflow"
echo "  has_builder=$has_builder"
