# Btop Cheatsheet

`vim_keys = false` in `btop.conf`, so the `h j k l g G` navigation keys are
**not** active in this config — use arrow keys instead. Mouse is enabled
(`disable_mouse = false`), so most of this is also clickable.

## Global

| Key | Action |
|-----|--------|
| `q` / `Ctrl-C` / `Esc` | Quit |
| `m` / `Esc` | Open main menu |
| `F1` / `?` | Help menu |
| `F2` / `o` | Options menu |
| `0`-`9` | Toggle visibility of a box (cpu/mem/net/proc/gpu) |
| `p` / `Shift-P` | Cycle presets forward / backward |
| `+` / `-` (in CPU box) | Increase / decrease update interval |

## Process Box

| Key | Action |
|-----|--------|
| Arrow keys | Navigate the process list |
| Left / Right | Cycle sort column |
| `f` / `/` | Filter processes |
| `Delete` | Clear filter |
| `Enter` | Show detailed info for selected process |
| `e` | Toggle tree view |
| `Shift-E` | Collapse all in tree view |
| `r` | Reverse sort order |
| `c` | Toggle per-core CPU display |
| `%` | Toggle memory display as bytes vs percent |
| `t` | Send SIGTERM to selected process |
| `k` | Send SIGKILL to selected process |
| `s` | Open signal-selection menu |
| `Shift-N` | Open renice menu |
| `u` | Pause / unpause the process list |
| `Shift-F` | Toggle following the selected process |

## Memory Box

| Key | Action |
|-----|--------|
| `i` | Toggle I/O mode |
| `d` | Toggle disk display |

## Network Box

| Key | Action |
|-----|--------|
| `b` / `n` | Previous / next network interface |
| `y` | Toggle sync mode (up/down share one scale) |
| `a` | Toggle auto-scaling |
| `z` | Reset network graph stats |
