# ****
# Load Plugin Manager (https://www.zapzsh.com/)
# ****
[ ! -f "${HOME}/.local/share/zap/zap.zsh" ] \
	&& zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1 --keep
[ -f "${HOME}/.local/share/zap/zap.zsh" ] \
	&& source "$HOME/.local/share/zap/zap.zsh"

# ****
# Options Configuration (man zshoptions)
# ****
setopt autocd extendedglob nomatch menucomplete interactivecomments
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_VERIFY
unsetopt beep correct
zle_highlight=('paste:none')

# ****
# Bash Completion
# ****
autoload -Uz +X compinit && compinit
autoload -Uz +X bashcompinit && bashcompinit

# ****
# User Defined Locals
# ****
plug "${HOME}/.config/zsh/*"

# ****
# Plugins
# ****
plug "hlissner/zsh-autopair"
plug "zap-zsh/exa"
plug "zsh-users/zsh-history-substring-search"
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-syntax-highlighting"

if [ -z "$SSH_CONNECTION" ] && [ "$(tty)" != "/dev/tty1" ]; then
    eval "$(oh-my-posh init zsh --config ${HOME}/.config/ohmyposh/lean.yaml)"
fi

# ****
# Trailing New Line
# Make a magenta block that is three spaces in length, instead of the %
# ****
PROMPT_EOL_MARK='%K{magenta} %k'

zle-line-init() {
    zle -K viins
    echo -n "${${KEYMAP/vicmd/}/(main|viins)/}"
}

zle -N zle-line-init

# Remove newline from pasted text
zle_bracketed_paste() {
    local paste_content
    zle .$WIDGET -N paste_content
    paste_content="${paste_content%$'\n'}"
    LBUFFER+="$paste_content"
}

zle -N bracketed-paste zle_bracketed_paste

#**********
# Evaluations
#**********
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
eval "$(atuin init zsh)"
