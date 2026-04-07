#!/usr/bin/env bash
# council — setup wizard
# Usage: bash setup.sh <plugin_root>
# Outputs a config.yml to <plugin_root>/config.yml

set -euo pipefail

PLUGIN_ROOT="${1:-}"
if [[ -z "$PLUGIN_ROOT" ]]; then
  echo "ERROR: plugin root path required as first argument" >&2
  exit 1
fi

# ── colors & symbols ──────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'
CHECK="${GREEN}✓${RESET}"
WARN="${YELLOW}⚠${RESET}"
ERR="${RED}✗${RESET}"
ARROW="${CYAN}›${RESET}"

# ── drawing helpers ───────────────────────────────────────────────────────────
divider() { echo -e "${DIM}────────────────────────────────────────────────${RESET}"; }

header() {
  local step="$1" total="$2" title="$3"
  echo ""
  divider
  echo -e "  ${BOLD}council${RESET} ${DIM}·${RESET} setup wizard  ${DIM}[step ${step}/${total}]${RESET}"
  echo -e "  ${CYAN}${title}${RESET}"
  divider
  echo ""
}

success() { echo -e "  ${CHECK} $1"; }
warn()    { echo -e "  ${WARN} $1"; }
error()   { echo -e "  ${ERR} $1"; }
info()    { echo -e "  ${DIM}$1${RESET}"; }
prompt()  { echo -ne "  ${ARROW} $1 "; }

# ── expand ~ in paths ─────────────────────────────────────────────────────────
expand_path() {
  local p="${1/#\~/$HOME}"
  echo "$p"
}

# ── existing config check ─────────────────────────────────────────────────────
CONFIG_FILE="$PLUGIN_ROOT/config.yml"

clear
echo ""
echo -e "  ${BOLD}${CYAN}⬡  council setup wizard${RESET}"
echo ""
info "Configures paths and defaults for /council:spawn and /council:assemble."
echo ""

if [[ -f "$CONFIG_FILE" ]]; then
  divider
  echo -e "  ${BOLD}Existing config found:${RESET}"
  echo ""
  while IFS= read -r line; do
    echo -e "  ${DIM}${line}${RESET}"
  done < "$CONFIG_FILE"
  echo ""
  prompt "Update config? [y/N]"
  read -r answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo ""
    success "Nothing changed. Config is ready."
    echo ""
    exit 0
  fi
fi

# ── step 1: experts-clones path ───────────────────────────────────────────────
header 1 4 "Experts-clones directory"
info "Where do you keep your brain.md files?"
info "Example: ~/brain/knowledge/experts-clones"
echo ""

EXPERTS_PATH=""
attempts=0
while [[ -z "$EXPERTS_PATH" ]]; do
  prompt "Path:"
  read -r raw_path

  if [[ -z "$raw_path" ]]; then
    error "Path cannot be empty."
    continue
  fi

  expanded="$(expand_path "$raw_path")"

  if [[ -d "$expanded" ]]; then
    EXPERTS_PATH="$expanded"
    success "Found: $EXPERTS_PATH"
  else
    attempts=$((attempts + 1))
    error "Directory not found: $expanded"
    if [[ $attempts -ge 2 ]]; then
      echo ""
      warn "Can't find the directory. You can copy an example clone to get started."
      info "Re-run setup after creating your experts-clones directory."
      echo ""
      prompt "Continue anyway and use examples? [y/N]"
      read -r fallback
      if [[ "$fallback" =~ ^[Yy]$ ]]; then
        EXPERTS_PATH="$expanded"
        warn "Path saved but directory doesn't exist yet — create it before using /council:assemble."
        break
      else
        exit 1
      fi
    fi
  fi
done

# ── step 2: topics-index.yml ──────────────────────────────────────────────────
header 2 4 "Topics index"
info "topics-index.yml enables /council:assemble <topic> routing."
echo ""

TOPICS_INDEX_PATH="none"
DEFAULT_INDEX="$EXPERTS_PATH/topics-index.yml"

if [[ -f "$DEFAULT_INDEX" ]]; then
  success "Found automatically: $DEFAULT_INDEX"
  TOPICS_INDEX_PATH="$DEFAULT_INDEX"
