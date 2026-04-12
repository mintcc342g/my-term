#!/bin/bash
# installers/pyenv.sh — pyenv + pyenv-virtualenv
# source'd by install.sh

install_pyenv() {
  log_start "install pyenv…"

  if ! command -v brew &>/dev/null; then
    log_fail "Homebrew not found. Please install convenience tools first."
    return 1
  fi
  brew install pyenv pyenv-virtualenv

  ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"
  ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

  if ! grep -q 'pyenv/bin' "$ZPROFILE" 2>/dev/null; then
    PYENV_BLOCK='if [[ ":$PATH:" != *":$HOME/.pyenv/bin:"* ]]; then
  export PATH="$HOME/.pyenv/bin:$PATH"
  export PATH="$PYENV_ROOT/bin:$PATH"
fi'
    printf "\n# pyenv PATH 설정\n%s\n" "$PYENV_BLOCK" >> "$ZPROFILE"
  fi

  if ! grep -q 'pyenv 설정' "$ZSHRC" 2>/dev/null; then
    cat <<'EOF' >> "$ZSHRC"

# pyenv 설정
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
  if command -v pyenv-virtualenv-init 1>/dev/null 2>&1; then
    eval "$(pyenv virtualenv-init -)"
  fi
fi

EOF
  fi

  log_done "pyenv installed."
}
