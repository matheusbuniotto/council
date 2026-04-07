---
name: assemble
description: Assemble a team of council expert agents by topic or team.yml. Prefer /council:assemble when available. Uses assembler agent and project-local ephemeral registry.
---

You are assembling a team of expert agents. Delegate file generation to the `assembler` agent. Language: match the user's language.

**Source of truth:** Mirror `commands/assemble.md`. If this skill and the command disagree, the command wins.

## Portable paths

- Config: `${CLAUDE_PLUGIN_ROOT}/config.yml`
- Agent template path passed to assembler: `${CLAUDE_PLUGIN_ROOT}/templates/agent-template.md`

Never hardcode `~/.claude/plugins/council`.

## Pre-flight

Read config; require `experts_clones_path`. For topic mode, `topics_index_path` must not be `"none"` (otherwise error and suggest `/council:spawn` or setup).

## Mode and ephemeral registry

Same flag and `agents_output_scope` rules as `/council:spawn` (including `ephemeral` as a config default).

When mode is **ephemeral**, after the assembler returns, append each generated file's **absolute** path to `{cwd}/.claude/council/ephemeral-registry` (mkdir the directory first). Never use `${CLAUDE_PLUGIN_ROOT}/ephemeral-registry`.

## Delegate to assembler

Invoke the `assembler` agent with:

```
mode: topic | team-file
input: <topic or absolute path to team.yml>
experts_clones_path: <from config>
topics_index_path: <from config or "none">
output_path: <absolute directory>
template_path: ${CLAUDE_PLUGIN_ROOT}/templates/agent-template.md
```

Wait for the structured `generated:` list.

## Report

Summarize agents and files; if ephemeral, mention `/council:dismiss`.
