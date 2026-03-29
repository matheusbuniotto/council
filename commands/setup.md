---
description: Configure the council plugin — set paths, validate structure, and optionally clone an example expert brain. Run once before using assemble or spawn.
allowed-tools: Read
---

The setup wizard must run directly in your terminal (it's interactive — needs a real TTY).

Run this in your terminal:

```
! bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh" "${CLAUDE_PLUGIN_ROOT}"
```

The wizard will guide you through 4 steps: experts-clones path, topics index, example clone, and agent scope.

When you're done, come back and say "setup done" — I'll verify the config and confirm everything is ready.

---

If you've already run it, read `${CLAUDE_PLUGIN_ROOT}/config.yml` to verify the config, show it to the user, and confirm they can now use `/council:spawn` and `/council:assemble`.
