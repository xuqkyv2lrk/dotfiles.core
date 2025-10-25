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
detect_distro() {
  if [ -f /etc/os-release ]; then
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
    local package=$1
    local distro=$2
    local package_name=$package

    if grep -q "^exceptions:" packages.yaml; then
        if grep -q "^  $distro:" packages.yaml; then
            local exception
            exception=$(sed -n "/^  $distro:/,/^  [^ ]/p" packages.yaml | grep "^    $package:" | cut -d ':' -f2- | sed 's/ //')
            if [ ! -z "$exception" ]; then
                package_name=$exception
            fi
        fi
    fi

    echo "$package_name"
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
      sudo apt-get upgrade -y
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
      # Install yay if not already installed
      if ! command -v yay &> /dev/null; then
        echo -e "\n${YELLOW}Installing yay...${GREEN}"
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
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
      
      # Docker repository and key
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      
      # Kubernetes repository and key
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
      
      # Update apt after adding new repositories
      sudo apt-get update
      ;;
    *)
      echo "Unsupported distribution: ${distro}"
      ;;
  esac
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
  
  if [[ "${package_name}" == "none" ]]; then
    echo -e "\n${YELLOW}Skipping ${BOLD}${package}${NC}${YELLOW} (not available for ${distro})${NC}"
    return
  fi
  
  case "${distro}" in
    "arch")
      echo -e "\n${MAGENTA}Installing ${BOLD}${package_name}${NC}"
      yay -S --noconfirm "${package_name}"
      ;;
    "ubuntu")
      echo -e "\n${MAGENTA}Installing ${BOLD}${package_name}${NC}"
      sudo apt-get install -y "${package_name}"
      ;;
    *)
      echo "Unsupported distribution: ${distro}"
      ;;
  esac
}

# Placeholder functions for the script (implementations omitted for brevity)
function create_working_dirs() {
  echo -e "\n${BLUE}Creating working directories...${NC}"
  mkdir -p "${HOME}/.config" "${HOME}/.local/bin"
}

function install_binaries() {
  echo -e "\n${BLUE}Installing custom binaries...${NC}"
  # Add your binary installation logic here
}

function install_tmux_plugins() {
  echo -e "\n${BLUE}Installing tmux plugins...${NC}"
  # Add your tmux plugin installation logic here
}

function create_nm_dispatcher() {
  echo -e "\n${BLUE}Creating NetworkManager dispatcher...${NC}"
  # Add your dispatcher creation logic here
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
    *)
      echo -e "\n\e[1;37mNo hardware-specific configurations needed for this model\e[0m"
      ;;
  esac
}

# Function: select_desktop_interface
# Description: On Ubuntu, prompts the user to apply a custom GNOME configuration or leave the current setup unchanged. On other distros, prompts for desktop interface selection.
function select_desktop_interface() {
    local __choice=$1
    local distro
    distro=$(detect_distro)
    
    # Skip desktop interface selection in minimal mode
    if [[ "${MINIMAL_MODE}" == "true" ]]; then
        echo -e "\n${YELLOW}Skipping desktop interface installation (minimal mode)${NC}"
        return
    fi
    
    if [[ "$distro" == "ubuntu" ]]; then
        # Check if the current desktop session is GNOME
        if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* && "$DESKTOP_SESSION" != "gnome" ]]; then
            echo -e "\n${RED}Unsupported desktop environment detected.\nThis script supports only Ubuntu with GNOME desktop. Exiting.${NC}\n"
            exit 1
        fi
        echo -e "\n${BLUE}${BOLD}You are running Ubuntu with GNOME.${NC}"
        echo -e "${BLUE}How would you like to handle your GNOME desktop configuration?${NC}"
        select choice in "Apply custom GNOME configuration" "Apply custom GNOME configuration with PaperWM" "Leave GNOME as it is"; do
            case $choice in
                "Apply custom GNOME configuration")
                    eval "$__choice"="gnome"
                    use_paperwm="false"
                    return
                    ;;
                "Apply custom GNOME configuration with PaperWM")
                    eval "$__choice"="gnome"
                    use_paperwm="true"
                    return
                    ;;
                "Leave GNOME as it is")
                    printf "\nNo changes will be made to your GNOME desktop.\n"
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
            case $choice in
                "Yes")
                    echo -e "\n${BLUE}${BOLD}Please select a desktop interface:${NC}"
                    mapfile -t options < <(curl -sSL ${DIREPO_RAW}/packages.yaml | yq -e '.desktop_packages | keys | .[]' | tr -d '"')
                    select de in "${options[@]}"; do
                        if [[ -n "$de" ]]; then
                            eval "$__choice"="$de"
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
    . "${HOME}/.cargo/env"
    rustup default stable
    
    # Manually add cargo to .zshenv only if not already present
    if [[ -f "${HOME}/.zshenv" ]] && ! grep -q ".cargo/env" "${HOME}/.zshenv"; then
      echo -e "\n# Cargo environment" >> "${HOME}/.zshenv"
      echo '. "$HOME/.cargo/env"' >> "${HOME}/.zshenv"
    fi
  fi
}

# Function: hardware_setup
# Description: Detects hardware and applies specific configurations.
# Side effects: Calls configure_hardware_specific if hardware is detected.
function hardware_setup() {
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
  doom sync

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

  # Install VIM plugins using vim-plug
  echo -e "\n\e[1;37mInstall VIM plugins...\e[0;32m"
  vim +'PlugInstall --sync' +qa

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
    
    # Manually add Atuin configuration to .zshrc only if not already present
    if [[ -f "${HOME}/.zshrc" ]] && ! grep -q "atuin init zsh" "${HOME}/.zshrc"; then
      echo -e "\n# Atuin shell history" >> "${HOME}/.zshrc"
      echo 'eval "$(atuin init zsh)"' >> "${HOME}/.zshrc"
    fi
    
    # Add to .zshenv if it exists and doesn't have the entry
    if [[ -f "${HOME}/.zshenv" ]] && ! grep -q "atuin/bin" "${HOME}/.zshenv"; then
      echo '. "$HOME/.atuin/bin/env"' >> "${HOME}/.zshenv"
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
  stow -v */
  install_rust
  install_tmux_plugins
  create_nm_dispatcher
  hardware_setup
  post_install_configure
  select_desktop_interface desktop_interface
  
  # Only run desktop interface installation if not in minimal mode
  if [[ "${MINIMAL_MODE}" != "true" ]]; then
    curl -sSL "${DIREPO_RAW}/install.sh" | bash -s "${distro}" "${desktop_interface}" "${use_paperwm}"
  fi
  
  echo -e "\n${GREEN}${BOLD}Installation complete!${NC}"
  if [[ "${MINIMAL_MODE}" == "true" ]]; then
    echo -e "${YELLOW}GUI applications and VM tools were skipped in minimal mode.${NC}"
  fi
}

main "$@"
