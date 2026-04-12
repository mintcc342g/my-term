#!/usr/bin/env bash
#
# SF-HUD configuration UI — arrow key navigation
# Usage: bash statusline.sh --config
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/config.json"

YELLOW_BOLD='\033[33;1m'
BLUE_BOLD='\033[34;1m'
GREEN_BOLD='\033[32;1m'
RED_BOLD='\033[31;1m'
DIM='\033[2m'
RESET='\033[0m'
REVERSE='\033[7m'

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

# ── Helpers ──────────────────────────────────────────────────────
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

# ── Read single keypress (arrow keys return special) ────────────
read_key() {
  local key
  # Use stty for raw mode to ensure arrow keys work across bash/zsh
  local old_stty
  old_stty=$(stty -g < /dev/tty 2>/dev/null)
  stty raw -echo < /dev/tty 2>/dev/null

  key=$(dd bs=1 count=1 2>/dev/null < /dev/tty)

  if [[ "$key" == $'\x1b' ]]; then
    local seq
    seq=$(dd bs=1 count=2 2>/dev/null < /dev/tty)
    stty "$old_stty" < /dev/tty 2>/dev/null
    case "$seq" in
      '[A') echo "up" ;;
      '[B') echo "down" ;;
      *)    echo "esc" ;;
    esac
  elif [[ "$key" == "" || "$key" == $'\n' || "$key" == $'\r' ]]; then
    stty "$old_stty" < /dev/tty 2>/dev/null
    echo "enter"
  else
    stty "$old_stty" < /dev/tty 2>/dev/null
    echo "$key"
  fi
}

# ── Draw menu ───────────────────────────────────────────────────
THEMES=("mygo" "eimes" "ave-mujica")

draw_main() {
  local sel=$1
  local items=(
    "Theme: ${theme}"
    "workspace: $([ "$sec_workspace" = "true" ] && echo "ON" || echo "OFF")"
    "claude: $([ "$sec_claude" = "true" ] && echo "ON" || echo "OFF")"
    "codex: $([ "$sec_codex" = "true" ] && echo "ON" || echo "OFF")"
    "Save & Exit"
    "Exit without saving"
  )

  printf '\033[2J\033[H'  # clear screen
  echo -e "${BLUE_BOLD} CLAUDE HUD Settings${RESET}"
  echo -e " ─────────────────────"
  echo -e " ${DIM}↑↓ move  Enter select${RESET}\n"

  for i in "${!items[@]}"; do
    if [ "$i" -eq "$sel" ]; then
      echo -e "  ${REVERSE} ▸ ${items[$i]} ${RESET}"
    else
      echo -e "    ${items[$i]}"
    fi
  done
}

draw_theme_menu() {
  local sel=$1

  printf '\033[2J\033[H'
  echo -e "${BLUE_BOLD} Select Theme${RESET}"
  echo -e " ─────────────────────"
  echo -e " ${DIM}↑↓ move  Enter select${RESET}\n"

  for i in "${!THEMES[@]}"; do
    local marker=""
    [ "${THEMES[$i]}" = "$theme" ] && marker=" ${DIM}(current)${RESET}"
    if [ "$i" -eq "$sel" ]; then
      echo -e "  ${REVERSE} ▸ ${THEMES[$i]}${RESET}${marker}"
    else
      echo -e "    ${THEMES[$i]}${marker}"
    fi
  done
  echo
  if [ 3 -eq "$sel" ]; then
    echo -e "  ${REVERSE} ▸ Back ${RESET}"
  else
    echo -e "    Back"
  fi
}

# ── Theme submenu ───────────────────────────────────────────────
run_theme_menu() {
  local sel=0
  local max=3  # 0-2: themes, 3: back

  while true; do
    draw_theme_menu "$sel"
    local key
    key=$(read_key)
    case "$key" in
      up)    sel=$(( (sel - 1 + max + 1) % (max + 1) )) ;;
      down)  sel=$(( (sel + 1) % (max + 1) )) ;;
      enter)
        if [ "$sel" -eq 3 ]; then
          return
        else
          theme="${THEMES[$sel]}"
          return
        fi
        ;;
      esc|q) return ;;
    esac
  done
}

# ── Main menu loop ──────────────────────────────────────────────
load_config

sel=0
max=5  # 0-5: 6 items

# Hide cursor
printf '\033[?25l'
trap 'printf "\033[?25h"' EXIT

while true; do
  draw_main "$sel"
  key=$(read_key)
  case "$key" in
    up)    sel=$(( (sel - 1 + max + 1) % (max + 1) )) ;;
    down)  sel=$(( (sel + 1) % (max + 1) )) ;;
    enter)
      case "$sel" in
        0) run_theme_menu ;;
        1) sec_workspace=$(toggle "$sec_workspace") ;;
        2) sec_claude=$(toggle "$sec_claude") ;;
        3) sec_codex=$(toggle "$sec_codex") ;;
        4)
          save_config
          printf '\033[2J\033[H'
          echo -e "${GREEN_BOLD}✔${RESET} Settings saved."
          exit 0
          ;;
        5)
          printf '\033[2J\033[H'
          echo "Bye!"
          exit 0
          ;;
      esac
      ;;
    q)
      printf '\033[2J\033[H'
      echo "Bye!"
      exit 0
      ;;
  esac
done
