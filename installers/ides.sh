#!/bin/bash
# installers/ides.sh — IDE installers (Antigravity, ...)
# source'd by install.sh

install_ides() {
  log_start "IDE setup…"

  if ! command -v brew &>/dev/null; then
    log_fail "Homebrew not found. Please install convenience tools first."
    return 1
  fi

  while true; do
    local choice=""
    local menu_items=()
    local menu_actions=()

    menu_items+=("Antigravity"); menu_actions+=("antigravity")
    # Add more IDEs here (VSCode, GoLand, …) as needed.
    menu_items+=("No (Skip)");   menu_actions+=("exit")

    ui_menu "IDE — select to install" choice "${menu_items[@]}"

    [ "$choice" = "255" ] && break
    local action="${menu_actions[$choice]:-exit}"

    case "$action" in
      antigravity) _install_antigravity ;;
      exit)        break ;;
    esac
  done
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
    local found
    found="$(find "$HOME" -maxdepth 4 -type d -path "*antigravity-ide*/bin" 2>/dev/null | head -n 1)"
    if [ -n "$found" ]; then
      bin_dir="$found"
      log_step "Found Antigravity bin dir at: $bin_dir"
    else
      log_fail "Antigravity bin dir not found. Launch the IDE once, then re-run this step."
      return 1
    fi
  fi

  ui_clear_screen
  echo -e "${UI_BLUE_BOLD} Antigravity command setup${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────────" > /dev/tty
  echo -e " ${UI_DIM}Enter short command name for antigravity (default: agy)${UI_RESET}\n" > /dev/tty
  echo -ne " ${UI_YELLOW_BOLD}name: ${UI_RESET}" > /dev/tty
  local cmd_name
  read -r cmd_name < /dev/tty
  [ -z "$cmd_name" ] && cmd_name="agy"

  # Sanitize: allow letters, digits, underscore, hyphen; must start with a letter/_.
  if [[ ! "$cmd_name" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
    log_fail "Invalid name. Using default: agy"
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
