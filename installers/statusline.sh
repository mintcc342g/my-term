#!/bin/bash
# installers/statusline.sh — claude hud/statusline setup
# source'd by install.sh — uses shared log functions and variables

install_statusline() {
  log_start "install claude hud statusline…"

  # Copy hud files
  mkdir -p "$HOME/.claude/my-hud"
  chmod 700 "$HOME/.claude" "$HOME/.claude/my-hud"
  cp -f "$SCRIPT_DIR/my-claude/hud/"*.sh "$HOME/.claude/my-hud/"
  cp -f "$SCRIPT_DIR/my-claude/hud/"*.json "$HOME/.claude/my-hud/"
  chmod +x "$HOME/.claude/my-hud/"*.sh

  # Copy themes
  mkdir -p "$HOME/.claude/my-hud/themes"
  cp -f "$SCRIPT_DIR/my-claude/hud/themes/"*.sh "$HOME/.claude/my-hud/themes/"

  # Copy lib/ui.sh for configure.sh
  mkdir -p "$HOME/.claude/my-hud/lib"
  cp -f "$SCRIPT_DIR/lib/ui.sh" "$HOME/.claude/my-hud/lib/"

  # Register slash command
  mkdir -p "$HOME/.claude/commands"
  cp -f "$SCRIPT_DIR/my-claude/commands/my-term:hud.md" "$HOME/.claude/commands/"
  chmod 600 "$HOME/.claude/commands/my-term:hud.md"

  log_done "statusline installed."

  # Run initial configuration
  log_start "configure statusline…"
  bash "$HOME/.claude/my-hud/configure.sh"
}
