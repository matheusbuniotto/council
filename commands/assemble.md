---
description: Assemble a team of Claude agents from your knowledge base. Usage — /council:assemble <topic|team.yml>. Prompts for ephemeral/persistent mode unless --ephemeral, --persist, or --user flag is given.
allowed-tools: Bash, Read, Glob, Write
---

You are assembling a team of expert agents. Delegate file generation to the `assembler` agent. Language: match the user's language.

## Pre-flight

Read `${CLAUDE_PLUGIN_ROOT}/config.yml`.

If missing or invalid: stop and say:
> "Run `/council:setup` first to configure your experts-clones path."

Extract `experts_clones_path`, `topics_index_path`, `agents_output_scope`.

## Determine input

Parse `$ARGUMENTS` for the topic/file and any flag (`--ephemeral`, `--persist`, `--user`).

If no topic given: ask "What topic or team file?"

## Determine mode

If `--ephemeral` flag → mode = `ephemeral`
If `--persist` flag  → mode = `project`
If `--user` flag     → mode = `user`

If no flag and `agents_output_scope` is `project` → mode = `project`, skip prompt.
If no flag and `agents_output_scope` is `user`    → mode = `user`, skip prompt.

If no flag and `agents_output_scope` is `ask`: use AskUserQuestion:
- header: "Team scope"
- question: "How long should this team live?"
- multiSelect: false
- options:
  - label: "Ephemeral" — description: "This session only. Removed when you run /council:dismiss."
  - label: "Project"   — description: "Saved to .claude/agents/ in this project. Persists across sessions."
  - label: "User"      — description: "Saved to ~/.claude/agents/. Available in all projects."

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

If mode is `ephemeral`: append each output file path as a new line to `${CLAUDE_PLUGIN_ROOT}/ephemeral-registry`.

## Report

**Ephemeral:**
```
⟳ Council assembled (ephemeral) — {topic}

  Agent           | Expert           | File
  ----------------|------------------|-----------------------------
  {slug}          | {name}           | {slug}.md
  ...

Agents active this session. Type @ to invoke. Run /council:dismiss to remove when done.
```

**Persistent:**
```
⬡ Council assembled (persistent) — {topic}
  Scope: project | user

  Agent           | Expert           | File
  ----------------|------------------|-----------------------------
  {slug}          | {name}           | {slug}.md
  ...

Type @ and select the agent from the picker.
```
