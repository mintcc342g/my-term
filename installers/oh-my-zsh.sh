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
  if ! grep -q 'zsh-syntax-highlighting.zsh' "$ZSHRC" 2>/dev/null; then
    printf '\n# zsh-syntax-highlighting 설정\nsource %s/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n' "$brew_prefix" >> "${ZSHRC}"
    export ZSHRC_MODIFIED=true
  fi
  if ! grep -q 'zsh-autosuggestions.zsh' "$ZSHRC" 2>/dev/null; then
    printf '\n# zsh-autosuggestions 설정\nsource %s/share/zsh-autosuggestions/zsh-autosuggestions.zsh\n' "$brew_prefix" >> "${ZSHRC}"
    export ZSHRC_MODIFIED=true
  fi
  log_done "oh-my-zsh + plugins installed."
}
