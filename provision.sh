#!/usr/bin/env bash

set -eu

BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
NC="\033[0m"

DIREPO_RAW="https://gitlab.com/wd2nf8gqct/dotfiles.di/-/raw/main"

# Global variable to track PaperWM selection
use_paperwm="false"

# Global variable to track minimal/server installation mode
MINIMAL_MODE="false"

# Packages to skip in minimal/server mode
SKIP_PACKAGES=(
  # GUI Applications
  "firefox"
  "thunderbird"
  "foot"
  "bitwarden"
  "1password"
  
  # Media & Music
  "cava"
  "mpc"
  "mpd"
  "mpv"
  "ncmpcpp"
  "ncspot"
  
  # Virtualization
  "dnsmasq"
  "ebtables"
  "libvirt"
  "qemu"
  "virt-install"
  "virt-manager"
  "virt-viewer"
  
  # Hardware/GUI-dependent utilities
  "bluetooth"
  "wl-clipboard"
)

# Function: parse_arguments
# Description: Parses command-line arguments to determine installation mode
function parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --minimal|--server)
        MINIMAL_MODE="true"
        echo -e "${YELLOW}Running in minimal/server mode - skipping GUI applications and VM tools${NC}"
        shift
        ;;
      --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --minimal, --server    Install only CLI tools, skip GUI apps and VM tools"
        echo "  --help, -h            Show this help message"
        exit 0
        ;;
      *)
        echo -e "${RED}Unknown option: $1${NC}"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
  done
}

# Function: should_skip_package
# Description: Determines if a package should be skipped in minimal mode
# Parameters:
#   $1 - The package name
# Returns: 0 if should skip, 1 if should install
function should_skip_package() {
  local package="${1}"
  
  if [[ "${MINIMAL_MODE}" != "true" ]]; then
    return 1  # Don't skip in normal mode
  fi
  
  # Check if package is in global skip list
  for skip_pkg in "${SKIP_PACKAGES[@]}"; do
    if [[ "${package}" == "${skip_pkg}" ]]; then
      echo -e "${YELLOW}Skipping ${BOLD}${package}${NC}${YELLOW} (minimal mode)${NC}"
      return 0  # Skip this package
    fi
  done
  
  return 1  # Don't skip
}

# Function: detect_distro
# Description: Detects the Linux distribution of the current system.
# Returns: The ID of the detected distribution ("arch", "ubuntu", "legacy", "unsupported", or "unknown").
function detect_distro() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "${ID}" in
      arch|ubuntu)
        echo "${ID}"
        ;;
      fedora|opensuse-tumbleweed)
        echo "legacy"
        ;;
      *)
        echo "unsupported"
        ;;
    esac
  else
    echo "unknown"
  fi
}

# Function: detect_hardware
# Description: Detects the hardware model of the current system.
# Returns: The system model identifier (e.g., "ThinkPad T480s", "ROG") or "unknown" if not detected.
function detect_hardware() {
  if ! command -v dmidecode &> /dev/null; then
    echo "unknown"
    return
  fi
  local system_version
  local system_product
  system_version=$(sudo dmidecode -s system-version)
  system_product=$(sudo dmidecode -s system-product-name)
  if [[ "${system_version}" == "ThinkPad T480s" ]]; then
    echo "ThinkPad T480s"
  elif [[ "${system_product}" == *"ROG"* ]]; then
    echo "ROG"
  elif [[ "${system_product}" == "XPS 13 9350" ]]; then
    echo "XPS 13 9350"
  else
    echo "unknown"
  fi
}

# Function: get_packages
# Description: Gets the list of packages from packages.yaml, ignoring comments and empty lines.
# Returns: Array of package names.
function get_packages() {
  sed -n '/^packages:/,/^[^[:space:]#-]/{/^[[:space:]]*-[[:space:]]*\([^[:space:]#]\+\).*/!d; s/^[[:space:]]*-[[:space:]]*\([^[:space:]#]\+\).*/\1/p}' packages.yaml
}

# Function: get_package_name
# Description: Retrieves the package name for the defined distro, considering any exceptions defined in packages.yaml.
# Parameters:
#   $1 - The default package name
#   $2 - The distribution ID
# Returns: The package name to use for installation
function get_package_name() {
    local package="$1"
    local distro="$2"
    local package_name="${package}"

    if grep -q "^exceptions:" packages.yaml; then
        if grep -q "^  ${distro}:" packages.yaml; then
            local exception
            exception=$(sed -n "/^  ${distro}:/,/^  [^ ]/p" packages.yaml | grep "^    ${package}:" | cut -d ':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*#.*//;s/[[:space:]]*$//')
            if [[ -n "${exception}" ]]; then
                package_name="${exception}"
            fi
        fi
    fi

    echo "${package_name}"
}

# Function: system_update
# Description: Updates the system using the appropriate package manager.
# Parameters:
#   $1 - The distribution ID
function system_update() {
  local distro="${1}"
  echo -e "\n${BLUE}Updating ${BOLD}${distro}${NC}"
  case "${distro}" in
    "arch")
      sudo pacman -Syu --noconfirm
      ;;
    "ubuntu")
      sudo apt-get update -y
      sudo apt-get dist-upgrade -y
      ;;
    *)
      echo "Unsupported distribution: ${distro}"
      ;;
  esac
}

