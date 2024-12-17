#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

#***
# Filesearch
#***
function f() { find . -iname "*$1*" "${@:2}"; }
function r() { grep "$1" "${@:2}" -R .; }

#***
# Search file with fzf and open
#***
function fe() {
    local files
    IFS=$'\n' files=($(fzf --multi --select-1 --exit-0))
    [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

#***
# Create directory and enter it
#***
function mkcd() { mkdir -p "$@" && cd "$_" || exit; }

#***
# Save Python packages into a requirements file
#***
function pip-install-save { 
    pip install "$1" && pip freeze | grep "$1" >> requirements.txt
}

#***
# Create tmux Session
#***
function tsession() {
    sh ~/.tmux/tmux-bootstrap.sh "$1"
}

#***
# Set AWS profile
#***
function setaws() {
    local PURPLE='\033[1;35m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m' # No Color

    if ! command -v aws &> /dev/null; then
	echo -e "${PURPLE}Please install the AWS Command Line Interface.${NC}"
	return 1
    fi

    local profile_name="${1}"
    local profile_status=$( (aws configure --profile ${profile_name} list) 2>&1)

    if [[ $profile_status = *'could not be found'* ]]; then
        echo -e "Unable to locate credentials for ${PURPLE}${profile_name}${NC}."
        echo -e "You can configure credentials by running \"${YELLOW}aws configure --profile ${1}${NC}\"."
    else
        export AWS_DEFAULT_PROFILE=$profile_name
        export AWS_PROFILE=$profile_name
        export AWS_DEFAULT_REGION=$(aws configure get region)
        export AWS_REGION=$(aws configure get region)
        export AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
        export AWS_ACCOUNT_ALIAS=$(aws iam list-account-aliases --query "AccountAliases" --output text)
    fi
}

#***
# Create a new git branch
#***
function createbranch() {
    if [[ -z $1 ]]; then
        echo "Please specify a branch name."
        return 1
    fi

    g checkout -b "${1}"
    git push --set-upstream origin "${1}"
}

#***
# Remove all branches other than defined
#***
function prunebranches() {
    if [[ -z $1 ]] ; then
        echo "Please specify the branch you would like to keep."
        return 1
    fi

    git checkout "${1}" && g pull && g branch | grep -v "${1}" | xargs git branch -D
}

#***
# Rename branch local and remote
#***
function mvbranch() {
    if [[ -z $1 ]] ; then
        current_branch=$(git branch --show-current)
    else
        current_branch=$1
        git checkout "$current_branch"
    fi

    printf "\nDo you want to rename the branch ${bold}%s${normal}?\n" "$current_branch"
    
    select yn in "Yes" "No"; do
        case $yn in
            "Yes")
                printf "\nNew branch name:"

                read -r new_branch_name
                
                printf "\nRenaming branch from %s to %s..." "$current_branch" "$new_branch_name"

                git branch -m "$new_branch_name"
                git push origin -u "$new_branch_name"
                git push origin :"$current_branch"
                break
                ;;
            "No")
                break
                ;;
        esac
    done
}

#***
# Remove branch local and remote
#***
function rmbranch() {
    if [[ -z $1 ]] ; then
        printf "Please specify a branch name."
        return 1
    fi

    git branch -d "$1"
    git push origin :"$1"
}

#***
# Export encrypted GPG private key
#***
function egpg() {
    if [[ -z $1 ]] ; then
        printf "Please specify the GPG UID."
        return 1
    fi
    
    if [[ -z $2 ]] ; then
        printf "Please specify output filename."
        return 1
    fi
    
    gpg --output pubkey.gpg --export ${1} && \
    gpg --output - --export-secret-key ${1} | cat pubkey.gpg - | gpg --armor --output ${2} --symmetric --cipher-algo AES256 && \
    rm -f ./pubkey.gpg 
}

#***
# Import encrypted GPG private key with ultimate trust level
#***
function igpg() {
    if [[ -z $1 ]] ; then
        printf "Please specify filename."
        return 1
    fi

    gpg --output - ${1} | gpg --import | (echo 5; echo y; echo save) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key - trust
}

#***
# Generate unique username
#***
function genuser() {
    local case_type="$1"

    openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1 | awk -v case_type="$case_type" '{
        srand();
        for (i=1; i<=length($0); i++) {
            c = substr($0,i,1);
            if (c ~ /[a-zA-Z]/) {
                if (case_type) {
                    # If an argument is passed, use mixed case
                    if (rand() > 0.5) {
                        printf "%s", toupper(c);
                    } else {
                        printf "%s", tolower(c);
                    }
                } else {
                    # Default to all lowercase
                    printf "%s", tolower(c);
                }
            } else {
                printf "%s", c;  # Print non-alphabetic characters as-is
            }
        }
    }'
}

#***
# GNOME
#***
GNOME_CATEGORIES=(
    "/org/gnome/desktop/interface/:interface.ini"
    "/org/gnome/desktop/wm/:wm.ini"
    "/org/gnome/nautilus/:nautilus.ini"
    "/org/gnome/desktop/input-sources/:input-sources.ini"
    "/org/gnome/settings-daemon/plugins/:plugins.ini"
    "/org/gnome/shell/extensions/:extensions.ini"
)

function gnomeexport() {
    local output_dir
    
    output_dir="${1:-${DIDOTS}/gnome/_settings}"

    if [[ ! -d "${output_dir}" ]]; then
        mkdir -p "${output_dir}" || { echo "Failed to create directory ${output_dir}"; return 1; }
    fi

    for category in "${GNOME_CATEGORIES[@]}"; do
        IFS=':' read -r dconf_path file <<< "${category}"
        dconf dump "${dconf_path}" > "${output_dir}/${file}"
        echo "Exported ${dconf_path} to ${output_dir}/${file}"
    done

    echo -e "\nGNOME settings exported to ${output_dir}"
}

function gnomeimport() {
    local input_dir

    input_dir="${1:-${DIDOTS}/gnome/_settings}"

    if [ ! -d "${input_dir}" ]; then
        echo "Error: Directory ${input_dir} does not exist"
        return 1
    fi

    # Import each category from its corresponding file
    for category in "${GNOME_CATEGORIES[@]}"; do
        IFS=':' read -r dconf_path file <<< "${category}"
        if [ -f "${input_dir}/${file}" ]; then
            dconf load "${dconf_path}" < "${input_dir}/${file}"
            echo "Imported ${input_dir}/${file} to $dconf_path"
        else
            echo "Warning: ${file} not found in ${input_dir}"
        fi
    done

    echo -e "\nGNOME settings imported from ${input_dir}"
    echo -e "You may need to log out and back in for all changes to take effect."
}
