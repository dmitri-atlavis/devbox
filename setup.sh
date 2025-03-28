#!/bin/bash
set -e # Exit on error

SUPPORTED_OS="MacOS and Ubuntu"

COMMON_BASE_PACKAGES="7zip git imagemagick fzf npm ripgrep tmux zoxide"
LINUX_BASE_PACKAGES="${COMMON_BASE_PACKAGES} curl fd-find jq poppler-utils software-properties-common zsh unzip"
MAC_BASE_PACKAGES="${COMMON_BASE_PACKAGES} fd font-hack-nerd-font lazygit yazi"

DEVBOX_PATHS=""

# OS detection
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]] && command -v apt-get >/dev/null 2>&1; then
    OS_TYPE="ubuntu"
else
    echo "Error: Only ${SUPPORTED_OS} are supported"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup configs
backup_configs() {
    local ARCHIVE_DIR="/tmp/$(whoami)-configs-archive"
    echo "Backing up existing configurations to ${ARCHIVE_DIR}..."

    rm -rf "${ARCHIVE_DIR}"
    mkdir -p "${ARCHIVE_DIR}"

    for item in ~/.oh-my-zsh ~/.zshrc ~/.config/nvim ~/.config/tmux; do
        if [[ -e "${item}" ]]; then
            echo "Backing up ${item}"
            cp -r "${item}" "${ARCHIVE_DIR}/"
            rm -rf "${item}"
        fi
    done

    # Clean nvim cache
    if [[ -d ~/.local/share/nvim ]]; then
        rm -rf ~/.local/share/nvim
    fi

    echo "Archived current configs to ${ARCHIVE_DIR}"
}

# Function to install Linux packages
install_linux_packages() {
    echo "Installing packages for Ubuntu..."
    export DEBIAN_FRONTEND=noninteractive

    sudo apt-get update
    sudo apt-get install --no-install-recommends -y ${LINUX_BASE_PACKAGES} apt-utils || {
        echo "Error: Failed to install base packages"
        exit 1
    }

    # Switch default shell to zsh
    if [[ "$(getent passwd $USER | cut -d: -f7)" != "/usr/bin/zsh" ]]; then
        echo "Changing default shell to zsh..."
        sudo usermod --shell /usr/bin/zsh "$(whoami)" || {
            echo "Warning: Failed to change shell. Please run: chsh -s /usr/bin/zsh"
        }
    fi

    # Install neovim
    if ! command_exists nvim; then
        echo "Installing Neovim..."
        sudo add-apt-repository -y ppa:neovim-ppa/unstable
        sudo apt-get update
        sudo apt-get install --no-install-recommends -y neovim
    fi

    # Create temporary directory for downloads
    local tmp_dir=$(mktemp -d)
    cd "${tmp_dir}"

    # Install Nerd fonts
    echo "Installing Nerd fonts..."
    install_nerd_fonts

    # Install LazyGit
    if ! command_exists lazygit; then
        echo "Installing LazyGit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit -D -t /usr/local/bin/
    fi

    # Install Yazi
    if ! command_exists yazi; then
        echo "Installing Yazi..."
        if ! command_exists cargo; then
            curl https://sh.rustup.rs -sSf | bash -s -- -y
            source "$HOME/.cargo/env"
        fi

        git clone https://github.com/sxyazi/yazi.git
        cd yazi && cargo build --release --locked
        sudo install -D target/release/yazi target/release/ya -t /usr/local/bin/
    fi

    # Clean up
    cd
    rm -rf "${tmp_dir}"
}

