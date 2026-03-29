# expert-agency

Claude Code plugin for assembling and spawning expert agents from a personal knowledge base of expert clones.

## What it does

- `/expert-agency:assemble <topic>` — finds experts that cover a topic, generates agent `.md` files, makes them available immediately
- `/expert-agency:spawn <slug>` — generates a single expert agent on-the-fly
- `/expert-agency:setup` — first-time wizard: configures paths, validates structure, offers an example clone

## Requirements

- Claude Code with plugins enabled
- A directory of `brain.md` files (your expert-clones knowledge base)
- Optional but recommended: a `topics-index.yml` for topic-based routing

## Install

```bash
# Clone or copy this plugin to your user plugins directory
cp -r expert-agency ~/.claude/plugins/

# Run the setup wizard in Claude Code
/expert-agency:setup
```

## First-time setup

Run `/expert-agency:setup`. The wizard will:

1. Ask where your `experts-clones` directory is
2. Locate your `topics-index.yml`
3. Offer to clone an example expert brain (deep or simple) so you have a reference
4. Ask your default agent output scope (project or user)
5. Write `~/.claude/plugins/expert-agency/config.yml`

## Usage

```bash
# Assemble a team for a topic (uses topics-index.yml for routing)
/expert-agency:assemble rag
/expert-agency:assemble evals
/expert-agency:assemble python

# Assemble from a team definition file
/expert-agency:assemble path/to/team.yml

# Spawn a single expert agent
/expert-agency:spawn chip-huyen
/expert-agency:spawn martin-fowler

# Invoke an assembled agent
@chip-huyen review this RAG pipeline
@martin-fowler is this design correct?
```

## Directory structure expected

The plugin is path-agnostic. It works with any structure as long as each expert has a `brain.md`:

```
your-experts-clones/
├── any-category/
│   └── expert-slug/
│       ├── brain.md      # required — frontmatter + knowledge
│       └── soul.md       # optional — voice/consulting override
└── topics-index.yml      # optional — enables topic routing
```

## brain.md frontmatter (required fields)

```yaml
---
name: Full Name
slug: first-last
area: category-name
topics: [topic-1, topic-2]
key_concepts: [concept-1, concept-2]
pairs_well_with: [other-slug]
use_when: "when to invoke this expert — one sentence"
---
```

See `templates/brain-template.md` for the full structure.

## soul.md (optional)

Overrides the consulting section of `brain.md` for the generated agent's system prompt. Use when you want fine-grained control over the agent's voice beyond what the brain.md provides.

See `templates/soul-template.md` for the format.

## team.yml (optional)

Define a named team of experts to assemble together:

```yaml
name: my-team
experts:
  - slug: chip-huyen
  - slug: eugene-yan
```

See `templates/team.yml.example`.

## Examples

`examples/deep-clone/` — Chip Huyen: full brain.md with all sections
`examples/simple-clone/` — Martin Fowler: minimal brain.md with just the essentials

Use these as reference when creating your own clones.

## Config

After setup, `~/.claude/plugins/expert-agency/config.yml` contains:

```yaml
experts_clones_path: ~/path/to/experts-clones
topics_index_path: ~/path/to/topics-index.yml  # or "none"
agents_output_scope: project | user | ask
```

Re-run `/expert-agency:setup` to update it.
