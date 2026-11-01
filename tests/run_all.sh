#!/usr/bin/env bash
# Run all council plugin verification tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Council Plugin Verification Test Suite ==="
echo ""

echo ">>> 1. Manifests & Markdown Frontmatter Validation"
python3 "$SCRIPT_DIR/test_manifests.py"
echo ""

echo ">>> 2. Shell Scripts & Non-Interactive CLI Tests"
bash "$SCRIPT_DIR/test_scripts.sh"
echo ""

echo ">>> 3. Lifecycle Hooks & Knowledge-Base Protection Tests"
python3 "$SCRIPT_DIR/test_hooks.py"
echo ""

echo "=============================================="
echo "✓ ALL TESTS PASSED SUCCESSFULLY"
echo "=============================================="
