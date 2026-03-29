---
description: Spawn a single expert agent from your knowledge base. Usage — /council:spawn <slug>. Prompts for ephemeral/persistent mode unless --ephemeral, --persist, or --user flag is given.
allowed-tools: Bash, Read, Glob, Write
---

You are spawning a single expert agent. Language: match the user's language.

## Pre-flight

Read `${CLAUDE_PLUGIN_ROOT}/config.yml`.

If missing or invalid: use these defaults silently and continue:
- `experts_clones_path`: `~/experts-clones`
- `agents_output_scope`: `ask`

Extract `experts_clones_path`, `agents_output_scope`.

## Resolve the expert

Parse `$ARGUMENTS` for the slug and any flag (`--ephemeral`, `--persist`, `--user`).

If no slug given: ask "Which expert? (e.g. chip-huyen, martin-fowler)"

Search for `{experts_clones_path}/**/{slug}/brain.md` using Glob.

- If not found: list available slugs by globbing `{experts_clones_path}/**/brain.md` and extracting parent directory names. Ask user to pick one.

## Determine mode

If `--ephemeral` flag → mode = `ephemeral`
If `--persist` flag  → mode = `project`
If `--user` flag     → mode = `user`

If no flag and `agents_output_scope` is `project` → mode = `project`, skip prompt.
If no flag and `agents_output_scope` is `user`    → mode = `user`, skip prompt.

If no flag and `agents_output_scope` is `ask`: use AskUserQuestion:
- header: "Agent scope"
- question: "How long should @{slug} live?"
- multiSelect: false
- options:
  - label: "Ephemeral" — description: "This session only. Removed when you run /council:dismiss."
  - label: "Project"   — description: "Saved to .claude/agents/ in this project. Persists across sessions."
  - label: "User"      — description: "Saved to ~/.claude/agents/. Available in all projects."

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

If mode is `ephemeral`: append the output path as a new line to `~/.council-ephemeral-agents`.

## Report

**Ephemeral:**
```
⟳ Spawned (ephemeral): @agent-{slug}
  Expert:   {name}
  Use when: {use_when}
  File:     {output_path}

Run /council:dismiss to remove when done.
```

**Persistent:**
```
⬡ Spawned (persistent): @agent-{slug}
  Expert:   {name}
  Use when: {use_when}
  Scope:    project | user
  File:     {output_path}
```
