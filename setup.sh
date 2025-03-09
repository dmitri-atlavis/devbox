#!/bin/bash

#
# install brew if necessary
#
if ! command -v brew 2>&1 >/dev/null; then
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        BREW_BIN_PATH="/home/linuxbrew/.linuxbrew/bin"
        sudo useradd -m -s /bin/bash linuxbrew
        sudo sh -c "printf 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers"
        # keep brew installs the last intentionally, so that the host/parent system defaults do not change
        sudo sh -c "printf '\nexport PATH=\${PATH}:${BREW_BIN_PATH}\n' >>/home/linuxbrew/.bashrc"
        sudo sh -c "printf '\nexport PATH=\${PATH}:${BREW_BIN_PATH}\n' >>${HOME}/.bashrc"
        export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH
        sudo -u linuxbrew -H NONINTERACTIVE=1 PATH=$PATH /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        sudo chown -R $(whoami) /home/linuxbrew/.linuxbrew
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        printf "Unsupported OS"
        exit 1
    fi
fi

#
# Install git
#
if ! command -v git 2>&1 >/dev/null; then
    brew install git
fi

#
# Install and setup zsh
#
if ! command -v zsh 2>&1 >/dev/null; then
    brew install zsh
    sudo chsh -s $(which zsh) $(whoami)
fi

# Install oh-my-zsh
[[ -d ~/.oh-my-zsh ]] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install powerlevel10k
if [ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]; then
    zsh -c 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"'
    sed -i -e 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc
fi

# Setup zsh
printf "\nalias v=nvim" >>~/.zshrc
printf "\nalias tmux='tmux -u'\n" >>~/.zshrc
printf "\nexport TERM=xterm-256color\n" >>~/.zshrc
printf "\nexport PATH=/home/linuxbrew/.linuxbrew/bin:\${PATH}\n" >>~/.zshrc
printf "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >>~/.zshrc

# Install tools
brew install lazygit neovim node tmux yazi
brew install --cask font-hack-nerd-font

#
# Sync configurations
#
git clone https://github.com/dmitri-atlavis/devbox.git ~/atlavis-devbox
cp ~/atlavis-devbox/.p10k.zsh ~
cp -r ~/atlavis-devbox/.config ~
rm -rf ~/atlavis-devbox

# Setup tmux
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
~/.config/tmux/plugins/tpm/bin/install_plugins
