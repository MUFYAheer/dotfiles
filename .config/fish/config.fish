set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_DATA_DIRS $HOME/.local/share:/usr/local/share:/usr/share:/home/mufy/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share
set -gx NVM_DIR $XDG_CONFIG_HOME/nvm
set -gx GOPATH $HOME/.local/go
set -gx EDITOR nvim

