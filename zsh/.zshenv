#!/usr/bin/env zsh

# ****
# ENV Variables
# ****
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export DISTRO=$(. /etc/os-release && echo ${ID})
export SHELL="$(which zsh)"
export WORK="${HOME}/work"
export GPG_TTY="${TTY}"
export COREDOTS="${HOME}/.dotfiles.core"
export DIDOTS="${HOME}/.dotfiles.di"
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
typeset -U path
# user binaries
path=("${HOME}/bin" $path)
path=("${HOME}/.local/bin" $path)
# system binaries
path=("/sbin" $path)
# emacs
path=("${HOME}/.emacs.d/bin" $path)
# rust cargo
path=("${HOME}/.cargo/bin" $path)
# atuin
path=("${HOME}/.atuin/bin" $path)
