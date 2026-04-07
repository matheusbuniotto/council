---
description: List all active council agents — shows ephemeral and persistent agents separately, with scope and expert info.
allowed-tools: Bash, Read, Glob
---

You are listing active council agents. Language: match the user's language.

## Find active agents

Run these in parallel (use `$PWD` for the current project — do not leave `{cwd}` literal in shell):

```bash
# Ephemeral registry for this project (absolute paths, one per line)
cat "${PWD}/.claude/council/ephemeral-registry" 2>/dev/null
```

```bash
# Project agents
ls "${PWD}/.claude/agents/"*.md 2>/dev/null
```

```bash
# User agents
ls "${HOME}/.claude/agents/"*.md 2>/dev/null
```

## Read frontmatter for each agent

For each `.md` file found: read the first ~30 lines to extract `name` and `description` from YAML frontmatter.

A project-scoped agent file is **ephemeral** if its absolute path appears in `${PWD}/.claude/council/ephemeral-registry`. Otherwise it is **persistent** (project). User-scope files under `~/.claude/agents/` are always **persistent**.

## Report

If nothing found:

```
No active council agents.

Spawn one with /council:spawn <slug>
Assemble a team with /council:assemble <topic>
```

If agents found, group by scope:

```
Active council agents

⟳ Ephemeral (this session)
  @agent-{slug}  —  {description}
  ...

⬡ Project (.claude/agents/)
  @agent-{slug}  —  {description}
  ...

⬡ User (~/.claude/agents/)
  @agent-{slug}  —  {description}
  ...

Type @ to invoke any agent. Run /council:dismiss to remove ephemeral agents.
```

Only show sections that have agents. Omit empty sections.
