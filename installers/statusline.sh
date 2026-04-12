#!/bin/bash
# installers/statusline.sh — claude hud/statusline setup
# source'd by install.sh — uses shared log functions and variables

install_statusline() {
  log_start "install claude hud theme…\n"
  mkdir -p "$HOME/.claude/my-hud"
  chmod 700 "$HOME/.claude" "$HOME/.claude/my-hud"
  cp -f "$SCRIPT_DIR/my-claude/hud/"* "$HOME/.claude/my-hud/"
  chmod +x "$HOME/.claude/my-hud/"*.sh
  log_done "statusline installed."
}
