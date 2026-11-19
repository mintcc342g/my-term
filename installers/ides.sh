#!/bin/bash
# installers/ides.sh — IDE installers (Antigravity, LazyVim)
# source'd by install.sh

_install_lazyvim() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  log_step "Installing LazyVim…"
  if ! brew install --formula neovim tree-sitter-cli ripgrep fd lazygit node; then
    log_fail "LazyVim dependencies could not be installed."
    return 1
  fi

  if [ -e "$config_dir" ] || [ -L "$config_dir" ]; then
    log_step "Neovim config already exists at $config_dir. Skipping the LazyVim starter."
    return 0
  fi

  if ! mkdir -p "${config_dir%/*}" ||
     ! git clone --depth 1 https://github.com/LazyVim/starter.git "$config_dir"; then
    log_fail "LazyVim starter could not be installed at $config_dir"
    return 1
  fi
  # Detach the freshly cloned starter so it can be customized independently.
  if ! rm -rf -- "$config_dir/.git"; then
    log_fail "Could not remove the LazyVim starter's Git metadata at $config_dir"
    return 1
  fi

  log_done "LazyVim installed. Run nvim to start."
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
