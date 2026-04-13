bindkey '^ ' autosuggest-accept
bindkey "^I" expand-or-complete-with-dots

zmodload zsh/terminfo
bindkey "${terminfo[kcuu1]:-^[[A}" history-substring-search-up
bindkey "${terminfo[kcud1]:-^[[B}" history-substring-search-down
