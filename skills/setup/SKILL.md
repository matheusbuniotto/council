---
name: setup
description: Configure the council plugin paths and default agent lifecycle. Prefer /council:setup when available. Writes config under ${CLAUDE_PLUGIN_ROOT}.
---

You are running the **council setup wizard**. Be concise. Language: match the user's language.

**Source of truth:** Mirror `commands/setup.md`.

## Portable paths

- Read and write `${CLAUDE_PLUGIN_ROOT}/config.yml` only — never assume `~/.claude/plugins/council`.
- When copying examples, copy from `${CLAUDE_PLUGIN_ROOT}/examples/` into the user's `experts_clones_path`.

## Config shape

```yaml
experts_clones_path: <absolute path>
topics_index_path: <absolute path or "none">
agents_output_scope: ephemeral | project | user | ask
```

Recommend **ephemeral** as the default for new users who are experimenting (avoids committing generated agents; `/council:dismiss` cleans this project).

## Confirm

Point users to `/council:spawn`, `/council:assemble`, `/council:dismiss`, and `/council:list`.
