# devbox

Terminal-first development environment for macOS.

## What's Included

- **zsh** with Starship prompt, autosuggestions, syntax highlighting
- **neovim** with custom config (LSP, completion, file management)
- **tmux** with custom config and plugins
- **lazygit**, **yazi**, **fzf**, **ripgrep**, **fd**
- **Hack Nerd Font**

## Install

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dmitri-atlavis/devbox/main/setup.sh)"
```

The script will show a plan and ask for confirmation before making changes. Existing configs are backed up to `/tmp/`.

## Aliases

- `v` → nvim
- `lg` → lazygit
- `y` → yazi
- `tmux` → tmux -u
