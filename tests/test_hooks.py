#!/usr/bin/env python3
"""Tests for Council lifecycle hooks."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent

def test_protect_brain_hook():
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)
        plugin_root = tmp_path / "plugin"
        plugin_root.mkdir()
        
        experts_dir = tmp_path / "my_experts"
        experts_dir.mkdir()
        
        # Write config.yml
        config_file = plugin_root / "config.yml"
        config_file.write_text(f"experts_clones_path: {experts_dir}\n", encoding="utf-8")
        
        hook_script = ROOT_DIR / "hooks" / "protect_brain.py"
        env = dict(os.environ, CLAUDE_PLUGIN_ROOT=str(plugin_root))
        
        # Test 1: Write to file inside experts directory -> MUST BLOCK (exit code 2)
        payload_blocked = {
            "hook_event_name": "PreToolUse",
            "tool_name": "Write",
            "cwd": str(tmp_path),
            "tool_input": {
                "file_path": str(experts_dir / "chip-huyen" / "brain.md")
            }
        }
        res_blocked = subprocess.run(
            [sys.executable, str(hook_script)],
            input=json.dumps(payload_blocked),
            text=True,
            capture_output=True,
            env=env
        )
        assert res_blocked.returncode == 2, (
            f"Expected exit code 2 for write to brain, got {res_blocked.returncode}. Stderr: {res_blocked.stderr}"
        )
        assert "Guard blocked" in res_blocked.stderr
        print("✓ protect_brain blocked unauthorized write to knowledge base")
        
        # Test 2: Write to project file outside experts directory -> MUST ALLOW (exit code 0)
        payload_allowed = {
            "hook_event_name": "PreToolUse",
            "tool_name": "Write",
            "cwd": str(tmp_path),
            "tool_input": {
                "file_path": str(tmp_path / "src" / "index.ts")
            }
        }
        res_allowed = subprocess.run(
            [sys.executable, str(hook_script)],
            input=json.dumps(payload_allowed),
            text=True,
            capture_output=True,
            env=env
        )
        assert res_allowed.returncode == 0, (
            f"Expected exit code 0 for normal write, got {res_allowed.returncode}. Stderr: {res_allowed.stderr}"
        )
        print("✓ protect_brain allowed write to project file")

def test_session_start_hook():
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)
        plugin_root = tmp_path / "plugin"
        plugin_root.mkdir()
        
        hook_script = ROOT_DIR / "hooks" / "session_start.sh"
        
        # Case 1: No config.yml
        env1 = dict(os.environ, CLAUDE_PLUGIN_ROOT=str(plugin_root), CLAUDE_PROJECT_DIR=str(tmp_path))
        res1 = subprocess.run(["bash", str(hook_script)], text=True, capture_output=True, env=env1)
        assert res1.returncode == 0
        assert "Run /council:setup" in res1.stderr
        print("✓ session_start warned about missing config")
        
        # Case 2: Config exists and ephemeral agents exist
        (plugin_root / "config.yml").write_text("experts_clones_path: /dummy\n", encoding="utf-8")
        registry_dir = tmp_path / ".claude" / "council"
        registry_dir.mkdir(parents=True)
        registry_file = registry_dir / "ephemeral-registry"
        
        agent_file = tmp_path / "agent.md"
        agent_file.write_text("test", encoding="utf-8")
        registry_file.write_text(f"{agent_file}\n", encoding="utf-8")
        
        res2 = subprocess.run(["bash", str(hook_script)], text=True, capture_output=True, env=env1)
        assert res2.returncode == 0
        assert "1 ephemeral agent(s) active" in res2.stderr
        print("✓ session_start notified about active ephemeral agents")

if __name__ == "__main__":
    test_protect_brain_hook()
    test_session_start_hook()
    print("\nAll hook tests PASSED.")
