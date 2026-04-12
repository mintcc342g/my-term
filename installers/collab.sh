#!/bin/bash
# installers/collab.sh — claude collab (multi-agent) setup
# source'd by install.sh — uses shared log functions and variables

install_collab() {
  log_start "install claude collab…\n"
  mkdir -p "$HOME/.claude/my-collab"
  chmod 700 "$HOME/.claude/my-collab"
  cp -f "$SCRIPT_DIR/my-claude/collab/"* "$HOME/.claude/my-collab/"
  chmod +x "$HOME/.claude/my-collab/"*.sh
  chmod 600 "$HOME/.claude/my-collab/co-agents.json"
  chmod 600 "$HOME/.claude/my-collab/co-directive.md"
  log_done "collab installed."
}
