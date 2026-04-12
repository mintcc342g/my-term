#!/bin/bash
# installers/convenience.sh — CLI tools, macOS apps, DevOps tools
# source'd by install.sh

install_convenience() {
  log_start "install Homebrew…"
  if ! command -v brew &>/dev/null; then
    log_step "Homebrew not found. Installing…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log_step "Homebrew found. Updating…"
    brew update
  fi

  BREW_PREFIX=$(brew --prefix)
  ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"
  if ! grep -q 'brew shellenv' "$ZPROFILE" 2>/dev/null; then
    printf '\n# Homebrew 설정\neval "$(%s/bin/brew shellenv)"\n' "$BREW_PREFIX" >> "${ZPROFILE}"
  fi
  eval "$($BREW_PREFIX/bin/brew shellenv)"

  log_start "install CLI tools…"
  brew install ripgrep fd bat television tree tmux telnet
  if ! command -v jq &>/dev/null; then
    brew install jq
  fi

  log_start "install macOS apps…"
  brew install maccy rectangle
  brew install --cask macs-fan-control
  brew install --cask alt-tab

  log_start "install DevOps tools…"
  brew install awscli
  brew install helm argocd istioctl k9s

  log_start "install package managers…"
  brew install oven-sh/bun/bun

  # television shell integration
  ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
  if ! grep -q 'tv init' "$ZSHRC" 2>/dev/null; then
    printf '\n# television 설정\neval "$(tv init zsh)"\n' >> "${ZSHRC}"
  fi

  log_done "convenience tools installed."
}
