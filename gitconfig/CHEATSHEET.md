# Git Aliases Cheatsheet

Defined in `[alias]` in `.gitconfig`.

| Alias | Expands to | Use |
|-------|-----------|-----|
| `git lg` | `log --graph --pretty=format:'%C(auto)%h%d %s %C(green)(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative` | Compact graph log with relative dates and author |
| `git co` | `checkout` | |
| `git br` | `branch` | |
| `git sw` | `switch` | |
| `git rs` | `restore` | |
| `git cleanup` | `branch --merged \| grep -v '\*' \| xargs -n 1 git branch -d` | Delete local branches already merged into the current one |

## Notable Non-Alias Behavior

Worth remembering since it changes how common commands act:

| Setting | Effect |
|---------|--------|
| `pull.ff = only` | `git pull` fast-forwards only — it will refuse to create a merge commit |
| `push.autosetupremote = true` | `git push` on a new branch auto-creates the upstream, no `-u` needed |
| `push.followTags = true` | `git push` also pushes annotated tags reachable from what's pushed |
| `merge.conflictstyle = zdiff3` | Conflict markers show the common ancestor, not just both sides |
| `rerere.enabled = true` | Git remembers how you resolved a conflict and reapplies it if it recurs |
| `core.pager = delta` | Diffs render through `delta` (side-by-side, line numbers, Catppuccin Mocha) |
