# Tmux Cheatsheet

Prefix is remapped to **`Ctrl-f`** (not the default `Ctrl-b`). Every binding below
that isn't marked "no prefix" is `Ctrl-f` then the key.

## Custom Bindings

| Key | Action |
|-----|--------|
| `Ctrl-f r` | Reload `~/.tmux.conf` |
| `Ctrl-f \|` | Split pane side-by-side (vertical divider) |
| `Ctrl-f -` | Split pane stacked (horizontal divider) |
| `Ctrl-f i` | Toggle synchronize-panes (type into every pane at once) |
| `Alt-Left/Right/Up/Down` | Switch pane in that direction (no prefix) |
| Mouse | Click to select pane/window, drag borders to resize, scroll to scroll/copy-mode |

Windows and panes are numbered starting at **1**, and windows renumber
automatically when one is closed.

## Windows

| Key | Action |
|-----|--------|
| `Ctrl-f c` | New window |
| `Ctrl-f n` / `Ctrl-f p` | Next / previous window |
| `Ctrl-f 0`-`9` | Jump to window by number |
| `Ctrl-f w` | Interactive window list |
| `Ctrl-f ,` | Rename current window |
| `Ctrl-f &` | Kill current window (confirm) |
| `Ctrl-f !` | Break current pane into its own window |

## Panes

| Key | Action |
|-----|--------|
| `Ctrl-f x` | Kill current pane (confirm) |
| `Ctrl-f z` | Zoom/unzoom pane (fullscreen toggle) |
| `Ctrl-f {` / `Ctrl-f }` | Swap pane with previous/next |
| `Ctrl-f q` | Briefly show pane numbers |

## Copy Mode / Sessions

| Key | Action |
|-----|--------|
| `Ctrl-f [` | Enter copy mode (scroll back, search, select text) |
| `Ctrl-f ]` | Paste last copied text |
| `Ctrl-f $` | Rename session |
| `Ctrl-f s` | Interactive session list |
| `Ctrl-f d` | Detach from session |

## Shell (outside tmux)

```
tmux new -s name       # start a named session
tmux attach -t name    # reattach
tmux ls                # list sessions
tmux kill-session -t name
```

If an app inside tmux also binds `Ctrl-f` natively, press `Ctrl-f Ctrl-f`
(send-prefix) to pass a literal `Ctrl-f` through to it.
