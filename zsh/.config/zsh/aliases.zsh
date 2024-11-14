alias work="cd ${WORK}"
alias projects="cd ${WORK}/projects"
alias notes="cd ${NOTES}"
alias dots="cd ${DOTFILES}"
alias cdots="cd .dotfiles.core"

alias zshconfig="${EDITOR} ${HOME}/.zshrc"
alias envconfig="${EDITOR} ${HOME}/.zshenv"
alias aliasconfig="${EDITOR} ${HOME}/.config/zsh/aliases.zsh"
alias helperconfig="${EDITOR} ${HOME}/.config/zsh/helpers.zsh"
alias keybindconfig="${EDITOR} ${HOME}/.config/zsh/keybinds.zsh"
alias functionconfig="${EDITOR} ${HOME}/.config/zsh/functions.zsh"

# ****
# tmux
# ****
alias tmain="~/.tmux/tmux-bootstrap.sh ethicz"

# ****
# bat
# ****
if command -v bat &> /dev/null; then
  alias cat="bat -pp" 
  alias catt="bat" 
fi

# ****
# git
# ****
alias g="git"

# ****
# zoxide
# ****
alias j="z"
alias f="zi"

# ****
# kuberenetes
# ****
alias k="kubectl"
alias kns="k config set-context --current --namespace ${1}"
compdef __start_kubectl k

# ****
# gnome
# ****
alias gmpv="gnome-session-inhibit mpv ${1}"
alias gnomedump="echo "Saving Gnome configuration to ${DOTFILES}/_deskmod/gnome/gnome-config"; dconf dump / >! ${DOTFILES}/_deskmod/gnome/gnome-config"
alias gnomeload="echo "Loading Gnome configuration from ${DOTFILES}/_deskmod/gnome/gnome-config"; dconf load / < ${DOTFILES}/_deskmod/gnome/gnome-config"

# ****
# dotfiles git command
# ****
alias gdots="g --git-dir=${COREDOTS}/.git --work-tree=${COREDOTS}"
alias gconfig="g --git-dir=${DOTFILES}/.git --work-tree=${DOTFILES}" 
