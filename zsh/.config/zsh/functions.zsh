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
    printf "${CMOCHA_PURPLE}......${NC}"
    zle expand-or-complete
    zle redisplay
}
zle -N expand-or-complete-with-dots
