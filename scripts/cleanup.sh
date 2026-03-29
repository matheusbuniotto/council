#!/usr/bin/env bash
# council — cleanup ephemeral agents
# Usage: bash cleanup.sh <plugin_root> [--dry-run]

PLUGIN_ROOT="${1:-}"
if [[ -z "$PLUGIN_ROOT" ]]; then
  echo "ERROR: plugin root path required as first argument" >&2
  exit 1
fi

REGISTRY="$PLUGIN_ROOT/ephemeral-registry"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

BOLD='\033[1m'
GREEN='\033[0;32m'
DIM='\033[2m'
YELLOW='\033[0;33m'
RESET='\033[0m'
CHECK="${GREEN}✓${RESET}"
WARN="${YELLOW}⚠${RESET}"

if [[ ! -f "$REGISTRY" ]]; then
  echo -e "  ${DIM}No ephemeral agents to clean up.${RESET}"
  exit 0
fi

removed=0
skipped=0

while IFS= read -r filepath; do
  [[ -z "$filepath" ]] && continue
  if [[ -f "$filepath" ]]; then
    if $DRY_RUN; then
      echo -e "  ${WARN} would remove: ${DIM}$filepath${RESET}"
    else
      rm "$filepath"
      echo -e "  ${CHECK} removed: ${DIM}$filepath${RESET}"
      removed=$((removed + 1))
    fi
  else
    skipped=$((skipped + 1))
  fi
done < "$REGISTRY"

if ! $DRY_RUN; then
  rm "$REGISTRY"
  echo ""
  echo -e "  ${BOLD}Done.${RESET} Removed $removed ephemeral agent(s)."
  [[ $skipped -gt 0 ]] && echo -e "  ${DIM}$skipped file(s) already gone — skipped.${RESET}"
fi
