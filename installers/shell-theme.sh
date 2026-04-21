#!/bin/bash
# installers/shell-theme.sh — newro zsh theme
# source'd by install.sh

install_shell_theme() {
  log_start "install newro theme…"

  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    log_fail "oh-my-zsh not found. Please install oh-my-zsh first."
    return 1
  fi

  local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

  # Clone to temp dir, extract theme, cleanup
  local tmp_dir
  tmp_dir=$(mktemp -d)
  log_step "clone newro theme (pinned commit)…"
  git clone -q https://gitlab.com/newrovp/develconfig.git "$tmp_dir/newrovp"
  if ! git -C "$tmp_dir/newrovp" checkout dcfac8cef1cc18058adf1233da6d6d4dfa8449e4 -q; then
    log_fail "newro theme commit verification failed."
    rm -rf "$tmp_dir"
    return 1
  fi

  # Install to oh-my-zsh
  cp "$tmp_dir/newrovp/newro_vcs.zsh-theme" "${HOME}/.oh-my-zsh/themes/newro_vcs.zsh-theme"

  # Backup original theme to project root
  cp "$tmp_dir/newrovp/newro_vcs.zsh-theme" "$SCRIPT_DIR/newro_vcs.zsh-theme"
  log_step "theme backed up to $SCRIPT_DIR/newro_vcs.zsh-theme"

  rm -rf "$tmp_dir"

  if grep -q 'robbyrussell' "$ZSHRC" 2>/dev/null; then
    sed -i'' -E 's/robbyrussell/newro_vcs/g' "$ZSHRC"
  fi

  log_done "newro theme installed."
}
