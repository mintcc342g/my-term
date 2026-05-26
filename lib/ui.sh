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
# Banner-only palette (used by ui_print_completion)
UI_YELLOW=$'\033[93m'
UI_BLUE=$'\033[94m'
UI_PINK=$'\033[38;5;205m'
UI_PURPLE=$'\033[35m'
UI_GREEN=$'\033[92m'

# ── Clear screen + home cursor ─────────────────────────────────
# Usage: ui_clear_screen
ui_clear_screen() {
  printf '\033[2J\033[H' > /dev/tty
}

# ── Read single keypress (arrow keys, enter, q) ────────────────
ui_read_key() {
  local key old_stty
  old_stty=$(stty -g < /dev/tty 2>/dev/null)
  stty raw -echo < /dev/tty 2>/dev/null
  trap 'stty "$old_stty" < /dev/tty 2>/dev/null' RETURN

  key=$(dd bs=1 count=1 2>/dev/null < /dev/tty)

  if [[ "$key" == $'\x1b' ]]; then
    # ESC may be standalone OR the lead byte of an arrow-key sequence
    # (\x1b[A/B/C/D). Set a brief inter-byte timeout so a lone ESC doesn't
    # block waiting for follow-up bytes that never arrive.
    stty min 0 time 1 < /dev/tty 2>/dev/null
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
    ui_clear_screen
    echo "${UI_BLUE_BOLD} ${title}${UI_RESET}" > /dev/tty
    # Optional note set by caller via env var (e.g. red warning). 호출자가
    # `UI_MENU_NOTE=... ui_menu ...` 형태로 inline 설정 시 자동 unset.
    if [ -n "${UI_MENU_NOTE:-}" ]; then
      echo -e "${UI_MENU_NOTE}" > /dev/tty
    fi
    echo " ─────────────────────" > /dev/tty
    echo " ${UI_DIM}↑↓ move │ Enter select${UI_RESET}" > /dev/tty
    echo "" > /dev/tty

    local UI_CYAN=$'\033[36;1m'
    for i in "${!items[@]}"; do
      local num=$((i + 1))
      local item="${items[$i]}"
      # Items whose first character isn't ASCII alphanumeric are treated as
      # navigation actions (e.g. "← Back", "✓ Save & Exit", "✗ Exit") and
      # rendered without the numeric prefix.
      local label
      if [[ ! "${item:0:1}" =~ [a-zA-Z0-9] ]]; then
        label="$item"
      else
        label="${num}) $item"
      fi
      if [ "$i" -eq "$sel" ]; then
        echo "  ${UI_CYAN}❯ ${label}${UI_RESET}" > /dev/tty
      else
        echo "  ${UI_DIM}  ${label}${UI_RESET}" > /dev/tty
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

# ── Skip-log helpers ───────────────────────────────────────────
# Centralizes the "log a skip line + pause briefly so the next ui_menu's
# screen clear doesn't eat the message" pattern. Direct callers of
# install_* (e.g. install_ides, which isn't wrapped in ui_confirm_run)
# should call these instead of inlining log_step + sleep.
#
# Tunable: change UI_SKIP_PAUSE here to adjust pacing globally.
UI_SKIP_PAUSE="${UI_SKIP_PAUSE:-0.5}"

# "skipped: <label>" — user opted out of an optional step.
ui_log_skipped() {
  log_step "skipped: $1" 2>/dev/null || true
  sleep "$UI_SKIP_PAUSE"
}

# "skipping <label> — <hint> not available." — prerequisite missing.
# $2 (hint) defaults to $1 (label) when caller omits it.
ui_log_skipping_dep() {
  log_step "skipping $1 — ${2:-$1} not available." 2>/dev/null || true
  sleep "$UI_SKIP_PAUSE"
}

# ── Yes/No prompt that runs a function on Yes ──────────────────
# Usage: ui_confirm_run "Label" function_name
# Shows a Yes/No menu titled "Label?"; on Yes, calls the named function.
# After selection: leave the menu on screen, blank line for spacing, then
# print the result/log below. The next menu's clear handles the cleanup.
ui_confirm_run() {
  local label="$1" func="$2"
  local choice=""
  ui_menu "${label}?" choice "Yes" "No (Skip)"
  echo
  case "$choice" in
    0) "$func"; sleep "$UI_SKIP_PAUSE" ;;
    *) ui_log_skipped "$label" ;;
  esac
}

