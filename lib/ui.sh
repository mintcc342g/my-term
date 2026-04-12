#!/bin/bash
# lib/ui.sh — shared arrow-key menu UI
# source'd by install.sh, configure.sh, etc.

UI_REVERSE=$'\033[7m'
UI_RESET=$'\033[0m'
UI_DIM=$'\033[2m'
UI_BOLD=$'\033[1m'
UI_BLUE_BOLD=$'\033[34;1m'
UI_GREEN_BOLD=$'\033[32;1m'
UI_RED_BOLD=$'\033[31;1m'
UI_YELLOW_BOLD=$'\033[33;1m'

# ── Read single keypress (arrow keys, enter, q) ────────────────
ui_read_key() {
  local key old_stty
  old_stty=$(stty -g < /dev/tty 2>/dev/null)
  stty raw -echo < /dev/tty 2>/dev/null
  trap 'stty "$old_stty" < /dev/tty 2>/dev/null' RETURN

  key=$(dd bs=1 count=1 2>/dev/null < /dev/tty)

  if [[ "$key" == $'\x1b' ]]; then
    local seq
    seq=$(dd bs=1 count=2 2>/dev/null < /dev/tty)
    case "$seq" in
      '[A') echo "up" ;;
      '[B') echo "down" ;;
      '[C'|'[D') echo "ignore" ;;
      *)    echo "esc" ;;
    esac
  elif [[ "$key" == "" || "$key" == $'\n' || "$key" == $'\r' ]]; then
    echo "enter"
  else
    echo "$key"
  fi
}

# ── Generic arrow-key menu ──────────────────────────────────────
# Usage: ui_menu "Title" result_var "item1" "item2" "item3" ...
# Returns selected index (0-based) in result_var
# User can press q/esc to cancel (returns 255)
ui_menu() {
  local title="$1"
  local __result_var="$2"
  shift 2
  local items=("$@")
  local count=${#items[@]}
  local sel=0

  # Hide cursor
  printf '\033[?25l' > /dev/tty

  while true; do
    # Clear screen and draw
    printf '\033[2J\033[H' > /dev/tty
    echo "${UI_BLUE_BOLD} ${title}${UI_RESET}" > /dev/tty
    echo " ─────────────────────" > /dev/tty
    echo " ${UI_DIM}↑↓ move  Enter select${UI_RESET}\n" > /dev/tty

    for i in "${!items[@]}"; do
      if [ "$i" -eq "$sel" ]; then
        echo "  ${UI_REVERSE} ▸ ${items[$i]} ${UI_RESET}" > /dev/tty
      else
        echo "    ${items[$i]}" > /dev/tty
      fi
    done

    local key
    key=$(ui_read_key)
    case "$key" in
      up)    sel=$(( (sel - 1 + count) % count )) ;;
      down)  sel=$(( (sel + 1) % count )) ;;
      enter)
        printf '\033[?25h' > /dev/tty
        printf -v "$__result_var" '%s' "$sel"
        return 0
        ;;
      ignore) ;;
      q|esc)
        printf '\033[?25h' > /dev/tty
        printf -v "$__result_var" '%s' "255"
        return 0
        ;;
    esac
  done
}
