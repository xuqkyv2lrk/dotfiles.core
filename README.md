<div align="center">
<img src="./dotfile.png" alt="dotfiles.core" width="120px" /> <br />
<h1>dotfiles.core</h1>
<p>A personal collection of configurations and tools that match my workflow and preferences.</p>

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![GitLab](https://img.shields.io/badge/GitLab-Main-orange.svg?logo=gitlab)](https://gitlab.com/wd2nf8gqct/dotfiles.core)
[![GitHub Mirror](https://img.shields.io/badge/GitHub-Mirror-black.svg?logo=github)](https://github.com/xuqkyv2lrk/dotfiles.core)
[![Codeberg Mirror](https://img.shields.io/badge/Codeberg-Mirror-2185D0.svg?logo=codeberg)](https://codeberg.org/iw8knmadd5/dotfiles.core)

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff&style=flat)](https://archlinux.org)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=flat&logo=ubuntu&logoColor=white)](https://ubuntu.com)

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
| 📝 Editors             | [Vim](https://www.vim.org/), [Emacs](https://www.gnu.org/software/emacs/) with [Doom](https://github.com/doomemacs/doomemacs)                                    | Customized text editors with extensive configurations        |
| 🔲 Terminal            | [foot](https://codeberg.org/dnkl/foot), [tmux](https://github.com/tmux/tmux)                                                                                     | Fast terminal emulator + multiplexer for efficient workflows |
| 🌐 Browser             | [Firefox](https://www.mozilla.org/firefox/), [Thunderbird](https://www.thunderbird.net)                                                                          | Modern browsers and email client                            |
| 📂 Files               | [ranger](https://ranger.github.io/), [eza](https://github.com/eza-community/eza)                                                                                 | TUI file manager + modern ls replacement                     |
| 📈 Version Control     | [Git](https://git-scm.com/) with [delta](https://github.com/dandavison/delta)                                                                                    | Enhanced Git experience with modern diffing                  |
| 🎵 Music               | [MPD](https://www.musicpd.org/) + [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp), [cava](https://github.com/karlstav/cava)                                       | Music daemon with TUI client + audio visualizer             |
| 👨‍💻 Development        | [Python](https://www.python.org/), [Go](https://go.dev/), [Node.js](https://nodejs.org/), [GCC](https://gcc.gnu.org/)      | Complete development environment with multiple languages     |
| 🔄 Virtualization      | [QEMU](https://www.qemu.org/)/[KVM](https://www.linux-kvm.org/), [libvirt](https://libvirt.org/)                                                                | Full virtualization stack with virt-manager                  |
| 🔒 Security            | [1Password](https://1password.com/), [Bitwarden](https://bitwarden.com/)                                                                                         | Comprehensive password management solutions                  |

## 📋 Table of Contents
- [Overview](#overview)
- [Getting Started](#getting-started)
- [System Configuration](#system-configuration)
- [Automation Features](#automation-features)
- [Package Categories](#package-categories)
- [Repository Structure](#repository-structure)
- [License](#license)

## Overview

A minimalist yet powerful dotfiles framework built around my personal development workflow. This setup provides automated system provisioning for Arch Linux and Ubuntu, focusing on the tools and configurations that power my daily development environment.

### Key Features

**🚀 Streamlined Installation**
- One-command setup for complete development environment
- Automatic distribution detection and package management
- Smart handling of distribution-specific package names and requirements

**🛠️ Curated Development Tools**
- Hand-picked selection of productivity tools and configurations
- Modern replacements for traditional Unix utilities
- Comprehensive development environment with multiple language support

**🎯 Hardware-Aware Configuration**
- Automatic hardware detection and optimization
- Specific support for ThinkPad T480s and ROG laptops
- Location-aware timezone management via NetworkManager

**🔒 Security-First Approach**
- Verified package sources and secure installation methods
- Multiple password manager integrations
- Proper system hardening configurations

### Supported Systems

| Distribution | Package Manager | AUR Support | Desktop Environment |
|--------------|-----------------|-------------|-------------------|
| **Arch Linux** | pacman + yay | ✅ Full AUR access | Optional selection |
| **Ubuntu** | apt | ✅ PPAs + custom repos | GNOME with PaperWM option |

> **Legacy Distribution Support**: Previous support for Fedora and openSUSE Tumbleweed has been moved to the `legacy-distros` branch. These distributions are no longer actively maintained.

## Getting Started

### Prerequisites
- Git installed on your system
- curl installed on your system
- sudo privileges
- One of the supported distributions (Arch Linux or Ubuntu)
- Active internet connection for package downloads

### Quick Installation

1. **Clone the repository**:
   ```bash
   # Using GitLab (primary)
   git clone https://gitlab.com/wd2nf8gqct/dotfiles.core.git ~/.dotfiles.core
   cd ~/.dotfiles.core
   ```

2. **Review the configuration** (optional but recommended):
   ```bash
   # Check which packages will be installed
   cat packages.yaml
   
   # Review the main provisioning script
   less provision.sh
   ```

3. **Run the installation**:
   ```bash
   ./provision.sh
   ```

The script will automatically:
- Detect your distribution and hardware
- Install required repositories and update the system
- Install all configured packages with distribution-specific handling
- Set up development tools and configurations
- Configure your shell environment
- Apply hardware-specific optimizations

### Repository Mirrors

| Platform | Purpose | URL |
|----------|---------|-----|
| **GitLab** | Primary repository | [gitlab.com/wd2nf8gqct/dotfiles.core](https://gitlab.com/wd2nf8gqct/dotfiles.core) |
| **GitHub** | Mirror | [github.com/xuqkyv2lrk/dotfiles.core](https://github.com/xuqkyv2lrk/dotfiles.core) |
| **Codeberg** | Mirror | [codeberg.org/iw8knmadd5/dotfiles.core](https://codeberg.org/iw8knmadd5/dotfiles.core) |

## System Configuration

### Distribution-Specific Features

**Arch Linux**:
- Automatic yay installation for AUR package management
- Conflict resolution (e.g., iptables removal for ebtables compatibility)
- ASUS ROG Linux repository integration for ROG hardware

**Ubuntu**:
- Custom repository setup for modern packages (1Password, kubectl, fastfetch)
- Foot terminal compiled from source with full Wayland support
- Bitwarden installation via direct .deb download (no Snap dependency)

### Package Management System

The `packages.yaml` file provides centralized package management with smart distribution-specific handling:

```yaml
packages:
  - firefox
  - docker
  - python

exceptions:
  arch:
    docker: docker docker-buildx docker-compose
    python: python
  
  ubuntu:
    python: python3
    docker: docker.io docker-compose
    fd: fd-find
```

**Special Handling**:
- Distribution-specific package names automatically resolved
- Custom installation procedures for complex packages
- Skip options for packages unavailable on certain distributions

### Additional Tools Installation

Beyond package managers, the system automatically installs:

| Tool | Purpose | Installation Method |
|------|---------|-------------------|
| **AWS CLI** | Cloud management | Direct download + install |
| **Oh My Posh** | Shell theming | Official installer script |
| **tfenv** | Terraform version management | Git clone to ~/bin |
| **dyff** | YAML diffing | GitHub release download |
| **Doom Emacs** | Enhanced Emacs config | Git clone + setup |
| **Atuin** | Shell history management | Official installer |
| **diff-so-fancy** | Enhanced git diffs | Git clone to /usr/local/bin |

## Automation Features

### Environment Setup

**Directory Structure Creation**:
```
~/
├── bin/              # User binaries and scripts
├── notes/
│   └── tome/        # Personal knowledge base
└── work/
    ├── priming/     # System setup and configuration files
    ├── projects/    # Active development projects
    └── sandbox/     # Testing and experimentation area
```

**Shell Configuration**:
- ZSH as default shell with Oh My Posh theming
- Atuin for enhanced shell history with sync capabilities
- Custom aliases and functions via stow-managed dotfiles

**Development Environment**:
- Vim with vim-plug and curated plugin selection
- Doom Emacs with personal configuration
- tmux with plugin manager and custom keybindings
- Git with delta for enhanced diffing and custom aliases

### Hardware-Specific Optimizations

**ThinkPad T480s**:
- IR camera disabled via udev rules (privacy and power savings)
- Power management optimizations

**ASUS ROG Laptops** (Arch Linux only):
- ASUS Linux repository integration
- asusctl, supergfxctl, and ROG Control Center installation
- Proper service enablement for hardware control

**Universal Features**:
- NetworkManager dispatcher for automatic timezone updates based on location
- libvirtd setup for virtualization management
- Bluetooth and wireless hardware support

### Desktop Interface Integration

**Ubuntu with GNOME**:
- Detects existing GNOME installation and offers custom configuration options
- Optional PaperWM installation for advanced tiling window management
- Integrates with [dotfiles.di](https://gitlab.com/wd2nf8gqct/dotfiles.di) repository for full desktop theming

**Arch Linux**:
- Prompts for desktop interface installation preference
- Delegates desktop environment setup to [dotfiles.di](https://gitlab.com/wd2nf8gqct/dotfiles.di) repository
- Provides foundation for desktop customization and theming

> **Note**: Desktop environment installation and theming is handled by the companion [dotfiles.di](https://gitlab.com/wd2nf8gqct/dotfiles.di) repository that focuses specifically on desktop interface customization and visual theming.

## Package Categories

### Core Development Tools
**Languages & Runtimes**: Python, Go, Node.js, Rust (via rustup)  
**Build Tools**: GCC, cmake, meson, make  
**Version Control**: Git with delta, git-delta for enhanced diffs  
**Containers**: Docker with BuildX and Compose  
**Cloud**: kubectl for Kubernetes, AWS CLI  

### System Utilities
**File Management**: ranger (TUI), eza (modern ls), fd (find replacement)  
**Text Processing**: bat (cat replacement), ripgrep (grep replacement), jq/yq (JSON/YAML)  
**Shell Enhancement**: zsh, tmux, fzf (fuzzy finder), zoxide (cd replacement)  
**System Monitoring**: btop (htop replacement), fastfetch (system info)  

### Media & Communication
**Browsers**: Firefox with custom configuration  
**Email**: Thunderbird with optimized settings  
**Music**: MPD + ncmpcpp + cava for complete audio experience  
**Terminal**: foot (Wayland-native) with tmux integration  

### Security & Privacy
**Password Managers**: 1Password and Bitwarden for comprehensive coverage  
**VPN**: WireGuard tools for secure networking  
**Firewall**: UFW for simplified iptables management  
**Development Security**: OpenSSL with development headers  

## Repository Structure

```
.dotfiles.core/
├── LICENSE               # BSD 3-Clause license
├── README.md             # This documentation
├── bat/                  # Modern cat replacement config
├── btop/                 # System monitor configuration
├── cava/                 # Audio visualizer settings
├── delta/                # Git diff enhancer config
├── doom/                 # Doom Emacs configuration
├── dotfile.png           # Repository logo
├── fastfetch/            # System info display config
├── fonts/                # Custom font files
├── foot/                 # Terminal emulator config
├── gitconfig/            # Git aliases and settings
├── ncmpcpp/              # Music player client config
├── ncspot/               # Spotify terminal client config
├── ohmyposh/             # Shell prompt themes
├── packages.yaml         # Package definitions and exceptions
├── provision.sh          # Main installation script
├── ranger/               # File manager configuration
├── tmux/                 # Terminal multiplexer setup
├── vim/                  # Vim editor configuration
└── zsh/                  # Z shell config and plugins
```

**Configuration Management**: All configurations are managed via [GNU Stow](https://www.gnu.org/software/stow/), enabling easy symlinking and updates of dotfiles.

## License

This project is licensed under the **BSD 3-Clause License** - see the [LICENSE](LICENSE) file for complete details.

---

<div align="center">
<strong>Built with ❤️ for productive development workflows</strong>
</div>
