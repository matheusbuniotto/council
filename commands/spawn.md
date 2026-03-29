---
description: Spawn a single expert agent from your knowledge base. Usage — /council:spawn <slug> [--ephemeral|--persist]. Ephemeral agents are removed after the session; persistent agents stay in .claude/agents/.
allowed-tools: Bash, Read, Glob, Write
---

You are spawning a single expert agent. Language: match the user's language.

## Pre-flight

Read `${CLAUDE_PLUGIN_ROOT}/config.yml`.

- If missing: stop and say "Run `/council:setup` first."
- Extract `experts_clones_path`, `agents_output_scope`.

## Resolve the expert

The user passes a slug (e.g. `chip-huyen`, `martin-fowler`). It may be passed as `$ARGUMENTS`.

If no slug given: ask "Which expert? (e.g. chip-huyen, martin-fowler)"

Search for `{experts_clones_path}/**/{slug}/brain.md` using Glob.

- If not found: list available slugs by globbing `{experts_clones_path}/**/brain.md` and extracting parent directory names. Ask user to pick one.

## Determine mode

Check `$ARGUMENTS` for flags:
- `--ephemeral` → mode = ephemeral
- `--persist` → mode = persistent

If no flag: check `agents_output_scope` from config:
- `project` or `user` → mode = persistent
- `ask` → ask the user:

```
Spawn mode:
  1) ephemeral  — active this session only, removed after
  2) persistent — saved to .claude/agents/, available across sessions
```

## Determine output path

**Ephemeral:**
- Write to `{cwd}/.claude/agents/{slug}.md`
- Register the file path in `~/.council-ephemeral-agents` (append one path per line)

**Persistent (project):**
- Write to `{cwd}/.claude/agents/{slug}.md`

**Persistent (user):**
- Write to `~/.claude/agents/{slug}.md`

## Read frontmatter

Read only the first 25 lines of the found `brain.md`:
- `name`, `slug`, `area`, `use_when`, `topics`, `key_concepts`

## Check for soul.md

Check if `{experts_clones_path}/**/{slug}/soul.md` exists. If yes: read it.

## Generate agent file

Read `${CLAUDE_PLUGIN_ROOT}/templates/agent-template.md`.

Fill in the template with:
- `name`: `{slug}`
- `description`: the `use_when` field from frontmatter
- `brain_path`: absolute path to `brain.md`
- `topics`: from frontmatter
- `key_concepts`: from frontmatter

Write to the resolved output path.

## Report

**Ephemeral:**
```
⟳ Spawned (ephemeral): @{slug}
  Expert:    {name}
  Use when:  {use_when}
  File:      {output_path}
  Lifetime:  this session only

Run /council:dismiss to remove ephemeral agents when done.
```

**Persistent:**
```
⬡ Spawned (persistent): @{slug}
  Expert:    {name}
  Use when:  {use_when}
  File:      {output_path}
  Scope:     project | user
```
