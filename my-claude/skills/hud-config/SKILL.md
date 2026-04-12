---
name: hud-config
description: Configure HUD statusline theme and sections
user-invocable: true
---

Read the HUD statusline config at `~/.claude/my-hud/config.json` and show the user the current settings:

- **Theme**: current theme name (mygo, eimes, ave-mujica)
- **Sections**: which sections are enabled/disabled (workspace, claude, codex)

Then ask the user what they'd like to change. Available options:
- Theme: `mygo` (deep blue → light gray), `eimes` (blue → pink), `ave-mujica` (dark crimson → muted white)
- Sections: `workspace`, `claude`, `codex` — each can be enabled or disabled

After the user decides, update `~/.claude/my-hud/config.json` using jq. Only modify the fields the user wants to change. Confirm the changes when done.

Always respond in the user's language.
