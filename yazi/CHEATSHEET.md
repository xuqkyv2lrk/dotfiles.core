# Yazi Cheatsheet

Custom binds live in `keymap.toml` and prepend onto (don't replace) yazi's
stock keymap, so both work.

## Custom Bindings

| Key | Action |
|-----|--------|
| `e x` | Extract selected archive(s) here (`aunpack`) |
| `e z` | Compress selected files (`apack`) |
| `R` | Reveal hovered file in Finder |
| `T` | Open a new tmux window in the current directory (no-op outside tmux) |

## Navigation

| Key | Action |
|-----|--------|
| `h` / `j` / `k` / `l` | Left (leave dir) / down / up / right (enter dir) |
| `H` / `L` | Back / forward through directory history |
| `g g` / `G` | Jump to top / bottom |
| `Ctrl-u` / `Ctrl-d` | Half page up / down |
| `Ctrl-b` / `Ctrl-f` | Full page up / down |
| `g h` | Go to `~` |
| `g c` | Go to `~/.config` |
| `g d` | Go to `~/Downloads` |
| `g Space` | Go to directory (interactive) |
| `Enter` / `o` | Open selected |
| `O` | Open interactively (pick app) |

## Selection

| Key | Action |
|-----|--------|
| `Space` | Toggle selection, move down |
| `Ctrl-a` | Select all |
| `Ctrl-r` | Invert selection |
| `v` / `V` | Enter / exit visual (range) select mode |

## File Operations

| Key | Action |
|-----|--------|
| `y` | Yank (copy) |
| `x` | Yank with cut |
| `p` / `P` | Paste / paste (force overwrite) |
| `d` | Move to trash |
| `D` | Delete permanently |
| `a` | Create file/dir (trailing `/` for dir) |
| `A` | Bulk rename (create) |
| `r` | Rename |
| `.` | Toggle hidden files |
| `-` / `_` | Symlink / relative symlink |

## Search, Filter, Sort

| Key | Action |
|-----|--------|
| `f` | Filter (smart case) |
| `/` / `?` | Find next / previous (smart case) |
| `n` / `N` | Repeat find forward / backward |
| `s` / `S` | Search via `fd` / `rg` |
| `z` | Fuzzy jump (fzf plugin) |
| `Z` | Zoxide jump |
| `, a` / `, n` / `, m` / `, s` | Sort by alphabetical / natural / mtime / size |

## Tabs & Misc

| Key | Action |
|-----|--------|
| `t t` | New tab (at current dir) |
| `1`-`9` | Switch to tab N |
| `[` / `]` | Previous / next tab |
| `w` | Show task manager |
| `~` or `F1` | Help (full keymap, searchable) |
| `q` / `Q` | Quit (with / without writing cwd-file) |

Full reference: `~` inside yazi always reflects your actual installed
version's keymap, which beats any static list here.
