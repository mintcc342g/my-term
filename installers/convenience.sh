#!/bin/bash
# installers/convenience.sh — CLI tools, macOS apps, DevOps tools
# source'd by install.sh

install_convenience() {
  # Homebrew + jq are installed by install_required (installers/required.sh).
  # This step assumes brew is already on PATH; updates brew before installing.
  log_start "brew update…"
  brew update

  log_start "brew install CLI tools…"
  brew install ripgrep fd bat television tree tmux telnet

  log_start "brew install macOS apps…"
  brew install maccy rectangle
  brew install --cask macs-fan-control
  brew install --cask alt-tab

  log_start "brew install DevOps tools…"
  brew install awscli
  brew install helm argocd istioctl k9s

  log_start "brew install package managers…"
  brew install oven-sh/bun/bun

  # television shell integration
  local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
  rc_upsert_block "$ZSHRC" "television" 'eval "$(tv init zsh)"'
  export ZSHRC_MODIFIED=true

  log_done "convenience tools installed."
}
