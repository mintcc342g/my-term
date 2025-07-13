
#!/bin/bash
cd $HOME

if [ "$(uname -s)" = "Linux" ]; then
    OS="Linux"
    echo "\033[31;1mNOT SUPPORT OS\033[0m…"
    exit 0
else
    OS="Darwin"
fi

# oh-my-zsh 설치
echo "\033[34;1m===>\033[0m install oh-my-zsh…"
RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# homebrew 설치 또는 업뎃
echo "\033[34;1m===>\033[0m install brew…"
if ! command -v brew &>/dev/null; then
  echo "\033[33;1mHomebrew not found. Installing…\033[0m"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "\033[32;1mHomebrew found. Updating…\033[0m"
  brew update
fi

brew_prefix=$(brew --prefix)
echo "eval \"\$($brew_prefix/bin/brew shellenv)\"" >> ${HOME}/.zprofile
eval "$($brew_prefix/bin/brew shellenv)"

# brew로 유틸 설치
echo "\033[34;1m===>\033[0m install useful features with Homebrew…"
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting
brew install ripgrep
brew install tree
brew install maccy
brew install rectangle
brew install --cask macs-fan-control
brew install --cask alt-tab
brew install television
brew install awscli
brew install asdf
brew install k9s

# PATH 셋팅
zshrc_dir="${ZDOTDIR:-$HOME}/.zshrc"
asdf_block='if [[ ":$PATH:" != *":$HOME/.asdf/shims:"* ]]; then
  export PATH="$HOME/.asdf/shims:$PATH"
fi'
if ! grep -q 'asdf/shims' "$zshrc_dir"; then
  printf "\n# asdf shims PATH 설정\n%s\n" "$asdf_block" >> "$zshrc_dir"
fi


# .zshrc 셋팅
echo "\033[34;1m===>\033[0m add shell startup settings…"
echo "\n# Homebrew 설정\neval \"\$($brew_prefix/bin/brew shellenv)\"" >> ${ZDOTDIR:-$HOME}/.zshrc
echo "\n# zsh-syntax-highlighting 설정\nsource $brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
echo "\n# zsh-autosuggestions 설정\nsource $brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
echo "\n# television 설정\neval \"\$(tv init zsh)\"" >> ${ZDOTDIR:-$HOME}/.zshrc
echo "\n# vscode 설정\ncode () { VSCODE_CWD=\"\$PWD\" open -n -b \"com.microsoft.VSCode\" --args \$* ;}" >> ${ZDOTDIR:-$HOME}/.zshrc
echo "\n# asdf 함수 설정, type asdf\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ${ZDOTDIR:-$HOME}/.zshrc


# 쉘 테마 설정
echo "\033[34;1m===>\033[0m install newro theme…"
doc_dir="$HOME/Documents"
if [ ! -d "$doc_dir" ]; then
  mkdir -p "$doc_dir"
fi
echo "clone newro theme to $doc_dir"
git clone https://gitlab.com/newrovp/develconfig.git "$doc_dir/newrovp"
cp "$doc_dir/newrovp/newro_vcs.zsh-theme" "${HOME}/.oh-my-zsh/themes/newro_vcs.zsh-theme"
sed -i -E 's/robbyrussell/newro_vcs/g' "$zshrc_path"

# TODO: for linux
# if [ "$OS" != "" ]; then
#     echo "\033[34;1m===>\033[0m install nord colors…"
#     git clone https://github.com/nordtheme/dircolors.git ./custom_colors/nord_color
#     ln -srfv "./custom_colors/nord_color/src/dir_colors" ./.dir_colors
#     echo -e "\n# nord color 설정\neval \"\$(dircolors ./.dir_colors)\"" >> ./.zshrc
# fi

# asdf - Golang 설정
echo "\033[34;1m===>\033[0m 프로그래밍 언어 설정 작업을 시작합니다."
read -p "asdf의 golang 설정을 진행하시겠습니까? (y/N) " answer
case "$answer" in
  [yY])
    # asdf plugin add golang https://github.com/kennyp/asdf-golang.git
    echo "\n# asdf golang 환경 설정\n. ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh" >> "${ZDOTDIR:-$HOME}/.zshrc"
    echo "\033[32;1m===>\033[0m asdf의 golang 설정이 .zshrc에 추가되었습니다"
    ;;
  *)
    echo "\033[31;1m===>\033[0m asdf의 golang 설정을 진행하지 않습니다."
    ;;
esac

echo "\033[32;1m===>\033[0m 모든 설치가 완료되었습니다. 'source \${HOME}/.zshrc' 를 실행시키거나 쉘을 재시작 해주세요."
echo "==========> It's MyGO\!\!\!\!\!"