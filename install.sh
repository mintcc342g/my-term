
#!/bin/bash
cd $HOME

if [ "$(uname -s)" = "Linux" ]; then
    OS="Linux"
    echo "\033[31;1mNOT SUPPORT OS\033[0m…"
    exit 0
else
    OS=""
fi
# oh-my-zsh 설치
echo "\033[33;1m→\033[0m install oh-my-zsh…"
RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# homebrew 설치 또는 업뎃
echo "\033[33;1m→\033[0m install brew…"
if ! command -v brew &>/dev/null; then
  echo "\033[33;1mHomebrew not found. Installing…\033[0m"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "\033[33;1mHomebrew found. Updating…\033[0m"
  brew update
fi
brew_prefix=$(brew --prefix)
echo "eval \"\$($brew_prefix/bin/brew shellenv)\"" >> ./.zprofile
eval "$($brew_prefix/bin/brew shellenv)"

# brew로 유틸 설치
echo "\033[33;1m→\033[0m install useful features with Homebrew…"
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting
brew install ripgrep
brew install tree
brew install maccy
brew install rectangle
brew install television

# 환경변수 셋팅
echo "\033[33;1m→\033[0m add shell startup settings…"
echo "\n# Homebrew 설정\neval \"\$($brew_prefix/bin/brew shellenv)\"" >> ./.zshrc
echo "\n# zsh-syntax-highlighting 설정\nsource $brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ./.zshrc
echo "\n# zsh-autosuggestions 설정\nsource $brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ./.zshrc
echo "\n# television 설정\neval \"\$(tv init zsh)\"" >> ./.zshrc
echo "\n# vscode 설정\ncode () { VSCODE_CWD=\"\$PWD\" open -n -b \"com.microsoft.VSCode\" --args \$* ;}" >> ./.zshrc

# 쉘 테마 설정
echo "\033[33;1m→\033[0m install newro theme…"
git clone https://gitlab.com/newrovp/develconfig.git ./Documents/newrovp
cp ./Documents/newrovp/newro_vcs.zsh-theme ./.oh-my-zsh/themes/newro_vcs.zsh-theme
sed -i -E 's/robbyrussell/newro_vcs/g' ./.zshrc

# TODO: for linux
# if [ "$OS" != "" ]; then
#     echo "\033[33;1m→\033[0m install nord colors…"
#     git clone https://github.com/nordtheme/dircolors.git ./custom_colors/nord_color
#     ln -srfv "./custom_colors/nord_color/src/dir_colors" ./.dir_colors
#     echo -e "\n# nord color 설정\neval \"\$(dircolors ./.dir_colors)\"" >> ./.zshrc
# fi
