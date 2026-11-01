#!/usr/bin/env bash
# council — setup wizard
# Usage: bash setup.sh <plugin_root> [options]
# Outputs a config.yml to <plugin_root>/config.yml

set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
divider() { [[ "$QUIET" == "true" ]] || echo -e "${DIM}────────────────────────────────────────────────${RESET}"; }

header() {
  local step="$1" total="$2" title="$3"
  if [[ "$QUIET" != "true" ]]; then
    echo ""
    divider
    echo -e "  ${BOLD}council${RESET} ${DIM}·${RESET} setup wizard  ${DIM}[step ${step}/${total}]${RESET}"
    echo -e "  ${CYAN}${title}${RESET}"
    divider
    echo ""
  fi
}

success() { [[ "$QUIET" == "true" ]] || echo -e "  ${CHECK} $1"; }
warn()    { echo -e "  ${WARN} $1" >&2; }
error()   { echo -e "  ${ERR} $1" >&2; }
info()    { [[ "$QUIET" == "true" ]] || echo -e "  ${DIM}$1${RESET}"; }
prompt()  { [[ "$QUIET" == "true" ]] || echo -ne "  ${ARROW} $1 "; }

# ── expand ~ in paths ─────────────────────────────────────────────────────────
expand_path() {
  local p="${1/#\~/$HOME}"
  echo "$p"
}

usage() {
  cat <<EOF
Usage: bash setup.sh <plugin_root> [options]

Arguments:
  <plugin_root>              Path to council plugin root

Options:
  --experts-path <path>      Path to directory containing expert brain.md files
  --topics-index <path>      Path to topics-index.yml (or 'none' to skip)
  --scope <mode>             Default agent scope: ephemeral | project | user | ask
  --example <type>           Copy starter clone: deep-clone | simple-clone | none
  -y, --yes, --force         Skip confirmation prompts and overwrite existing config
  -q, --quiet                Suppress non-error output
  -h, --help                 Show this help message
EOF
  exit 0
}

# ── parse arguments ───────────────────────────────────────────────────────────
PLUGIN_ROOT=""
CLI_EXPERTS_PATH=""
CLI_TOPICS_INDEX=""
CLI_SCOPE=""
CLI_EXAMPLE=""
FORCE=false
QUIET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    -q|--quiet)
      QUIET=true
      shift
      ;;
    -y|--yes|--force)
      FORCE=true
      shift
      ;;
    --experts-path)
      CLI_EXPERTS_PATH="${2:-}"
      shift 2
      ;;
    --topics-index)
      CLI_TOPICS_INDEX="${2:-}"
      shift 2
      ;;
    --scope)
      CLI_SCOPE="${2:-}"
      shift 2
      ;;
    --example)
      CLI_EXAMPLE="${2:-}"
      shift 2
      ;;
    *)
      if [[ -z "$PLUGIN_ROOT" ]]; then
        PLUGIN_ROOT="$1"
        shift
      else
        error "Unknown argument: $1"
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$PLUGIN_ROOT" ]]; then
  error "Plugin root path required as first argument."
  usage
fi

PLUGIN_ROOT="$(cd "$PLUGIN_ROOT" 2>/dev/null && pwd || echo "$PLUGIN_ROOT")"
CONFIG_FILE="$PLUGIN_ROOT/config.yml"

IS_INTERACTIVE=false
if [[ -t 0 ]] && [[ "$FORCE" == "false" ]] && [[ -z "$CLI_EXPERTS_PATH" ]]; then
  IS_INTERACTIVE=true
fi

# ── existing config check ─────────────────────────────────────────────────────
if [[ -f "$CONFIG_FILE" ]]; then
  if $IS_INTERACTIVE; then
    echo ""
    echo -e "  ${BOLD}${CYAN}⬡  council setup wizard${RESET}"
    echo ""
    info "Configures paths and defaults for /council:spawn and /council:assemble."
    echo ""
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
  elif [[ "$FORCE" != "true" ]] && [[ -z "$CLI_EXPERTS_PATH" ]]; then
    # In non-interactive mode without --force or new params, preserve existing
    success "Existing config found at $CONFIG_FILE. Pass --force to overwrite."
    exit 0
  fi
fi

# ── step 1: experts-clones path ───────────────────────────────────────────────
EXPERTS_PATH=""
if [[ -n "$CLI_EXPERTS_PATH" ]]; then
  EXPERTS_PATH="$(expand_path "$CLI_EXPERTS_PATH")"
  if [[ ! -d "$EXPERTS_PATH" ]]; then
    warn "Directory '$EXPERTS_PATH' does not exist yet. Ensure it is created before spawning."
  fi
elif $IS_INTERACTIVE; then
  header 1 4 "Experts-clones directory"
  info "Where do you keep your brain.md files?"
  info "Example: ~/brain/knowledge/experts-clones"
  echo ""

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
        prompt "Continue anyway? [y/N]"
        read -r fallback
        if [[ "$fallback" =~ ^[Yy]$ ]]; then
          EXPERTS_PATH="$expanded"
          warn "Path saved but directory doesn't exist yet."
          break
        else
          exit 1
        fi
      fi
    fi
  done
else
  error "--experts-path is required in non-interactive mode."
  exit 1
