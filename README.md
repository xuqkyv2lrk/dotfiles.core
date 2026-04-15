<div align="center">
<img src="./dotfile.png" alt="dotfiles.core" width="140px" />
<h3>dotfiles.core</h3>
<p>Program configurations for zsh, vim, tmux, and more — managed with GNU Stow.</p>
<p>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-BSD%203--Clause-blue.svg" alt="License" /></a>
  <a href="https://gitlab.com/wd2nf8gqct/dotfiles.core"><img src="https://img.shields.io/badge/GitLab-Main-orange.svg?logo=gitlab" alt="GitLab" /></a>
  <a href="https://github.com/xuqkyv2lrk/dotfiles.core"><img src="https://img.shields.io/badge/GitHub-Mirror-black.svg?logo=github" alt="GitHub Mirror" /></a>
  <a href="https://codeberg.org/iw8knmadd5/dotfiles.core"><img src="https://img.shields.io/badge/Codeberg-Mirror-2185D0.svg?logo=codeberg" alt="Codeberg Mirror" /></a>
</p>
<p>
  <a href="https://archlinux.org"><img src="https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff&style=flat" alt="Arch Linux" /></a>
  <a href="https://ubuntu.com"><img src="https://img.shields.io/badge/Ubuntu-E95420?style=flat&logo=ubuntu&logoColor=white" alt="Ubuntu" /></a>
</p>
</div>

## What is this?

Configuration files for the programs I use daily. Each directory is a [GNU Stow](https://www.gnu.org/software/stow/) package that symlinks its contents into `$HOME`.

For full machine setup — package installation, hardware configuration, and bootstrapping — see [dotfiles.bootstrap](https://gitlab.com/wd2nf8gqct/dotfiles.bootstrap).

## Usage

```bash
git clone https://gitlab.com/wd2nf8gqct/dotfiles.core.git ~/.dotfiles.core
cd ~/.dotfiles.core
```

Stow everything at once:

```bash
stow bat btop cava claude delta doom fastfetch foot \
     gitconfig mpd ncmpcpp ncspot ohmyposh tmux vim yazi zsh
```

Or stow individual modules:

```bash
stow vim
stow zsh
stow tmux
```

## Repository layout

```
.
├── bat/              # bat (cat with syntax highlighting)
├── btop/             # btop system monitor
├── cava/             # cava audio visualizer
├── claude/           # Claude Code settings
├── delta/            # git-delta diff viewer
├── doom/             # Doom Emacs
├── fastfetch/        # fastfetch system info
├── foot/             # foot terminal
├── gitconfig/        # git settings
├── mpd/              # MPD music daemon
├── ncmpcpp/          # ncmpcpp MPD client
├── ncspot/           # ncspot Spotify client
├── ohmyposh/         # Oh My Posh shell themes
├── tmux/             # tmux multiplexer
├── vim/              # Vim
├── yazi/             # yazi file manager
└── zsh/              # zsh shell
```

## License

BSD 3-Clause License. See [LICENSE](LICENSE) file.
