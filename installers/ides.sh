#!/bin/bash
# installers/ides.sh — IDE installers (Antigravity, LazyVim)
# source'd by install.sh

_install_lazyvim() (
  local app_name="${NVIM_APPNAME:-nvim}"
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/$app_name"
  local -a existing_paths=(
    "$config_dir"
    "${XDG_DATA_HOME:-$HOME/.local/share}/$app_name"
    "${XDG_STATE_HOME:-$HOME/.local/state}/$app_name"
    "${XDG_CACHE_HOME:-$HOME/.cache}/$app_name"
  )
  log_step "Installing LazyVim…"
  if ! brew install --formula neovim tree-sitter-cli ripgrep fd lazygit node; then
    log_fail "LazyVim dependencies could not be installed."
    return 1
  fi

  local staging_dir
  if ! mkdir -p "${config_dir%/*}" ||
     ! staging_dir="$(mktemp -d "${config_dir%/*}/.lazyvim.XXXXXXXX")"; then
    log_fail "Could not prepare a staging directory for $config_dir"
    return 1
  fi
  trap 'rm -rf -- "$staging_dir"' EXIT
  local starter_dir="$staging_dir/starter"
  if ! git clone --depth 1 https://github.com/LazyVim/starter.git "$starter_dir" ||
     ! rm -rf -- "$starter_dir/.git"; then
    log_fail "Could not prepare the LazyVim starter."
    return 1
  fi

  local timestamp path backup index failed=0
  local -a moved_paths=() backups=()
  timestamp="$(date +%Y%m%d-%H%M%S)" || return 1
  for path in "${existing_paths[@]}"; do
    [[ -e "$path" || -L "$path" ]] || continue
    backup="$path.bak.$timestamp.${staging_dir##*.}"
    if [[ -e "$backup" || -L "$backup" ]] ||
       ! mv -n -- "$path" "$backup" || [[ -e "$path" || -L "$path" ]]; then
      log_fail "Could not back up $path"
      failed=1
      break
    fi
    moved_paths+=("$path")
    backups+=("$backup")
    log_step "Backed up $path to $backup"
  done

  if [ "$failed" -eq 0 ] &&
     [[ ! -e "$config_dir" && ! -L "$config_dir" ]] &&
     mv -n -- "$starter_dir" "$config_dir" &&
     [ ! -d "$starter_dir" ]; then
    log_done "LazyVim installed. Run nvim to start."
    return 0
  fi

  log_fail "Could not install the LazyVim starter at $config_dir"
  for ((index=${#backups[@]}-1; index>=0; index--)); do
    path="${moved_paths[$index]}"
    backup="${backups[$index]}"
    if [[ -e "$path" || -L "$path" ]] ||
       ! mv -n -- "$backup" "$path" || [[ -e "$backup" || -L "$backup" ]]; then
      log_fail "Could not restore $path. Backup remains at $backup"
    fi
  done
  return 1
)

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
