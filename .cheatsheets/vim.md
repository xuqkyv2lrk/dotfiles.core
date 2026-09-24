# Vim Cheatsheet

## Hover Documentation

| Key | Action |
|-----|--------|
| `K` | Show docs / type info for symbol under cursor (CoC + rust-analyzer) |
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gr` | Show references |

## Surround (vim-surround)

| Key | Action |
|-----|--------|
| `ysiw"` | Surround word with `"..."` |
| `ysiw(` | Surround word with `(...)` |
| `ys$"` | Surround cursor to end of line with `"..."` |
| `yss{` | Surround entire line with `{ ... }` |
| `ds"` | Delete surrounding quotes |
| `cs"'` | Change surrounding `"` to `'` |
| `S{` | (visual) Surround selection with `{}` |

## Text Objects

Works with any operator: `c` (change), `d` (delete), `y` (yank), `v` (visual select).

| Key | Action |
|-----|--------|
| `ci"` | Change inside quotes |
| `ca"` | Change around quotes (includes the quotes) |
| `ci(` | Change inside parens |
| `ci{` | Change inside braces |
| `cit` | Change inside tag |
| `da[` | Delete around brackets (includes brackets) |

Swap the operator to get variants — `di"`, `yi(`, `va{`, etc.

## Line Navigation

| Key | Action |
|-----|--------|
| `f<char>` | Jump to next occurrence of char on line |
| `t<char>` | Jump to just before char |
| `F` / `T` | Same but backwards |
| `;` | Repeat f/t forward |
| `,` | Repeat f/t backward |
| `%` | Jump between matching `(`, `{`, `[` |

## Quick Line Edits

| Key | Action |
|-----|--------|
| `A` | Append at end of line |
| `I` | Insert at start of line |
| `C` | Change from cursor to end of line |
| `D` | Delete from cursor to end of line |
| `S` | Delete entire line and start inserting |
| `J` | Join line below onto current line |

## Repeat and Macros

| Key | Action |
|-----|--------|
| `.` | Repeat last change |
| `qq` | Start recording macro into register `q` |
| `q` | Stop recording |
| `@q` | Replay macro `q` |
| `@@` | Replay last macro again |
| `5@q` | Replay macro `q` five times |

## Custom Mappings

| Key | Action |
|-----|--------|
| `,w` | (visual) Wrap selection in a block — prompts for keyword (`loop`, `if`, etc.) |
| `<C-p>` | Fuzzy file finder (fzf) |
| `,fg` | Live grep (rg) |
| `,fb` | Buffer list |

## Rust / Cargo

| Key | Action |
|-----|--------|
| `,rb` | `cargo build` |
| `,rt` | `cargo test` |
| `,rr` | `cargo run` |
| `,rc` | `cargo check` |
| `,rf` | Format with rust-analyzer |

## CoC (LSP)

| Key | Action |
|-----|--------|
| `[g` / `]g` | Previous / next diagnostic |
| `,ce` | Show diagnostics float |
| `,ac` | Code actions |
| `,qf` | Quick fix |
| `,n` | Rename symbol |
| `,oi` | Organize imports |
| `Tab` | Next completion item |
| `S-Tab` | Previous completion item |
| `Enter` | Confirm completion |
