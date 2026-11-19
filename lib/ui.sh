#!/bin/bash
# lib/ui.sh — shared arrow-key menu UI
# source'd by install.sh, configure.sh, etc.

UI_REVERSE=$'\033[7m'
UI_RESET=$'\033[0m'
UI_DIM=$'\033[2m'
UI_ITALIC=$'\033[3m'
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

# ── Language catalog bootstrap ─────────────────────────────────
# Locate lib/lang next to this file (works in repo and the deployed HUD copy)
# and load the default catalog. install.sh overrides via ui_select_language
# after the user picks a language; standalone callers (configure.sh) stay on
# the MYTERM_LANG env default (en). Colors above are already defined, so catalog
# strings that embed ${UI_*} expand correctly at source time.
_UI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$_UI_DIR/lang/lang.sh" ]; then
  source "$_UI_DIR/lang/lang.sh"
  [ -z "${_MYTERM_LANG_LOADED:-}" ] && lang_load "${MYTERM_LANG:-en}"
fi

# ── Clear screen + home cursor ─────────────────────────────────
# Usage: ui_clear_screen
ui_clear_screen() {
  printf '\033[2J\033[H' > /dev/tty
}

# Overwrite the menu in place. Erase only the unused end of each line and
# the area below the frame so navigation never shows a blank screen.
ui_draw_menu() {
  local frame="$1"
  printf '\033[H%s\033[K\n\033[J' "${frame//$'\n'/$'\033[K\n'}" > /dev/tty
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
      '[C') echo "right" ;;
      '[D') echo "left" ;;
      *)    echo "esc" ;;
    esac
  elif [[ "$key" == $'\x03' || "$key" == $'\x04' ]]; then
    # Ctrl+C / Ctrl+D. In `stty raw` mode ISIG is disabled, so these arrive as
    # bytes (ETX/EOT) instead of signals — the script's INT trap never fires.
    # Surface them as an explicit abort so the menu can quit immediately.
    echo "interrupt"
  elif [[ "$key" == "" || "$key" == $'\n' || "$key" == $'\r' ]]; then
    echo "enter"
  else
    echo "$key"
  fi
}