# Function to install Nerd fonts
install_nerd_fonts() {
    local fonts=("Hack")
    local fonts_version=$(curl -s 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest' | jq -r '.name')

    if [[ -z "${fonts_version}" || "${fonts_version}" == "null" ]]; then
        fonts_version="v3.2.1"
    fi

    echo "Installing Nerd fonts version: ${fonts_version}"

    local fonts_dir="${HOME}/.local/share/fonts"
    mkdir -p "${fonts_dir}"

    for font in "${fonts[@]}"; do
        local zip_file="${font}.zip"
        local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${fonts_version}/${zip_file}"

        echo "Downloading ${font} font..."
        wget -q "${download_url}" || {
            echo "Warning: Failed to download ${font} font"
            continue
        }

        echo "Extracting ${font} font..."
        unzip -o "${zip_file}" -d "${fonts_dir}"
        rm "${zip_file}"
    done

    # Remove Windows compatible fonts
    find "${fonts_dir}" -name 'Windows Compatible' -delete

    # Refresh font cache on Linux
    if command_exists fc-cache; then
        fc-cache -f
    fi
}

# Function to install macOS packages
install_macos_packages() {
    echo "Installing packages for macOS..."

    # Install Homebrew if not installed
    if ! command_exists brew; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Determine Homebrew path
    if [[ -f /opt/homebrew/bin/brew ]]; then
        BREW_BIN_PATH="/opt/homebrew/bin"
    elif [[ -f /usr/local/bin/brew ]]; then
        BREW_BIN_PATH="/usr/local/bin"
    else
        echo "Error: Homebrew installation not found"
        exit 1
    fi

    # Add Homebrew to PATH for this session
    export PATH="${BREW_BIN_PATH}:${PATH}"

    # Install packages
    echo "Installing packages with Homebrew..."
    brew install --quiet ${MAC_BASE_PACKAGES}

    # Set path for zshrc
    DEVBOX_PATHS="export PATH=${BREW_BIN_PATH}:\$PATH"
}

# Function to install zsh plugins
install_zsh_plugins() {
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Install powerlevel10k theme
    if [[ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]]; then
        echo "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    fi

    # Install zsh plugins
    echo "Installing Zsh plugins..."
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi

    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi
}

# Function to sync configurations
sync_configurations() {
    echo "Syncing configurations..."

    DEVBOX_DIR=~/.config/atlavis-devbox
    ATLAVIS_DEVBOX_DIR=${DEVBOX_DIR}/atlavis

    mkdir -p ${DEVBOX_DIR}

    if [[ -d ${ATLAVIS_DEVBOX_DIR} ]]; then
        echo "Updating existing repository..."
        cd ${ATLAVIS_DEVBOX_DIR}
        git pull
    else
        echo "Cloning repository..."
        git clone https://github.com/dmitri-atlavis/devbox.git ${ATLAVIS_DEVBOX_DIR}
    fi

    # Copy configuration files
    echo "Copying configuration files..."
    cp ${ATLAVIS_DEVBOX_DIR}/.p10k.zsh ~

    # Ensure .config directory exists
    mkdir -p ~/.config
    cp -r ${ATLAVIS_DEVBOX_DIR}/.config/. ~/.config/

    # Copy custom configs if any
    if [[ -d ${DEVBOX_DIR}/custom ]]; then
        echo "Applying custom configurations..."
        cp -r ${DEVBOX_DIR}/custom/. ~
    fi

    # Setup tmux
    echo "Setting up Tmux..."
    mkdir -p ~/.config/tmux/plugins
    if [[ ! -d ~/.config/tmux/plugins/tpm ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    fi
    ~/.config/tmux/plugins/tpm/bin/install_plugins
}

# Function to configure zshrc
configure_zshrc() {
    echo "Configuring Zsh..."

    # Use different sed syntax based on OS
    if [[ "${OS_TYPE}" == "macos" ]]; then
        sed -i '' 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc
        sed -i '' 's/plugins=\(.*\)/plugins=\( git zsh-autosuggestions zsh-syntax-highlighting \)/g' ~/.zshrc
    else
        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc
        sed -i 's/plugins=\(.*\)/plugins=\( git zsh-autosuggestions zsh-syntax-highlighting \)/g' ~/.zshrc
    fi

    # Add p10k configuration
    if ! grep -q "source ~/.p10k.zsh" ~/.zshrc; then
        echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >>~/.zshrc
    fi

    # Add Atlavis DevBox configuration
    if ! grep -q "# Atlavis DevBox Config" ~/.zshrc; then
        cat >>~/.zshrc <<EOF

#
# Atlavis DevBox Config
#

# Paths
${DEVBOX_PATHS}

# aliases
alias v=nvim
alias lg=lazygit
alias y=yazi
alias tmux='tmux -u'

# terminal settings
export TERM=xterm-256color
export EDITOR=nvim
bindkey -v

#
# End of Atlavis DevBox Config
#
EOF
    fi
}

# Main installation process
main() {
    echo "Starting Atlavis DevBox installation..."
    echo "OS detected: ${OS_TYPE}"

    # Backup existing configurations
    backup_configs

    # Install packages based on OS
    if [[ "${OS_TYPE}" == "ubuntu" ]]; then
        install_linux_packages
    elif [[ "${OS_TYPE}" == "macos" ]]; then
        install_macos_packages
    fi

    # Install and configure zsh
    install_zsh_plugins

    # Sync configurations
    sync_configurations

    # Configure zshrc
    configure_zshrc

    echo -e "\nAtlavis DevBox installation completed successfully!"
    echo "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
}

# Run the main function
main
