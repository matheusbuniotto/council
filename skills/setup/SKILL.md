---
name: setup
description: Configure the council plugin — set paths, validate structure, and optionally clone an example expert brain. Run once before using assemble or spawn.
---

You are running the **council setup wizard**. Guide the user through configuration step by step. Be concise and direct. Language: match the user's language.

## Step 1 — Check for existing config

Read `~/.claude/plugins/council/config.yml`.

- If it exists and is valid: show current config, ask "Update config or continue?". If continue, stop here.
- If it does not exist: proceed to Step 2.

## Step 2 — Locate experts-clones directory

Ask the user:
> "Where is your experts-clones directory? (e.g. ~/brain/knowledge/experts-clones)"

Expand `~` to the full home path. Verify the path exists using Glob (`{path}/*`).

- If valid: proceed.
- If not found: show error, ask again. After 2 failures, suggest using the bundled example clone to get started (jump to Step 4).

## Step 3 — Locate topics-index.yml

Check if `{experts_clones_path}/topics-index.yml` exists.

- If yes: use it automatically, inform user.
- If no: ask for the path explicitly.
  - If not found anywhere: warn that topic-based routing (`/assemble <topic>`) will not work, but slug-based spawning (`/spawn <slug>`) still will. Proceed.

## Step 4 — Clone example (optional)

Ask:
> "Want to clone an example expert brain to understand the structure? Choose:
> 1. deep-clone — full brain.md with all sections (Chip Huyen, AI Engineering)
> 2. simple-clone — minimal brain.md with just the essentials (Martin Fowler)
> 3. skip"

If 1 or 2: copy the relevant files from `~/.claude/plugins/council/examples/` into `{experts_clones_path}/examples/`. Inform the user of the path and suggest they use it as a reference when creating new clones.

## Step 5 — Agents output scope default

Ask:
> "Where should assembled agents be written by default?
> 1. project — .claude/agents/ in the current project (scoped, recommended)
> 2. user — ~/.claude/agents/ (available in all projects)
> 3. ask every time"

Store the choice as `agents_output_scope`.

## Step 6 — Write config

Write `~/.claude/plugins/council/config.yml` with this structure:

```yaml
experts_clones_path: <expanded absolute path>
topics_index_path: <expanded absolute path>/topics-index.yml   # or "none" if not found
agents_output_scope: project | user | ask
```

Confirm: "Config saved. You can now use `/council:assemble` and `/council:spawn`."

Show a quick reference:
```
/council:assemble rag        → assemble team for topic "rag"
/council:assemble team.yml   → assemble from a team definition file
/council:spawn chip-huyen    → spawn solo agent for this expert
/council:setup               → re-run this wizard
```
