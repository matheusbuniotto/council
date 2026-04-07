#!/usr/bin/env bash
# council — remove ephemeral agent files listed in a project-local registry
# Usage: bash cleanup.sh [--dry-run] <registry_file>
#
# registry_file: absolute path, usually <project>/.claude/council/ephemeral-registry
# Each line is an absolute path to a generated agent .md file.

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  shift
fi

REGISTRY="${1:-}"
if [[ -z "$REGISTRY" ]]; then
  echo "ERROR: registry file path required (e.g. \$PWD/.claude/council/ephemeral-registry)" >&2
  echo "Usage: bash cleanup.sh [--dry-run] <registry_file>" >&2
  exit 1
fi

BOLD='\033[1m'
GREEN='\033[0;32m'
DIM='\033[2m'
YELLOW='\033[0;33m'
RESET='\033[0m'
CHECK="${GREEN}✓${RESET}"
WARN="${YELLOW}⚠${RESET}"

if [[ ! -f "$REGISTRY" ]]; then
  echo -e "  ${DIM}No ephemeral registry at this project (${REGISTRY}).${RESET}"
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
  rm -f "$REGISTRY"
  # Remove empty council dir if nothing else left
  council_dir="$(dirname "$REGISTRY")"
  if [[ -d "$council_dir" ]] && [[ -z "$(ls -A "$council_dir" 2>/dev/null)" ]]; then
    rmdir "$council_dir" 2>/dev/null || true
  fi
  echo ""
  echo -e "  ${BOLD}Done.${RESET} Removed $removed ephemeral agent file(s)."
  [[ $skipped -gt 0 ]] && echo -e "  ${DIM}$skipped path(s) already gone — skipped.${RESET}"
fi
