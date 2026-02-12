
#!/bin/bash
YELLOW='\033[93m'
YELLOW_BOLD='\033[33;1m'
BLUE='\033[94m'
BLUE_BOLD='\033[34;1m'
RED_BOLD='\033[31;1m'
PINK='\033[38;5;205m'
PURPLE='\033[35m'
GREEN='\033[92m'
GREEN_BOLD='\033[32;1m'
RESET='\033[0m'

log_start() {
  echo "${BLUE_BOLD}➜${RESET} $*"
}

log_step() {
  echo "${YELLOW_BOLD}⚙${RESET} $*"
}

log_fail() {
  echo "${RED_BOLD}✖${RESET} $*"
}

log_done() {
  echo "${GREEN_BOLD}✔${RESET} $*"
}


### 셋업 시작
cd $HOME

if [ "$(uname -s)" = "Linux" ]; then
    OS="Linux"
    echo "${RED_BOLD}NOT SUPPORT OS${RESET}…\n"
    exit 0
else
    OS="Darwin"
fi



### oh-my-zsh 설치
log_start "install oh-my-zsh…\n"
RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"



### homebrew 설치 또는 업뎃
log_start "install brew…\n"
if ! command -v brew &>/dev/null; then
  log_step "Homebrew not found. Installing…\n"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log_step "Homebrew found. Updating…\n"
  brew update
fi

BREW_PREFIX=$(brew --prefix)
echo "# Homebrew 설정\neval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> ${ZPROFILE}
eval "$($BREW_PREFIX/bin/brew shellenv)"



### brew로 유틸 설치
log_start "install useful features with Homebrew…\n"
brew install zsh-autosuggestions zsh-syntax-highlighting
brew install ripgrep fd bat television tree
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
brew install opencode
brew install oven-sh/bun/bun
bunx oh-my-opencode install


### claude statusline 스크립트 이동
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.claude"
cp -f "$SCRIPT_DIR/claude-statusline.sh" "$HOME/.claude/statusline-command.sh"
chmod +x "$HOME/.claude/statusline-command.sh"



### PATH 셋팅
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
echo "\n# zsh-syntax-highlighting 설정\nsource \$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZSHRC}
echo "\n# zsh-autosuggestions 설정\nsource \$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ${ZSHRC}
echo "\n# television 설정\neval \"\$(tv init zsh)\"" >> ${ZSHRC}
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



### 쉘 테마 설정
log_start "install newro theme…\n"
DOC_DIR="$HOME/Documents"
if [ ! -d "$DOC_DIR" ]; then
  mkdir -p "$DOC_DIR"
fi

log_step "clone newro theme to $DOC_DIR\n"
git clone https://gitlab.com/newrovp/develconfig.git "$DOC_DIR/newrovp"
cp "$DOC_DIR/newrovp/newro_vcs.zsh-theme" "${HOME}/.oh-my-zsh/themes/newro_vcs.zsh-theme"
sed -i -E 's/robbyrussell/newro_vcs/g' "$ZSHRC"



### asdf 설정
log_start "Starting programming language setup…\n"

ask_asdf_config() {
  local lang="$1"
  local __varname="$2"
  local answer

  read -r -p "Would you like to configure ${lang} with asdf? (y/N) " answer
  printf -v "$__varname" '%s' "$answer"
}

print_env_uncomment_warning() {
  local lang="$1"

  echo
  log_done "${lang} configuration for asdf has been added to .zprofile."
  echo
  echo "${YELLOW_BOLD}[WARNING]${RESET} ${RED_BOLD}After installing ${lang}${RESET}, please ${RED_BOLD}uncomment${RESET} the ${lang} environment configuration in your ${RED_BOLD}.zprofile.${RESET}"
  echo
}

# Golang 설정
ask_asdf_config "Golang" yn
case "$yn" in
  [yY])
    asdf plugin add golang https://github.com/kennyp/asdf-golang.git
    echo "\n# asdf Golang 환경 설정\n#. \${ASDF_DATA_DIR:-\$HOME/.asdf}/plugins/golang/set-env.zsh" >> ${ZPROFILE}
    print_env_uncomment_warning "Golang"
    ;;
  *)
    log_fail "Skipping Golang configuration for asdf.\n"
    ;;
esac

# Java 설정
ask_asdf_config "Java" yn
case "$yn" in
  [yY])
    asdf plugin add java https://github.com/halcyon/asdf-java.git
    echo "\n# asdf Java 환경 설정\n#. \${ASDF_DATA_DIR:-\$HOME/.asdf}/plugins/java/set-java-home.zsh" >> ${ZPROFILE}
    print_env_uncomment_warning "Java"
    ;;
  *)
    log_fail "Skipping Java configuration for asdf.\n"
    ;;
esac



### done
log_done "${GREEN_BOLD}All installations are complete!${RESET} 🎉"
echo "  Please run ${YELLOW_BOLD}'source \${HOME}/.zshrc'${RESET} or ${YELLOW_BOLD}restart${RESET} your shell.\n\n"

cat << EOF
::::::::::: ::::::::::: ::: ::::::::       ::::    ::::  :::   :::  ::::::::   ::::::::  $(printf ${YELLOW}):::$(printf ${BLUE}) :::$(printf ${PINK}) :::$(printf ${PURPLE}) :::$(printf ${GREEN}) :::$(printf ${RESET}) 
    :+:         :+:     :+ :+:    :+:      +:+:+: :+:+:+ :+:   :+: :+:    :+: :+:    :+: $(printf ${YELLOW}):+:$(printf ${BLUE}) :+:$(printf ${PINK}) :+:$(printf ${PURPLE}) :+:$(printf ${GREEN}) :+:$(printf ${RESET}) 
    +:+         +:+        +:+             +:+ +:+:+ +:+  +:+ +:+  +:+        +:+    +:+ $(printf ${YELLOW})+:+$(printf ${BLUE}) +:+$(printf ${PINK}) +:+$(printf ${PURPLE}) +:+$(printf ${GREEN}) +:+$(printf ${RESET}) 
    +#+         +#+        +#++:++#++      +#+  +:+  +#+   +#++:   :#:        +#+    +:+ $(printf ${YELLOW})+#+$(printf ${BLUE}) +#+$(printf ${PINK}) +#+$(printf ${PURPLE}) +#+$(printf ${GREEN}) +#+$(printf ${RESET}) 
    +#+         +#+               +#+      +#+       +#+    +#+    +#+   +#+# +#+    +#+ $(printf ${YELLOW})+#+$(printf ${BLUE}) +#+$(printf ${PINK}) +#+$(printf ${PURPLE}) +#+$(printf ${GREEN}) +#+$(printf ${RESET}) 
    #+#         #+#        #+#    #+#      #+#       #+#    #+#    #+#    #+# #+#    #+#                     
###########     ###         ########       ###       ###    ###     ########   ########  $(printf ${YELLOW})###$(printf ${BLUE}) ###$(printf ${PINK}) ###$(printf ${PURPLE}) ###$(printf ${GREEN}) ###$(printf ${RESET}) 
EOF
echo "\n"
