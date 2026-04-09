#!/usr/bin/env bash
# Display previous session summary on first tool call, then delete the log.
# Uses mv for atomic grab so it only fires once even if PreToolUse fires in parallel.

LOG="${HOME}/.claude/last-session.log"
TEMP="${HOME}/.claude/last-session.displaying"

if mv "${LOG}" "${TEMP}" 2>/dev/null; then
    cat "${TEMP}"
    rm "${TEMP}"
fi
