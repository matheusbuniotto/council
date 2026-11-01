#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="$(mktemp -d /tmp/council-test-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Running tests in temporary directory: $TMP_DIR"

# 1. Test pick-mode.sh flags and non-interactive fallback
echo "Testing scripts/pick-mode.sh with flags..."
res_eph="$(bash "$ROOT_DIR/scripts/pick-mode.sh" "test" --ephemeral)"
[[ "$res_eph" == "ephemeral" ]] || { echo "Failed: pick-mode.sh --ephemeral expected 'ephemeral', got '$res_eph'"; exit 1; }

res_per="$(bash "$ROOT_DIR/scripts/pick-mode.sh" "test" --persist)"
[[ "$res_per" == "project" ]] || { echo "Failed: pick-mode.sh --persist expected 'project', got '$res_per'"; exit 1; }

res_usr="$(bash "$ROOT_DIR/scripts/pick-mode.sh" "test" --user)"
[[ "$res_usr" == "user" ]] || { echo "Failed: pick-mode.sh --user expected 'user', got '$res_usr'"; exit 1; }

# Non-interactive fallback (pipe empty stdin)
res_pipe="$(echo "" | bash "$ROOT_DIR/scripts/pick-mode.sh" "test")"
[[ "$res_pipe" == "ephemeral" ]] || { echo "Failed: non-interactive pick-mode.sh should default to 'ephemeral', got '$res_pipe'"; exit 1; }
echo "✓ pick-mode.sh tests passed"

# 2. Test cleanup.sh
echo "Testing scripts/cleanup.sh..."
REGISTRY_FILE="$TMP_DIR/ephemeral-registry"
MOCK_AGENT1="$TMP_DIR/agent1.md"
MOCK_AGENT2="$TMP_DIR/agent with spaces.md"

touch "$MOCK_AGENT1" "$MOCK_AGENT2"
cat <<EOF > "$REGISTRY_FILE"
$MOCK_AGENT1
$MOCK_AGENT2
$TMP_DIR/nonexistent.md
/etc/passwd  # should be skipped as non-.md path
EOF

# Dry run test
output_dry="$(bash "$ROOT_DIR/scripts/cleanup.sh" --dry-run "$REGISTRY_FILE")"
[[ -f "$MOCK_AGENT1" ]] || { echo "Failed: dry-run should not delete $MOCK_AGENT1"; exit 1; }
[[ -f "$REGISTRY_FILE" ]] || { echo "Failed: dry-run should not delete registry"; exit 1; }

# Live run test
output_live="$(bash "$ROOT_DIR/scripts/cleanup.sh" -q "$REGISTRY_FILE")"
[[ ! -f "$MOCK_AGENT1" ]] || { echo "Failed: cleanup.sh should delete $MOCK_AGENT1"; exit 1; }
[[ ! -f "$MOCK_AGENT2" ]] || { echo "Failed: cleanup.sh should delete $MOCK_AGENT2"; exit 1; }
[[ ! -f "$REGISTRY_FILE" ]] || { echo "Failed: cleanup.sh should delete registry file itself"; exit 1; }

# Nonexistent registry test (should exit 0 gracefully)
bash "$ROOT_DIR/scripts/cleanup.sh" -q "$TMP_DIR/no-such-registry"
echo "✓ cleanup.sh tests passed"

# 3. Test setup.sh with CLI options
echo "Testing scripts/setup.sh CLI options..."
MOCK_PLUGIN_DIR="$TMP_DIR/plugin"
MOCK_EXPERTS_DIR="$TMP_DIR/experts"
mkdir -p "$MOCK_PLUGIN_DIR" "$MOCK_EXPERTS_DIR"
touch "$MOCK_EXPERTS_DIR/topics-index.yml"

bash "$ROOT_DIR/scripts/setup.sh" "$MOCK_PLUGIN_DIR" \
  --experts-path "$MOCK_EXPERTS_DIR" \
  --topics-index "$MOCK_EXPERTS_DIR/topics-index.yml" \
  --scope project \
  --example simple-clone \
  --force \
  --quiet

CONFIG_OUT="$MOCK_PLUGIN_DIR/config.yml"
[[ -f "$CONFIG_OUT" ]] || { echo "Failed: setup.sh did not create config.yml"; exit 1; }

grep -q "experts_clones_path: $MOCK_EXPERTS_DIR" "$CONFIG_OUT" || { echo "Failed: config missing experts_clones_path"; exit 1; }
grep -q "topics_index_path: $MOCK_EXPERTS_DIR/topics-index.yml" "$CONFIG_OUT" || { echo "Failed: config missing topics_index_path"; exit 1; }
grep -q "agents_output_scope: project" "$CONFIG_OUT" || { echo "Failed: config missing agents_output_scope"; exit 1; }
[[ -f "$MOCK_EXPERTS_DIR/examples/simple-clone/brain.md" ]] || { echo "Failed: example clone was not copied"; exit 1; }

echo "✓ setup.sh non-interactive CLI tests passed"

echo "All shell script unit tests PASSED."
