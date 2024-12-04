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

# Function: detect_distro
# Description: Detects the Linux distribution of the current system.
# Returns: The ID of the detected distribution (e.g., "arch", "fedora") or "unknown" if not detected.
function detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Function: detect_hardware
# Description: Detects the hardware model of the current system
# Returns: The system model identifier (e.g., "ThinkPad T480s", "ROG") or "unknown" if not detected
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
# Description: Gets the list of packages from packages.yaml, ignoring comments and empty lines
# Returns: Array of package names
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
            local exception=$(sed -n "/^  $distro:/,/^  [^ ]/p" packages.yaml | grep "^    $package:" | cut -d ':' -f2- | sed 's/ //')
            if [ ! -z "$exception" ]; then
                package_name=$exception
            fi
        fi
    fi

    echo "$package_name"
}

# Function: install_repos
# Description: Installs additional repositories based on the detected distribution.
# Parameters:
#   $1 - The distribution ID
# Side effects: Adds new repositories to the system's package manager
function install_repos() {
    local distro=$1

    case $distro in
        "arch")
            # Install yay if not already installed
            # Not a repo, but a helper for the AUR repository
            if ! command -v yay &> /dev/null; then
                echo -e "\n${YELLOW}Installing yay...${GREEN}"
                sudo pacman -S --needed --noconfirm git base-devel
                git clone https://aur.archlinux.org/yay.git
                cd yay
                makepkg -si --noconfirm
                cd ..
                rm -rf yay
            fi        

            # Remove iptables in package is installed as it conflicts with ebtables
            if yay -Qi iptables 2>/dev/null | grep -q "^Name\s*: iptables$"; then
                echo -e "\n${MAGENTA}Removing conflicting package ${BOLD}iptables${NC}"
                yay -Rdd --noconfirm iptables
            fi
            
            # 1Password, Docker, and kubectl can be installed via yay
            ;;
        "fedora")
            # 1Password
            sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
            sudo tee /etc/yum.repos.d/1password.repo > /dev/null << EOF
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

            # Docker
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager addrepo --overwrite --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo"
            
            # kubectl
            sudo tee /etc/yum.repos.d/kubernetes.repo > /dev/null << EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF

            # RPMFusion Repository
            sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm
            ;;
        "opensuse-tumbleweed")
            # 1Password
            sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
            sudo zypper addrepo https://downloads.1password.com/linux/rpm/stable/x86_64 1password
            
            # kubectl
            sudo bash -c "cat <<EOF > /etc/zypp/repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF"
            
            sudo zypper refresh
            ;;
        *)
            echo "Unsupported distribution for repository installation: ${distro}"
            ;;
    esac
}

# Function: install_package
# Description: Installs a specified package using the appropriate package manager for the distribution.
# Parameters:
#   $1 - The package name to install
#   $2 - The distribution ID
# Side effects: Installs the specified package on the system
function install_package() {
    local package=$1
    local distro=$2
    local package_name=$(get_package_name $package $distro)

    echo -e "\n\e[35mInstalling \e[1m${package_name}\e[0m"

    case $distro in
        "arch")
            yay -S --noconfirm $package_name
            ;;
        "fedora")
            sudo dnf install -y --allowerasing $package_name
            ;;
        "opensuse-tumbleweed")
            sudo zypper install -y $package_name
            ;;
        *)
            echo "Unsupported distribution: ${distro}"
            ;;
    esac
}