else
  warn "Not found at: $DEFAULT_INDEX"
  echo ""
  prompt "Enter path to topics-index.yml (or press Enter to skip):"
  read -r raw_index

  if [[ -n "$raw_index" ]]; then
    expanded_index="$(expand_path "$raw_index")"
    if [[ -f "$expanded_index" ]]; then
      TOPICS_INDEX_PATH="$expanded_index"
      success "Found: $TOPICS_INDEX_PATH"
    else
      error "File not found: $expanded_index"
      warn "Topic routing disabled. /council:spawn <slug> still works."
      TOPICS_INDEX_PATH="none"
    fi
  else
    warn "Skipped. /council:assemble <topic> won't work without it."
    info "/council:spawn <slug> still works without a topics index."
    TOPICS_INDEX_PATH="none"
  fi
fi

# ── step 3: example clone ─────────────────────────────────────────────────────
header 3 4 "Example clone"
info "Copy a reference brain.md into your experts-clones directory?"
echo ""
echo -e "  ${DIM}1)${RESET} deep-clone   ${DIM}— full brain.md, all sections (Chip Huyen)${RESET}"
echo -e "  ${DIM}2)${RESET} simple-clone ${DIM}— minimal brain.md, essentials only (Martin Fowler)${RESET}"
echo -e "  ${DIM}3)${RESET} skip"
echo ""
prompt "Choice [1/2/3]:"
read -r clone_choice

case "$clone_choice" in
  1)
    src="$PLUGIN_ROOT/examples/deep-clone"
    dst="$EXPERTS_PATH/examples/deep-clone"
    mkdir -p "$dst"
    cp -r "$src/." "$dst/"
    success "Copied deep-clone to: $dst"
    info "Use it as a reference when writing your own brain.md files."
    ;;
  2)
    src="$PLUGIN_ROOT/examples/simple-clone"
    dst="$EXPERTS_PATH/examples/simple-clone"
    mkdir -p "$dst"
    cp -r "$src/." "$dst/"
    success "Copied simple-clone to: $dst"
    info "Use it as a reference when writing your own brain.md files."
    ;;
  *)
    info "Skipped."
    ;;
esac

# ── step 4: agents output scope ───────────────────────────────────────────────
header 4 4 "Agent output scope"
info "Default lifecycle for spawned/assembled agents (override anytime with flags)."
echo ""
echo -e "  ${DIM}1)${RESET} ephemeral ${DIM}— session-first; tracked in ${CYAN}.claude/council/${RESET}${DIM}, removed with /council:dismiss ${GREEN}(recommended for experiments)${RESET}"
echo -e "  ${DIM}2)${RESET} project     ${DIM}— persistent in .claude/agents/ in each project${RESET}"
echo -e "  ${DIM}3)${RESET} user        ${DIM}— persistent in ~/.claude/agents/${RESET}"
echo -e "  ${DIM}4)${RESET} ask         ${DIM}— prompt every time${RESET}"
echo ""
prompt "Choice [1/2/3/4] (default 1):"
read -r scope_choice

case "$scope_choice" in
  2) AGENTS_SCOPE="project" ;;
  3) AGENTS_SCOPE="user" ;;
  4) AGENTS_SCOPE="ask" ;;
  *) AGENTS_SCOPE="ephemeral" ;;
esac

success "Scope: $AGENTS_SCOPE"

# ── write config ──────────────────────────────────────────────────────────────
echo ""
divider

cat > "$CONFIG_FILE" <<EOF
# council config
# Generated by /council:setup — edit manually if you move directories.

# Absolute path to your experts-clones directory
experts_clones_path: $EXPERTS_PATH

# Absolute path to topics-index.yml
# Set to "none" to disable topic routing (/council:assemble <topic>)
topics_index_path: $TOPICS_INDEX_PATH

# Default lifecycle for generated agent files
# ephemeral → write to .claude/agents/ but register paths in .claude/council/ephemeral-registry (dismiss removes them)
# project   → persistent .claude/agents/ in current working directory
# user      → persistent ~/.claude/agents/
# ask       → prompt every time
agents_output_scope: $AGENTS_SCOPE
EOF

echo ""
success "Config saved to: $CONFIG_FILE"
echo ""
divider
echo ""
echo -e "  ${BOLD}Council is ready.${RESET}"
echo ""
echo -e "  ${DIM}/council:spawn chip-huyen${RESET}     → spawn a solo expert agent"
echo -e "  ${DIM}/council:assemble rag${RESET}         → assemble a team by topic"
echo -e "  ${DIM}/council:assemble team.yml${RESET}    → assemble from a team file"
echo -e "  ${DIM}/council:setup${RESET}                → re-run this wizard"
echo ""
divider
echo ""
