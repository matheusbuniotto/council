#!/usr/bin/env bash
# council — interactive mode picker for spawn/assemble
#
# Usage: bash pick-mode.sh <context> [--ephemeral|--persist]
#   context: "spawn <slug>" or "assemble <topic>"
#
# Exits 0 and prints one of: ephemeral | project | user
# All visual output goes to stderr so Claude can capture stdout cleanly.

CONTEXT="${1:-}"
FLAG="${2:-}"

# ── colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'
ARROW="${CYAN}›${RESET}"

divider() { echo -e "${DIM}────────────────────────────────────────────────${RESET}" >&2; }

# ── if flag provided, skip interaction ───────────────────────────────────────
case "$FLAG" in
  --ephemeral) echo "ephemeral"; exit 0 ;;
  --persist)   echo "project";   exit 0 ;;
  --user)      echo "user";      exit 0 ;;
esac

# ── interactive picker ────────────────────────────────────────────────────────
echo "" >&2
divider
echo -e "  ${BOLD}council${RESET} ${DIM}·${RESET} ${CONTEXT}" >&2
divider
echo "" >&2
echo -e "  How long should this agent live?" >&2
echo "" >&2
echo -e "  ${DIM}1)${RESET} ${BOLD}ephemeral${RESET}  ${DIM}— this session only, auto-removed on /council:dismiss${RESET}" >&2
echo -e "  ${DIM}2)${RESET} ${BOLD}project${RESET}    ${DIM}— saved to .claude/agents/ in this project${RESET}" >&2
echo -e "  ${DIM}3)${RESET} ${BOLD}user${RESET}       ${DIM}— saved to ~/.claude/agents/ across all projects${RESET}" >&2
echo "" >&2
echo -ne "  ${ARROW} Choice [1/2/3]: " >&2
read -r choice

echo "" >&2

case "$choice" in
  2) echo "project" ;;
  3) echo "user" ;;
  *) echo "ephemeral" ;;  # default to ephemeral on enter or 1
esac