fi

# ── step 2: topics-index.yml ──────────────────────────────────────────────────
TOPICS_INDEX_PATH="none"
DEFAULT_INDEX="$EXPERTS_PATH/topics-index.yml"

if [[ -n "$CLI_TOPICS_INDEX" ]]; then
  if [[ "$CLI_TOPICS_INDEX" == "none" ]]; then
    TOPICS_INDEX_PATH="none"
  else
    expanded_index="$(expand_path "$CLI_TOPICS_INDEX")"
    if [[ -f "$expanded_index" ]]; then
      TOPICS_INDEX_PATH="$expanded_index"
    else
      warn "Specified topics index '$expanded_index' not found. Setting to none."
      TOPICS_INDEX_PATH="none"
    fi
  fi
elif $IS_INTERACTIVE; then
  header 2 4 "Topics index"
  info "topics-index.yml enables /council:assemble <topic> routing."
  echo ""

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
      TOPICS_INDEX_PATH="none"
    fi
  fi
else
  if [[ -f "$DEFAULT_INDEX" ]]; then
    TOPICS_INDEX_PATH="$DEFAULT_INDEX"
  else
    TOPICS_INDEX_PATH="none"
  fi
fi

# ── step 3: example clone ─────────────────────────────────────────────────────
CLONE_CHOICE="${CLI_EXAMPLE:-}"
if [[ -z "$CLONE_CHOICE" ]] && $IS_INTERACTIVE; then
  header 3 4 "Example clone"
  info "Copy a reference brain.md into your experts-clones directory?"
  echo ""
  echo -e "  ${DIM}1)${RESET} deep-clone   ${DIM}— full brain.md, all sections (Chip Huyen)${RESET}"
  echo -e "  ${DIM}2)${RESET} simple-clone ${DIM}— minimal brain.md, essentials only (Martin Fowler)${RESET}"
  echo -e "  ${DIM}3)${RESET} skip"
  echo ""
  prompt "Choice [1/2/3]:"
  read -r user_choice
  case "$user_choice" in
    1) CLONE_CHOICE="deep-clone" ;;
    2) CLONE_CHOICE="simple-clone" ;;
    *) CLONE_CHOICE="none" ;;
  esac
fi

examples_base="$PLUGIN_ROOT/examples"
if [[ ! -d "$examples_base" ]] && [[ -d "$SCRIPT_ROOT/examples" ]]; then
  examples_base="$SCRIPT_ROOT/examples"
fi

case "$CLONE_CHOICE" in
  deep-clone|1)
    src="$examples_base/deep-clone"
    dst="$EXPERTS_PATH/examples/deep-clone"
    if [[ -d "$src" ]]; then
      mkdir -p "$dst"
      cp -r "$src/." "$dst/"
      success "Copied deep-clone to: $dst"
    fi
    ;;
  simple-clone|2)
    src="$examples_base/simple-clone"
    dst="$EXPERTS_PATH/examples/simple-clone"
    if [[ -d "$src" ]]; then
      mkdir -p "$dst"
      cp -r "$src/." "$dst/"
      success "Copied simple-clone to: $dst"
    fi
    ;;
  *)
    # none or skip
    ;;
esac

# ── step 4: agents output scope ───────────────────────────────────────────────
AGENTS_SCOPE="ephemeral"
if [[ -n "$CLI_SCOPE" ]]; then
  case "$CLI_SCOPE" in
    ephemeral|project|user|ask) AGENTS_SCOPE="$CLI_SCOPE" ;;
    *)
      warn "Invalid scope '$CLI_SCOPE'. Defaulting to ephemeral."
      AGENTS_SCOPE="ephemeral"
      ;;
  esac
elif $IS_INTERACTIVE; then
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
fi

success "Scope: $AGENTS_SCOPE"

# ── write config ──────────────────────────────────────────────────────────────
cat > "$CONFIG_FILE" <<EOF
# council config
# Generated by council setup wizard — edit manually if you move directories.

# Absolute path to your experts-clones directory
experts_clones_path: $EXPERTS_PATH

# Absolute path to topics-index.yml
# Set to "none" to disable topic routing (/council:assemble <topic>)
topics_index_path: $TOPICS_INDEX_PATH

# Default lifecycle for generated agent files
# ephemeral -> write to .claude/agents/ but register paths in .claude/council/ephemeral-registry
# project   -> persistent .claude/agents/ in current working directory
# user      -> persistent ~/.claude/agents/
# ask       -> prompt every time
agents_output_scope: $AGENTS_SCOPE
EOF

success "Config saved to: $CONFIG_FILE"

if $IS_INTERACTIVE; then
  echo ""
  divider
  echo -e "  ${BOLD}Council is ready.${RESET}"
  echo ""
  echo -e "  ${DIM}/council:spawn <slug>${RESET}       → spawn a solo expert agent"
  echo -e "  ${DIM}/council:assemble <topic>${RESET}   → assemble a team by topic"
  echo -e "  ${DIM}/council:list${RESET}              → list active agents"
  echo -e "  ${DIM}/council:dismiss${RESET}           → remove ephemeral agents"
  echo -e "  ${DIM}/council:setup${RESET}             → re-run this wizard"
  echo ""
  divider
  echo ""
fi
