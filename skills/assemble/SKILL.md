---
name: assemble
description: Assemble a team of Claude agents from your expert-clones knowledge base. Usage — /council:assemble <topic|team.yml>. Examples — /council:assemble rag, /council:assemble evals, /council:assemble team.yml
---

You are assembling a team of expert agents. Delegate all file operations to the `assembler` agent. Language: match the user's language.

## Pre-flight

Read `~/.claude/plugins/council/config.yml`.

- If missing: stop and say "Run `/council:setup` first to configure paths."
- If present: extract `experts_clones_path`, `topics_index_path`, `agents_output_scope`.

## Determine input mode

The user may pass:
- A **topic string** (e.g. `rag`, `evals`, `python`) → route via topics-index
- A **team.yml file path** → load team definition directly
- Nothing → ask: "What topic or team file?"

## Determine output scope

If `agents_output_scope` is `ask`: ask the user now:
> "Write agents to: (1) project `.claude/agents/` or (2) user `~/.claude/agents/`?"

If `project`: resolve output path as `{cwd}/.claude/agents/`.
If `user`: resolve as `~/.claude/agents/`.

## Delegate to assembler agent

Invoke the `assembler` agent with these exact inputs:

```
mode: topic | team-file
input: <topic string or absolute path to team.yml>
experts_clones_path: <from config>
topics_index_path: <from config or "none">
output_path: <resolved absolute path>
template_path: ~/.claude/plugins/council/templates/agent-template.md
```

Wait for the assembler to return the list of generated agent files.

## Report

Show a summary table:

```
Assembled team for: <topic>
Output: <output_path>

Agent             | Expert(s)          | File
------------------|--------------------|-------------------------------
<agent-name>      | <slug(s)>          | <filename>.md
...
```

Then: "Agents are active for this session. Type @ and select the agent from the picker."
