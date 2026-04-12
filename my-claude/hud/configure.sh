#!/usr/bin/env bash
#
# SF-HUD configuration UI — arrow key navigation
# Called by install.sh with --project-root <path>
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse args
PROJECT_ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project-root) PROJECT_ROOT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Config location: use installed config if exists, else project
if [ -f "$HOME/.claude/my-hud/config.json" ]; then
  CONFIG="$HOME/.claude/my-hud/config.json"
elif [ -f "$SCRIPT_DIR/config.json" ]; then
  CONFIG="$SCRIPT_DIR/config.json"
else
  echo "Error: config.json not found" >&2
  exit 1
fi

# Source shared UI
if [ -f "$SCRIPT_DIR/../../lib/ui.sh" ]; then
  source "$SCRIPT_DIR/../../lib/ui.sh"
elif [ -f "$HOME/.claude/my-hud/lib/ui.sh" ]; then
  source "$HOME/.claude/my-hud/lib/ui.sh"
else
  echo "Error: lib/ui.sh not found" >&2
  exit 1
fi

# ── Load / Save config ──────────────────────────────────────────
load_config() {
  theme=$(jq -r '.theme // "mygo"' < "$CONFIG" 2>/dev/null)
  sec_workspace=$(jq -r '.sections.workspace.enabled // true' < "$CONFIG" 2>/dev/null)
  sec_claude=$(jq -r '.sections.claude.enabled // true' < "$CONFIG" 2>/dev/null)
  sec_codex=$(jq -r '.sections.codex.enabled // false' < "$CONFIG" 2>/dev/null)
}

save_config() {
  local tmp
  tmp=$(mktemp)
  jq --arg theme "$theme" \
     --argjson ws "$sec_workspace" \
     --argjson cl "$sec_claude" \
     --argjson cx "$sec_codex" \
     '.theme = $theme | .sections.workspace.enabled = $ws | .sections.claude.enabled = $cl | .sections.codex.enabled = $cx' \
     < "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
}

toggle() {
  if [ "$1" = "true" ]; then echo "false"; else echo "true"; fi
}

on_off() {
  if [ "$1" = "true" ]; then echo "ON"; else echo "OFF"; fi
}

# ── Sync HUD files from project ────────────────────────────────
sync_hud() {
  if [ -z "$PROJECT_ROOT" ] || [ ! -d "$PROJECT_ROOT/my-claude/hud" ]; then
    printf '\033[2J\033[H' > /dev/tty
    echo "${UI_RED_BOLD}✖${UI_RESET} Project root not found." > /dev/tty
    sleep 2
    return 1
  fi

  local dest="$HOME/.claude/my-hud"

  # Backup config.json
  local config_backup
  config_backup=$(mktemp)
  cp "$dest/config.json" "$config_backup" 2>/dev/null || true

  # Remove old files and sync fresh
  rm -f "$dest/"*.sh "$dest/"*.pl 2>/dev/null || true
  rm -rf "$dest/themes" "$dest/lib" 2>/dev/null || true

  # Copy latest
  mkdir -p "$dest/themes" "$dest/lib"
  cp -f "$PROJECT_ROOT/my-claude/hud/"*.sh "$dest/"
  chmod +x "$dest/"*.sh
  cp -f "$PROJECT_ROOT/my-claude/hud/themes/"*.sh "$dest/themes/"
  cp -f "$PROJECT_ROOT/lib/ui.sh" "$dest/lib/"

  # Restore config.json
  if [ -s "$config_backup" ]; then
    cp "$config_backup" "$dest/config.json"
  else
    cp -f "$PROJECT_ROOT/my-claude/hud/config.json" "$dest/config.json"
  fi
  rm -f "$config_backup"

  printf '\033[2J\033[H' > /dev/tty
  echo "${UI_GREEN_BOLD}✔${UI_RESET} HUD synced." > /dev/tty
  sleep 1
}

# ── Theme submenu ───────────────────────────────────────────────
select_theme() {
  local current_marker_0="" current_marker_1="" current_marker_2=""
  [ "$theme" = "mygo" ] && current_marker_0=" (current)"
  [ "$theme" = "eimes" ] && current_marker_1=" (current)"
  [ "$theme" = "ave-mujica" ] && current_marker_2=" (current)"

  local choice
  ui_menu "Select Theme" choice \
    "mygo${current_marker_0}" \
    "eimes${current_marker_1}" \
    "ave-mujica${current_marker_2}" \
    "Back"

  case "$choice" in
    0) theme="mygo" ;;
    1) theme="eimes" ;;
    2) theme="ave-mujica" ;;
  esac
}

# ── Main loop ───────────────────────────────────────────────────
load_config

while true; do
  choice=""

  # Show sync option only if project root is available
  if [ -n "$PROJECT_ROOT" ]; then
    ui_menu "CLAUDE HUD Settings" choice \
      "Theme: ${theme}" \
      "Workspace: $(on_off "$sec_workspace")" \
      "Claude: $(on_off "$sec_claude")" \
      "Codex: $(on_off "$sec_codex")" \
      "Sync HUD (update from project)" \
      "Save & Exit" \
      "Exit"

    case "$choice" in
      0) select_theme ;;
      1) sec_workspace=$(toggle "$sec_workspace") ;;
      2) sec_claude=$(toggle "$sec_claude") ;;
      3) sec_codex=$(toggle "$sec_codex") ;;
      4) sync_hud ;;
      5)
        save_config
        printf '\033[2J\033[H'
        echo "${UI_GREEN_BOLD}✔${UI_RESET} Settings saved."
        exit 0
        ;;
      6|255)
        printf '\033[2J\033[H'
        echo "Bye!"
        exit 0
        ;;
    esac
  else
    ui_menu "CLAUDE HUD Settings" choice \
      "Theme: ${theme}" \
      "Workspace: $(on_off "$sec_workspace")" \
      "Claude: $(on_off "$sec_claude")" \
      "Codex: $(on_off "$sec_codex")" \
      "Save & Exit" \
      "Exit"

    case "$choice" in
      0) select_theme ;;
      1) sec_workspace=$(toggle "$sec_workspace") ;;
      2) sec_claude=$(toggle "$sec_claude") ;;
      3) sec_codex=$(toggle "$sec_codex") ;;
      4)
        save_config
        printf '\033[2J\033[H'
        echo "${UI_GREEN_BOLD}✔${UI_RESET} Settings saved."
        exit 0
        ;;
      5|255)
        printf '\033[2J\033[H'
        echo "Bye!"
        exit 0
        ;;
    esac
  fi
done
