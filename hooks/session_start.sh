#!/usr/bin/env bash
# council — SessionStart lifecycle hook
# Notifies about ephemeral agents or missing configuration when a session begins.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${PWD}}"

REGISTRY="${PROJECT_DIR}/.claude/council/ephemeral-registry"
CONFIG_FILE="${PLUGIN_ROOT}/config.yml"

if [[ ! -f "$CONFIG_FILE" ]]; then
  # Subtle hint if not configured yet
  echo "Council: Run /council:setup once to configure your expert knowledge base." >&2
  exit 0
fi

if [[ -f "$REGISTRY" ]]; then
  count=0
  while IFS= read -r line; do
    [[ -n "$line" ]] && [[ -f "$line" ]] && count=$((count + 1))
  done < "$REGISTRY"

  if [[ $count -gt 0 ]]; then
    echo "Council: $count ephemeral agent(s) active in this project. Run /council:dismiss to clean up." >&2
  fi
fi

exit 0
