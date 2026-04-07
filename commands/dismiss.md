---
description: Remove all ephemeral agents spawned in this session. Usage — /council:dismiss
allowed-tools: Bash
---

Remove ephemeral council agents registered for **this project** (current working directory). Ephemeral paths are listed in `.claude/council/ephemeral-registry` — never in the plugin folder.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup.sh" "${PWD}/.claude/council/ephemeral-registry"
```

If the script prints that no registry exists and no files were removed, say: "No ephemeral agents registered in this project."
If it removes files, confirm: "Council dismissed — ephemeral agent files removed for this project."

**Legacy (pre–project-registry installs):** if the user still has `${CLAUDE_PLUGIN_ROOT}/ephemeral-registry` from an older version, mention they can delete that file manually after upgrading; do not pass the plugin root to `cleanup.sh` anymore.
