# Atlavis DevBox Development Environment

This is a cross-platform development environment setup for macOS and Ubuntu, focused on terminal-based development with Neovim.

## Setup
- **Main setup script**: `setup.sh` - Installs and configures the entire development environment
- **Docker**: Use `make build` and `make shell` for containerized development
- **Supports**: macOS (Homebrew) and Ubuntu (apt)

## Key Components
- **Neovim**: Primary editor with custom configuration
- **Zsh**: Shell with Starship prompt, autosuggestions, syntax highlighting
- **Tmux**: Terminal multiplexer with custom config and plugins
- **Tools**: lazygit, fzf, ripgrep, yazi (macOS), Hack Nerd Font

## Aliases
- `v` → nvim
- `lg` → lazygit
- `y` → yazi
- `tmux` → tmux -u

## Testing
- Run setup script: `./setup.sh`
- Docker test: `make build && make shell`
