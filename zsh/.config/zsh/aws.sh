#!/usr/bin/env bash

# Catppuccin Mocha palette
RED='\033[38;2;243;139;168m'
GREEN='\033[38;2;166;227;161m'
YELLOW='\033[38;2;249;226;175m'
BLUE='\033[38;2;137;180;250m'
MAUVE='\033[38;2;203;166;247m'
TEAL='\033[38;2;148;226;213m'
TEXT='\033[38;2;205;214;244m'
SUBTEXT='\033[38;2;166;173;200m'
RESET='\033[0m'

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
  if [[ -t 2 ]]; then
    fzf --prompt="$prompt"
  elif command -v fuzzel &>/dev/null; then
    fuzzel -d --prompt="$prompt" 2>/dev/null
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

    # zsh-autosuggestions' POSTDISPLAY overlay doesn't clear on backspace
    # inside vared's recursive edit loop, leaving stray un-deletable text.
    local had_autosuggest=0
    if typeset -f _zsh_autosuggest_disable >/dev/null; then
      had_autosuggest=1
      _zsh_autosuggest_disable
    fi

    # In vi mode, backspace can't erase text pre-filled before insert mode
    # started, so the default_val becomes permanent and typing just appends.
    # Switch to emacs keymap for the duration of the prompt to allow full
    # editing, then restore whatever keymap was active.
    local prev_keymap_cmd
    prev_keymap_cmd=$(bindkey -lL main 2>/dev/null)
    bindkey -e
    vared -p "$prompt_text" "$var_name"
    [[ -n "$prev_keymap_cmd" ]] && eval "$prev_keymap_cmd"

    [[ "$had_autosuggest" -eq 1 ]] && _zsh_autosuggest_enable
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

# Converts an RFC3339/ISO8601 timestamp to a Unix epoch, trying GNU date
# first (Linux) then falling back to BSD date's stricter parsing (macOS).
function _iso8601_to_epoch() {
  local iso="$1"
  [[ -z "$iso" ]] && return 1
  date -u -d "$iso" +%s 2>/dev/null && return 0
  date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso" +%s 2>/dev/null && return 0
  date -u -j -f "%Y-%m-%dT%H:%M:%S%z" "$iso" +%s 2>/dev/null
}

function _resolve_sso_session() {
  local profile="$1"
  local seen=""
  while [[ -n "$profile" ]]; do
    if [[ ",${seen}," == *",${profile},"* ]]; then
      return 1
    fi
    seen="${seen},${profile}"
    local sso_session
    sso_session=$(aws configure get sso_session --profile "$profile" 2>/dev/null)
    if [[ -n "$sso_session" ]]; then
      printf '%s' "$sso_session"
      return 0
    fi
    profile=$(aws configure get source_profile --profile "$profile" 2>/dev/null)
  done
  return 1
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

  local chained_sso_session
  chained_sso_session=$(_resolve_sso_session "$profile")

  local okta_org_domain
  okta_org_domain=$(aws configure get okta_org_domain --profile "$profile" 2>/dev/null)

  if [[ -n "$(aws configure get sso_account_id --profile "$profile" 2>/dev/null)" || -n "$chained_sso_session" ]]; then
    local export_cmd
    export_cmd=$(aws configure export-credentials --profile "$profile" --format env 2>/dev/null)

    if [[ -n "$export_cmd" ]]; then
      eval "${export_cmd// *= /=}"
      export AWS_REGION="${target_region:-us-east-1}"
      export AWS_DEFAULT_REGION="${target_region:-us-east-1}"
      export AWS_PROFILE="$profile"
    else
      stop_spinner
      print_warning "SSO session expired, re-authenticating..."
      local sso_session
      sso_session="$chained_sso_session"
      if [[ -n "$sso_session" ]]; then
        aws sso login --sso-session "$sso_session" >&2 || return 1
      else
        aws sso login --profile "$profile" >&2 || return 1
      fi
      export_cmd=$(aws configure export-credentials --profile "$profile" --format env 2>/dev/null)
      if [[ -n "$export_cmd" ]]; then
        eval "${export_cmd// *= /=}"
        export AWS_REGION="${target_region:-us-east-1}"
        export AWS_DEFAULT_REGION="${target_region:-us-east-1}"
        export AWS_PROFILE="$profile"
        printf "%b[done]%b\n" "${GREEN}" "${RESET}" >&2
      else
        print_error "Failed to export credentials after SSO login."
        return 1
      fi
    fi
  elif [[ -n "$okta_org_domain" ]]; then
    local expires_at now_epoch expiry_epoch
    expires_at=$(aws configure get x_security_token_expires --profile "$profile" 2>/dev/null)
    now_epoch=$(date -u +%s)
    expiry_epoch=$(_iso8601_to_epoch "$expires_at")

    if [[ -z "$expiry_epoch" || "$expiry_epoch" -le "$now_epoch" ]]; then
      stop_spinner
      print_warning "Okta session expired, re-authenticating..."
      _okta_authenticate "$profile" || { print_error "Okta authentication failed."; return 1; }
      if [[ "$silent" != "true" ]]; then
        printf "%b Exporting %b%s %b" "${TEAL}" "${MAUVE}" "$profile" "${RESET}" >&2
        spinner & spinner_pid=$!
        disown "$spinner_pid" 2>/dev/null
      fi
    fi

    export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile "$profile" 2>/dev/null)
    export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile "$profile" 2>/dev/null)
    export AWS_SESSION_TOKEN=$(aws configure get aws_session_token --profile "$profile" 2>/dev/null)
    export AWS_REGION="${target_region:-us-east-1}"
    export AWS_DEFAULT_REGION="${target_region:-us-east-1}"
    export AWS_PROFILE="$profile"
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

