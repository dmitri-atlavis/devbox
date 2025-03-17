#!/bin/bash

SUPPORTED_OS="MacOS and Ubuntu"

COMMON_BASE_PACKAGES="7zip git imagemagick fzf npm ripgrep tmux zoxide"
LINUX_BASE_PACKAGES="${COMMON_BASE_PACKAGES} curl fd-find jq poppler-utils software-properties-common zsh unzip"
MAC_BASE_PACKAGES="${COMMON_BASE_PACKAGES} fd font-hack-nerd-font lazygit yazi"

DEVBOX_PATHS=""

if ! command -v apt 2>&1 >/dev/null && [[ "$OSTYPE" != "darwin"* ]]; then
    printf "Only MacOS and Ubuntu are supported"
    exit 1
fi

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

#
# Install base packages
#
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt update
    sudo apt install --no-install-recommends -y ${LINUX_BASE_PACKAGES}

    # switch default shell to zsh
    usermod --shell /usr/bin/zsh $(whoami)

    #
    # The rest is installed manually
    #
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt-get update
    sudo apt-get install neovim

    mkdir /tmp/devbox
    cd /tmp/devbox

    # Nerd fonts
    declare -a fonts=(Hack)

    fonts_version=$(curl -s 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest' | jq -r '.name')
    if [ -z "$version" ] || [ "$version" = "null" ]; then
        version="v3.2.1"
    fi
    echo "latest fonts version: $version"

    fonts_dir="${HOME}/.local/share/fonts"

    if [[ ! -d "$fonts_dir" ]]; then
        mkdir -p "$fonts_dir"
    fi

    for font in "${fonts[@]}"; do
        zip_file="${font}.zip"
        download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${zip_file}"
        wget "$download_url"
        unzip -o "$zip_file" -d "$fonts_dir" # Added the -o option here to allow replacing
        rm "$zip_file"
    done

    find "$fonts_dir" -name 'Windows Compatible' -delete

    # LazyGit
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t /usr/local/bin/

    # Yazi
    curl https://sh.rustup.rs -sSf | bash -s -- -y
    git clone https://github.com/sxyazi/yazi.git
    cd yazi && ~/.cargo/bin/cargo build --release --locked
    sudo mv target/release/yazi target/release/ya /usr/local/bin/

    rm -rf /tmp/devbox
    cd ~

elif [[ "$OSTYPE" == "darwin"* ]]; then
    BREW_BIN_PATH="/opt/homebrew/bin"
    if ! command -v brew 2>&1 >/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install --quiet ${MAC_BASE_PACKAGES}
    DEVBOX_PATHS="export PATH=$BREW_BIN_PATH:\$PATH"
fi

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install powerlevel10k
if [ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    sed -i -e 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc
    printf "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh\n" >>~/.zshrc
fi

# Install zsh autosuggestions plugin
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Install zsh syntax highlighter plugin
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

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
sed -i -e 's/plugins=\(.*\)/plugins=\( git zsh-autosuggestions zsh-syntax-highlighting \)/g' ~/.zshrc

printf "%s\n""\
" \
    "#" \
    "# Atlavis DevBox Config" \
    "#" \
    "" \
    "# Paths" \
    "$DEVBOX_PATHS" \
    "" \
    "# aliases" \
    "alias v=nvim" \
    "alias lg=lazygit" \
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
