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
# Cheatsheets
# ****
function cheat() {
    local sheet_dir="${COREDOTS}/.cheatsheets"
    local sheet="${1:-}"

    if [[ -z "${sheet}" ]]; then
        print -rl -- "${sheet_dir}"/*.md(:t:r)
        return 0
    fi

    local file="${sheet_dir}/${sheet}.md"
    if [[ ! -f "${file}" ]]; then
        echo "No cheatsheet for '${sheet}'. Available:" >&2
        print -rl -- "${sheet_dir}"/*.md(:t:r) >&2
        return 1
    fi

    glow "${file}"
}

_cheat() {
    local -a sheets
    sheets=("${COREDOTS}/.cheatsheets"/*.md(:t:r))
    _describe 'cheatsheet' sheets
}
compdef _cheat cheat

# ****
# Autocomplete Red Dots
# ****
expand-or-complete-with-dots() {
    printf "${CMOCHA_PURPLE}......${NC}"
    zle expand-or-complete
    zle redisplay
}
zle -N expand-or-complete-with-dots
