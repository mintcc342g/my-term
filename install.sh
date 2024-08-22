
#!/bin/bash
cd $HOME

if [ "$(uname -s)" = "Linux" ]; then
    OS="Linux"
    mkdir "Documents"
else
    OS=""
fi

echo "\033[33;1m→\033[0m install oh-my-zsh…"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "\033[33;1m→\033[0m install brew…"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ./.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "\033[33;1m→\033[0m install useful features with Homebrew…"
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting
brew install ripgrep
brew install tree
brew install maccy
brew install rectangle

echo "\033[33;1m→\033[0m add shell startup settings…"
echo -e "\n# Homebrew 설정\neval \"\$(/opt/homebrew/bin/brew shellenv)\"" >> ./.zshrc
echo -e "\n# zsh-syntax-highlighting 설정\nsource /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ./.zshrc
echo -e "\n# zsh-autosuggestions 설정\nsource $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ./.zshrc

echo "\033[33;1m→\033[0m install newro theme…"
git clone https://gitlab.com/newrovp/develconfig.git ./Documents/newrovp
cp ./Documents/newrovp/newro_vcs.zsh-theme ./.oh-my-zsh/themes/newro_vcs.zsh-theme
sed -i -E 's/robbyrussell/newro_vcs/g' ./.zshrc

if [ "$OS" != "" ]; then
    echo "\033[33;1m→\033[0m install nord colors…"
    git clone https://github.com/nordtheme/dircolors.git ./custom_colors/nord_color
    ln -srfv "./custom_colors/nord_color/src/dir_colors" ./.dir_colors
    echo -e "\n# nord color 설정\neval \"\$(dircolors ./.dir_colors)\"" >> ./.zshrc
fi
