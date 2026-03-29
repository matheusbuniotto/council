---
description: List all active council agents — shows ephemeral and persistent agents separately, with scope and expert info.
allowed-tools: Bash, Read, Glob
---

You are listing active council agents. Language: match the user's language.

## Find active agents

Run these in parallel:

```bash
# Ephemeral registry
cat ${CLAUDE_PLUGIN_ROOT}/ephemeral-registry 2>/dev/null
```

```bash
# Project agents
ls {cwd}/.claude/agents/*.md 2>/dev/null
```

```bash
# User agents
ls ~/.claude/agents/*.md 2>/dev/null
```

## Read frontmatter for each agent

For each `.md` file found: read the first 5 lines to extract `name` and `description` from frontmatter.

Cross-reference with `${CLAUDE_PLUGIN_ROOT}/ephemeral-registry` to determine if ephemeral or persistent.

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
