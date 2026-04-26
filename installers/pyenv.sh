#!/bin/bash
# installers/pyenv.sh — pyenv + pyenv-virtualenv
# source'd by install.sh

install_pyenv() {
  log_start "brew install pyenv…"

  if ! command -v brew &>/dev/null; then
    log_fail "Homebrew not found. Please install convenience tools first."
    return 1
  fi
  brew install pyenv pyenv-virtualenv

  local ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"
  local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

  rc_upsert_block "$ZPROFILE" "pyenv-path" 'if [[ ":$PATH:" != *":$HOME/.pyenv/bin:"* ]]; then
  export PATH="$HOME/.pyenv/bin:$PATH"
  export PATH="$PYENV_ROOT/bin:$PATH"
fi'

  rc_upsert_block "$ZSHRC" "pyenv-init" 'if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --no-rehash -)"
  if command -v pyenv-virtualenv-init 1>/dev/null 2>&1; then
    eval "$(pyenv virtualenv-init -)"
  fi
fi'
  export ZSHRC_MODIFIED=true

  log_done "pyenv installed."
}