# Function: install_repos
# Description: Installs additional repositories based on the detected distribution.
# Parameters:
#   $1 - The distribution ID
function install_repos() {
  local distro="${1}"
  case "${distro}" in
    "arch")
      # Update mirrors using reflector for faster downloads
      echo -e "\n${BLUE}Updating Arch mirrors with reflector...${NC}"
      sudo pacman -S --needed --noconfirm reflector
      
      # Use US mirrors sorted by age (most recently synced)
      echo -e "${YELLOW}Selecting fastest US mirrors...${NC}"
      sudo reflector --country US --latest 10 --protocol https --sort age --download-timeout 10 --save /etc/pacman.d/mirrorlist
      echo -e "${GREEN}Using recently synced US mirrors${NC}"
      
      # Install yay if not already installed
      if ! command -v yay &> /dev/null; then
        echo -e "\n${YELLOW}Installing yay...${GREEN}"
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd - > /dev/null
        rm -rf yay
      fi
      # Remove iptables if installed as it conflicts with ebtables
      if yay -Qi iptables 2>/dev/null | grep -q "^Name\s*: iptables$"; then
        echo -e "\n${MAGENTA}Removing conflicting package ${BOLD}iptables${NC}"
        yay -Rdd --noconfirm iptables
      fi
      # 1Password, Docker, and kubectl can be installed via yay
      ;;
    "ubuntu")
      # 1Password repository and key
      if [[ "${MINIMAL_MODE}" != "true" ]]; then
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --yes --output /usr/share/keyrings/1password-archive-keyring.gpg
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
        sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
        curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null
        sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --yes --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
      fi

      # fastfetch PPA
      sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch

      # kubectl (Kubernetes) repository and key
      local latest_version
      latest_version=$(curl -s https://api.github.com/repos/kubernetes/kubernetes/releases/latest | grep tag_name | cut -d '"' -f 4)
      local latest_minor_version
      latest_minor_version=$(echo "${latest_version}" | grep -oE 'v1\.[0-9]+')
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL "https://pkgs.k8s.io/core:/stable:/${latest_minor_version}/deb/Release.key" | sudo gpg --dearmor --yes --output /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${latest_minor_version}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
      ;;
    *)
      echo "Unsupported distribution: ${distro}"
      ;;
  esac
}

# Function: install_foot_ubuntu
# Description: Installs the Foot terminal emulator on Ubuntu. Tries apt first
#              (available in Ubuntu 24.04 universe), then falls back to building
#              from source. The source build requires several -dev packages that
#              can conflict with security-patched runtime libs during Ubuntu repo
#              timing gaps, so apt is always preferred when available.
# Side effects: Installs packages, and optionally builds foot and installs terminfo.
function install_foot_ubuntu() {
  echo -e "\n${MAGENTA}Installing ${BOLD}foot${NC}"

  # Skip if already installed (e.g. prior source build or apt install)
  if command -v foot &>/dev/null; then
    echo -e "${YELLOW}foot is already installed, skipping${NC}"
    return
  fi

  # Try apt first (available in Ubuntu 24.04 universe). Avoids pulling in -dev
  # packages that may have strict version deps conflicting with security-patched
  # runtime libs.
  if sudo apt-get install -y foot 2>/dev/null; then
    echo -e "${GREEN}foot installed via apt${NC}"
    return
  fi

  # Fall back to building from source
  echo -e "${YELLOW}foot not available via apt, building from source...${NC}"

  # Install build dependencies
  echo -e "${YELLOW}Installing build dependencies for Foot...${NC}"
  sudo apt-get update
  sudo apt-get install -y \
    build-essential meson ninja-build pkg-config wayland-protocols \
    libwayland-dev libxkbcommon-dev libpixman-1-dev libfcft-dev libutf8proc-dev \
    libfontconfig1-dev libpam0g-dev scdoc git

  # Clone and build Foot
  echo -e "${YELLOW}Cloning Foot repository...${NC}"
  git clone https://codeberg.org/dnkl/foot.git /tmp/foot
  cd /tmp/foot

  echo -e "${YELLOW}Building Foot...${NC}"
  meson setup build
  ninja -C build

  echo -e "${GREEN}Installing Foot...${NC}"
  sudo ninja -C build install

  # Cleanup
  cd -
  rm -rf /tmp/foot
}

# Function: patch_foot_config_ubuntu
# Description: Patches the deployed foot config for Ubuntu 24.04 (foot 1.16.x).
#              foot 1.17 introduced resize-by-cells, cursor.unfocused-style, and
#              [colors-dark]/[colors-light] sections. Ubuntu noble ships 1.16.2 and
#              errors on these options at startup.
#
#              stow symlinks the entire ~/.config/foot directory to the dotfiles
#              source, so we can't patch just the deployed copy without first
#              replacing the symlink with a real directory. This function does that,
#              then applies the patches in-place. The dotfiles source is untouched,
#              so the 1.17 options are ready to restore when foot is upgraded.
function patch_foot_config_ubuntu() {
    local foot_dir="${HOME}/.config/foot"
    local config="${foot_dir}/foot.ini"
    local foot_version

    foot_version="$(foot --version 2>/dev/null | awk '{print $3}')"

    # Only patch when foot is older than 1.17
    local major minor
    major="$(echo "${foot_version}" | cut -d. -f1)"
    minor="$(echo "${foot_version}" | cut -d. -f2)"
    if [[ "${major}" -gt 1 || ( "${major}" -eq 1 && "${minor}" -ge 17 ) ]]; then
        return 0
    fi

    echo -e "${YELLOW}foot ${foot_version} detected — patching config for 1.16.x compatibility${NC}"

    # stow creates ~/.config/foot as a symlink to the package source directory.
    # Replace it with a real directory containing copies of all files so that
    # edits here do not propagate back to the dotfiles source.
    if [[ -L "${foot_dir}" ]]; then
        local stow_target
        stow_target="$(readlink -f "${foot_dir}")"
        local tmp_dir
        tmp_dir="$(mktemp -d)"
        cp -a "${stow_target}/." "${tmp_dir}/"
        rm "${foot_dir}"
        mv "${tmp_dir}" "${foot_dir}"
    fi

    [[ -f "${config}" ]] || return 0

    # Comment out resize-by-cells (1.17+)
    sed -i 's/^resize-by-cells=no/# resize-by-cells=no  # foot 1.17+; re-enable after upgrade/' "${config}"
    # Comment out cursor.unfocused-style (1.17+)
    sed -i 's/^unfocused-style=none/# unfocused-style=none  # foot 1.17+; re-enable after upgrade/' "${config}"
    # Rename [colors-dark] to [colors] (1.17 splits into light/dark sections)
    sed -i 's/^\[colors-dark\]/[colors] # was [colors-dark]; rename back after foot upgrade/' "${config}"
}