# Re-runs okta-aws-cli against a profile's persisted Okta app config,
# writing fresh temporary credentials (+ expiry) into ~/.aws/credentials.
function _okta_authenticate() {
  local profile="$1"
  local org_domain client_id fed_app_id region session_duration

  org_domain=$(aws configure get okta_org_domain --profile "$profile" 2>/dev/null)
  client_id=$(aws configure get okta_oidc_client_id --profile "$profile" 2>/dev/null)
  fed_app_id=$(aws configure get okta_aws_fed_app_id --profile "$profile" 2>/dev/null)
  region=$(aws configure get region --profile "$profile" 2>/dev/null)
  session_duration=$(aws configure get okta_aws_session_duration --profile "$profile" 2>/dev/null)

  if [[ -z "$org_domain" || -z "$client_id" ]]; then
    print_error "Profile '${profile}' is missing Okta configuration."
    return 1
  fi

  local -a cmd=(okta-aws-cli web
    --org-domain "$org_domain"
    --oidc-client-id "$client_id"
    --profile "$profile"
    --format aws-credentials
    --write-aws-credentials
    --expiry-aws-variables
    --open-browser)
  # Only required when the OIDC app isn't set up for multiple AWS environments;
  # if unset, okta-aws-cli will prompt for the environment/role interactively.
  [[ -n "$fed_app_id" ]] && cmd+=(--aws-acct-fed-app-id "$fed_app_id")
  [[ -n "$region" ]] && cmd+=(--aws-region "$region")
  [[ -n "$session_duration" ]] && cmd+=(--aws-session-duration "$session_duration")

  printf "\n%b==>%b Authenticating with Okta...%b\n\n" "${MAUVE}" "${TEAL}" "${RESET}" >&2
  "${cmd[@]}" >&2
  local okta_exit_status=$?
  printf "\n" >&2
  return "$okta_exit_status"
}

function _create_okta_profile() {
  if ! command -v okta-aws-cli &>/dev/null; then
    print_error "okta-aws-cli not found. Install: https://github.com/okta/okta-aws-cli"
    return 1
  fi

  local org_domain client_id fed_app_id profile_name account_type default_region region session_duration

  _prompt_read "$(printf "%bOkta org domain (e.g. my-org.okta.com): %b" "${TEAL}" "${RESET}")" org_domain ""
  [[ -z "${org_domain}" ]] && return 1
  _prompt_read "$(printf "%bOIDC client ID: %b" "${TEAL}" "${RESET}")" client_id ""
  [[ -z "${client_id}" ]] && return 1
  _prompt_read "$(printf "%bAWS Account Federation app ID (blank if org supports multiple environments): %b" "${TEAL}" "${RESET}")" fed_app_id ""

  account_type=$(printf "Commercial\nGovCloud\n" | _smart_picker "Account type: ")
  if [[ "${account_type}" == "GovCloud" ]]; then
    default_region="us-gov-west-1"
  else
    default_region="us-east-1"
  fi
  _prompt_read "$(printf "%bDefault region: %b" "${TEAL}" "${RESET}")" region "$default_region"
  _prompt_read "$(printf "%bSession duration in seconds (blank for default): %b" "${TEAL}" "${RESET}")" session_duration ""

  _prompt_read "$(printf "%bProfile name: %b" "${TEAL}" "${RESET}")" profile_name ""
  [[ -z "${profile_name}" ]] && return 1
  profile_name=$(echo "$profile_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

  aws configure set okta_org_domain "$org_domain" --profile "$profile_name"
  aws configure set okta_oidc_client_id "$client_id" --profile "$profile_name"
  [[ -n "$fed_app_id" ]] && aws configure set okta_aws_fed_app_id "$fed_app_id" --profile "$profile_name"
  [[ -n "$session_duration" ]] && aws configure set okta_aws_session_duration "$session_duration" --profile "$profile_name"
  aws configure set region "$region" --profile "$profile_name"

  _okta_authenticate "$profile_name" || return 1
  _activate_profile "$profile_name"
}

function setaws() {
  [[ -n "$ZSH_VERSION" ]] && setopt localoptions no_notify no_monitor

  local profile_name="${1:-}"
  if [[ -z "${profile_name}" ]]; then
    local choices=("[Create new API profile]" "[Create new SSO profile]" "[Create new Okta profile]")
    while IFS= read -r line; do choices+=("$line"); done < <(aws configure list-profiles 2>/dev/null)
    profile_name=$(printf '%s\n' "${choices[@]}" | _smart_picker "Select Profile: ")
  fi

  [[ -z "$profile_name" ]] && return 1

  if [[ "$profile_name" != "[Create new SSO profile]" && "$profile_name" != "[Create new API profile]" && "$profile_name" != "[Create new Okta profile]" ]]; then
    if ! aws configure list-profiles 2>/dev/null | grep -qx "$profile_name"; then
      print_warning "Profile '${profile_name}' not found. Available profiles:"
      aws configure list-profiles 2>/dev/null | while IFS= read -r p; do
        printf "  %b%s%b\n" "${MAUVE}" "$p" "${RESET}" >&2
      done
      printf "\n%bTo create a new profile run: %bsetaws%b\n" "${YELLOW}" "${GREEN}" "${RESET}" >&2
      return 1
    fi
  fi

  if [[ "$profile_name" == "[Create new SSO profile]" ]]; then
    _create_sso_profile
  elif [[ "$profile_name" == "[Create new Okta profile]" ]]; then
    _create_okta_profile
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
    _activate_profile "$profile_name"
  fi
}
