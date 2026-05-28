# ****
# Autocomplete Red Dots
# ****
# ****
# diff
# ****
if command -v delta &> /dev/null; then
  function diff() { command diff -u "$@" | delta; }
fi

# ****
# Autocomplete Red Dots
# ****
expand-or-complete-with-dots() {
    echo -n "\e[31m......\e[0m"
    zle expand-or-complete
    zle redisplay
}
zle -N expand-or-complete-with-dots
