---
name: spawn
description: Spawn a single expert agent from the council knowledge base. Prefer /council:spawn when available. Respects ephemeral vs persistent lifecycle and ${CLAUDE_PLUGIN_ROOT} for all plugin paths.
---

You are spawning a single expert agent. Language: match the user's language.

**Source of truth:** Mirror the slash command at `commands/spawn.md` in this plugin. If this skill and the command ever disagree, the command wins.

## Portable paths (plugins best practice)

- Read config from `${CLAUDE_PLUGIN_ROOT}/config.yml` — never hardcode `~/.claude/plugins/council` (marketplace installs use versioned cache paths).
- Read templates from `${CLAUDE_PLUGIN_ROOT}/templates/agent-template.md`.

## Pre-flight

Read `${CLAUDE_PLUGIN_ROOT}/config.yml`. If missing or invalid: tell the user to run `/council:setup`.

Extract `experts_clones_path`, `agents_output_scope`.

## Mode (ephemeral is the safe default for ad-hoc use)

Respect flags if the user passes them: `--ephemeral`, `--persist` (project persistent), `--user`.

Otherwise use `agents_output_scope` from config:

- `ephemeral` → ephemeral (no prompt)
- `project` → project persistent (no prompt)
- `user` → user persistent (no prompt)
- `ask` → AskUserQuestion with Ephemeral / Project / User options (same copy as the command)

**Ephemeral registry (required):** when mode is ephemeral, after writing the agent file, append its **absolute** path as one line to `{cwd}/.claude/council/ephemeral-registry`. `mkdir -p {cwd}/.claude/council` first. Do **not** store ephemeral registries under `${CLAUDE_PLUGIN_ROOT}`.

## Output paths

- `ephemeral` or `project` → `{cwd}/.claude/agents/{slug}.md`
- `user` → `~/.claude/agents/{slug}.md` (expand to absolute home path)

## Generate

Read only the first ~25 lines of `brain.md` for frontmatter; load `soul.md` if present. Fill `agent-template.md` and Write the agent file.

## Confirm

Tell the user how to invoke `@` the agent. If ephemeral, remind them: `/council:dismiss` removes registered ephemeral files **for this project**.
