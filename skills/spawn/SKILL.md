---
name: spawn
description: Spawn a single expert agent on-the-fly from your knowledge base. Usage — /council:spawn <slug>. Examples — /council:spawn chip-huyen, /council:spawn martin-fowler. The agent is written to the project scope and available immediately.
---

You are spawning a single expert agent. Language: match the user's language.

## Pre-flight

Read `~/.claude/plugins/council/config.yml`.

- If missing: stop and say "Run `/council:setup` first."
- Extract `experts_clones_path`.

## Resolve the expert

The user passes a slug (e.g. `chip-huyen`, `martin-fowler`).

If no slug given: ask "Which expert? (e.g. chip-huyen, martin-fowler)"

Search for `{experts_clones_path}/**/{slug}/brain.md` using Glob.

- If not found: list available slugs by globbing `{experts_clones_path}/**/brain.md` and extracting parent directory names. Ask user to pick one.

## Read frontmatter only

Read only the first 25 lines of the found `brain.md` to extract YAML frontmatter:
- `name`, `slug`, `area`, `use_when`, `topics`, `key_concepts`

Do not read the full file body at this stage.

## Check for soul.md

Check if `{experts_clones_path}/**/{slug}/soul.md` exists.

- If yes: read it — this becomes the agent system prompt.
- If no: use the consulting section fallback (the assembler handles this).

## Generate agent file

Read `~/.claude/plugins/council/templates/agent-template.md`.

Fill in the template with:
- `name`: `{slug}`
- `description`: the `use_when` field from frontmatter
- `brain_path`: absolute path to `brain.md`
- `soul_path`: absolute path to `soul.md` (or `none`)
- `topics`: from frontmatter
- `key_concepts`: from frontmatter

Write the generated agent to `{cwd}/.claude/agents/{slug}.md`.

## Confirm

Report:
```
Spawned: @{slug}
Expert: {name}
Use when: {use_when}
File: .claude/agents/{slug}.md
```

"Invoke with `@{slug}` in this session."
