#!/usr/bin/env bash

# Catppuccin Mocha palette
readonly RED='\033[38;2;243;139;168m'
readonly GREEN='\033[38;2;166;227;161m'
readonly YELLOW='\033[38;2;249;226;175m'
readonly BLUE='\033[38;2;137;180;250m'
readonly MAUVE='\033[38;2;203;166;247m'
readonly TEAL='\033[38;2;148;226;213m'
readonly TEXT='\033[38;2;205;214;244m'
readonly SUBTEXT='\033[38;2;166;173;200m'
readonly RESET='\033[0m'

function print_info()    { printf "${BLUE}[INFO]${RESET} %s\n" "$*"; }
function print_success() { printf "${GREEN}[OK]${RESET} %s\n" "$*"; }
function print_warning() { printf "${YELLOW}[WARN]${RESET} %s\n" "$*" >&2; }
function print_error()   { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; }
function print_step()    { printf "${MAUVE}==>${RESET} %s\n" "$*"; }
function print_dry_run() { printf "${TEAL}[DRY-RUN]${RESET} %s\n" "$*"; }

# --- Internal Helpers ---

function spinner() {
  local delay=0.1
  local spinstr="|/-\\"
  tput civis
  while true; do
    local temp="${spinstr#?}"
    printf "%b[%c]  " "${RESET}" "$spinstr" >&2
    spinstr="$temp${spinstr%"$temp"}"
    sleep "$delay"
    printf "\b\b\b\b\b" >&2
  done
}

function stop_spinner() {
  tput cnorm
  if [[ -n "${spinner_pid:-}" ]]; then
    kill "$spinner_pid" > /dev/null 2>&1
    wait "$spinner_pid" > /dev/null 2>&1
    printf "\b\b\b\b\b\033[K" >&2
    unset spinner_pid
  fi
}

function _smart_picker() {
  local prompt="$1"
  if command -v fuzzel &>/dev/null; then
    fuzzel -d --prompt="$prompt" 2>/dev/null || fzf --prompt="$prompt"
  else
    fzf --prompt="$prompt"
  fi
}

# Uses 'vared' for Zsh (full backspace support) and 'read -e' for Bash
function _prompt_read() {
  local prompt_text="$1"
  local var_name="$2"
  local default_val="$3"

  if [[ -n "$ZSH_VERSION" ]]; then
    eval "$var_name=\"$default_val\""
    vared -p "$prompt_text" "$var_name"
  else
    read -re -p "$prompt_text" -i "$default_val" "$var_name"
  fi
}

function _get_sso_start_url() {
  local profile="$1"
  local sso_session
  sso_session=$(aws configure get sso_session --profile "$profile" 2>/dev/null)
  if [[ -n "$sso_session" ]]; then
    awk -v session="$sso_session" '$0 ~ "\\[sso-session "session"\\]" {found=1; next} /^\[.*\]/ {found=0} found && $1 == "sso_start_url" {print $3; exit}' ~/.aws/config
  else
    aws configure get sso_start_url --profile "$profile" 2>/dev/null
  fi
}

