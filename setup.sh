#!/bin/bash
set -e # Exit on error

SUPPORTED_OS="MacOS and Ubuntu"

COMMON_BASE_PACKAGES="7zip git fzf ripgrep"
LINUX_BASE_PACKAGES="${COMMON_BASE_PACKAGES} fd-find jq poppler-utils software-properties-common zsh unzip"
MAC_BASE_PACKAGES="${COMMON_BASE_PACKAGES} imagemagick fd font-hack-nerd-font lazygit npm starship tmux yazi"

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

    for item in ~/.zsh ~/.zshrc ~/.config/nvim ~/.config/tmux ~/.config/starship.toml; do
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
    sudo apt-get install --no-install-recommends -y curl
    curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
    sudo bash nodesource_setup.sh
    sudo apt-get update
    sudo apt-get clean
    sudo apt-get autoremove
    sudo apt install --no-install-recommends -y nodejs
    rm -rf nodesource_setup.sh
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

    # Install or update neovim
    if ! command_exists nvim; then
        sudo add-apt-repository -y ppa:neovim-ppa/unstable
        sudo apt-get update
    fi
    echo "Installing/updating Neovim..."
    sudo apt-get install --no-install-recommends -y neovim

    # Create temporary directory for downloads
    local tmp_dir=$(mktemp -d)
    cd "${tmp_dir}"

    # Install Nerd fonts
    echo "Installing Nerd fonts..."
    install_nerd_fonts

    # Install or update LazyGit via PPA
    if ! command_exists lazygit; then
        sudo add-apt-repository -y ppa:lazygit-team/release
        sudo apt-get update
    fi
    echo "Installing/updating LazyGit..."
    sudo apt-get install --no-install-recommends -y lazygit

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

    # Install or upgrade packages
    echo "Installing/updating packages with Homebrew..."
    brew upgrade --quiet ${MAC_BASE_PACKAGES} 2>/dev/null || brew install --quiet ${MAC_BASE_PACKAGES}

    # Set path for zshrc
    DEVBOX_PATHS="export PATH=${BREW_BIN_PATH}:\$PATH"
}

# Function to install Starship prompt
install_starship() {
    if command_exists starship; then
        echo "Starship already installed."
        return
    fi

    echo "Installing Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

# Function to install zsh plugins
install_zsh_plugins() {
    local plugins_dir="${HOME}/.zsh/plugins"
    mkdir -p "${plugins_dir}"

    echo "Installing Zsh plugins..."

    if [[ ! -d "${plugins_dir}/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "${plugins_dir}/zsh-autosuggestions"
    else
        echo "zsh-autosuggestions already installed."
    fi

    if [[ ! -d "${plugins_dir}/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${plugins_dir}/zsh-syntax-highlighting"
    else
        echo "zsh-syntax-highlighting already installed."
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

    cat >~/.zshrc <<EOF
#
# Atlavis DevBox .zshrc
#

# Paths
${DEVBOX_PATHS}

# Zsh plugins
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Autosuggestion settings
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=true

# Aliases
alias v=nvim
alias lg=lazygit
alias y=yazi
alias tmux='tmux -u'

# Terminal settings
export TERM=xterm-256color
export EDITOR=nvim
bindkey -v

# Starship prompt
eval "\$(starship init zsh)"
EOF
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

    # Install Starship (curl installer for Linux, already in brew for macOS)
    if [[ "${OS_TYPE}" == "ubuntu" ]]; then
        install_starship
    fi

    # Install zsh plugins (standalone, no OMZ)
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
