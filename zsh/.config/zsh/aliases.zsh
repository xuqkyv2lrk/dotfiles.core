alias work="cd ${WORK}"
alias projects="cd ${WORK}/projects"
alias notes="cd ${NOTES}"
alias cdots="cd ${COREDOTS}"
alias didots="cd ${DIDOTS}"

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
alias x="zi"

# ****
# kubernetes
# ****
alias k="kubectl"
compdef __start_kubectl k

# ****
# gnome
# ****

# ****
# dotfiles git command
# ****
alias gdots="g --git-dir=${COREDOTS}/.git --work-tree=${COREDOTS}"
alias gconfig="g --git-dir=${DOTFILES}/.git --work-tree=${DOTFILES}"

# ****
# nixos
# ****
alias nrs="sudo nixos-rebuild switch --flake \"~/.dotfiles.nix#$(hostname)\""
