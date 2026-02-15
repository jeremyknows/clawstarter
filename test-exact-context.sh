#!/usr/bin/env bash
# Test with EXACT conditions from original script
set -euo pipefail

# Add the exact trap from the script
trap 'echo -e "\n❌ SCRIPT FAILED AT LINE $LINENO"; echo -e "Last command: $BASH_COMMAND" >&2' ERR

echo "Testing with EXACT script conditions"
echo "====================================="
echo ""

# Test 1: Simple case (this should work)
echo "TEST 1: Single conditional"
use_case_input="4"
has_content=false

echo "Running: [[ \"$use_case_input\" == *\"1\"* ]] && has_content=true"
[[ "$use_case_input" == *"1"* ]] && has_content=true
echo "✓ Passed line (has_content=$has_content)"
echo ""

# Test 2: In a function (closer to real script)
echo "TEST 2: Inside function with local vars"
test_function() {
    local use_case_input="$1"
    local has_content=false
    local has_workflow=false
    local has_builder=false
    
    echo "Running conditionals on input: $use_case_input"
    [[ "$use_case_input" == *"1"* ]] && has_content=true
    [[ "$use_case_input" == *"2"* ]] && has_workflow=true
    [[ "$use_case_input" == *"3"* ]] && has_builder=true
    
    echo "✓ Completed (content=$has_content, workflow=$has_workflow, builder=$has_builder)"
}

test_function "4"
echo ""

# Test 3: After a command substitution (like in real script)
echo "TEST 3: After command substitution (like prompt_validated)"
test_with_subshell() {
    local use_case_input
    use_case_input=$(echo "4")  # Simulate prompt_validated output
    
    local has_content=false
    local has_workflow=false
    local has_builder=false
    
    echo "Running conditionals on input: $use_case_input"
    [[ "$use_case_input" == *"1"* ]] && has_content=true
    [[ "$use_case_input" == *"2"* ]] && has_workflow=true
    [[ "$use_case_input" == *"3"* ]] && has_builder=true
    
    echo "✓ Completed (content=$has_content, workflow=$has_workflow, builder=$has_builder)"
}

test_with_subshell
echo ""

echo "All tests passed - unable to reproduce bug in isolation"
echo "This suggests the issue may be:"
echo "  1. Specific to the full script context"
echo "  2. Related to pipefail interaction"
echo "  3. Only occurs with actual user input (read)"
echo "  4. Bash version specific behavior difference"
