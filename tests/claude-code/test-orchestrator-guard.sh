#!/usr/bin/env bash
# ABOUTME: Tests for the orchestrator-guard PreToolUse hook.
# ABOUTME: Verifies the hook correctly classifies planning vs implementation actions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_DIR="$(cd "$SCRIPT_DIR/../../hooks" && pwd)"

# Create sentinel file so the hook activates (it early-exits without it)
mkdir -p .superpowers
touch .superpowers/orchestrator-mode
trap 'rm -f .superpowers/orchestrator-mode && rmdir .superpowers 2>/dev/null' EXIT

HAS_API_KEY=false
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    HAS_API_KEY=true
fi

echo "=== Test: orchestrator-guard hook ==="
if [ "$HAS_API_KEY" = false ]; then
    echo "(ANTHROPIC_API_KEY not set -- tests requiring Haiku classification will be skipped)"
fi
echo ""

PASS=0
FAIL=0
SKIP=0

# Helper: call the hook with simulated input and check the decision
test_hook() {
    local test_name="$1"
    local input_json="$2"
    local expected_decision="$3"

    local output
    output=$(echo "$input_json" | bash "$HOOK_DIR/orchestrator-guard" 2>/dev/null) || true

    local decision
    decision=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecision // "allow"')

    if [ "$decision" = "$expected_decision" ]; then
        echo "  [PASS] $test_name (got: $decision)"
        PASS=$((PASS + 1))
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "    Expected: $expected_decision"
        echo "    Got:      $decision"
        echo "    Output:   $output"
        FAIL=$((FAIL + 1))
        return 1
    fi
}

# Helper: skip a test with a message
skip_test() {
    local test_name="$1"
    echo "  [SKIP] $test_name -- requires ANTHROPIC_API_KEY"
    SKIP=$((SKIP + 1))
}

# Test 1: Writing to a plan file should be allowed
echo "Test 1: Plan file write is allowed..."
test_hook "Write to docs/plans/" \
    '{"tool_name":"Write","tool_input":{"file_path":"docs/plans/2026-01-01-feature.md","content":"# Plan"}}' \
    "allow" || true

# Test 2: Editing source code should be denied (requires Haiku)
echo "Test 2: Source code edit is denied..."
if [ "$HAS_API_KEY" = true ]; then
    test_hook "Edit src/ file" \
        '{"tool_name":"Edit","tool_input":{"file_path":"src/components/Button.tsx","old_string":"old","new_string":"new"}}' \
        "deny" || true
else
    skip_test "Edit src/ file"
fi

# Test 3: Running git status should be allowed
echo "Test 3: Read-only git is allowed..."
test_hook "git status" \
    '{"tool_name":"Bash","tool_input":{"command":"git status"}}' \
    "allow" || true

# Test 4: Running tests should be denied (requires Haiku)
echo "Test 4: Running tests is denied..."
if [ "$HAS_API_KEY" = true ]; then
    test_hook "npm test" \
        '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' \
        "deny" || true
else
    skip_test "npm test"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "=== SOME orchestrator-guard tests FAILED ==="
    exit 1
fi

echo "=== All orchestrator-guard tests passed ==="
