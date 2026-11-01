#!/usr/bin/env bash
# council — remove ephemeral agent files listed in a project-local registry
# Usage: bash cleanup.sh [options] <registry_file>

set -euo pipefail

DRY_RUN=false
QUIET=false
REGISTRY=""

usage() {
  cat <<EOF
Usage: bash cleanup.sh [options] <registry_file>

Arguments:
  <registry_file>     Path to .claude/council/ephemeral-registry

Options:
  -n, --dry-run       Show files that would be removed without deleting
  -q, --quiet         Suppress non-error output
  -h, --help          Show this help message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -q|--quiet)
      QUIET=true
      shift
      ;;
    *)
      if [[ -z "$REGISTRY" ]]; then
        REGISTRY="$1"
        shift
      else
        echo "ERROR: Unknown argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$REGISTRY" ]]; then
  echo "ERROR: registry file path required (e.g. \$PWD/.claude/council/ephemeral-registry)" >&2
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
  [[ "$QUIET" == "true" ]] || echo -e "  ${DIM}No ephemeral registry at this project (${REGISTRY}).${RESET}"
  exit 0
fi

removed=0
skipped=0

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
  # Trim leading/trailing whitespace
  filepath="$(echo "$raw_line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [[ -z "$filepath" ]] && continue
  
  # Safety check: must be an absolute path ending with .md
  if [[ "$filepath" != /* ]] || [[ "$filepath" != *.md ]]; then
    [[ "$QUIET" == "true" ]] || echo -e "  ${WARN} Skipping non-agent path: ${DIM}$filepath${RESET}" >&2
    skipped=$((skipped + 1))
    continue
  fi

  if [[ -f "$filepath" ]]; then
    if $DRY_RUN; then
      [[ "$QUIET" == "true" ]] || echo -e "  ${WARN} would remove: ${DIM}$filepath${RESET}"
    else
      rm -f "$filepath"
      [[ "$QUIET" == "true" ]] || echo -e "  ${CHECK} removed: ${DIM}$filepath${RESET}"
      removed=$((removed + 1))
    fi
  else
    skipped=$((skipped + 1))
  fi
done < "$REGISTRY"

if ! $DRY_RUN; then
  rm -f "$REGISTRY"
  council_dir="$(dirname "$REGISTRY")"
  if [[ -d "$council_dir" ]] && [[ -z "$(ls -A "$council_dir" 2>/dev/null)" ]]; then
    rmdir "$council_dir" 2>/dev/null || true
  fi
  if [[ "$QUIET" != "true" ]]; then
    echo ""
    echo -e "  ${BOLD}Done.${RESET} Removed $removed ephemeral agent file(s)."
    [[ $skipped -gt 0 ]] && echo -e "  ${DIM}$skipped path(s) already gone or skipped.${RESET}"
  fi
fi
