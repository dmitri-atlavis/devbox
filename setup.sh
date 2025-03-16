#!/bin/bash

#
# Install base packages
#
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt 2>&1 >/dev/null; then
        sudo apt update
        sudo apt install --no-install-recommends -y curl zsh
        # switch current user to zsh by default
        sudo chsh -s $(which zsh) $(whoami)
        # install brew for linux
        BREW_BIN_PATH="/home/linuxbrew/.linuxbrew/bin"
        export PATH=$BREW_BIN_PATH:$PATH
        sudo useradd -m -s /bin/bash linuxbrew
        sudo sh -c "printf 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers"
        sudo -u linuxbrew -H NONINTERACTIVE=1 PATH=$PATH /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        sudo chown -R $(whoami) /home/linuxbrew/.linuxbrew
    else
        printf "Only MacOS and Ubuntu are supported at the moment."
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    BREW_BIN_PATH="/opt/homebrew/bin"
    if ! command -v brew 2>&1 >/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
else
    printf "Only MacOS and Ubuntu are supported at the moment."
    exit 1
fi

# Install git and node
brew install --quiet git node

#
# Archive old configs into a directory
#
ARCHIVE_DIR=/tmp/$(whoami)-configs-archive
rm -rf $ARCHIVE_DIR
mkdir -p $ARCHIVE_DIR
if [[ -d ~/.oh-my-zsh ]]; then
    mv ~/.oh-my-zsh $ARCHIVE_DIR
fi

if [[ -f ~/.zshrc ]]; then
    mv ~/.zshrc $ARCHIVE_DIR
fi

if [[ -d ~/.config/nvim ]]; then
    mv ~/.config/nvim $ARCHIVE_DIR
    # clean cache
    rm -rf ~/.local/share/nvim
fi

if [[ -d ~/.config/tmux ]]; then
    mv ~/.config/tmux $ARCHIVE_DIR
fi

printf "Archived current configs to $ARCHIVE_DIR\n"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install powerlevel10k
if [ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    sed -i -e 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc
    printf "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh\n" >>~/.zshrc
fi

# Install plugins and tools
brew install --quiet lazygit neovim tmux yazi zsh-autosuggestions zsh-syntax-highlighting
brew install --cask --quiet font-hack-nerd-font

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

#
# Write to .zshrc
#
printf "%s\n""\
" \
    "#" \
    "# Atlavis DevBox Config" \
    "#" \
    "" \
    "# Paths" \
    "export PATH=$BREW_BIN_PATH:\$PATH" \
    "" \
    "# zsh plugins" \
    "source \$($BREW_BIN_PATH/brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
    "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
    "" \
    "# aliases" \
    "alias v=nvim" \
    "alias tmux='tmux -u'" \
    "" \
    "# terminal settings" \
    "export TERM=xterm-256color" \
    "export EDITOR=nvim" \
    "bindkey -v" \
    "" \
    "#" \
    "# End of Atlavis DevBox Config" \
    "#" >>~/.zshrc

printf "\n\nArchived current configs to $ARCHIVE_DIR\n\n"