# Function: install_package
# Description: Installs a package using the appropriate package manager.
# Parameters:
#   $1 - The package name
#   $2 - The distribution ID
function install_package() {
  local package="${1}"
  local distro="${2}"
  
  # Check if package should be skipped
  if should_skip_package "${package}"; then
    return
  fi
  
  local package_name
  package_name=$(get_package_name "${package}" "${distro}")
  
  if [[ "${package_name}" == "skip" ]]; then
    return
  fi

  # Special case for Foot on Ubuntu
  if [[ "${package_name}" == "foot" && "${distro}" == "ubuntu" ]]; then
    install_foot_ubuntu
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y foot-terminfo
    return
  fi

  # Special case for Bitwarden on Ubuntu (no Snap)
  if [[ "${package_name}" == "bitwarden" && "${distro}" == "ubuntu" ]]; then
    if dpkg -l bitwarden 2>/dev/null | grep -q "^ii"; then
      echo -e "\n${YELLOW}bitwarden is already installed, skipping${NC}"
      return
    fi
    echo -e "\n\e[35mInstalling \e[1mBitwarden (.deb)\e[0m"
    wget -O /tmp/Bitwarden-latest.deb "https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb"
    sudo dpkg -i /tmp/Bitwarden-latest.deb || sudo apt-get -f install -y
    rm /tmp/Bitwarden-latest.deb
    return
  fi
  
  echo -e "\n\e[35mInstalling \e[1m${package_name}\e[0m"
  case "${distro}" in
    "arch")
      # shellcheck disable=SC2086
      yay -S --noconfirm ${package_name}
      ;;
    "ubuntu")
      # shellcheck disable=SC2086
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ${package_name}
      ;;
    *)
      echo "Unsupported distribution: ${distro}"
      ;;
  esac
}

# Function: create_working_dirs
# Description: Creates necessary working directories in the user's home folder.
# Side effects: Creates directories for notes, work projects, and sandboxes
function create_working_dirs() {
  local required_dirs=(
    "${HOME}/bin"
    "${HOME}/notes/tome"
    "${HOME}/work/priming"
    "${HOME}/work/projects"
    "${HOME}/work/sandbox"
  )
  for d in "${required_dirs[@]}"; do
    if [[ ! -d "${d}" ]]; then
      mkdir -p "${d}"
      echo -e "\n\e[35mCreated directory \e[1m${d}\e[0m"
    fi
  done
  # Export paths needed for provisioning script during session
  export PATH="${HOME}/bin:${HOME}/.emacs.d/bin:${HOME}/.atuin/bin:${PATH}"
}

