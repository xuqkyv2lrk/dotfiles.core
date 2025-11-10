<div align="center">
<img src="./dotfile.png" alt="dotfiles.core" width="120px" /> <br />
<h1>dotfiles.core</h1>
<p>My personal dotfiles and system setup automation.</p>

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![GitLab](https://img.shields.io/badge/GitLab-Main-orange.svg?logo=gitlab)](https://gitlab.com/wd2nf8gqct/dotfiles.core)
[![GitHub Mirror](https://img.shields.io/badge/GitHub-Mirror-black.svg?logo=github)](https://github.com/xuqkyv2lrk/dotfiles.core)
[![Codeberg Mirror](https://img.shields.io/badge/Codeberg-Mirror-2185D0.svg?logo=codeberg)](https://codeberg.org/iw8knmadd5/dotfiles.core)

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff&style=flat)](https://archlinux.org)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=flat&logo=ubuntu&logoColor=white)](https://ubuntu.com)

</div>

## What is this?

This is my automated system setup for Arch Linux and Ubuntu. It installs all the tools I use daily and configures them the way I like. One script does everything from package installation to shell configuration.

The setup works great on both desktop machines and headless systems like WSL or servers.

## Table of Contents
- [What is this?](#what-is-this)
- [Quick Start](#quick-start)
- [Installation Modes](#installation-modes)
- [What Gets Installed](#what-gets-installed)
- [Supported Systems](#supported-systems)
- [How It Works](#how-it-works)
- [Package Management](#package-management)
- [Hardware Support](#hardware-support)
- [Directory Structure](#directory-structure)
- [Configuration Files](#configuration-files)
- [Mirrors](#mirrors)
- [Desktop Integration](#desktop-integration)
- [License](#license)

## Quick Start

```bash
# Clone the repo
git clone https://gitlab.com/wd2nf8gqct/dotfiles.core.git ~/.dotfiles.core
cd ~/.dotfiles.core

# Full installation (desktop with GUI apps)
./provision.sh

# Minimal installation (CLI only, perfect for WSL/servers)
./provision.sh --minimal
```

That's it. The script handles everything else.

## Installation Modes

### Full Mode (Default)

Installs everything including GUI applications, media tools, and virtualization.

```bash
./provision.sh
```

**Includes:**
- All development tools and languages
- GUI applications (Firefox, Thunderbird, Bitwarden)
- Media players and music tools (MPD, ncmpcpp, cava)
- Virtualization stack (QEMU, libvirt, virt-manager)
- Desktop environment customization options

### Minimal Mode

For servers, WSL, containers, or any headless system. Skips GUI apps and VM tools.

```bash
./provision.sh --minimal
# or
./provision.sh --server
```

**Skips:**
- GUI applications (Firefox, Thunderbird, foot, 1Password, Bitwarden)
- Media tools (MPD, ncmpcpp, cava, mpv, ncspot)
- Virtualization (QEMU, libvirt, virt-manager, related networking)
- GUI-dependent utilities (Bluetooth, wl-clipboard)
- Desktop environment setup

**Still installs:**
- All CLI development tools (docker, kubectl, go, python, nodejs)
- Shell utilities (zsh, fzf, ripgrep, bat, eza, fd, jq, yq)
- Text editors (vim, doom emacs)
- System essentials (git, tmux, stow, rsync)
- Cloud tools (AWS CLI, kubectl)

## What Gets Installed

### Core Tools

**Shell**: ZSH with Oh My Posh for theming  
**Editors**: Vim with plugins, Doom Emacs  
**Terminal**: foot (Wayland), tmux multiplexer  
**Version Control**: Git with delta for better diffs  

### Development

**Languages**: Python, Go, Node.js, Rust (via rustup), GCC  
**Build Tools**: cmake, meson, make  
**Containers**: Docker with Compose and BuildX  
**Cloud**: kubectl, AWS CLI  

### CLI Utilities

**File Tools**: ranger (TUI file manager), eza (modern ls), fd (modern find)  
**Search**: ripgrep (faster grep), fzf (fuzzy finder)  
**Text**: bat (cat with syntax highlighting), jq/yq (JSON/YAML processors)  
**Navigation**: zoxide (smarter cd), direnv  
**Monitoring**: btop, fastfetch  

### GUI Apps (Full Mode Only)

**Browsers**: Firefox, Thunderbird  
**Music**: MPD + ncmpcpp + cava  
**Passwords**: 1Password, Bitwarden (both skipped in minimal mode)  

### Virtualization (Full Mode Only)

QEMU/KVM with libvirt, virt-manager for VM management

## Supported Systems

| Distribution | Full Support | Minimal/Server | Notes |
|--------------|--------------|----------------|-------|
| Arch Linux | Yes | Yes | Uses yay for AUR |
| Ubuntu | Yes | Yes | Custom PPAs for modern packages |
| Fedora | Legacy branch | Legacy branch | No longer maintained |
| openSUSE | Legacy branch | Legacy branch | No longer maintained |

Works great in WSL and ArchWSL with `--minimal` flag.

## How It Works

The script does the following:

1. Detects your distribution (Arch or Ubuntu)
2. Configures package repositories
3. Updates the system
4. Installs packages from `packages.yaml` with distro-specific handling
5. Installs additional tools (AWS CLI, Oh My Posh, tfenv, etc.)
6. Creates working directories (~/bin, ~/notes, ~/work)
7. Stows dotfile configurations
8. Sets up shell environment (ZSH, tmux, vim)
9. Configures hardware-specific settings if applicable
10. Optionally sets up desktop environment

## Package Management

Packages are defined in `packages.yaml` with smart exception handling:

```yaml
packages:
  - docker
  - python
  - firefox

exceptions:
  arch:
    docker: docker docker-buildx docker-compose
    python: python
  ubuntu:
    python: python3
    docker: docker.io docker-compose
```

The script automatically uses the right package names for your distribution.

## Hardware Support

**ThinkPad T480s**: Disables IR camera, applies power optimizations  
**ASUS ROG Laptops**: Installs ROG Control Center (Arch only)  
**All Systems**: Automatic timezone updates via NetworkManager

## Directory Structure

The script creates:

```
~/
├── bin/              # Your scripts and binaries
├── notes/tome/       # Note-taking space
└── work/
    ├── priming/      # System configs
    ├── projects/     # Active projects
    └── sandbox/      # Testing area
```

## Configuration Files

All configs are managed with GNU Stow for easy symlink management:

```
.dotfiles.core/
├── bat/              # Cat replacement config
├── btop/             # System monitor
├── delta/            # Git diff
├── doom/             # Emacs config
├── fastfetch/        # System info
├── foot/             # Terminal
├── gitconfig/        # Git settings
├── ohmyposh/         # Shell themes
├── ranger/           # File manager
├── tmux/             # Multiplexer
├── vim/              # Editor
└── zsh/              # Shell
```

## Mirrors

**Primary**: [GitLab](https://gitlab.com/wd2nf8gqct/dotfiles.core)  
**Mirrors**: [GitHub](https://github.com/xuqkyv2lrk/dotfiles.core), [Codeberg](https://codeberg.org/iw8knmadd5/dotfiles.core)

## Desktop Integration

For desktop environment setup and theming, check out [dotfiles.di](https://gitlab.com/wd2nf8gqct/dotfiles.di). The provision script will prompt you about desktop setup on full installations (skipped in minimal mode).

## License

BSD 3-Clause License. See [LICENSE](LICENSE) file.

---

<div align="center">
Built for my workflow, shared for yours.
</div>
