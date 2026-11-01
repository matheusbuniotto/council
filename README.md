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

### Setup Wizard

Run the setup wizard once to configure your knowledge base paths:

**Option A — Directly in Claude Code chat:**
```
/council:setup
```
This runs an interactive multi-choice wizard using native Claude Code prompts.

**Option B — From terminal or scripts:**
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh" "${CLAUDE_PLUGIN_ROOT}"
```

**Non-interactive / Scripted setup:**
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh" "${CLAUDE_PLUGIN_ROOT}" \
  --experts-path ~/brain/knowledge/experts-clones \
  --topics-index ~/brain/knowledge/experts-clones/topics-index.yml \
  --scope ephemeral \
  --force \
  --quiet
```

Options supported by `scripts/setup.sh`:
- `--experts-path <path>`: Directory containing your `brain.md` notes
- `--topics-index <path>`: Path to `topics-index.yml` (or `none`)
- `--scope <mode>`: Default lifecycle (`ephemeral`, `project`, `user`, or `ask`)
- `--example <type>`: Copy starter clone (`deep-clone`, `simple-clone`, `none`)
- `-y`, `--yes`, `--force`: Skip overwrite confirmation prompts
- `-q`, `--quiet`: Suppress non-error output

---

## Commands & Skills

### Slash Commands (`commands/`)

| Command | What it does |
|---|---|
| `/council:setup` | First-time wizard — configure paths and options |
| `/council:spawn <slug>` | Spawn a single expert agent — prompts for ephemeral or persistent |
| `/council:assemble <topic>` | Assemble a team by topic — prompts for ephemeral or persistent |
| `/council:assemble <team.yml>` | Assemble from a named team definition file |
| `/council:list` | List all active agents — ephemeral and persistent, grouped by scope |
| `/council:dismiss` | Remove **this project's** ephemeral agents |

Flags skip the mode prompt: `--ephemeral`, `--persist`, `--user`.

### Contextual Radar Skill (`skills/suggest`)

Council includes an autonomous background skill that observes technical discussions and suggests relevant experts when your knowledge base covers the topic. Suggestions are polite, non-intrusive, and require your explicit confirmation before spawning.

---

## Safety & Lifecycle Hooks

Council leverages official Claude Code plugin hooks (`hooks/hooks.json`) for safety and session hygiene:

1. **Knowledge Base Guard (`PreToolUse`)**
   - Intercepts file modification tools (`Write`, `Edit`).
   - Automatically blocks any attempt by agents or subagents to edit, overwrite, or delete files inside your `experts_clones_path`.
   - Your personal notes and expert brains remain strictly read-only consultants.

2. **Session Health (`SessionStart`)**
   - Automatically checks project status when a session opens.
   - Gently alerts you if uncleaned ephemeral agents remain in `.claude/council/ephemeral-registry`.
   - Reminds you if `/council:setup` has not yet been configured.

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

The `examples/` directory includes starter clones you can use right away:

| Clone | Expert | Domain | Depth |
|-------|--------|--------|-------|
| `deep-clone/` | Chip Huyen | AI/ML Engineering | Full — all sections |
| `simple-clone/` | Martin Fowler | Software Engineering | Minimal — just essentials |
| `uncle-bob/` | Robert C. Martin | Clean Code, SOLID | Full — universally known |
| `karpathy/` | Andrej Karpathy | Deep Learning, Neural Nets | Full — universally known |

Run `/council:setup` and choose to copy any of these into your knowledge base to get started.

---

## Ephemeral agents (recommended default)

**Ephemeral** agents are generated files under `.claude/agents/`, recorded in **`.claude/council/ephemeral-registry`** in the project directory. `/council:dismiss` deletes only those files and clears the registry. It never touches persistent agents created with `--persist` or user scope.

Override any default with flags: `--ephemeral`, `--persist` (project persistent), `--user`.

---

## Testing & Verification

Council includes a comprehensive test suite covering manifest validation, frontmatter schemas, shell scripts, and lifecycle hook interception:

```bash
bash tests/run_all.sh
```

Continuous integration runs automatically on push and pull request via GitHub Actions.

---

## License

MIT
