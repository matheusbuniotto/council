#!/usr/bin/env python3
"""Validation tests for Claude Code plugin manifests and frontmatter."""

import json
import os
import re
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent

def test_plugin_manifest():
    plugin_path = ROOT_DIR / ".claude-plugin" / "plugin.json"
    assert plugin_path.exists(), f"Missing plugin manifest: {plugin_path}"
    
    with open(plugin_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    # Required core fields
    for field in ["name", "version", "description"]:
        assert field in data and data[field], f"Missing required field in plugin.json: {field}"
    
    assert re.match(r"^[a-z0-9-]+$", data["name"]), f"Plugin name '{data['name']}' must be kebab-case"
    assert "author" in data and isinstance(data["author"], dict), "Author must be an object"
    assert "name" in data["author"], "Author object must contain a 'name' field"
    
    # Check referenced directories if present
    for key in ["commands", "skills", "agents", "hooks"]:
        if key in data:
            val = data[key]
            if isinstance(val, str):
                target = (ROOT_DIR / val).resolve()
                assert target.exists(), f"Path '{val}' referenced in plugin.json does not exist"
    
    print("✓ plugin.json validation passed")

def test_marketplace_manifest():
    marketplace_path = ROOT_DIR / ".claude-plugin" / "marketplace.json"
    assert marketplace_path.exists(), f"Missing marketplace manifest: {marketplace_path}"
    
    with open(marketplace_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    assert "name" in data and data["name"], "Marketplace must have a name"
    assert "plugins" in data and isinstance(data["plugins"], list) and len(data["plugins"]) > 0, (
        "Marketplace must contain at least one plugin"
    )
    
    for plugin in data["plugins"]:
        assert "name" in plugin, "Plugin in marketplace must have a name"
        assert "source" in plugin, "Plugin in marketplace must have a source"
        source_path = (ROOT_DIR / plugin["source"]).resolve()
        assert source_path.exists(), f"Source path for plugin '{plugin['name']}' does not exist: {source_path}"
    
    print("✓ marketplace.json validation passed")

def test_markdown_frontmatter():
    """Verify that commands, skills, and agents contain valid frontmatter."""
    md_paths = []
    for d in ["commands", "skills", "agents"]:
        dir_path = ROOT_DIR / d
        if dir_path.exists():
            md_paths.extend(dir_path.rglob("*.md"))
    
    assert len(md_paths) > 0, "No markdown files found to validate"
    
    for path in md_paths:
        text = path.read_text(encoding="utf-8")
        if not text.startswith("---"):
            continue
        parts = text.split("---", 2)
        assert len(parts) >= 3, f"Invalid frontmatter format in {path}"
        frontmatter_text = parts[1].strip()
        assert "description:" in frontmatter_text, f"{path} is missing 'description:' in frontmatter"

    print(f"✓ Validated frontmatter in {len(md_paths)} markdown files")

if __name__ == "__main__":
    try:
        test_plugin_manifest()
        test_marketplace_manifest()
        test_markdown_frontmatter()
        print("\nAll manifest checks PASSED.")
    except Exception as e:
        print(f"\nFAIL: {e}", file=sys.stderr)
        sys.exit(1)