function _urlencode() {
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

function _activate_profile() {
  local profile="$1"
  local silent="${2:-false}"

  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE
  unset AWS_REGION AWS_DEFAULT_REGION AWS_CREDENTIAL_EXPIRATION AWS_VAULT

  if [[ "$silent" != "true" ]]; then
    printf "%b Exporting %b%s %b" "${TEAL}" "${MAUVE}" "$profile" "${RESET}" >&2
    spinner & spinner_pid=$!
    disown "$spinner_pid" 2>/dev/null
  fi

  local target_region
  target_region=$(aws configure get region --profile "$profile" 2>/dev/null)

  if [[ -n "$(aws configure get sso_account_id --profile "$profile" 2>/dev/null)" ]]; then
    local export_cmd
    export_cmd=$(aws configure export-credentials --profile "$profile" --format env 2>/dev/null)

    if [[ -n "$export_cmd" ]]; then
      eval "${export_cmd// *= /=}"
      export AWS_REGION="${target_region:-us-east-1}"
      export AWS_DEFAULT_REGION="${target_region:-us-east-1}"
      export AWS_PROFILE="$profile"
    else
      if [[ "$silent" != "true" ]]; then
        stop_spinner
        print_error "SSO session expired. Run: aws sso login --profile ${profile}"
      fi
      return 1
    fi
  else
    local val_id val_key
    val_id=$(aws configure get aws_access_key_id --profile "$profile" 2>/dev/null)
    val_key=$(aws configure get aws_secret_access_key --profile "$profile" 2>/dev/null)

    export AWS_ACCESS_KEY_ID="$val_id"
    export AWS_SECRET_ACCESS_KEY="$val_key"
    export AWS_REGION="${target_region:-us-east-1}"
    export AWS_DEFAULT_REGION="${target_region:-us-east-1}"
    export AWS_PROFILE="$profile"
  fi

  if [[ "$silent" != "true" ]]; then
    stop_spinner
    printf "%b[done]%b\n" "${GREEN}" "${RESET}" >&2
  fi

  export AWS_ACTIVE_PROFILE="$profile"
  echo "$profile" > ~/.aws/.active_profile
  return 0
}

function _create_sso_profile() {
  local session_name start_url sso_region existing_sessions
  existing_sessions=$(awk '/^\[sso-session /{gsub(/^\[sso-session |]$/, "", $0); print}' "${HOME}/.aws/config" 2>/dev/null)

  if [[ -n "${existing_sessions}" ]]; then
    session_name=$(printf "%s\n[New session]\n" "${existing_sessions}" | _smart_picker "SSO session: ")
  fi

  if [[ -z "${session_name:-}" || "${session_name}" == "[New session]" ]]; then
    _prompt_read "$(printf "%bSSO session name: %b" "${TEAL}" "${RESET}")" session_name ""
  fi
  [[ -z "${session_name:-}" ]] && return 1

  start_url=$(awk -v s="$session_name" '$0 == "[sso-session "s"]" {found=1; next} /^\[/ {found=0} found && $1 == "sso_start_url" {print $3; exit}' ~/.aws/config)

  if [[ -z "${start_url}" ]]; then
    _prompt_read "$(printf "%bSSO start URL: %b" "${TEAL}" "${RESET}")" start_url ""
    _prompt_read "$(printf "%bSSO region: %b" "${TEAL}" "${RESET}")" sso_region "us-west-2"
    aws configure set sso_start_url "$start_url" --sso-session "$session_name"
    aws configure set sso_region "$sso_region" --sso-session "$session_name"
    aws configure set sso_registration_scopes "sso:account:access" --sso-session "$session_name"
  else
    sso_region=$(awk -v s="$session_name" '$0 == "[sso-session "s"]" {found=1; next} /^\[/ {found=0} found && $1 == "sso_region" {print $3; exit}' ~/.aws/config)
  fi

  local access_token=""
  local now_utc
  now_utc=$(date -u +%s)
  access_token=$(find "${HOME}/.aws/sso/cache/" -name "*.json" -type f -printf "%T@ %p\n" 2>/dev/null | sort -rn | cut -d' ' -f2- | xargs -r jq -r --arg now "$now_utc" 'select(.accessToken and (.expiresAt | fromdateiso8601 > ($now | tonumber))) | .accessToken' 2>/dev/null | head -n 1)

  if [[ -z "$access_token" ]]; then
    aws sso login --sso-session "${session_name}" >&2 || return 1
    local attempts=0
    printf "%b Searching cache %b" "${TEAL}" "${RESET}" >&2
    spinner & spinner_pid=$!
    disown "$spinner_pid" 2>/dev/null
    while [[ -z "$access_token" && $attempts -lt 10 ]]; do
      access_token=$(find "${HOME}/.aws/sso/cache/" -name "*.json" -type f -printf "%T@ %p\n" 2>/dev/null | sort -rn | cut -d' ' -f2- | xargs -r jq -r 'select(.accessToken != null) | .accessToken' 2>/dev/null | head -n 1)
      if [[ -z "$access_token" ]]; then
        sleep 1
        attempts=$((attempts + 1))
      fi
    done
    stop_spinner
    printf "%b[done]%b\n" "${GREEN}" "${RESET}" >&2
  fi

  [[ -z "${access_token}" ]] && return 1

  printf "%b Loading accounts %b" "${TEAL}" "${RESET}" >&2
  spinner & spinner_pid=$!
  disown "$spinner_pid" 2>/dev/null
  local accounts_json
  accounts_json=$(aws sso list-accounts --access-token "${access_token}" --region "${sso_region}" --output json 2>/dev/null)
  stop_spinner
  printf "%b[done]%b\n" "${GREEN}" "${RESET}" >&2

  local account_line
  account_line=$(echo "$accounts_json" | jq -r '.accountList[] | "\(.accountId)\t\(.accountName)"' | _smart_picker "Account: ")
  [[ -z "${account_line}" ]] && return 1

  local account_id account_name
  account_id=$(echo "$account_line" | cut -f1)
  account_name=$(echo "$account_line" | cut -f2)

  printf "%b Loading roles %b" "${TEAL}" "${RESET}" >&2
  spinner & spinner_pid=$!
  disown "$spinner_pid" 2>/dev/null
  local roles_json
  roles_json=$(aws sso list-account-roles --access-token "${access_token}" --account-id "${account_id}" --region "${sso_region}" --output json 2>/dev/null)
  stop_spinner
  printf "%b[done]%b\n" "${GREEN}" "${RESET}" >&2

  local role_name
  role_name=$(echo "$roles_json" | jq -r '.roleList[].roleName' | _smart_picker "Role: ")
  [[ -z "${role_name}" ]] && return 1

  local profile_name
  _prompt_read "$(printf "%bProfile name: %b" "${TEAL}" "${RESET}")" profile_name "$account_name"
  profile_name=$(echo "$profile_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

  local profile_region
  _prompt_read "$(printf "%bDefault region: %b" "${TEAL}" "${RESET}")" profile_region "$sso_region"

  aws configure set sso_session "$session_name" --profile "$profile_name"
  aws configure set sso_account_id "$account_id" --profile "$profile_name"
  aws configure set sso_role_name "$role_name" --profile "$profile_name"
  aws configure set region "$profile_region" --profile "$profile_name"

  _activate_profile "$profile_name"
}

function setaws() {
  [[ -n "$ZSH_VERSION" ]] && setopt localoptions no_notify no_monitor

  local profile_name="${1:-}"
  if [[ -z "${profile_name}" ]]; then
    local choices=("[Create new API profile]" "[Create new SSO profile]")
    while IFS= read -r line; do choices+=("$line"); done < <(aws configure list-profiles 2>/dev/null)
    profile_name=$(printf '%s\n' "${choices[@]}" | _smart_picker "Select Profile: ")
  fi

  [[ -z "$profile_name" ]] && return 1

  if [[ "$profile_name" == "[Create new SSO profile]" ]]; then
    _create_sso_profile
  elif [[ "$profile_name" == "[Create new API profile]" ]]; then
    local new_p ak sk reg
    _prompt_read "New profile name: " new_p ""
    _prompt_read "Access Key: " ak ""
    printf "Secret Key: " >&2; read -rs sk; echo "" >&2
    _prompt_read "Default Region: " reg "us-east-1"
    aws configure set aws_access_key_id "$ak" --profile "$new_p"
    aws configure set aws_secret_access_key "$sk" --profile "$new_p"
    aws configure set region "$reg" --profile "$new_p"
    _activate_profile "$new_p"
  else
    local is_silent="false"
    [[ -n "$1" ]] && is_silent="true"
    _activate_profile "$profile_name" "$is_silent"
  fi
}
