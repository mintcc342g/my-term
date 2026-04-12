#!/bin/bash
# installers/hooks.sh — claude hooks setup
# source'd by install.sh — uses shared log functions and variables

install_hooks() {
  log_start "install claude hooks…\n"
  mkdir -p "$HOME/.claude/my-hooks"
  chmod 700 "$HOME/.claude/my-hooks"
  cp -f "$SCRIPT_DIR/my-claude/hooks/"* "$HOME/.claude/my-hooks/"
  chmod +x "$HOME/.claude/my-hooks/"*.sh
  log_done "hooks installed."
}
