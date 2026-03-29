---
description: Remove all ephemeral agents spawned in this session. Usage — /council:dismiss
allowed-tools: Bash
---

Remove all ephemeral council agents registered for this session.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup.sh"
```

If the script reports nothing to clean up, say: "No ephemeral agents found."
If it removes files, confirm: "Council dismissed — ephemeral agents removed."
