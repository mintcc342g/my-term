#!/bin/bash
# installers/shell-theme.sh — newro zsh theme
# source'd by install.sh

install_shell_theme() {
  log_start "install newro theme…"

  ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
  DOC_DIR="$HOME/Documents/my"

  if [ ! -d "$DOC_DIR" ]; then
    mkdir -p "$DOC_DIR"
  fi

  if [ ! -d "$DOC_DIR/newrovp" ]; then
    log_step "clone newro theme to $DOC_DIR"
    git clone https://gitlab.com/newrovp/develconfig.git "$DOC_DIR/newrovp"
  else
    log_step "newro theme already cloned."
  fi

  cp "$DOC_DIR/newrovp/newro_vcs.zsh-theme" "${HOME}/.oh-my-zsh/themes/newro_vcs.zsh-theme"

  if grep -q 'robbyrussell' "$ZSHRC" 2>/dev/null; then
    sed -i'' -E 's/robbyrussell/newro_vcs/g' "$ZSHRC"
  fi

  log_done "newro theme installed."
}