# ── Abort the whole installer ──────────────────────────────────
# Usage: ui_abort [exit_code]
# Restores the cursor + cooked terminal and exits the process. Used by both the
# explicit "✗ Exit" menu item and the Ctrl+C handler, so a user can bail out of
# any step without relying on a working SIGINT. Self-contained (no log_* helper)
# because configure.sh sources ui.sh without defining them.
ui_abort() {
  printf '\033[?25h' > /dev/tty 2>/dev/null || true
  stty sane < /dev/tty 2>/dev/null || true
  printf '\n%s✖%s %s\n' \
    "${UI_RED_BOLD}" "${UI_RESET}" "${L_EXIT_ABORTED:-Aborted — exiting.}" > /dev/tty 2>/dev/null || true
  exit "${1:-0}"
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
  local sel=0 frame

  # Optional per-item detail (dimmed italic, right of the focused row). Caller
  # sets UI_MENU_DESC=(...) parallel to items; captured + cleared so it never
  # leaks into the next menu. Desc column is fixed to the widest label.
  local -a _descs=()
  if [ "${UI_MENU_DESC+set}" = set ]; then _descs=("${UI_MENU_DESC[@]}"); unset UI_MENU_DESC; fi
  local _maxw=0 _it _l
  if [ "${#_descs[@]}" -gt 0 ]; then
    for _it in "${items[@]}"; do
      case "$_it" in '✗'*|'✓'*|'←'*|'→'*) _l=${#_it} ;; *) _l=$(( ${#_it} + 3 )) ;; esac
      [ "$_l" -gt "$_maxw" ] && _maxw=$_l
    done
  fi

  # Hide cursor
  printf '\033[?25l' > /dev/tty

  while true; do
    frame=$(
      echo "${UI_BLUE_BOLD} ${title}${UI_RESET}"
      # Optional note set by caller via env var (e.g. red warning). 호출자가
      # `UI_MENU_NOTE=... ui_menu ...` 형태로 inline 설정 시 자동 unset.
      if [ -n "${UI_MENU_NOTE:-}" ]; then
        echo -e "${UI_MENU_NOTE}"
      fi
      echo " ─────────────────────"
      echo " ${UI_DIM}${L_UI_HINT}${UI_RESET}"
      echo ""
      # Optional note rendered BELOW the nav hint (vs UI_MENU_NOTE above it). Same
      # inline `UI_MENU_NOTE_BELOW=... ui_menu ...` auto-scoping.
      if [ -n "${UI_MENU_NOTE_BELOW:-}" ]; then
        echo -e "${UI_MENU_NOTE_BELOW}"
        echo ""
      fi

      local UI_CYAN=$'\033[36;1m'
      for i in "${!items[@]}"; do
        local num=$((i + 1))
        local item="${items[$i]}"
        # Items beginning with a UI nav symbol (✗ ✓ ← →) are navigation actions
        # (e.g. "← Back", "✓ Save & Exit", "✗ Exit") and render without a numeric
        # prefix. Everything else — including non-ASCII text such as Korean — is a
        # selectable option and gets numbered. (Matching the symbol prefix rather
        # than "first char is non-alnum" keeps Korean items numbered.)
        local label
        case "$item" in
          ('✗'*|'✓'*|'←'*|'→'*) label="$item" ;;
          (*)                    label="${num}) $item" ;;
        esac
        if [ "$i" -eq "$sel" ]; then
          if [ -n "${_descs[$sel]:-}" ]; then
            local _pad=$(( _maxw - ${#label} )); [ "$_pad" -lt 0 ] && _pad=0
            printf '  %s❯ %s%s%*s   %s\033[3m%s%s\n' \
              "$UI_CYAN" "$label" "$UI_RESET" "$_pad" "" "$UI_DIM" "${_descs[$sel]}" "$UI_RESET"
          else
            echo "  ${UI_CYAN}❯ ${label}${UI_RESET}"
          fi
        else
          echo "  ${UI_DIM}  ${label}${UI_RESET}"
        fi
      done
    )
    ui_draw_menu "$frame"

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
      interrupt) ui_abort 130 ;;
      q|esc)
        printf '\033[?25h' > /dev/tty
        printf -v "$__result_var" '%s' "255"
        return 0
        ;;
    esac
  done
}

# ── Categorized checkbox menu ──────────────────────────────────
# Usage: ui_checklist "Title" result_var
# Caller supplies UI_CHECKLIST_CATEGORIES, UI_CHECKLIST_LABELS and parallel
# UI_CHECKLIST_GROUPS (0-based category indexes). Set UI_CHECKLIST_NO_ALL[group]
# to 1 for a category that needs individual checkboxes only. Returns install/skip
# in result_var and 0/1 flags in UI_CHECKLIST_SELECTED. Starts unchecked.
# Uses indexed arrays only, for the macOS system Bash 3.2.
ui_checklist() {
  local title="$1" __result_var="$2"
  local -a row_groups=() row_items=() focus_rows=()
  local group item row count row_count selected total mark label style prefix key
  local focus=0 focused_row action=0 offset=0 height lines size end frame message=""
  # Turn off dimming before applying bold and italic, retaining the row color.
  local all_label_style=$'\033[22;1;3m'
  local -a actions=("$L_MENU_INSTALL" "$L_CHECKLIST_SKIP" "$L_MENU_EXIT")
  UI_CHECKLIST_SELECTED=()
  for ((item=0; item<${#UI_CHECKLIST_LABELS[@]}; item++)); do
    UI_CHECKLIST_SELECTED[$item]=0
  done
  for ((group=0; group<${#UI_CHECKLIST_CATEGORIES[@]}; group++)); do
    # Negative item indexes represent headings, blank lines, and All rows.
    if [ "$group" -gt 0 ]; then
      row_groups+=("$group"); row_items+=("-2")
    fi
    row_groups+=("$group"); row_items+=("-3")
    if [ "${UI_CHECKLIST_NO_ALL[$group]:-0}" -ne 1 ]; then
      focus_rows+=("${#row_items[@]}")
      row_groups+=("$group"); row_items+=("-1")
    fi
    for ((item=0; item<${#UI_CHECKLIST_LABELS[@]}; item++)); do
      if [ "${UI_CHECKLIST_GROUPS[$item]}" -eq "$group" ]; then
        focus_rows+=("${#row_items[@]}")
        row_groups+=("$group"); row_items+=("$item")
      fi
    done
  done
  count=${#focus_rows[@]}
  row_count=${#row_items[@]}
  printf '\033[?25l' > /dev/tty
  while true; do
    # Keep the footer visible even in a short terminal. Leave one spare line
    # to avoid scrolling the entire screen when printing the last newline.
    size=$(stty size < /dev/tty 2>/dev/null) || size="24 80"
    lines=${size%% *}
    [[ "$lines" =~ ^[0-9]+$ ]] || lines=24
    height=$((lines - 9))
    [ "$height" -lt 1 ] && height=1
    [ "$height" -gt "$row_count" ] && height=$row_count
    focused_row=${focus_rows[$focus]:--1}
    if [ "$focused_row" -ge 0 ]; then
      [ "$focused_row" -lt "$offset" ] && offset=$focused_row
      [ "$focused_row" -ge "$((offset + height))" ] && offset=$((focused_row - height + 1))
    fi
    [ "$offset" -gt "$((row_count - height))" ] && offset=$((row_count - height))
    end=$((offset + height))

    frame=$(
      printf ' %s%s%s\n %s%s%s\n\n' "$UI_BLUE_BOLD" "$title" "$UI_RESET" \
        "$UI_DIM" "$L_CHECKLIST_HINT" "$UI_RESET"
      if [ "$offset" -gt 0 ]; then
        printf ' %s↑%s\n' "$UI_DIM" "$UI_RESET"
      else
        printf '\n'
      fi
      for ((row=offset; row<end; row++)); do
        group=${row_groups[$row]}; item=${row_items[$row]}
        case "$item" in
          (-3) printf ' %s%s%s\n' "$UI_BOLD" "${UI_CHECKLIST_CATEGORIES[$group]}" "$UI_RESET"; continue ;;
          (-2) printf '\n'; continue ;;
        esac
        mark=' '
        if [ "$item" -lt 0 ]; then
          selected=0; total=0
          for ((item=0; item<${#UI_CHECKLIST_LABELS[@]}; item++)); do
            if [ "${UI_CHECKLIST_GROUPS[$item]}" -eq "$group" ]; then
              total=$((total + 1))
              selected=$((selected + UI_CHECKLIST_SELECTED[item]))
            fi
          done
          if [ "$selected" -eq "$total" ]; then mark=x
          elif [ "$selected" -gt 0 ]; then mark='-'; fi
          label="[$mark] ${all_label_style}${L_CHECKLIST_ALL}"
        else
          [ "${UI_CHECKLIST_SELECTED[$item]}" -eq 1 ] && mark=x
          label="[$mark] ${UI_CHECKLIST_LABELS[$item]}"
        fi
        style=$UI_DIM
        prefix='  '
        if [ "$row" -eq "$focused_row" ]; then prefix='❯ '; style=$UI_BLUE_BOLD; fi
        printf ' %s%s%s%s\n' "$style" "$prefix" "$label" "$UI_RESET"
      done
      if [ "$end" -lt "$row_count" ]; then
        printf ' %s↓%s\n' "$UI_DIM" "$UI_RESET"
      else
        printf '\n'
      fi
      printf '\n '
      for ((item=0; item<3; item++)); do
        style=$UI_DIM
        if [ "$focus" -eq "$count" ] && [ "$action" -eq "$item" ]; then style=$UI_REVERSE; fi
        printf ' %s %s %s  ' "$style" "${actions[$item]}" "$UI_RESET"
      done
      printf '\n %s%s%s\n' "$UI_YELLOW_BOLD" "$message" "$UI_RESET"
    )
    ui_draw_menu "$frame"

    key=$(ui_read_key)
    case "$key" in
      up) focus=$(( (focus - 1 + count + 1) % (count + 1) )) ;;
      down) focus=$(( (focus + 1) % (count + 1) )) ;;
      left) if [ "$focus" -eq "$count" ]; then action=$(( (action + 2) % 3 )); fi ;;
      right) if [ "$focus" -eq "$count" ]; then action=$(( (action + 1) % 3 )); fi ;;
      enter|' ')
        if [ "$focus" -eq "$count" ]; then
          case "$action" in
            0)
              selected=0
              for item in "${UI_CHECKLIST_SELECTED[@]}"; do selected=$((selected + item)); done
              if [ "$selected" -eq 0 ]; then message=$L_CHECKLIST_EMPTY; continue; fi
              printf -v "$__result_var" '%s' install
              ;;
            1) printf -v "$__result_var" '%s' skip ;;
            2) ui_abort 0 ;;
          esac
          printf '\033[?25h' > /dev/tty
          return 0
        fi
        group=${row_groups[$focused_row]}; item=${row_items[$focused_row]}
        if [ "$item" -ge 0 ]; then
          UI_CHECKLIST_SELECTED[$item]=$((1 - UI_CHECKLIST_SELECTED[item]))
        else
          # Partial selection becomes All; an already checked All clears it.
          selected=1
          for ((item=0; item<${#UI_CHECKLIST_LABELS[@]}; item++)); do
            if [ "${UI_CHECKLIST_GROUPS[$item]}" -eq "$group" ] && [ "${UI_CHECKLIST_SELECTED[$item]}" -eq 0 ]; then
              selected=0
            fi
          done
          for ((item=0; item<${#UI_CHECKLIST_LABELS[@]}; item++)); do
            if [ "${UI_CHECKLIST_GROUPS[$item]}" -eq "$group" ]; then
              UI_CHECKLIST_SELECTED[$item]=$((1 - selected))
            fi
          done
        fi
        message=""
        ;;
      interrupt) ui_abort 130 ;;
      q|esc)
        printf '\033[?25h' > /dev/tty
        printf -v "$__result_var" '%s' skip
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
  # Yes / No(Skip) / Exit. The "✗ Exit" item lets the user quit the installer
  # mid-run from any step (ui_menu renders ✗-prefixed items without a number).
  ui_menu "${label}?" choice "$L_YES" "$L_NO_SKIP" "$L_MENU_EXIT"
  echo
  case "$choice" in
    0) "$func"; sleep "$UI_SKIP_PAUSE" ;;
    2) ui_abort 0 ;;
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

  # Cancelled delete: one line, no 🎉, no banner.
  if [ "$action" = "delete-cancelled" ]; then
    printf '%s✔%s %s\n' "${UI_GREEN_BOLD}" "${UI_RESET}" "$L_DELETE_CANCELLED"
    return 0
  fi

  local headline=""
  case "$action" in
    update)      headline="$L_DONE_UPDATE" ;;
    hud-config)  headline="$L_DONE_HUDCFG" ;;
    delete)      headline="$L_DONE_DELETE" ;;
    install|*)   headline="$L_DONE_INSTALL" ;;
  esac

  ui_clear_screen
  printf '%s✔%s %s%s%s 🎉\n' \
    "${UI_GREEN_BOLD}" "${UI_RESET}" "${UI_GREEN_BOLD}" "$headline" "${UI_RESET}"

  # Action-specific follow-up note
  case "$action" in
    update)
      printf "  ${UI_YELLOW_BOLD}↻${UI_RESET} %s\n\n" "$L_DONE_RESTART_CC"
      ;;
    delete)
      # Shell rc blocks were removed — advise reloading the shell, then how to
      # set things up again.
      printf "  ${UI_YELLOW_BOLD}↻${UI_RESET} %s\n" "$L_DONE_DELETE_HINT"
      lang_done_source_zshrc
      ;;
    install|*)
      if [ "${ZSHRC_MODIFIED:-}" = "true" ]; then
        lang_done_source_zshrc
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
