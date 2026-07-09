#!/bin/bash
# installers/ides.sh — IDE installers (Antigravity, ...)
# source'd by install.sh

install_ides() {
  local next_step="${1:-}"   # label of the step that follows, shown on the "move on" option
  log_start "IDE setup…"

  if ! command -v brew &>/dev/null; then
    log_fail "$L_ERR_NO_BREW"
    return 1
  fi

  local touched=0
  while true; do
    local choice=""
    local menu_items=()
    local menu_actions=()

    menu_items+=("Antigravity"); menu_actions+=("antigravity")
    # Add more IDEs here (VSCode, GoLand, …) as needed.
    menu_items+=("$L_NO_SKIP");   menu_actions+=("skip")
    menu_items+=("$L_MENU_EXIT"); menu_actions+=("quit")

    ui_menu "$L_IDE_MENU_TITLE" choice "${menu_items[@]}"

    [ "$choice" = "255" ] && break
    local action="${menu_actions[$choice]:-skip}"

    case "$action" in
      # `|| true`: IDE setup is optional, and its non-fatal failures (e.g. the
      # "launch the IDE once, then re-run" advisory before its bin dir exists)
      # return nonzero, which would otherwise abort the installer under `set -e`.
      antigravity) touched=1; _install_antigravity || true ;;
      skip)        break ;;
      quit)        ui_abort 0 ;;
    esac

    # Only install actions reach here (skip/quit already left the loop). Ask
    # whether to add another IDE or move on — naming the next step so the user
    # knows where "continue" leads instead of landing back on this menu.
    local cont=""
    ui_menu "$L_IDE_MORE_TITLE" cont \
      "$L_IDE_ANOTHER" \
      "$(tf L_IDE_PROCEED_FMT "$next_step")"
    [ "$cont" = "0" ] || break   # 0=another IDE → loop; anything else → move on
  done

  # install_ides is called directly (no ui_confirm_run wrapper), so leave
  # the same kind of skip breadcrumb other installers do. Must be an `if`, not
  # `[ … ] && …`: with touched=1 the test is false, and as the function's last
  # command that nonzero status would abort the installer under `set -e`.
  if [ "$touched" = 0 ]; then ui_log_skipped "IDE setup"; fi
}

_install_antigravity() {
  log_step "brew install --cask antigravity-ide…"
  if brew list --cask antigravity-ide &>/dev/null; then
    log_done "antigravity-ide already installed."
  else
    brew install --cask antigravity-ide || { log_fail "antigravity-ide install failed"; return 1; }
    log_done "antigravity-ide installed."
  fi

  _setup_antigravity_command
}

# Create a short-name symlink (not a shell alias) so `which <name>` resolves
# and the command works in any shell / non-interactive context.
_setup_antigravity_command() {
  local app="/Applications/Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide"
  local bin_dir="$HOME/.antigravity-ide/antigravity-ide/bin"

  if [ ! -x "$app" ]; then
    log_fail "Antigravity launcher not found at: $app"
    return 1
  fi

  # Locate the IDE-managed bin dir. The IDE creates this on first launch and
  # registers it in PATH via ~/.zshrc, so the symlink only works if it lives
  # *inside* that dir. If the default path is missing, search for it; never
  # synthesize a directory ourselves (would land outside PATH).
  if [ ! -d "$bin_dir" ]; then
    # Search only the IDE's own dir, never all of $HOME: a home-wide find walks
    # into TCC-protected folders (Desktop/Documents/…) and fires a macOS consent
    # popup for each one. `|| true` keeps a nonzero find (missing root, or SIGPIPE
    # from head closing early) from aborting the installer under `set -e`; the
    # empty-result case is handled just below.
    local found
    found="$(find "$HOME/.antigravity-ide" -maxdepth 2 -type d -path "*antigravity-ide*/bin" 2>/dev/null | head -n 1 || true)"
    if [ -n "$found" ]; then
      bin_dir="$found"
      log_step "Found Antigravity bin dir at: $bin_dir"
    else
      log_fail "$L_IDE_BINDIR_NOTFOUND"
      return 1
    fi
  fi

  ui_clear_screen
  echo -e "${UI_BLUE_BOLD} ${L_IDE_CMD_HEADER}${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────────" > /dev/tty
  echo -e " ${UI_DIM}${L_IDE_CMD_PROMPT}${UI_RESET}\n" > /dev/tty
  echo -ne " ${UI_YELLOW_BOLD}${L_PROMPT_NAME}${UI_RESET}" > /dev/tty
  local cmd_name
  read -r cmd_name < /dev/tty
  [ -z "$cmd_name" ] && cmd_name="agy"

  # Sanitize: allow letters, digits, underscore, hyphen; must start with a letter/_.
  if [[ ! "$cmd_name" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
    log_fail "$L_IDE_INVALID_NAME"
    cmd_name="agy"
  fi

  local link="$bin_dir/$cmd_name"

  if [ -L "$link" ] && [ "$(readlink "$link")" = "$app" ]; then
    log_done "'$cmd_name' already linked."
    return 0
  fi

  ln -sfn "$app" "$link"
  log_done "'$cmd_name' command registered → $link"
}
