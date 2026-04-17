#!/usr/bin/env bash
set -euo pipefail

# Bootstrap a tmux session with a fixed window/pane layout
# Usage: tmux-bootstrap.sh <session-name>

function main() {
    local session="${1:?Session name required}"

    if ! tmux has-session -t "${session}" 2>/dev/null; then
        tmux new-session -d -s "${session}" -n scratchpad -c "${HOME}"

        local window=1
        tmux split-window -t "${session}:${window}.1" -v -c "${HOME}"
        tmux split-window -t "${session}:${window}.2" -h -c "${HOME}"
        tmux select-pane -t "${session}:${window}.1"

        window=2
        tmux new-window -t "${session}" -n workspace -c ~/work

        window=3
        tmux new-window -t "${session}" -n yazi -c "${HOME}"
        tmux send-keys -t "${session}:${window}" "yazi" Enter

        tmux select-window -t "${session}:1"
    fi

    tmux attach-session -t "${session}"
}

main "$@"