# Function: install_binaries
# Description: Installs binary packages that are not available through standard package managers.
# Side effects: Installs aws-cli, dyff, oh-my-posh, tfenv, and doom emacs if not already present.
function install_binaries() {
  local binary_installed=false

  # aws-cli
  if ! command -v aws &> /dev/null; then
    echo -e "\n\e[35mInstalling \e[1maws-cli\e[0;32m"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    binary_installed=true
  fi

  # dyff
  if ! command -v dyff &> /dev/null; then
    curl -s --location https://git.io/JYfAY | bash
  fi

  # diff-so-fancy
  if ! command -v diff-so-fancy &>/dev/null; then
    echo -e "\n\e[35mInstalling \e[1mdiff-so-fancy\e[0;32m"
    git clone https://github.com/so-fancy/diff-so-fancy.git /tmp/diff-so-fancy
    sudo cp /tmp/diff-so-fancy/diff-so-fancy /usr/local/bin/
    sudo cp -r /tmp/diff-so-fancy/lib /usr/local/bin/
    rm -rf /tmp/diff-so-fancy
  fi

  # Oh My Posh
  if ! command -v oh-my-posh &> /dev/null; then
    echo -e "\n\e[35mInstalling \e[1moh-my-posh\e[0;32m"
    curl -s https://ohmyposh.dev/install.sh | bash -s
    binary_installed=true
  fi

  # tfenv
  if ! command -v tfenv &> /dev/null; then
    echo -e "\n\e[35mInstalling \e[1mtfenv\e[0;32m"
    git clone --depth 1 --filter=blob:none --sparse https://github.com/tfutils/tfenv.git /tmp/tfenv
    cd /tmp/tfenv
    git sparse-checkout set bin
    mv bin/* "${HOME}/bin"
    cd - > /dev/null  # Return to previous directory
    rm -rf /tmp/tfenv
    binary_installed=true
  fi

  # sops
  if ! command -v sops &> /dev/null; then
    echo -e "\n\e[35mInstalling \e[1msops\e[0;32m"
    local sops_version
    sops_version=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -sLo /tmp/sops "https://github.com/getsops/sops/releases/download/${sops_version}/sops-${sops_version}.linux.amd64"
    sudo install -m 755 /tmp/sops /usr/local/bin/sops
    rm /tmp/sops
    binary_installed=true
  fi

  # yazi (not in Ubuntu apt repos — install pre-built static binary from GitHub)
  if ! command -v yazi &>/dev/null; then
    echo -e "\n\e[35mInstalling \e[1myazi\e[0;32m"
    local yazi_version
    yazi_version=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep '"tag_name"' | cut -d '"' -f4)
    local yazi_tmp
    yazi_tmp=$(mktemp -d)
    curl -sL "https://github.com/sxyazi/yazi/releases/download/${yazi_version}/yazi-x86_64-unknown-linux-musl.zip" \
        -o "${yazi_tmp}/yazi.zip"
    unzip -q "${yazi_tmp}/yazi.zip" -d "${yazi_tmp}"
    sudo install -m 755 "${yazi_tmp}/yazi-x86_64-unknown-linux-musl/yazi" /usr/local/bin/yazi
    sudo install -m 755 "${yazi_tmp}/yazi-x86_64-unknown-linux-musl/ya" /usr/local/bin/ya
    rm -rf "${yazi_tmp}"
    binary_installed=true
  fi

  # helm
  if ! command -v helm &> /dev/null; then
    echo -e "\n\e[35mInstalling \e[1mhelm\e[0;32m"
    curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    binary_installed=true
  fi

  # flux
  if ! command -v flux &> /dev/null; then
    echo -e "\n\e[35mInstalling \e[1mflux\e[0;32m"
    curl -s https://fluxcd.io/install.sh | sudo bash
    binary_installed=true
  fi

  # talosctl
  if ! command -v talosctl &> /dev/null; then
    echo -e "\n\e[35mInstalling \e[1mtalosctl\e[0;32m"
    curl -sL https://talos.dev/install | sh
    binary_installed=true
  fi

  # doom emacs
  if ! command -v doom &> /dev/null; then
    echo -e "\n\e[35mInstalling \e[1mdoom emacs\e[0;32m"
    git clone --depth 1 https://github.com/doomemacs/doomemacs "${HOME}/.emacs.d"
    binary_installed=true
  fi

  if [[ "${binary_installed}" == false ]]; then
    echo -e "\e[1;37mNo new binaries to install.\e[0m"
  fi
}


# Function: install_tmux_plugins
# Description: Installs and sets up tmux plugins.
# Side effects: Clones tmux plugin manager and installs configured plugins
function install_tmux_plugins() {
  echo -e "\n\e[1;37mInstall tmux plugins...\e[0;32m"
  if [[ ! -d "${HOME}/.tmux/plugins/tpm" ]]; then
    git clone "https://github.com/tmux-plugins/tpm" "${HOME}/.tmux/plugins/tpm"
  fi
  bash "${HOME}/.tmux/plugins/tpm/scripts/install_plugins.sh"
}


# Function: create_nm_dispatcher
# Description: Creates a NetworkManager dispatcher script for automatic timezone updates.
# Side effects: Creates a new script at /etc/NetworkManager/dispatcher.d/09-timezone.sh
function create_nm_dispatcher() {
  if [[ ! -f "/etc/NetworkManager/dispatcher.d/09-timezone.sh" ]]; then
    echo -e "\n\e[1;37mCreating NetworkManager dispatcher for Timezone changes...\e[0;32m"
    sudo mkdir -p "/etc/NetworkManager/dispatcher.d"
    sudo tee "/etc/NetworkManager/dispatcher.d/09-timezone.sh" > /dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
function log() {
  logger -t "timezone-update" "$1"
}
function update_timezone() {
  local new_timezone
  new_timezone=$(curl --fail --silent --show-error "https://ipapi.co/timezone")
  if [[ -n "${new_timezone}" ]]; then
    timedatectl set-timezone "${new_timezone}"
    log "Timezone updated to ${new_timezone}"
  else
    log "Failed to fetch timezone"
  fi
}
case "$2" in
  connectivity-change)
    update_timezone
    ;;
esac
EOF
    sudo chmod +x "/etc/NetworkManager/dispatcher.d/09-timezone.sh"
    sudo systemctl enable --now NetworkManager-dispatcher
  fi
}


# Function: configure_hardware_specific
# Description: Applies hardware-specific configurations.
# Parameters:
#   $1 - The hardware model
#   $2 - The distribution ID
function configure_hardware_specific() {
  local hardware="${1}"
  local distro="${2}"
  case "${hardware}" in
    "ThinkPad T480s")
      sudo tee /etc/udev/rules.d/80-lenovo-ir-camera.rules > /dev/null << EOF
SUBSYSTEM=="usb", ATTRS{idVendor}=="04f2", ATTRS{idProduct}=="b615", ATTR{authorized}="0"
EOF
      echo -e "\n\e[1;37mDisabled IR camera for \e[1;33mThinkPad T480s\e[1;37m\e[0;32m"
      ;;
    "ROG")
      case "${distro}" in
        "arch")
          echo -e "\n${BLUE}Installing packages for ${BOLD}ASUS ROG Linux${NC}"
          sudo pacman-key --recv-keys 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
          sudo pacman-key --finger 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
          sudo pacman-key --lsign-key 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
          sudo pacman-key --finger 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
          if ! grep -q "^\[g14\]" "/etc/pacman.conf"; then
            echo -e "\n[g14]\nServer = https://arch.asus-linux.org" | sudo tee -a /etc/pacman.conf > /dev/null
            yay -Syu
          fi
          sudo pacman -S --noconfirm asusctl supergfxctl rog-control-center
          sudo systemctl enable asusd
          sudo systemctl enable supergfxd
          ;;
        *)
          echo -e "\n${YELLOW}Warning: ROG-specific packages are not configured for this distribution${NC}"
          ;;
      esac
      echo -e "\n${BLUE}ROG packages installed. You can configure your device using ROG Control Center.${NC}"
      ;;
    "XPS 13 9350")
      local script_dir
      script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      local firmware_src="${script_dir}/system_components/xps_13_9350/bluetooth/BCM4350C5_003.006.007.0095.1703.hcd"
      local firmware_dst="/lib/firmware/brcm/BCM4350C5-0a5c-6412.hcd"
      print_step "Configuring Bluetooth firmware for XPS 13 9350"
      [[ ! -d "/lib/firmware/brcm" ]] && sudo mkdir -p /lib/firmware/brcm
      sudo cp -f "${firmware_src}" "${firmware_dst}"
      print_success "Bluetooth firmware installed"
      ;;
    *)
      echo -e "\n\e[1;37mNo hardware-specific configurations needed for this model\e[0m"
      ;;
  esac
}

# Function: select_desktop_interface
# Description: Prompts the user to select a desktop configuration to apply.
#              On Ubuntu, GNOME is already present so we ask how to configure it
#              (apply dotfiles + optional PaperWM, or replace with Niri) rather
#              than asking whether to "install" a desktop. On Arch, presents the
#              full list of available desktop interfaces from packages.yaml.
#              DE-specific options (Quickshell, PaperWM) are handled by install.sh.
#              In minimal mode, skips selection entirely.
function select_desktop_interface() {
    local __choice=$1
    local distro
    distro=$(detect_distro)

    # Skip desktop interface selection in minimal mode
    if [[ "${MINIMAL_MODE}" == "true" ]]; then
        echo -e "\n${YELLOW}Skipping desktop interface installation (minimal mode)${NC}"
        return
    fi

    if [[ "${distro}" == "ubuntu" ]]; then
        # Ubuntu ships with GNOME — we are configuring it, not installing a DE.
        echo -e "\n${BLUE}${BOLD}How would you like to configure your desktop?${NC}"
        echo -e "${BLUE}Ubuntu includes GNOME by default.${NC}"
        select de in "Configure GNOME (+ optional PaperWM)" "Install Niri (Wayland compositor)" "Skip"; do
            case "${de}" in
                "Configure GNOME (+ optional PaperWM)")
                    eval "${__choice}"="gnome"
                    return
                    ;;
                "Install Niri (Wayland compositor)")
                    eval "${__choice}"="niri"
                    return
                    ;;
                "Skip")
                    printf "\nSkipping desktop configuration.\n"
                    exit
                    ;;
                *)
                    echo -e "\n${RED}Invalid option. Please try again.${NC}\n"
                    ;;
            esac
        done
    else
        echo -e "\n${BLUE}${BOLD}Do you want to install a desktop interface?${NC}"
        select choice in "Yes" "No"; do
            case ${choice} in
                "Yes")
                    echo -e "\n${BLUE}${BOLD}Please select a desktop interface:${NC}"
                    local options
                    mapfile -t options < <(curl -sSL "${DIREPO_RAW}/packages.yaml" | yq -e '.desktop_packages | keys | .[]' | tr -d '"')
                    select de in "${options[@]}"; do
                        if [[ -n "${de}" ]]; then
                            eval "${__choice}"="${de}"
                            return
                        else
                            echo -e "\n${RED}Invalid option. Please try again.${NC}\n"
                        fi
                    done
                    ;;
                "No")
                    printf "\nSkipping desktop interface installation.\n"
                    exit
                    ;;
                *)
                    echo -e "\n${RED}Invalid option. Please try again.${NC}\n"
                    ;;
            esac
        done
    fi
}

# Function: install_rust
# Description: Installs Rust and the ncspot package.
# Side effects: Installs rustup, sets up the Rust environment.
function install_rust() {
  # Check if Rust is already installed and configured
  if command -v rustup &> /dev/null && command -v cargo &> /dev/null; then
    echo -e "\n${YELLOW}Rust is already installed, skipping installation${NC}"
    # Still ensure the stable toolchain is set
    rustup default stable
  else
    echo -e "\n${MAGENTA}Installing ${BOLD}rustup${NC}"
    # Install with --no-modify-path to prevent automatic shell config modification
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    # shellcheck source=/dev/null
    . "${HOME}/.cargo/env"
    rustup default stable
    
    # Manually add cargo to .zshenv only if not already present
    if [[ -f "${HOME}/.zshenv" ]] && ! grep -q ".cargo" "${HOME}/.zshenv"; then
      echo -e "\n# Rust" >> "${HOME}/.zshenv"
      # shellcheck disable=SC2016
      echo 'path=("${HOME}/.cargo/bin" $path)' >> "${HOME}/.zshenv"
    fi
  fi
}

# Function: install_media_tools
# Description: Installs media processing tools not available via package managers
# Parameters:
#   $1 - The distribution ID
# Side effects: Installs yt-dlp (Ubuntu) and ffmpeg-lh (all distros)
function install_media_tools() {
  local distro="${1}"
  echo -e "\n${MAGENTA}Installing media processing tools${NC}"
  
  # Install yt-dlp on Ubuntu (Arch gets it from pacman)
  if [[ "${distro}" == "ubuntu" ]]; then
    if ! command -v yt-dlp &> /dev/null; then
      echo -e "${BLUE}Installing ${BOLD}yt-dlp${NC} ${BLUE}via pip${NC}"
      pip3 install --user yt-dlp
    else
      echo -e "${YELLOW}yt-dlp already installed${NC}"
    fi
  fi
  
  # Install ffmpeg-lh via cargo (not in any package manager)
  if ! command -v ffmpeg-lh &> /dev/null; then
    echo -e "${BLUE}Installing ${BOLD}ffmpeg-lh${NC} ${BLUE}via cargo${NC}"
    # Ensure cargo is in PATH for this session
    if [[ -f "${HOME}/.cargo/env" ]]; then
      # shellcheck source=/dev/null
      . "${HOME}/.cargo/env"
    fi
    cargo install --git https://github.com/indiscipline/ffmpeg-loudnorm-helper.git
  else
    echo -e "${YELLOW}ffmpeg-lh already installed${NC}"
  fi
  
  echo -e "${GREEN}Media processing tools installed${NC}"
}

# Function: configure_uv1_audio
# Description: Creates modprobe configuration for the Universal Audio UV1
#              interface to fix audio playback issues.
# Side effects: Creates /etc/modprobe.d/uv1-audio.conf and reloads the
#               snd-usb-audio kernel module.
function configure_uv1_audio() {
  local conf_file="/etc/modprobe.d/uv1-audio.conf"
  local conf_content="options snd_usb_audio implicit_fb=1 ignore_ctl_error=1 autoclock=0 quirk_flags=0x1397:0x0510:0x40"

  if [[ ! -f "${conf_file}" ]]; then
    echo -e "\n${MAGENTA}Configuring ${BOLD}UV1 audio interface${NC}"
    echo "${conf_content}" | sudo tee "${conf_file}" > /dev/null
    if sudo modprobe -r snd-usb-audio 2>/dev/null && sudo modprobe snd-usb-audio 2>/dev/null; then
      echo -e "${GREEN}UV1 audio configuration applied${NC}"
    else
      echo -e "${YELLOW}UV1 config written but module reload failed (device may be in use).${NC}"
      echo -e "${YELLOW}To apply without rebooting, unplug the UV1 and run:${NC}"
      echo -e "${YELLOW}  sudo modprobe -r snd-usb-audio && sudo modprobe snd-usb-audio${NC}"
    fi
  else
    echo -e "\n${YELLOW}UV1 audio configuration already present, skipping${NC}"
  fi
}


# Function: hardware_setup
# Description: Detects hardware and applies specific configurations.
# Parameters:
#   $1 - The distribution ID
# Side effects: Calls configure_hardware_specific if hardware is detected.
# Function: add_kernel_parameter
# Description: Appends a kernel parameter to the active bootloader config
#              (systemd-boot or GRUB). Skips if already present. Idempotent.
# Parameters:
#   $1 - The kernel parameter to add (e.g. "mem_sleep_default=s2idle")
# Function: find_systemd_boot_entries
# Description: Returns the systemd-boot loader entries directory if systemd-boot
#              is installed, regardless of where the ESP is mounted.
#              Checks via bootctl first, then falls back to common mount points.
function find_systemd_boot_entries() {
    local esp=""
    if command -v bootctl &>/dev/null && bootctl is-installed &>/dev/null; then
        esp=$(bootctl --print-esp-path 2>/dev/null)
    fi
    # Fallback: common ESP mount points
    if [[ -z "${esp}" ]]; then
        for mount_point in /boot /efi /boot/efi; do
            if [[ -d "${mount_point}/loader/entries" ]]; then
                esp="${mount_point}"
                break
            fi
        done
    fi
    if [[ -n "${esp}" && -d "${esp}/loader/entries" ]]; then
        echo "${esp}/loader/entries"
    fi
}

# Function: add_kernel_parameter
# Description: Appends a kernel parameter to the active bootloader config
#              (systemd-boot or GRUB). Skips if already present. Idempotent.
# Parameters:
#   $1 - The kernel parameter to add (e.g. "mem_sleep_default=s2idle")
function add_kernel_parameter() {
    local param="${1}"
    local distro
    distro=$(detect_distro)

    local entries_dir
    entries_dir=$(find_systemd_boot_entries)

    if [[ -n "${entries_dir}" ]]; then
        local updated=0
        for entry in "${entries_dir}"/*.conf; do
            [[ "${entry}" == *fallback* ]] && continue
            if [[ -z "$(grep -w "${param}" "${entry}" 2>/dev/null)" ]]; then
                sudo sed -i "/^options / s/$/ ${param}/" "${entry}"
                echo -e "${GREEN}Added '${param}' to ${entry}${NC}"
                updated=1
            fi
        done
        [[ "${updated}" -eq 0 ]] && echo -e "${YELLOW}'${param}' already present in systemd-boot entries${NC}"
    elif [[ -f /etc/default/grub ]]; then
        if [[ -z "$(grep -w "${param}" /etc/default/grub 2>/dev/null)" ]]; then
            sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"${param} /" /etc/default/grub
            if [[ "${distro}" == "ubuntu" ]]; then
                sudo update-grub
            else
                sudo grub-mkconfig -o /boot/grub/grub.cfg
            fi
            echo -e "${GREEN}Added '${param}' to GRUB config${NC}"
        else
            echo -e "${YELLOW}'${param}' already present in GRUB config${NC}"
        fi
    else
        echo -e "${YELLOW}No supported bootloader config found. Add '${param}' manually.${NC}" >&2
    fi
}

# Function: configure_sleep_state
# Description: Detects S0ix (Modern Standby) hardware support and optionally
#              enables it via a kernel parameter. Prompts the user if supported.
#              Skipped in minimal mode or if already configured.
function configure_sleep_state() {
    if [[ "${MINIMAL_MODE}" == "true" ]]; then
        return
    fi

    if [[ ! -f /sys/power/mem_sleep ]]; then
        return
    fi

    # Already using s2idle — nothing to do
    if grep -q "\[s2idle\]" /sys/power/mem_sleep 2>/dev/null; then
        echo -e "\n${GREEN}S0ix (Modern Standby) already active.${NC}"
        return
    fi

    # s2idle listed but not selected — hardware supports it
    if ! grep -q "s2idle" /sys/power/mem_sleep 2>/dev/null; then
        echo -e "\n${YELLOW}S0ix (Modern Standby) not supported on this hardware — keeping S3.${NC}"
        return
    fi

    echo -e "\n${BLUE}${BOLD}S0ix (Modern Standby) is supported on this hardware.${NC}"
    echo -e "${BLUE}S0ix enables faster resume and allows the system to wake on events${NC}"
    echo -e "${BLUE}such as plugging in an external monitor while the lid is closed.${NC}"
    echo -e "${YELLOW}Trade-off: may increase battery drain while suspended on some hardware.${NC}"
    echo -e "${YELLOW}It is well-supported on recent Intel and AMD Ryzen 6000+ laptops.${NC}"

    select choice in "Enable S0ix (Modern Standby)" "Keep S3 (Suspend-to-RAM)"; do
        case ${choice} in
            "Enable S0ix (Modern Standby)")
                add_kernel_parameter "mem_sleep_default=s2idle"
                echo -e "\n${GREEN}S0ix enabled. Reboot to apply.${NC}"
                return
                ;;
            "Keep S3 (Suspend-to-RAM)")
                echo -e "\n${YELLOW}Keeping S3 suspend.${NC}"
                return
                ;;
            *)
                echo -e "\n${RED}Invalid option. Please try again.${NC}\n"
                ;;
        esac
    done
}

function hardware_setup() {
  local distro="${1}"
  local hardware
  hardware=$(detect_hardware)
  if [[ "${hardware}" != "unknown" ]]; then
    echo -e "\n\e[33mDetected hardware: \e[1m${hardware}\e[0m"
    configure_hardware_specific "${hardware}" "${distro}"
  else
    echo -e "\n${BLUE}No hardware-specific configurations needed${NC}"
  fi
}

# Function: post_install_configure
# Description: Performs post-installation configuration tasks.
# Side effects: Sets up doom emacs, rebuilds bat cache, installs VIM plugins, enables libvirtd, and updates the user's shell to zsh.
function post_install_configure() {
  # Sync doom emacs configuration and packages
  echo -e "\n\e[1;37mSetting up doom emacs...\e[0;32m"
  
  # Add doom bin directory to PATH for this session
  local doom_bin_path=""
  if [[ -d "${HOME}/.config/emacs/bin" ]]; then
    export PATH="${HOME}/.config/emacs/bin:${PATH}"
    doom_bin_path="${HOME}/.config/emacs/bin/doom"
  elif [[ -d "${HOME}/.emacs.d/bin" ]]; then
    export PATH="${HOME}/.emacs.d/bin:${PATH}"
    doom_bin_path="${HOME}/.emacs.d/bin/doom"
  fi
  
  # Check if doom binary actually exists
  if [[ -n "${doom_bin_path}" ]] && [[ -x "${doom_bin_path}" ]]; then
    doom sync
  elif command -v doom &> /dev/null; then
    doom sync
  else
    echo -e "\n${YELLOW}Warning: doom command not found. Skipping doom sync.${NC}"
    echo -e "${YELLOW}If you need Doom Emacs, install it with:${NC}"
    echo -e "${YELLOW}  git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs${NC}"
    echo -e "${YELLOW}  ~/.config/emacs/bin/doom install${NC}"
  fi

  # Rebuild bat cache (syntax highlighting for bat)
  echo -e "\n\e[1;37mRebuilding cache for \e[1;33mbat\e[1;37m...\e[0;32m"
  # Ensure 'bat' command is present on Ubuntu/Debian systems
  if [[ "$(detect_distro)" == "ubuntu" ]]; then
    if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
      # Symlink batcat to bat for compatibility
      echo -e "\n\e[35mSymlinking batcat to bat in /usr/local/bin (Ubuntu/Debian)\e[0m"
      sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
    fi
  fi
  bat cache --build

  # Install VIM plugins using vim-plug (if vim-plug is installed)
  if [[ -f "${HOME}/.vim/autoload/plug.vim" ]] || [[ -f "${HOME}/.local/share/nvim/site/autoload/plug.vim" ]]; then
    echo -e "\n\e[1;37mInstalling VIM plugins...\e[0;32m"
    vim +'PlugInstall --sync' +qa
  else
    echo -e "\n${YELLOW}vim-plug not found, skipping plugin installation${NC}"
    echo -e "${YELLOW}To install vim-plug, see: https://github.com/junegunn/vim-plug${NC}"
  fi

  # Enable libvirtd for VM system management (skip in minimal mode)
  if [[ "${MINIMAL_MODE}" != "true" ]]; then
    echo -e "\n\e[1;37mEnabling libvirtd for VM system management...\e[0;32m"
    sudo systemctl enable --now libvirtd
  else
    echo -e "\n${YELLOW}Skipping libvirtd setup (minimal mode)${NC}"
  fi

  # Install Atuin shell history manager only if not already installed
  if ! command -v atuin &> /dev/null; then
    echo -e "\n\e[1;37mInstalling Atuin...\e[0;32m"
    # Download and run the installer with --no-modify-path flag if available
    # This prevents the installer from modifying shell config files
    curl --proto '=https' --tlsv1.2 -LsSf https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh | sh -s -- --no-modify-path 2>/dev/null || \
    curl --proto '=https' --tlsv1.2 -LsSf https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh | sh
    
    # Add Atuin to PATH for current session
    if [[ -d "${HOME}/.atuin/bin" ]]; then
      export PATH="${HOME}/.atuin/bin:${PATH}"
    fi
    
    # Add Atuin bin to PATH in .zshenv (sourced first, before .zshrc)
    if [[ -f "${HOME}/.zshenv" ]] && ! grep -q "atuin/bin" "${HOME}/.zshenv"; then
      echo -e "\n# Atuin" >> "${HOME}/.zshenv"
      # shellcheck disable=SC2016
      echo 'path=("${HOME}/.atuin/bin" $path)' >> "${HOME}/.zshenv"
    fi
    
    # Manually add Atuin configuration to .zshrc only if not already present
    if [[ -f "${HOME}/.zshrc" ]] && ! grep -q "atuin init zsh" "${HOME}/.zshrc"; then
      echo -e "\n# Atuin shell history" >> "${HOME}/.zshrc"
      # shellcheck disable=SC2016
      echo 'eval "$(atuin init zsh)"' >> "${HOME}/.zshrc"
    fi
  else
    echo -e "\n${YELLOW}Atuin is already installed, skipping installation${NC}"
  fi

  # Change default shell to zsh for the current user
  if [[ "$(basename "${SHELL}")" != "zsh" ]]; then
    echo -e "\n\e[0;33mUpdating shell for \e[1;35m$(whoami)\e[0;33m to \e[1;35mzsh\e[0;33m\e[0;32m"
    sudo chsh -s "/bin/zsh" "$(whoami)"
  else
    echo -e "\n${YELLOW}Shell is already set to zsh${NC}"
  fi
}

# Function: main
# Description: The main function that orchestrates the entire installation and configuration process.
function main() {
  # Parse command-line arguments
  parse_arguments "$@"
  
  local distro
  local desktop_interface
  distro=$(detect_distro)

  # Legacy distros disclaimer and exit
  if [[ "${distro}" == "legacy" ]]; then
    echo -e "\n${YELLOW}This distribution is no longer supported. Please use the ${BOLD}legacy-distros${NC}${YELLOW} branch for best-effort support. No further updates will be provided for ${BOLD}${distro}${NC}${YELLOW}.${NC}"
    exit 1
  fi

  if [[ "${distro}" != "arch" && "${distro}" != "ubuntu" ]]; then
    echo -e "\n${RED}Unsupported distribution: ${distro}. Only Arch and Ubuntu are supported.${NC}"
    exit 1
  fi

  echo -e "\n${YELLOW}***************************************\n"
  echo -e "Detected distribution: ${BOLD}${distro}${NC}${YELLOW}"
  if [[ "${MINIMAL_MODE}" == "true" ]]; then
    echo -e "Installation mode: ${BOLD}MINIMAL/SERVER${NC}${YELLOW}"
  fi
  echo -e "\n***************************************${NC}"
  echo -e "\n\e[1;37mConfiguring additional repositories...\e[0m"
  install_repos "${distro}"
  system_update "${distro}"

  echo -e "\n\e[1;37mPreparing to install packages...\e[0m"
  while IFS= read -r package; do
    [[ -n "${package}" ]] && install_package "${package}" "${distro}"
  done < <(get_packages)

  create_working_dirs
  echo -e "\n\e[1;37mPreparing to install binaries...\e[0m"
  install_binaries
  echo -e "\n\e[1;37mStowing dotfile configurations...\e[0;32m"
  # --adopt moves any conflicting files into the stow package, then symlinks them.
  # git restore */ ensures the committed dotfiles win over whatever was on the
  # system, scoped to stow package subdirectories only (not root files like
  # provision.sh or packages.yaml).
  #
  # On Ubuntu, skip stowing the foot package. Ubuntu 24.04 ships foot 1.16.x
  # which does not support options added in 1.17+ (resize-by-cells,
  # cursor.unfocused-style, [colors-dark]). foot.ini is deployed as an
  # independent (untracked) copy so it can be patched without the changes
  # being adopted back into dotfiles on the next provision run.
  if [[ "${distro}" == "ubuntu" ]]; then
      mapfile -t stow_pkgs < <(find . -maxdepth 1 -mindepth 1 -type d -name '[^.]*' ! -name 'foot' -printf '%f\n')
      stow --adopt -v "${stow_pkgs[@]}"
      git restore "${stow_pkgs[@]}"
      patch_foot_config_ubuntu
  else
      stow --adopt -v */
      git restore */
  fi
  install_rust
  install_media_tools "${distro}"
  install_tmux_plugins
  echo -e "\n\e[1;37mInstalling yazi packages...\e[0;32m"
  ya pkg install
  create_nm_dispatcher
  hardware_setup "${distro}"
  configure_uv1_audio
  configure_sleep_state
  post_install_configure
  select_desktop_interface desktop_interface
  
  # Only run desktop interface installation if not in minimal mode
  if [[ "${MINIMAL_MODE}" != "true" ]]; then
    # Download to a temp file before executing so the script has access to
    # terminal stdin. Running via curl | bash would consume stdin and break
    # any interactive select prompts inside install.sh.
    local di_install
    di_install=$(mktemp --suffix=.sh)
    curl -sSL "${DIREPO_RAW}/install.sh" -o "${di_install}"
    bash "${di_install}" "${distro}" "${desktop_interface}"
    rm -f "${di_install}"
  fi
  
  echo -e "\n${GREEN}${BOLD}Installation complete!${NC}"
  if [[ "${MINIMAL_MODE}" == "true" ]]; then
    echo -e "${YELLOW}GUI applications and VM tools were skipped in minimal mode.${NC}"
  fi
}

main "$@"
