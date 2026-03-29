---
description: Assemble a team of Claude agents from your knowledge base. Usage — /council:assemble <topic|team.yml>. Prompts for ephemeral/persistent mode unless --ephemeral, --persist, or --user flag is given.
allowed-tools: Bash, Read, Glob, Write
---

You are assembling a team of expert agents. Delegate file generation to the `assembler` agent. Language: match the user's language.

## Pre-flight

Read `${CLAUDE_PLUGIN_ROOT}/config.yml`.

- If missing: stop and say "Run `/council:setup` first to configure paths."
- If present: extract `experts_clones_path`, `topics_index_path`, `agents_output_scope`.

## Determine input

Parse `$ARGUMENTS` for the topic/file and any flag (`--ephemeral`, `--persist`, `--user`).

If no topic given: ask "What topic or team file?"

## Pick spawn mode

If `agents_output_scope` is `project` and no flag given → mode = `project`, skip picker.
If `agents_output_scope` is `user` and no flag given → mode = `user`, skip picker.

Otherwise run the interactive picker:

```bash
MODE=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/pick-mode.sh" "assemble {topic}" "{flag}")
```

`MODE` will be one of: `ephemeral` | `project` | `user`.

## Determine output path

- `ephemeral` → `{cwd}/.claude/agents/`
- `project`   → `{cwd}/.claude/agents/`
- `user`      → `~/.claude/agents/`

## Delegate to assembler agent

Invoke the `assembler` agent with:

```
mode: topic | team-file
input: <topic string or absolute path to team.yml>
experts_clones_path: <from config>
topics_index_path: <from config or "none">
output_path: <resolved absolute path>
template_path: ${CLAUDE_PLUGIN_ROOT}/templates/agent-template.md
```

Wait for the assembler to return the list of generated files.

## Register ephemeral

If `MODE` is `ephemeral`: append each output file path to `~/.council-ephemeral-agents`.

## Report

**Ephemeral:**
```
⟳ Council assembled (ephemeral) — {topic}

  Agent           | Expert           | File
  ----------------|------------------|-----------------------------
  {slug}          | {name}           | {slug}.md
  ...

Agents active this session. Run /council:dismiss to remove when done.
```

**Persistent:**
```
⬡ Council assembled (persistent) — {topic}
  Scope: project | user

  Agent           | Expert           | File
  ----------------|------------------|-----------------------------
  {slug}          | {name}           | {slug}.md
  ...

Invoke with @{slug}.
```
