<div align="center">
<img src="./dotfile.png" alt="dotfiles.core" width="120px" /> <br />
<h1>dotfiles.core</h1>
<p>A personal collection of configurations and tools that match my workflow and preferences.</p>

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![GitLab](https://img.shields.io/badge/GitLab-Main-orange.svg?logo=gitlab)](https://gitlab.com/wd2nf8gqct/dotfiles.core)
[![GitHub Mirror](https://img.shields.io/badge/GitHub-Mirror-black.svg?logo=github)](https://github.com/xuqkyv2lrk/dotfiles.core)
[![Codeberg Mirror](https://img.shields.io/badge/Codeberg-Mirror-2185D0.svg?logo=codeberg)](https://codeberg.org/iw8knmadd5/dotfiles.core)

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff&style=flat)](https://archlinux.org)
[![Fedora](https://img.shields.io/badge/Fedora-294172?style=flat&logo=fedora&logoColor=white)](https://getfedora.org)
[![openSUSE Tumbleweed](https://img.shields.io/badge/openSUSE-Tumbleweed-%2364B345?style=flat&logo=openSUSE&logoColor=white)](https://get.opensuse.org/tumbleweed/)
</div>

<br />

<details>
<summary><h3>⚡ Before You Begin</h3></summary>

To ensure a smooth implementation:

- 🔍 Review and understand each configuration before applying
- 🧪 Test configurations in a safe environment first
- 💾 Maintain backups of your existing dotfiles
- ⚙️ Configurations assume specific workflows and tools
- 🛡️ All changes are implemented at your own risk

</details>

## 🛠️ Core Components

| Category               | Tools                                                                                                                                                            | Description                                                  |
|------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| 🖥️ Shell               | [ZSH](https://zsh.org/) with [Oh My Posh](https://ohmyposh.dev/)                                                                                                 | Modern shell with customizable prompt themes                 |
| 📝 Editors             | [Vim](https://www.vim.org/), [Doom Emacs](https://github.com/doomemacs/doomemacs)                                                                                | Customized text editors with extensive configurations        |
| 🔲 Terminal            | [foot](https://codeberg.org/dnkl/foot), [tmux](https://github.com/tmux/tmux)                                                                                     | Fast terminal emulator + multiplexer for efficient workflows |
| 🌐 Browser             | [Firefox](https://www.mozilla.org/firefox/)                                                                                                                      | Modern, privacy-focused web browser                          |
| 📂 Files               | [ranger](https://ranger.github.io/), [bat](https://github.com/sharkdp/bat)                                                                                       | TUI file manager + modern cat replacement                    |
| 📈 Version Control     | [Git](https://git-scm.com/)                                                                                                                                      | With delta diffing and custom configurations                 |
| 🎵 Music               | [MPD](https://www.musicpd.org/) + [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp), [ncspot](https://github.com/hrkfdn/ncspot)                                      | Music daemon with TUI client + Spotify TUI                   |
| 👨‍💻 Development | [Python](https://www.python.org/), [Go](https://go.dev/), [Node.js](https://nodejs.org/), [Ruby](https://www.ruby-lang.org/), [Rust](https://www.rust-lang.org/) | Complete development environment with multiple languages     |
| 🔄 Virtualization      | [QEMU](https://www.qemu.org/)/[KVM](https://www.linux-kvm.org/)                                                                                                  | Full virtualization stack with virt-manager                  |
| 🔒 Security            | [1password](https://1password.com/), [Bitwarden](https://bitwarden.com/)                                                                                         | Comprehensive password management solutions                  |

## 📋 Table of Contents
- [Overview](#overview)
  - [Features](#features)
  - [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Quick Start](#quick-start)
  - [Repository Mirrors](#repository-mirrors)
- [System Configuration](#system-configuration)
  - [Distribution Support](#distribution-support)
  - [Package Management](#package-management)
  - [Additional Tools](#additional-tools)
- [Automation Features](#automation-features)
  - [Tool Installation](#tool-installation)
  - [Environment Setup](#environment-setup)
  - [Hardware Support](#hardware-support)
- [Package Categories](#package-categories)
- [Repository Structure](#repository-structure)
- [License](#license)

## Overview
A minimalist yet powerful dotfiles framework built around my personal development workflow. It provides automated system provisioning across my preferred Linux distributions, focusing on the tools and configurations I use daily.

### Features
- 🔍 Support for my primary Linux distributions:
  - Arch Linux with AUR support via yay
  - Fedora with RPM Fusion
  - openSUSE Tumbleweed with appropriate repositories
- 📦 Curated selection of development tools and packages
- 🛠️ My preferred development environment setup:
  - Vim with custom plugin selection
  - Doom Emacs configuration
  - tmux with personalized settings
  - Shell customization via Oh My Posh
- 🌐 Location-aware timezone management
- 💻 Specific hardware support for my devices
- 🔒 Secure package management with verified sources

### Prerequisites
- Git
- sudo privileges
- One of the supported distributions:
  - Arch Linux
  - Fedora
  - openSUSE Tumbleweed

## Getting Started

### Quick Start
1. Clone the repository:
   ```bash
   # GitLab (primary)
   git clone https://gitlab.com/wd2nf8gqct/dotfiles.core.git .dotfiles.core
   cd .dotfiles.core
   ```

2. Review configurations:
   ```bash
   # Review package selections
   vim packages.yaml
   ```

3. Run the provisioning script:
   ```bash
   ./provision.sh
   ```

## System Configuration

### Distribution Support
Automatically detects and configures for:
- **Arch Linux**: Uses pacman with yay for AUR support
- **Fedora**: Uses dnf with additional repository configuration
- **openSUSE Tumbleweed**: Uses zypper with custom repository management

### Package Management
Centralized package configuration via `packages.yaml` for managing packages across different distributions. It handles package name differences and special installation sources through a simple, structured format:

```yaml
# List of packages to install
packages:
  - shellcheck
  - vim
  - htop

# Handle distribution-specific names
exceptions:
  opensuse-tumbleweed:
    shellcheck: ShellCheck
```

The structure is straightforward:
- List packages under `packages:`
- Define exceptions when package names differ
- Original name is used if no exception exists

### Additional Tools
Automated installation and configuration of:
- AWS CLI
- Oh My Posh
- tfenv
- Doom Emacs
- Vim plugins
- tmux plugin manager

## Automation Features

### Tool Installation
- **Package Managers**: Automated setup of distribution-specific package managers
- **Development Tools**: Installation of required development tools and runtimes
- **Shell Configuration**: Automatic ZSH configuration and plugin setup

### Environment Setup
Automated creation of working directory structure:
```
~/
├── notes/
│   └── tome/
└── work/
    ├── priming/
    ├── projects/
    └── sandbox/
```

### Hardware Support
- Automatic hardware detection for specific configurations
- ThinkPad-specific optimizations (e.g., IR camera management)
- NetworkManager integration for location-aware timezone updates

## Package Categories

| Category                 | Packages                                                                                                                         |
|--------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| Browsers & Communication | firefox, foot (terminal emulator), thunderbird                                                                                   |
| Development Tools        | dmidecode, docker-buildx, docker-compose, emacs, go, graphviz, kubectl, nodejs, npm, python, ruby, rustup, shellcheck, tmux, vim |
| Document Processing      | pandoc                                                                                                                           |
| File Management          | ranger                                                                                                                           |
| Media & Music            | cava (audio visualizer), mpc, mpd, ncmpcpp (music player), ncspot (Spotify client)                                               |
| Password Management      | 1password, bitwarden                                                                                                             |
| Shell Utilities          | bat, direnv, dyff, eza, fd, fzf, git-delta, htop, ripgrep, stow, unzip, wget, yq, zoxide                                         |
| System Utilities         | man, rsync, wireguard-tools, wl-clipboard, zsh                                                                                   |
| Virtualization           | libvirt, qemu, virt-install, virt-manager, virt-viewer                                                                           |

> Note: Package names may vary by distribution. See `packages.yaml` for distribution-specific mappings.

## Repository Structure

```
.dotfiles.core
├── bat           # Modern cat replacement configuration
├── cava          # Console-based audio visualizer config
├── docs          # Project documentation
├── doom          # Doom Emacs configuration
├── fonts         # Custom font files
├── foot          # Modern terminal emulator config
├── gitconfig     # Git configuration and aliases
├── LICENSE       # BSD 3-Clause license
├── ncmpcpp       # Music Player Client config
├── ncspot        # Terminal Spotify client config
├── ohmyposh      # Shell prompt customization
├── packages.yaml # Package definitions and exceptions
├── provision.sh  # Main system provisioning script
├── ranger        # Terminal file manager config
├── README.md     # Project documentation
├── tmux          # Terminal multiplexer config
├── vim           # Vim editor configuration
└── zsh           # Z shell configuration and plugins
```

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.
