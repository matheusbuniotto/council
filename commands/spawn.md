---
description: Spawn a single expert agent from your knowledge base. Usage — /council:spawn <slug>. Prompts for ephemeral/persistent mode unless --ephemeral, --persist, or --user flag is given.
allowed-tools: Bash, Read, Glob, Write
---

You are spawning a single expert agent. Language: match the user's language.

## Pre-flight

Read `${CLAUDE_PLUGIN_ROOT}/config.yml`.

If missing or invalid: stop and say:
> "Run `/council:setup` first to configure your experts-clones path."

Extract `experts_clones_path`, `agents_output_scope`.

## Resolve the expert

Parse `$ARGUMENTS` for the slug and any flag (`--ephemeral`, `--persist`, `--user`).

If no slug given:
- Glob `{experts_clones_path}/**/brain.md` and read the first 10 lines of each to extract `name`, `slug`, `use_when`.
- Build a list of up to 4 options from the results (prioritize by directory order).
- Use AskUserQuestion:
  - header: "Pick expert"
  - question: "Which expert do you want to spawn?"
  - options: one per expert — label: `{slug}`, description: `{use_when}`
  - If more than 4 experts exist, add an option: label: "Other" — description: "I'll type the slug."
- If user picks "Other": ask as follow-up "Type the slug:"

Search for `{experts_clones_path}/**/{slug}/brain.md` using Glob.

- If not found: list available slugs by globbing `{experts_clones_path}/**/brain.md` and extracting parent directory names. Ask user to pick one.

## Determine mode

If `--ephemeral` flag → mode = `ephemeral`
If `--persist` flag  → mode = `project`
If `--user` flag     → mode = `user`

If no flag and `agents_output_scope` is `ephemeral` → mode = `ephemeral`, skip prompt (recommended default for trying experts without committing agent files to git).
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

## Register ephemeral (project-local)

Ephemeral agents must be tracked **per project** so `/council:dismiss` and multi-repo workflows do not leak or delete the wrong files. Never write the registry under `${CLAUDE_PLUGIN_ROOT}`.

If mode is `ephemeral`:

1. Resolve `registry_dir` = `{cwd}/.claude/council` and `registry_file` = `{cwd}/.claude/council/ephemeral-registry`.
2. Run `mkdir -p` on `registry_dir` (Bash is allowed).
3. Append the **absolute** path of the generated agent file as a single new line to `registry_file` (use Write to read-modify-write, or Bash `>>` with absolute path).

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
