#!/usr/bin/env zsh

# ****
# ENV Variables
# ****
export COLORTERM=truecolor
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export DISTRO=$(. /etc/os-release && echo ${ID})
export SHELL="$(which zsh)"
export WORK="${HOME}/work"
export GPG_TTY="${TTY}"
export SSH_ASKPASS_REQUIRE=never
export COREDOTS="${HOME}/.dotfiles.core"
export DIDOTS="${HOME}/.dotfiles.di"
export NOTES="${HOME}/notes"
#export TERM="xterm-256color"
export MISE_EXPERIMENTAL=1
export LESS="-eirMX"
export PAGER="less"
export EDITOR="vim"
export BROWSER="firefox"
export FMANAGER="yazi"
export READER="zathura"
export TERMINAL="foot"
export GOPATH="${HOME}/go"
export HISTFILE="${HOME}/.zsh_history"
export HISTSIZE=1000000
export SAVEHIST=1000000

if [[ "${XDG_SESSION_TYPE}" == "wayland" ]]; then
    export MOZ_DBUS_REMOTE=1
    export MOZ_ENABLE_WAYLAND=1
fi

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70,bg=none,bold"

export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#94E2D5,hl:#CBA6F7 \
--color=fg:#CDD6F4,header:#CBA6F7,info:#CBA6F7,pointer:#CBA6F7 \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#CBA6F7 \
--color=selected-bg:#45475A \
--color=border:#313244,label:#CDD6F4"

# eza colors (Catppuccin Mocha, mauve accent)
export EZA_COLORS="\
di=38;2;137;180;250:\
ln=38;2;148;226;213:\
or=38;2;243;139;168:\
ex=38;2;166;227;161:\
fi=38;2;205;214;244:\
pi=38;2;249;226;175:\
so=38;2;203;166;247:\
ur=38;2;166;227;161:\
uw=38;2;249;226;175:\
ux=38;2;203;166;247:\
ue=38;2;203;166;247:\
gr=38;2;166;227;161:\
gw=38;2;249;226;175:\
gx=38;2;203;166;247:\
tr=38;2;166;227;161:\
tw=38;2;249;226;175:\
tx=38;2;203;166;247:\
su=38;2;243;139;168:\
sf=38;2;250;179;135:\
xa=38;2;166;173;200:\
nb=38;2;108;112;134:\
nk=38;2;148;226;213:\
nm=38;2;137;180;250:\
ng=38;2;203;166;247:\
nt=38;2;243;139;168:\
sb=38;2;166;173;200:\
uu=38;2;203;166;247:\
un=38;2;249;226;175:\
gu=38;2;148;226;213:\
gn=38;2;249;226;175:\
da=38;2;166;173;200:\
ga=38;2;166;227;161:\
gm=38;2;249;226;175:\
gd=38;2;243;139;168:\
gv=38;2;148;226;213:\
gt=38;2;203;166;247:\
gi=38;2;108;112;134:\
gc=38;2;243;139;168"

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
# go
path=("${GOPATH}/bin" $path)
# npm globals
path=("${HOME}/.npm-global/bin" $path)
