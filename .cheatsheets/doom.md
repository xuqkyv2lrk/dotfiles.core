# Doom Emacs Cheatsheet

Leader = **SPC** (spacebar). Only works in **normal mode** — hit `ESC` or type `jk` fast to get there.

## Key Notation

| Notation | Meaning |
| --- | --- |
| `C-x` | Hold **Ctrl**, tap x. `C-c C-c` = Ctrl+c, release, Ctrl+c again |
| `M-x` | Hold **Alt**, tap x |
| `S-x` | Hold **Shift**, tap x |
| `SPC x` | Tap **Space**, then x — only works in normal mode |
| `g d` | Tap g, then d — sequential, nothing held |

**Modes**: normal (block cursor, SPC bindings work) → insert (line cursor, you're typing) → back with `ESC`.

---

## Daily Driver — Stuff You'll Use Every Session

| What | Key |
| --- | --- |
| **Create or open a note** | `SPC n f` or `C-c n f` — type name, Enter |
| **New plain note (default)** | `SPC n d` or `C-c n d` — type name, done |
| **New hugo note** | `SPC n n` or `C-c n n` — type name, done |
| **Create note from template** | `SPC n c` or `C-c n c` — pick d=plain, n=hugo, t=temp, p=private |
| **Insert link to another note** | `SPC n i` or `C-c n i` |
| **Today's daily note** | `SPC n j` or `C-c n j` |
| **Show backlinks panel** | `SPC n l` or `C-c n l` |
| **Find any file** | `SPC f f` |
| **Recent files** | `SPC f r` |
| **Switch between open buffers** | `SPC b b` |
| **Search inside project** | `SPC s p` |
| **Save file** | `SPC f s` |
| **Undo** | `u` (normal mode) |
| **Open magit** | `SPC g g` |
| **Close a popup / quit panel** | `q` |
| **See what SPC does** | hold `SPC` for a second |

---

## Org-mode — Writing Notes

### Headers

Type at the start of a line — the number of `*` sets the level:

```
* Top-level heading
** Sub-heading
*** Sub-sub-heading
```

In insert mode just type `* ` (star + space) to start a heading. In normal mode, `o` opens a new line below and drops into insert.

`TAB` on a heading cycles through: **folded → children visible → everything visible**. `S-TAB` does the same for the whole file.

### Editing inside an org file

| What | Key |
| --- | --- |
| New line below current heading | `o` in normal mode |
| New line above current heading | `O` in normal mode |
| Fold / unfold heading | `TAB` |
| Fold / unfold entire file | `S-TAB` |
| Promote heading (fewer stars) | `M-h` |
| Demote heading (more stars) | `M-l` |
| Move section up | `M-k` |
| Move section down | `M-j` |
| Toggle TODO / DONE | `SPC m t` |
| Set a deadline | `SPC m d` |
| Set scheduled date | `SPC m s` |
| Insert a link | `SPC m l l` |
| Open your agenda | `SPC o A` |
| Quick capture a note | `SPC X` |
| Export (to PDF, HTML, etc.) | `SPC m e` |
| Finish capture buffer | `C-c C-c` |
| Abort capture | `C-c k` |

---

## Org-roam — Your Note Network

Notes live in `~/notes/tome/`. Each file is a node you can link between.

**`~/notes/` vs `~/notes/tome/`** — `notes/` is the parent folder for everything (cheatsheets, scratch). `tome/` is the org-roam vault — only files in here get indexed and linked.

| What | Key |
| --- | --- |
| Open or create a note by name | `SPC n f` or `C-c n f` |
| Link to another note inline | `SPC n i` or `C-c n i` |
| Open today's daily log | `SPC n j` or `C-c n j` |
| Capture a quick note to a node | `SPC n c` or `C-c n c` |
| Show what links to this note | `SPC n l` or `C-c n l` (backlinks panel) |

**Capture templates** (shown after `SPC n c`):

| Key | Template | Use for |
| --- | --- | --- |
| `d` | default | plain note, no frontmatter |
| `n` | note | hugo blog post with full frontmatter |
| `t` | temp | timestamped throwaway |
| `p` | private | `slug-private.org`, kept out of exports |

---

## Evil — Moving Around

| What | Key |
| --- | --- |
| Enter normal mode | `ESC` or `jk` |
| Enter insert mode | `i` (before cursor) / `a` (after) |
| Enter visual select | `v` (char) / `V` (line) / `C-v` (block) |
| Move by word | `w` forward / `b` back |
| Top / bottom of file | `g g` / `G` |
| Go to line 42 | `:42` then Enter |
| Center cursor on screen | `z z` |
| Jump back / forward (history) | `C-o` / `C-i` |
| Search forward | `/` then type, Enter, `n` for next |
| Delete line | `d d` |
| Copy line | `y y` |
| Paste | `p` |
| Undo / redo | `u` / `C-r` |
| Comment line | `g c c` |
| Comment selection | `g c` in visual mode |

---

## Windows & Workspaces

| What | Key |
| --- | --- |
| Split window right | `SPC w v` |
| Split window down | `SPC w s` |
| Move between windows | `SPC w h/j/k/l` |
| Close window | `SPC w d` |
| New workspace tab | `SPC TAB n` |
| Switch workspace | `SPC TAB 1-9` |
| Rename workspace | `SPC TAB r` |

---

## Git — Magit

Open with `SPC g g`, quit with `q`.

| What | Key |
| --- | --- |
| Stage hunk or file | `s` |
| Unstage | `u` |
| Commit | `c c` (write message, `C-c C-c` to confirm) |
| Push | `P p` |
| Pull | `F p` |
| View diff | `d d` |
| View log | `l l` |
| Blame current line | `SPC g b` |

---

## LSP — Code Intelligence (Rust, Go, etc.)

Kicks in automatically when you open a supported file.

| What | Key |
| --- | --- |
| Go to definition | `g d` |
| Go to references | `g r` |
| Hover / show docs | `K` |
| Code actions (quick fix, refactor) | `SPC c a` |
| Rename symbol everywhere | `SPC c r` |
| Format file | `SPC c f` |
| Show all errors / warnings | `SPC c x` |
| Next / prev error | `] d` / `[ d` |

---

## Projects

| What | Key |
| --- | --- |
| Switch project | `SPC p p` |
| Find file in current project | `SPC p f` |
| Search text in project | `SPC p s` |
| Kill all project buffers | `SPC p k` |

---

## Misc

| What | Key |
| --- | --- |
| Command palette (run anything) | `SPC :` |
| Open your Doom config | `SPC f P` |
| Reload config | `SPC h r r` |
| Doom docs | `SPC h d h` |
| Quit Emacs | `SPC q q` |
