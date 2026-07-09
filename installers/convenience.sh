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
  # --adopt: if the .app is already in /Applications but not brew-managed (e.g.
  # a manual install, or a leftover from an earlier uninstall), take it over
  # instead of erroring with "It seems there is already an App at …", which would
  # abort the installer under `set -e`. The `brew list` guard still skips casks
  # brew already tracks, so a normal re-run won't re-open/upgrade them.
  brew list --cask maccy &>/dev/null || brew install --cask --adopt maccy
  brew list --cask rectangle &>/dev/null || brew install --cask --adopt rectangle
  brew list --cask macs-fan-control &>/dev/null || brew install --cask --adopt macs-fan-control
  brew list --cask alt-tab &>/dev/null || brew install --cask --adopt alt-tab

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
