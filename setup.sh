#!/bin/bash
set -e

# === Configuration ===

BREW_PACKAGES="7zip git fzf ripgrep imagemagick fd font-hack-nerd-font lazygit npm starship tmux yazi"

MANAGED_CONFIGS="nvim tmux starship.toml yazi devbox"

ZSH_PLUGINS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

DEVBOX_REPO="https://github.com/dmitri-atlavis/devbox.git"
PLUGINS_DIR="${HOME}/.zsh/plugins"
BACKUP_DIR="/tmp/config-backup-$(printf '%04x' $RANDOM)"

# === Preflight ===

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This script only supports macOS"
    exit 1
fi

need_brew=false
if ! command -v brew >/dev/null 2>&1; then
    need_brew=true
fi

# === Present Plan ===

echo ""
echo "=== Atlavis DevBox Setup Plan ==="
echo ""

step=1

if [[ "${need_brew}" == true ]]; then
    echo "  ${step}. Install Homebrew and add to ~/.zprofile"
    ((step++))
fi

echo "  ${step}. Install/upgrade brew packages:"
for pkg in ${BREW_PACKAGES}; do
    echo "       - ${pkg}"
done
((step++))

echo "  ${step}. Install zsh plugins (if not present):"
for entry in "${ZSH_PLUGINS[@]}"; do
    echo "       - ${entry%%|*}"
done
((step++))

echo "  ${step}. Backup existing configs to ${BACKUP_DIR}/"
echo "       Clear nvim plugin cache"
((step++))

echo "  ${step}. Sync configurations from ${DEVBOX_REPO}"
((step++))

echo "  ${step}. Install tmux plugins (tpm)"
((step++))

echo "  ${step}. Add devbox shell config to ~/.zshrc"
echo ""

# === Ask Permission ===

confirm_each=false

if [ -t 0 ]; then
    # Interactive: stdin is a terminal
    echo "Proceed?"
    echo "  Y - run all steps without confirmation"
    echo "  y - confirm each step before running"
    echo "  N - abort"
    echo ""
    read -n 1 -r response
    echo ""

    if [[ "${response}" == "N" || "${response}" == "n" ]]; then
        echo "Aborted."
        exit 0
    fi

    if [[ "${response}" == "y" ]]; then
        confirm_each=true
    fi
else
    # Non-interactive: piped from curl
    echo "Running in non-interactive mode..."
fi

run_step() {
    local description="$1"
    echo ""
    echo "==> ${description}"
    if [[ "${confirm_each}" == true ]]; then
        read -n 1 -r -p "    Run? [Y/n] " step_response
        echo ""
        if [[ "${step_response}" == "n" || "${step_response}" == "N" ]]; then
            echo "    Skipped."
            return 1
        fi
    fi
    return 0
}

# === Step: Homebrew ===

if [[ "${need_brew}" == true ]]; then
    if run_step "Installing Homebrew..."; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(brew shellenv)"
        echo 'eval "$(brew shellenv)"' >> ~/.zprofile
        echo "    Homebrew installed and added to ~/.zprofile"
    fi
fi

# === Step: Brew Packages ===

if run_step "Installing/upgrading brew packages..."; then
    brew upgrade --quiet ${BREW_PACKAGES} 2>/dev/null || brew install --quiet ${BREW_PACKAGES}
    echo "    Packages up to date."
fi

# === Step: Zsh Plugins ===

if run_step "Installing zsh plugins..."; then
    mkdir -p "${PLUGINS_DIR}"
    for entry in "${ZSH_PLUGINS[@]}"; do
        name="${entry%%|*}"
        url="${entry##*|}"
        if [[ ! -d "${PLUGINS_DIR}/${name}" ]]; then
            git clone "${url}" "${PLUGINS_DIR}/${name}"
        else
            echo "    ${name} already installed."
        fi
    done
fi

# === Step: Backup Configs ===

if run_step "Backing up existing configs to ${BACKUP_DIR}/..."; then
    mkdir -p "${BACKUP_DIR}"
    for name in ${MANAGED_CONFIGS}; do
        if [[ -e "${HOME}/.config/${name}" ]]; then
            echo "    ~/.config/${name} -> ${BACKUP_DIR}/${name}"
            mv "${HOME}/.config/${name}" "${BACKUP_DIR}/"
        fi
    done

    if [[ -d "${HOME}/.local/share/nvim" ]]; then
        echo "    Clearing nvim plugin cache..."
        rm -rf "${HOME}/.local/share/nvim"
    fi
fi

# === Step: Sync Configs ===

if run_step "Syncing configurations from GitHub..."; then
    tmp_dir=$(mktemp -d)
    git clone --depth 1 "${DEVBOX_REPO}" "${tmp_dir}/devbox"

    mkdir -p "${HOME}/.config"
    cp -r "${tmp_dir}/devbox/.config/." "${HOME}/.config/"
    rm -rf "${tmp_dir}"
    echo "    Configurations synced."
fi

# === Step: Tmux Plugins ===

if run_step "Installing tmux plugins..."; then
    mkdir -p "${HOME}/.config/tmux/plugins"
    if [[ ! -d "${HOME}/.config/tmux/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm "${HOME}/.config/tmux/plugins/tpm"
    fi
    "${HOME}/.config/tmux/plugins/tpm/bin/install_plugins"
    echo "    Tmux plugins installed."
fi

# === Step: Shell Config ===

if run_step "Adding devbox shell config to ~/.zshrc..."; then
    if ! grep -q 'devbox/rc.zsh' "${HOME}/.zshrc" 2>/dev/null; then
        echo 'source ~/.config/devbox/rc.zsh' >> "${HOME}/.zshrc"
        echo "    Added source line to ~/.zshrc"
    else
        echo "    Already configured."
    fi
fi

echo ""
echo "=== Atlavis DevBox setup complete ==="
echo "Please restart your terminal to apply changes."
