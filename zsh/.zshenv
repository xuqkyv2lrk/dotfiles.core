# shellcheck disable=SC2155

# ****
# ENV Variables
# ****
export DISTRO=$(. /etc/os-release && echo ${ID})
export SHELL="$(which zsh)"
export WORK="${HOME}/work"
export GPG_TTY="${TTY}"
export COREDOTS="${HOME}/.dotfiles.core"
export DOTFILES="${HOME}/.dotfiles.${DISTRO}"
export NOTES="${HOME}/notes"
#export TERM="xterm-256color"
export LESS="-eirMX"
export USER_NAME="$(whoami)"
export PAGER="less"
export EDITOR="vim"
export BROWSER="firefox"
export FMANAGER="ranger"
export READER="zathura"
export TERMINAL="foot"
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
export GOPATH="${HOME}/go"
export HISTFILE="${HOME}/.zsh_history"
export HISTSIZE=1000000
export SAVEHIST=1000000

if [[ "${XDG_SESSION_TYPE}" == "wayland" ]]; then
    export MOZ_DBUS_REMOTE=1
    export MOZ_ENABLE_WAYLAND=1
fi

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70,bg=none,bold"

#**********
# PATHS
#**********
if [[ -z "$TMUX" ]]; then
    path=("$HOME/.local/bin" /usr/local/{bin,sbin} $path)
    path+=("$HOME/.emacs.d/bin" "$HOME/bin" "$HOME/.npm-global/bin")
    path+=("$GOPATH/bin")
    
    if [[ $(uname -s) == "Darwin" ]]; then
        path=("/opt/homebrew/bin" $path)
        
        if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
            path=("$(gem environment gemdir)/bin" "/opt/homebrew/opt/ruby/bin" $path)
        fi
    fi
fi

# Remove duplicates paths
#typeset -U path

# Rust
. "$HOME/.cargo/env"

eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
