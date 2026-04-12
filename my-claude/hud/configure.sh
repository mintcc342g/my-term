#!/usr/bin/env bash
#
# SF-HUD configuration UI — arrow key navigation
# Called by installer after statusline install, or directly by user
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/config.json"

# Source shared UI (try installed location, then project relative)
if [ -f "$SCRIPT_DIR/lib/ui.sh" ]; then
  source "$SCRIPT_DIR/lib/ui.sh"
elif [ -f "$SCRIPT_DIR/../../lib/ui.sh" ]; then
  source "$SCRIPT_DIR/../../lib/ui.sh"
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
  ui_menu "CLAUDE HUD Settings" choice \
    "Theme: ${theme}" \
    "workspace: $(on_off "$sec_workspace")" \
    "claude: $(on_off "$sec_claude")" \
    "codex: $(on_off "$sec_codex")" \
    "Save & Exit" \
    "Exit without saving"

  case "$choice" in
    0) select_theme ;;
    1) sec_workspace=$(toggle "$sec_workspace") ;;
    2) sec_claude=$(toggle "$sec_claude") ;;
    3) sec_codex=$(toggle "$sec_codex") ;;
    4)
      save_config
      printf '\033[2J\033[H'
      echo -e "${UI_GREEN_BOLD}✔${UI_RESET} Settings saved."
      exit 0
      ;;
    5|255)
      printf '\033[2J\033[H'
      echo "Bye!"
      exit 0
      ;;
  esac
done
