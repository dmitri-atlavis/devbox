# devbox

Dockerized development environments.

WARNING:
Run in isolated (dockerized) environments.
Executing this script on a host machine may destroy your environment settings.

Components:

- zsh with oh-my-zsh and powerlevel10k theme pre-setup
- tmux with custom setup
- neovim customized and adopted to python development from the nvim-lua/kickstart.nvim
- yazi
- lazigit

## Installation

### Prerequisites

- glibc and gcc
- curl
- sudo

Add dev docker instructions:

```
# Add dev user
RUN useradd -m -s /bin/bash dev && \
    echo 'dev ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
RUN chown -R dev /home/dev
WORKDIR /home/dev
USER dev

# Setup dev environment
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dmitri-atlavis/devbox/refs/heads/main/setup.sh)"

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["zsh"]
```