# ── ui_confirm_run gated on a command existing in PATH ─────────
# Usage: ui_confirm_if_command <cmd> "Label" function_name [hint]
# If <cmd> is on PATH, prompt Yes/No and run function on Yes.
# Otherwise, log a skip message naming the missing dependency (defaults to <cmd>).
ui_confirm_if_command() {
  local cmd="$1" label="$2" func="$3" hint="${4:-$cmd}"
  if command -v "$cmd" &>/dev/null; then
    ui_confirm_run "$label" "$func"
  else
    echo
    ui_log_skipping_dep "$label" "$hint"
  fi
}

# ── ui_confirm_run gated on a directory existing ───────────────
# Usage: ui_confirm_if_dir <dir> "Label" function_name [hint]
# If <dir> exists, prompt Yes/No and run function on Yes.
# Otherwise, log a skip message naming the missing dependency (defaults to <dir>).
ui_confirm_if_dir() {
  local dir="$1" label="$2" func="$3" hint="${4:-$dir}"
  if [ -d "$dir" ]; then
    ui_confirm_run "$label" "$func"
  else
    echo
    ui_log_skipping_dep "$label" "$hint"
  fi
}

# ── Completion banner (clear screen + headline + ASCII art) ────
# Usage: ui_print_completion <action>   where action ∈ install|update|hud-config
# Reads $ZSHRC_MODIFIED to decide whether to remind about reloading shell.
ui_print_completion() {
  local action="${1:-install}"
  local headline=""
  case "$action" in
    update)     headline="Update complete!" ;;
    hud-config) headline="HUD configured." ;;
    install|*)  headline="Installation complete!" ;;
  esac

  ui_clear_screen
  printf '%s✔%s %s%s%s 🎉\n' \
    "${UI_GREEN_BOLD}" "${UI_RESET}" "${UI_GREEN_BOLD}" "$headline" "${UI_RESET}"

  # Action-specific follow-up note
  case "$action" in
    update)
      printf "  ${UI_YELLOW_BOLD}↻${UI_RESET} Restart Claude Code sessions to apply.\n\n"
      ;;
    install|*)
      if [ "${ZSHRC_MODIFIED:-}" = "true" ]; then
        printf "  Please run ${UI_YELLOW_BOLD}'source \${HOME}/.zshrc'${UI_RESET} or ${UI_YELLOW_BOLD}restart${UI_RESET} your shell.\n\n"
      else
        echo
      fi
      ;;
  esac

  cat <<EOF
::::::::::: ::::::::::: ::: ::::::::       ::::    ::::  :::   :::  ::::::::   ::::::::  ${UI_YELLOW}:::${UI_BLUE} :::${UI_PINK} :::${UI_PURPLE} :::${UI_GREEN} :::${UI_RESET}
    :+:         :+:     :+ :+:    :+:      +:+:+: :+:+:+ :+:   :+: :+:    :+: :+:    :+: ${UI_YELLOW}:+:${UI_BLUE} :+:${UI_PINK} :+:${UI_PURPLE} :+:${UI_GREEN} :+:${UI_RESET}
    +:+         +:+        +:+             +:+ +:+:+ +:+  +:+ +:+  +:+        +:+    +:+ ${UI_YELLOW}+:+${UI_BLUE} +:+${UI_PINK} +:+${UI_PURPLE} +:+${UI_GREEN} +:+${UI_RESET}
    +#+         +#+        +#++:++#++      +#+  +:+  +#+   +#++:   :#:        +#+    +:+ ${UI_YELLOW}+#+${UI_BLUE} +#+${UI_PINK} +#+${UI_PURPLE} +#+${UI_GREEN} +#+${UI_RESET}
    +#+         +#+               +#+      +#+       +#+    +#+    +#+   +#+# +#+    +#+ ${UI_YELLOW}+#+${UI_BLUE} +#+${UI_PINK} +#+${UI_PURPLE} +#+${UI_GREEN} +#+${UI_RESET}
    #+#         #+#        #+#    #+#      #+#       #+#    #+#    #+#    #+# #+#    #+#
###########     ###         ########       ###       ###    ###     ########   ########  ${UI_YELLOW}###${UI_BLUE} ###${UI_PINK} ###${UI_PURPLE} ###${UI_GREEN} ###${UI_RESET}
EOF
  echo
}
