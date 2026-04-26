#!/bin/bash
# installers/oh-my-zsh.sh — oh-my-zsh + zsh plugins + PATH
# source'd by install.sh

install_oh_my_zsh() {
  log_start "install oh-my-zsh…"
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

  log_start "brew install zsh plugins…"
  if ! command -v brew &>/dev/null; then
    log_fail "Homebrew not found. Please install convenience tools first."
    return 1
  fi
  brew install zsh-autosuggestions zsh-syntax-highlighting

  log_step "configure zsh plugins…"
  local brew_prefix
  brew_prefix=$(brew --prefix)
  rc_upsert_block "$ZSHRC" "zsh-syntax-highlighting" "source ${brew_prefix}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  rc_upsert_block "$ZSHRC" "zsh-autosuggestions" "source ${brew_prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  export ZSHRC_MODIFIED=true
  log_done "oh-my-zsh + plugins installed."
}
