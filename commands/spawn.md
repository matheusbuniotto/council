---
description: Spawn a single expert agent from your knowledge base. Usage — /council:spawn <slug>. Prompts for ephemeral/persistent mode unless --ephemeral, --persist, or --user flag is given.
allowed-tools: Bash, Read, Glob, Write
---

You are spawning a single expert agent. Language: match the user's language.

## Pre-flight

Read `${CLAUDE_PLUGIN_ROOT}/config.yml`.

- If missing: stop and say "Run `/council:setup` first."
- Extract `experts_clones_path`, `agents_output_scope`.

## Resolve the expert

Parse `$ARGUMENTS` for the slug and any flag (`--ephemeral`, `--persist`, `--user`).

If no slug given: ask "Which expert? (e.g. chip-huyen, martin-fowler)"

Search for `{experts_clones_path}/**/{slug}/brain.md` using Glob.

- If not found: list available slugs by globbing `{experts_clones_path}/**/brain.md` and extracting parent directory names. Ask user to pick one.

## Pick spawn mode

If `agents_output_scope` is `project` and no flag given → mode = `project`, skip picker.
If `agents_output_scope` is `user` and no flag given → mode = `user`, skip picker.

Otherwise run the interactive picker:

```bash
MODE=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/pick-mode.sh" "spawn {slug}" "{flag}")
```

`MODE` will be one of: `ephemeral` | `project` | `user`.

## Determine output path

- `ephemeral` → `{cwd}/.claude/agents/{slug}.md`
- `project`   → `{cwd}/.claude/agents/{slug}.md`
- `user`      → `~/.claude/agents/{slug}.md`

## Read frontmatter

Read only the first 25 lines of the found `brain.md`:
- `name`, `slug`, `area`, `use_when`, `topics`, `key_concepts`

## Check for soul.md

Check if `{experts_clones_path}/**/{slug}/soul.md` exists. If yes: read it.

## Generate agent file

Read `${CLAUDE_PLUGIN_ROOT}/templates/agent-template.md`. Fill and write to output path.

## Register ephemeral

If `MODE` is `ephemeral`: append the output path to `~/.council-ephemeral-agents`.

## Report

**Ephemeral:**
```
⟳ Spawned (ephemeral): @{slug}
  Expert:   {name}
  Use when: {use_when}
  File:     {output_path}

Run /council:dismiss to remove when done.
```

**Persistent:**
```
⬡ Spawned (persistent): @{slug}
  Expert:   {name}
  Use when: {use_when}
  Scope:    project | user
  File:     {output_path}
```
