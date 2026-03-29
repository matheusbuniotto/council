# council — Claude Code Plugin

> Summon a council of expert agents from your personal knowledge base.

**Council** turns your curated notes on thinkers, authors, and practitioners into live Claude Code agents. Clone any expert's reasoning into an agent, then invoke them by name — solo or as a team assembled by topic.

```
/council:spawn chip-huyen       → agent ready, type @ to invoke
/council:assemble rag           → team assembled, type @ to pick an expert
/council:assemble team.yml      → custom team from a definition file
```

---

## What it does

You maintain a directory of `brain.md` files — distilled notes on experts you follow. Council reads those files and generates Claude Code agents on-the-fly, each inheriting the expert's frameworks, vocabulary, and consulting lens.

The result: instead of asking Claude a generic question, you invoke **chip-huyen** from the agent picker (`@`) to review your RAG pipeline, or assemble the **rag team** and pick who to ask.

---

## Install

```bash
# 1. Add the council marketplace
claude plugin marketplace add https://github.com/matheusbuniotto/council

# 2. Install the plugin
claude plugin install council@council
```

Then, **run the setup wizard directly in your terminal** (it's interactive — needs a real TTY):

```bash
! bash ~/.claude/plugins/cache/council/council/0.1.0/scripts/setup.sh \
       ~/.claude/plugins/cache/council/council/0.1.0
```

Or from inside Claude Code, run `/council:setup` and it will give you the exact command to paste.

The setup wizard will ask for:
- Your `experts-clones/` directory path
- Your `topics-index.yml` path (optional — enables `/council:assemble <topic>`)
- Default agent output scope (project or user)

---

## Commands

| Command | What it does |
|---|---|
| `/council:setup` | First-time wizard — configure paths and options |
| `/council:spawn <slug>` | Spawn a single expert agent — prompts for ephemeral or persistent |
| `/council:assemble <topic>` | Assemble a team by topic — prompts for ephemeral or persistent |
| `/council:assemble <team.yml>` | Assemble from a named team definition file |
| `/council:dismiss` | Remove all ephemeral agents from this session |

Flags skip the mode prompt: `--ephemeral`, `--persist`, `--user`.

---

## Your knowledge base structure

Council is path-agnostic. It works with any directory layout as long as each expert has a `brain.md`:

```
your-experts-clones/
├── ai-engineering/
│   └── chip-huyen/
│       ├── brain.md        ← required
│       └── soul.md         ← optional: fine-grained voice control
├── software-engineering/
│   └── martin-fowler/
│       └── brain.md
└── topics-index.yml        ← optional: enables topic routing
```

### brain.md — required frontmatter

```yaml
---
name: Chip Huyen
slug: chip-huyen
area: ai-engineering
topics: [rag, evals, llmops, production-ai]
key_concepts: [productionization-gap, eval-first, data-flywheel]
pairs_well_with: [eugene-yan, shreya-shankar]
use_when: "LLM systems in production, eval pipelines, RAG architecture, inference cost"
---
```

Full template: [`templates/brain-template.md`](templates/brain-template.md)

### soul.md — optional voice override

Overrides the consulting section of `brain.md`. Use when you want precise control over the agent's voice beyond the brain.

Template: [`templates/soul-template.md`](templates/soul-template.md)

### topics-index.yml — optional topic routing

Enables `/council:assemble <topic>` to route to the right experts automatically:

```yaml
rag:
  - slug: chip-huyen
    priority: primary
  - slug: eugene-yan
    priority: secondary

evals:
  - slug: shreya-shankar
    priority: primary
  - slug: chip-huyen
    priority: secondary
```

---

## Usage

### Spawn a single expert

```
/council:spawn chip-huyen
```

Generates `.claude/agents/chip-huyen.md` and makes the agent available immediately.

Invoke by typing `@` and selecting `chip-huyen` from the agent picker, or explicitly:

```
@agent-chip-huyen review this RAG pipeline
@agent-chip-huyen should I fine-tune or keep prompting?
```

### Assemble a team by topic

```
/council:assemble rag
```

Council reads your `topics-index.yml`, resolves the matching experts, and generates one agent file per expert in `.claude/agents/`.

```
Assembled team for: rag
Output: .claude/agents/

Agent          | Expert        | File
---------------|---------------|------------------
chip-huyen     | Chip Huyen    | chip-huyen.md
eugene-yan     | Eugene Yan    | eugene-yan.md

Agents are active. Type @ and select chip-huyen or eugene-yan from the picker.
```

### Assemble from a team file

```
/council:assemble path/to/team.yml
```

```yaml
# team.yml
name: my-rag-team
experts:
  - slug: chip-huyen
  - slug: eugene-yan
  - slug: jason-liu
```

---

## Examples

The `examples/` directory includes two reference clones:

- **`deep-clone/`** — Chip Huyen: full `brain.md` with all sections
- **`simple-clone/`** — Martin Fowler: minimal `brain.md` with just the essentials

Run `/council:setup` and choose to copy one of these into your knowledge base to get started.

---

## How agents work

Generated agents are standard Claude Code agent files (`.claude/agents/*.md`). They:

- Load your `brain.md` on demand — only the relevant sections
- Respond in the expert's voice, using their frameworks
- Defer to other experts when appropriate (`"For evals, invoke shreya-shankar"`)
- Are scoped to the project (or user-wide, your choice)

Council generates them; Claude Code runs them. No magic — just well-structured prompts from your own notes.

---

## Config

After setup, `config.yml` is written to the plugin directory:

```yaml
experts_clones_path: ~/brain/knowledge/experts-clones
topics_index_path: ~/brain/knowledge/experts-clones/topics-index.yml
agents_output_scope: project   # project | user | ask
```

Re-run `/council:setup` to update it.

---

## License

MIT
