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
  if ! grep -q 'tv init' "$ZSHRC" 2>/dev/null; then
    printf '\n# television 설정\neval "$(tv init zsh)"\n' >> "${ZSHRC}"
    export ZSHRC_MODIFIED=true
  fi

  log_done "convenience tools installed."
}
