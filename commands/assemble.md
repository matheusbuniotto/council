---
description: Assemble a team of Claude agents from your expert-clones knowledge base. Usage — /council:assemble <topic|team.yml> [--ephemeral|--persist]. Examples — /council:assemble rag, /council:assemble evals --ephemeral
allowed-tools: Bash, Read, Glob, Write
---

You are assembling a team of expert agents. Delegate file generation to the `assembler` agent. Language: match the user's language.

## Pre-flight

Read `${CLAUDE_PLUGIN_ROOT}/config.yml`.

- If missing: stop and say "Run `/council:setup` first to configure paths."
- If present: extract `experts_clones_path`, `topics_index_path`, `agents_output_scope`.

## Determine input mode

The user may pass:
- A **topic string** (e.g. `rag`, `evals`, `python`) → route via topics-index
- A **team.yml file path** → load team definition directly
- Nothing → ask: "What topic or team file?"

## Determine spawn mode

Check `$ARGUMENTS` for flags:
- `--ephemeral` → mode = ephemeral
- `--persist` → mode = persistent

If no flag: check `agents_output_scope` from config:
- `project` or `user` → mode = persistent
- `ask` → ask the user:

```
Spawn mode for this team:
  1) ephemeral  — active this session only, removed after
  2) persistent — saved to .claude/agents/, available across sessions
```

## Determine output path

**Ephemeral:**
- Output path: `{cwd}/.claude/agents/`
- After assembler writes the files, register each file path in `~/.council-ephemeral-agents` (append one path per line)

**Persistent (project):**
- Output path: `{cwd}/.claude/agents/`

**Persistent (user):**
- Output path: `~/.claude/agents/`

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

After assembler returns: if mode is ephemeral, register each output file in `~/.council-ephemeral-agents`.

## Report

**Ephemeral:**
```
⟳ Council assembled (ephemeral) — topic: <topic>
  Lifetime: this session only

  Agent           | Expert           | File
  ----------------|------------------|-----------------------------
  <slug>          | <name>           | <filename>.md
  ...

Agents are active. Invoke with @<slug>.
Run /council:dismiss to remove when done.
```

**Persistent:**
```
⬡ Council assembled (persistent) — topic: <topic>
  Scope: project | user

  Agent           | Expert           | File
  ----------------|------------------|-----------------------------
  <slug>          | <name>           | <filename>.md
  ...

Agents are active. Invoke with @<slug>.
```