# Function: install_binaries
# Description: Installs binary packages that are not available through standard package managers.
# Side effects: Installs aws-cli and oh-my-posh if not already present
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

    # Oh My Posh
    if ! command -v oh-my-posh &> /dev/null; then
        echo -e "\n\e[35mInstalling \e[1moh-my-posh\e[0;32m"
        curl -s https://ohmyposh.dev/install.sh | bash -s
        binary_installed=true
    fi

    # tfenv
    if ! command -v tfenv &> /dev/null; then
        echo -e "\n\e[35mInstalling \e[1mtfenv\e[0;32m"
        (
            git clone --depth 1 --filter=blob:none --sparse https://github.com/tfutils/tfenv.git /tmp/tfenv
            cd /tmp/tfenv
            git sparse-checkout set bin
            mv bin/* "${HOME}/bin"
        )
        rm -rf /tmp/tfenv
        binary_installed=true
    fi

    # doom emacs
    if ! command -v doom  &> /dev/null; then
        echo -e "\n\e[35mInstalling \e[1mdoom emacs\e[0;32m"
        git clone --depth 1 https://github.com/doomemacs/doomemacs "${HOME}/.emacs.d"
        binary_installed=true
    fi

    if [[ "${binary_installed}" == false ]]; then
        echo -e "\e[1;37mNo new binaries to install.\e[0m"
    fi
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

log() {
    logger -t "timezone-update" "$1"
}

update_timezone() {
    local new_timezone
    new_timezone=$(curl --fail --silent --show-error "https://ipapi.co/timezone")
    if [[ -n "$new_timezone" ]]; then
        timedatectl set-timezone "$new_timezone"
        log "Timezone updated to $new_timezone"
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
    export PATH="${HOME}/bin:${HOME}/.emacs.d/bin:${PATH}"
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

# Function: configure_hardware_specific
# Description: Applies hardware-specific configurations based on detected model
# Parameters:
#   $1 - The hardware model identifier
#   $2 - The distribution ID
# Side effects: Creates configuration files and applies hardware-specific settings
function configure_hardware_specific() {
    local hardware_model=$1
    local distro=$2
    
    case "${hardware_model}" in
        "ThinkPad T480s")
            sudo tee /etc/udev/rules.d/80-lenovo-ir-camera.rules > /dev/null << EOF
SUBSYSTEM=="usb", ATTRS{idVendor}=="04f2", ATTRS{idProduct}=="b615", ATTR{authorized}="0"
EOF
            echo -e "\n\e[1;37mDisabled IR camera for \e[1;33mThinkPad T480s\e[1;37m\e[0;32m"
            ;;
            
        "ROG")
            # Install ROG-specific packages
            case "${distro}" in
                "arch")
                    echo -e "\n\e[1;37mInstalling ROG-specific packages from AUR...\e[0;32m"
                    yay -S --noconfirm asusctl supergfxctl rog-control-center
                    sudo systemctl enable --now asusd
                    sudo systemctl enable --now supergfxd
                    ;;
                "fedora")
                    echo -e "\n\e[1;37mInstalling ROG-specific packages for Fedora...\e[0;32m"
                    # Add COPR repository for ROG packages
                    sudo dnf copr enable -y lukenukem/asus-linux
                    sudo dnf install -y asusctl supergfxctl rog-control-center kernel-devel
                    sudo systemctl enable --now asusd
                    sudo systemctl enable --now supergfxd
                    ;;
                "opensuse-tumbleweed")
                    echo -e "\n\e[1;37mInstalling ROG-specific packages for openSUSE...\e[0;32m"
                    # Add hardware:asus repository
                    sudo zypper addrepo -f https://download.opensuse.org/repositories/hardware:/asus/openSUSE_Tumbleweed/ hardware:asus
                    sudo zypper --gpg-auto-import-keys refresh
                    sudo zypper install -y asusctl supergfxctl rog-control-center
                    sudo systemctl enable --now asusd
                    sudo systemctl enable --now supergfxd
                    ;;
                *)
                    echo -e "\n\e[1;33mWarning: ROG-specific packages are not configured for this distribution\e[0m"
                    ;;
            esac
            echo -e "\n\e[1;37mROG packages installed. You can configure your device using ROG Control Center.\e[0m"
            ;;
            
        *)
            echo -e "\n\e[1;37mNo hardware-specific configurations needed for this model\e[0m"
            ;;
    esac
}

# Function: select_desktop_interface
# Description: Prompts the user to select a desktop interface.
# Parameters:
#   $1 - A reference to store the selected desktop interface.
function select_desktop_interface() {
    local __choice=$1
    echo -e "\n${BLUE}${BOLD}Do you want to install a desktop interface?${NC}"
    select choice in "Yes" "No"; do
        case $choice in
            "Yes")
                echo -e "\n${BLUE}${BOLD}Please select a desktop interface:${NC}"
                mapfile -t options < <(curl -sSL ${DIREPO_RAW}/packages.yaml | yq -e '.desktop_packages | keys | .[]')
                select de in "${options[@]}"; do
                    if [[ -n "$de" ]]; then
                        eval "$__choice"="${de}"
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
}

function install_rust() {
    echo -e "\n${YELLOW}Installing rust stable...${GREEN}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    . "${HOME}/.cargo/env"
    rustup default stable

    echo -e "\n${MAGENTA}Installing ${BOLD}ncspot${NC}"
    cargo install ncspot
}

# Function: main
# Description: The main function that orchestrates the entire installation and configuration process.
# Side effects:
#   - Detects the distribution
#   - Installs additional repositories
#   - Installs required binaries and packages
#   - Detects hardware and applies specific configurations
#   - Configures the system and installs dotfiles
function main() {
    local distro
    local desktop_interface
    
    distro=$(detect_distro)

    echo -e "\n${YELLOW}***************************************\n"
    echo -e "Detected distribution: ${BOLD}${distro}${NC}${YELLOW}"
    echo -e "\n***************************************${NC}"
    
    echo -e "\n\e[1;37mConfiguring additional repositories...\e[0m"
    install_repos "${distro}"
    
    echo -e "\n\e[1;37mPreparing to install packages...\e[0m"
    while IFS= read -r package; do
        [[ -n "$package" ]] && install_package "$package" "$distro"
    done < <(get_packages)

    create_working_dirs

    echo -e "\n\e[1;37mPreparing to install binaries...\e[0m"
    install_binaries

    # Detect hardware after package installation to ensure dmidecode is available
    local hardware=$(detect_hardware)
    echo -e "\n\e[33mDetected hardware: \e[1m${hardware}\e[0m"

    echo -e "\n\e[1;37mStowing dotfile configurations...\e[0;32m"
    stow -v */

    install_rust

    echo -e "\n\e[1;37mSetting up doom emacs...\e[0;32m"
    doom sync

    echo -e "\n\e[1;37mRebuilding cache for \e[1;33mbat\e[1;37m...\e[0;32m"
    bat cache --build

    echo -e "\n\e[1;37mInstall VIM plugins...\e[0;32m"
    vim +'PlugInstall --sync' +qa

    echo -e "\n\e[1;37mEnabling libvirtd for VM system management...\e[0;32m"
    sudo systemctl enable --now libvirtd

    install_tmux_plugins

    create_nm_dispatcher

    configure_hardware_specific "${hardware}" "${distro}"

    echo -e "\n\e[0;33mUpdating shell for \e[1;35m$(whoami)\e[0;33m to \e[1;35mzsh\e[0;33m\e[0;32m"
    sudo chsh -s $(which zsh) "$(whoami)"

    select_desktop_interface desktop_interface

    curl -sSL "${DIREPO_RAW}/install.sh" | bash -s "${distro}" "${desktop_interface}"
}

main
