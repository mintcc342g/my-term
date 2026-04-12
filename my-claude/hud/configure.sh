#!/usr/bin/env bash
#
# SF-HUD configuration UI
# Usage: bash statusline.sh --config
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/config.json"

YELLOW_BOLD='\033[33;1m'
BLUE_BOLD='\033[34;1m'
GREEN_BOLD='\033[32;1m'
RED_BOLD='\033[31;1m'
RESET='\033[0m'
DIM='\033[2m'

# ── Load current config ─────────────────────────────────────────
load_config() {
  theme=$(jq -r '.theme // "mygo"' < "$CONFIG" 2>/dev/null)
  sec_workspace=$(jq -r '.sections.workspace.enabled // true' < "$CONFIG" 2>/dev/null)
  sec_claude=$(jq -r '.sections.claude.enabled // true' < "$CONFIG" 2>/dev/null)
  sec_codex=$(jq -r '.sections.codex.enabled // false' < "$CONFIG" 2>/dev/null)
}

# ── Save config ─────────────────────────────────────────────────
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

# ── Toggle helper ───────────────────────────────────────────────
toggle() {
  if [ "$1" = "true" ]; then echo "false"; else echo "true"; fi
}

status_label() {
  if [ "$1" = "true" ]; then
    printf "${GREEN_BOLD}ON${RESET}"
  else
    printf "${RED_BOLD}OFF${RESET}"
  fi
}

# ── Theme selector ──────────────────────────────────────────────
select_theme() {
  local themes=("mygo" "eimes" "ave-mujica")
  echo
  echo -e "${BLUE_BOLD}Select theme:${RESET}"
  local i=1
  for t in "${themes[@]}"; do
    local marker=""
    [ "$t" = "$theme" ] && marker=" ${DIM}(current)${RESET}"
    echo -e "  ${i}) ${t}${marker}"
    ((i++))
  done
  echo -e "  ${i}) Back"

  local choice
  read -r -p "$(echo -e "${YELLOW_BOLD}> ${RESET}")" choice

  case "$choice" in
    1) theme="mygo" ;;
    2) theme="eimes" ;;
    3) theme="ave-mujica" ;;
    *) ;;
  esac
}

# ── Main menu ───────────────────────────────────────────────────
load_config

while true; do
  echo
  echo -e "${BLUE_BOLD} CLAUDE HUD Settings${RESET}"
  echo -e " ─────────────────────"
  echo -e "  1) Theme: ${YELLOW_BOLD}${theme}${RESET}"
  echo -e "  2) workspace: $(status_label "$sec_workspace")"
  echo -e "  3) claude: $(status_label "$sec_claude")"
  echo -e "  4) codex: $(status_label "$sec_codex")"
  echo -e "  5) ${GREEN_BOLD}Save & Exit${RESET}"
  echo -e "  6) Exit without saving"

  read -r -p "$(echo -e "\n${YELLOW_BOLD}Select an option: ${RESET}")" choice

  case "$choice" in
    1) select_theme ;;
    2) sec_workspace=$(toggle "$sec_workspace") ;;
    3) sec_claude=$(toggle "$sec_claude") ;;
    4) sec_codex=$(toggle "$sec_codex") ;;
    5)
      save_config
      echo -e "\n${GREEN_BOLD}✔${RESET} Settings saved to ${CONFIG}"
      exit 0
      ;;
    6)
      echo "Bye!"
      exit 0
      ;;
    *)
      echo -e "${RED_BOLD}Invalid option.${RESET}"
      ;;
  esac
done
