#!/bin/bash
# installers/shell-theme.sh — newro zsh theme
# source'd by install.sh

install_shell_theme() {
  log_start "install newro theme…"

  ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

  # Clone to temp dir, extract theme, cleanup
  local tmp_dir
  tmp_dir=$(mktemp -d)
  log_step "clone newro theme to temp dir…"
  git clone --depth 1 https://gitlab.com/newrovp/develconfig.git "$tmp_dir/newrovp"

  # Install to oh-my-zsh
  cp "$tmp_dir/newrovp/newro_vcs.zsh-theme" "${HOME}/.oh-my-zsh/themes/newro_vcs.zsh-theme"

  # Backup original theme to project root
  cp "$tmp_dir/newrovp/newro_vcs.zsh-theme" "$SCRIPT_DIR/newro_vcs.zsh-theme"
  log_step "theme backed up to $SCRIPT_DIR/newro_vcs.zsh-theme"

  # Cleanup temp
  rm -rf "$tmp_dir"

  if grep -q 'robbyrussell' "$ZSHRC" 2>/dev/null; then
    sed -i'' -E 's/robbyrussell/newro_vcs/g' "$ZSHRC"
  fi

  log_done "newro theme installed."
}
