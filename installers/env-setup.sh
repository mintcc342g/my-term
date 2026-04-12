#!/bin/bash
# installers/env-setup.sh — oh-my-zsh, homebrew, brew packages, PATH, shell theme
# source'd by install.sh — uses shared log functions and variables

install_env_setup() {
  ### --- oh-my-zsh 설치 ---
  log_start "install oh-my-zsh…\n"
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
  ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"

  ### --- homebrew 설치 또는 업뎃 ---
  log_start "install brew…\n"
  if ! command -v brew &>/dev/null; then
    log_step "Homebrew not found. Installing…\n"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log_step "Homebrew found. Updating…\n"
    brew update
  fi

  BREW_PREFIX=$(brew --prefix)
  printf '\n# Homebrew 설정\neval "$(%s/bin/brew shellenv)"\n' "$BREW_PREFIX" >> "${ZPROFILE}"
  eval "$($BREW_PREFIX/bin/brew shellenv)"

  ### --- brew로 유틸 설치 ---
  log_start "install useful features with Homebrew…\n"
  brew install zsh-autosuggestions zsh-syntax-highlighting
  brew install ripgrep fd bat television tree tmux

  if ! command -v jq &>/dev/null; then
    brew install jq
  fi
  brew install telnet
  brew install maccy rectangle
  brew install --cask macs-fan-control
  brew install --cask alt-tab
  brew install awscli
  brew install asdf
  brew install mockery
  brew install pyenv pyenv-virtualenv
  brew install helm argocd istioctl k9s
  brew install --cask claude-code
  brew install opencode codex
  brew install oven-sh/bun/bun

  ### --- PATH 셋팅 ---
  # zprofile
  log_step "add shell login environment settings…\n"

  ASDF_BLOCK='if [[ ":$PATH:" != *":$HOME/.asdf/shims:"* ]]; then
  export PATH="$HOME/.asdf/shims:$PATH"
fi'
  if ! grep -q 'asdf/shims' "$ZPROFILE"; then
    printf "\n# asdf shims PATH 설정\n%s\n" "$ASDF_BLOCK" >> "$ZPROFILE"
  fi

  PYENV_BLOCK='if [[ ":$PATH:" != *":$HOME/.pyenv/bin:"* ]]; then
  export PATH="$HOME/.pyenv/bin:$PATH"
  export PATH="$PYENV_ROOT/bin:$PATH"
fi'
  if ! grep -q 'pyenv/bin' "$ZPROFILE"; then
    printf "\n# pyenv PATH 설정\n%s\n" "$PYENV_BLOCK" >> "$ZPROFILE"
  fi

  # zshrc
  log_step "add shell startup settings…\n"
  printf '\n# zsh-syntax-highlighting 설정\nsource $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n' >> "${ZSHRC}"
  printf '\n# zsh-autosuggestions 설정\nsource $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh\n' >> "${ZSHRC}"
  printf '\n# television 설정\neval "$(tv init zsh)"\n' >> "${ZSHRC}"
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

  # claude alias
  if ! grep -q "^alias c=" "$HOME/.zshrc" 2>/dev/null; then
    echo 'alias c="claude"' >> "$HOME/.zshrc"
  fi

  # vscode code 설정
  cat <<'FUNC_EOF' >> "$ZSHRC"

# vscode 설정
code () {
  VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args "$@"
}

FUNC_EOF

  ### --- 쉘 테마 설정 ---
  log_start "install newro theme…\n"
  DOC_DIR="$HOME/Documents/my"
  if [ ! -d "$DOC_DIR" ]; then
    mkdir -p "$DOC_DIR"
  fi

  log_step "clone newro theme to $DOC_DIR\n"
  git clone https://gitlab.com/newrovp/develconfig.git "$DOC_DIR/newrovp"
  cp "$DOC_DIR/newrovp/newro_vcs.zsh-theme" "${HOME}/.oh-my-zsh/themes/newro_vcs.zsh-theme"
  sed -i -E 's/robbyrussell/newro_vcs/g' "$ZSHRC"

  # Export for other installers
  export ZSHRC ZPROFILE
}
