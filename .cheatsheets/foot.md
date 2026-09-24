# Foot Cheatsheet

No keybindings are overridden in `foot.ini` — the `[key-bindings]`,
`[search-bindings]`, `[url-bindings]`, and `[mouse-bindings]` sections are
all commented out, so every value below is foot's built-in default (each
one is documented inline in `foot.ini`, just commented). One thing is
customized: URL hint letters are set to `sadfjklewcmpgh` instead of the
factory order.

## General

| Key | Action |
|-----|--------|
| `Shift-Page_Up` / `Shift-Page_Down` | Scroll back a page / forward a page |
| `Ctrl-Shift-C` | Copy to clipboard |
| `Ctrl-Shift-V` | Paste from clipboard |
| `Shift-Insert` | Paste from primary selection |
| `Ctrl-Shift-R` | Start scrollback search |
| `Ctrl-+` / `Ctrl--` / `Ctrl-0` | Increase / decrease / reset font size |
| `Ctrl-Shift-N` | Spawn a new terminal |
| `Ctrl-Shift-O` | Show URL hints, launch on select |
| `Ctrl-Shift-Z` / `Ctrl-Shift-X` | Previous / next shell prompt |
| `Ctrl-Shift-U` | Unicode input |

## Search Mode (after `Ctrl-Shift-R`)

| Key | Action |
|-----|--------|
| `Escape` / `Ctrl-G` / `Ctrl-C` | Cancel search |
| `Return` | Commit / jump to match |
| `Ctrl-R` / `Ctrl-S` | Find previous / next |
| `Ctrl-A` / `Ctrl-E` (or `Home`/`End`) | Cursor to start / end of search text |
| `Ctrl-V` / `Ctrl-Shift-V` / `Ctrl-Y` | Paste into search box |

## URL Hint Mode (after `Ctrl-Shift-O`)

| Key | Action |
|-----|--------|
| Letter shown next to a URL | Open that URL (`xdg-open`) |
| `T` | Toggle URL visibility |
| `Escape` / `Ctrl-G` / `Ctrl-C` / `Ctrl-D` | Cancel |

## Mouse

| Action | Result |
|--------|--------|
| Left click + drag | Select text |
| Left double-click | Select word |
| Left triple-click | Select line |
| Right click | Extend selection |
| Middle click | Paste primary selection |
| Scroll wheel | Scroll back / forward |
| `Ctrl` + scroll wheel | Increase / decrease font size |
