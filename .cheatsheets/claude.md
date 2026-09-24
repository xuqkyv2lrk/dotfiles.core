# Claude Code Cheatsheet

`.claude/keybindings.json` has no custom bindings (`{ "bindings": [] }`), so
everything below is the CLI's built-in default. These are the stable core
shortcuts; run `/help` inside a session for the authoritative, version-
current list rather than trusting a static file for anything not listed
here.

## Session Control

| Key | Action |
|-----|--------|
| `Esc` | Interrupt the current response / clear the input line |
| `Esc` `Esc` | Rewind to edit a previous message |
| `Ctrl-C` (twice) | Exit the session |
| `Ctrl-D` | Exit the session |
| `Ctrl-L` | Clear the terminal screen |

## Input & History

| Key | Action |
|-----|--------|
| `Up` / `Down` | Navigate prompt history |
| `Ctrl-R` | Reverse-search prompt history |
| `Tab` | Autocomplete file paths / slash commands |
| `Shift-Tab` | Cycle permission mode (e.g. auto-accept edits) |
| `!<command>` | Run a shell command directly in the session |
| `/<command>` | Run a slash command |

To customize any of these, edit `~/.claude/keybindings.json` (the
`keybindings-help` skill covers rebinding and chord bindings).
