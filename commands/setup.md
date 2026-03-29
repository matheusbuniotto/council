---
description: Configure the council plugin — set paths, validate structure, and optionally clone an example expert brain. Run once before using assemble or spawn.
allowed-tools: Bash
---

Run the setup wizard:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh" "${CLAUDE_PLUGIN_ROOT}"
```

Wait for the script to finish. It is fully interactive — do not send any additional messages while it runs.

When the script exits:
- If exit code 0: setup completed. Config written to `${CLAUDE_PLUGIN_ROOT}/config.yml`. Tell the user they can now use `/council:assemble` and `/council:spawn`.
- If exit code 1: setup was cancelled or failed. Ask the user if they want to try again.
