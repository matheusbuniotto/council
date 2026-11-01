#!/usr/bin/env python3
"""Council PreToolUse hook — protects user's expert brain.md files from accidental mutation.

Reads tool invocation payload from stdin. If tool is Write/Edit and the target
file lives inside the configured experts_clones_path, blocks the tool call
with exit code 2 and outputs an explanatory error message to stderr.
"""

import json
import os
import sys
from pathlib import Path

def resolve_target_path(tool_input: dict, cwd: str) -> Path | None:
    raw_path = (
        tool_input.get("file_path")
        or tool_input.get("path")
        or tool_input.get("target_file")
        or tool_input.get("filePath")
    )
    if not raw_path or not isinstance(raw_path, str):
        return None
    p = Path(os.path.expanduser(raw_path))
    if not p.is_absolute():
        p = Path(cwd) / p
    try:
        return p.resolve()
    except Exception:
        return p

def load_experts_path(plugin_root: str) -> Path | None:
    config_file = Path(plugin_root) / "config.yml"
    if not config_file.exists():
        return None
    try:
        with open(config_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("experts_clones_path:"):
                    parts = line.split(":", 1)
                    if len(parts) == 2:
                        val = parts[1].strip()
                        if val and val != "none":
                            return Path(os.path.expanduser(val)).resolve()
    except Exception:
        return None
    return None

def main():
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT")
    if not plugin_root:
        # Default fallback to parent of hooks directory
        plugin_root = str(Path(__file__).resolve().parent.parent)

    experts_dir = load_experts_path(plugin_root)
    if not experts_dir or not experts_dir.exists():
        sys.exit(0)

    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool_name = payload.get("tool_name", "")
    if tool_name not in ("Write", "Edit", "write_file", "edit_file"):
        sys.exit(0)

    tool_input = payload.get("tool_input", {})
    cwd = payload.get("cwd", os.getcwd())
    target_path = resolve_target_path(tool_input, cwd)

    if not target_path:
        sys.exit(0)

    # Check if target_path is within experts_dir
    try:
        is_subpath = (target_path == experts_dir or experts_dir in target_path.parents)
    except Exception:
        is_subpath = str(target_path).startswith(str(experts_dir))

    if is_subpath:
        sys.stderr.write(
            f"[council] Guard blocked: modifying '{target_path}' is prevented. "
            f"Files in experts knowledge base '{experts_dir}' are read-only.\n"
        )
        sys.exit(2)

    sys.exit(0)

if __name__ == "__main__":
    main()
