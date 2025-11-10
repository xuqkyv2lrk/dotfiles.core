_get_container_color() {
  local name="$1"
  local colors=("blue" "turquoise" "green" "yellow" "orange" "red" "pink" "purple")
  local idx=$(( $(printf "%s" "$name" | sha256sum | awk '{print "0x"substr($1,1,8)}') % ${#colors[@]} ))
  echo "${colors[$idx]}"
}

_pick_aws_profile() {
  local profiles=($(aws configure list-profiles 2>/dev/null))
  local profile_name
  if command -v fzf &>/dev/null; then
    profile_name="$(printf '%s\n' "${profiles[@]}" | fzf --prompt="${CMOCHA_CYAN}Select AWS profile: ${NC}" 2>/dev/null || true)"
  else
    printf "${CMOCHA_BLUE}Available profiles:${NC}\n"
    for i in {1..${#profiles[@]}}; do
      printf "  %s%d) %s${NC}\n" "${CMOCHA_CYAN}" "$i" "${profiles[$i]}"
    done
    printf "${CMOCHA_CYAN}  Enter the number of the profile to use: ${NC}"
    read selection
    if [[ ! "${selection}" =~ '^[0-9]+$' ]] || (( selection < 1 || selection > ${#profiles[@]} )); then
      printf "${CMOCHA_YELLOW}  ⚠️ Invalid selection. Aborting.${NC}\n"
      return 1
    fi
    profile_name="${profiles[$selection]}"
  fi
  if [[ -z "${profile_name}" ]]; then
    printf "${CMOCHA_YELLOW}  ⚠️ No profile selected. Aborting.${NC}\n"
    return 1
  fi
  echo "$profile_name"
}

_get_sso_start_url() {
  local profile="$1"
  local sso_session
  sso_session="$(aws configure get sso_session --profile "$profile" 2>/dev/null)"
  if [[ -n "$sso_session" ]]; then
    awk -v session="$sso_session" '
      $0 ~ "\\[sso-session "session"\\]" {found=1; next}
      /^\[.*\]/ {found=0}
      found && $1 == "sso_start_url" {print $3; exit}
    ' ~/.aws/config
  else
    aws configure get sso_start_url --profile "$profile" 2>/dev/null
  fi
}

_urlencode() {
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

# --- Public Function: setaws ---

function setaws {
  local profile_name="${1}"
  set +m

  # Interactive profile picker and new profile options
  if [[ -z "${profile_name}" ]]; then
    local profiles
    profiles=("[Create new API profile]" "[Create new SSO profile]")
    local aws_profiles
    aws_profiles=($(aws configure list-profiles 2>/dev/null))
    profiles+=("${aws_profiles[@]}")
    if command -v fzf &>/dev/null; then
      profile_name="$(printf '%s\n' "${profiles[@]}" | fzf --prompt='Select AWS profile: ' 2>/dev/null || true)"
    else
      for i in {1..${#profiles[@]}}; do
        printf "  %d) %s\n" $i "${profiles[$i]}"
      done
      printf "%b" "${CMOCHA_CYAN}  Enter the number of the profile to use: ${NC}"
      read selection
      if [[ ! "${selection}" =~ '^[0-9]+$' ]] || (( selection < 1 || selection > ${#profiles[@]} )); then
        printf "%b\n" "${CMOCHA_YELLOW}  ⚠️ Invalid selection. Aborting.${NC}"
        set -m
        return 1
      fi
      profile_name="${profiles[$selection]}"
    fi
    if [[ "${profile_name}" == "[Create new SSO profile]" ]]; then
      printf "%b\n" "${CMOCHA_CYAN}  Launching AWS SSO profile creation wizard...${NC}"
      aws configure sso
      if [[ $? -ne 0 ]]; then
        printf "%b\n" "${CMOCHA_RED}  ❌ SSO profile creation failed or was cancelled.${NC}"
        set -m
        return 1
      fi
      setaws
      return
    elif [[ "${profile_name}" == "[Create new API profile]" ]]; then
      printf "%b\n" "${CMOCHA_CYAN}  Creating new API-based profile...${NC}"
      printf "%b" "${CMOCHA_CYAN}  Enter a name for the new profile: ${NC}"
      read new_profile
      printf "%b" "${CMOCHA_CYAN}  Enter AWS Access Key ID: ${NC}"
      read access_key
      printf "%b" "${CMOCHA_CYAN}  Enter AWS Secret Access Key: ${NC}"
      read -s secret_key
      printf "\n"
      printf "%b" "${CMOCHA_CYAN}  Enter default region (e.g. us-east-1): ${NC}"
      read region
      aws configure set aws_access_key_id "${access_key}" --profile "${new_profile}"
      aws configure set aws_secret_access_key "${secret_key}" --profile "${new_profile}"
      aws configure set region "${region}" --profile "${new_profile}"
      printf "%b\n" "${CMOCHA_GREEN}  ✅ Created new API profile: ${new_profile}${NC}"
      profile_name="${new_profile}"
    elif [[ -z "${profile_name}" ]]; then
      printf "%b\n" "${CMOCHA_YELLOW}  ⚠️ No profile selected. Aborting.${NC}"
      set -m
      return 1
    fi
  fi

  if ! command -v aws &>/dev/null; then
    printf "%b\n" "${CMOCHA_RED}  ❌ AWS CLI not found${NC}"
    set -m
    return 1
  fi

  if ! aws configure list-profiles | grep -qx "${profile_name}"; then
    printf "%b\n" "${CMOCHA_YELLOW}  ⚠️ Profile ${CMOCHA_PURPLE}${profile_name}${CMOCHA_YELLOW} not found${NC}"
    set -m
    return 1
  fi

  printf "\r${CMOCHA_CYAN}  Exporting credentials for ${CMOCHA_PURPLE}${profile_name}${CMOCHA_CYAN}...${NC} "
  spinner & spinner_pid=${!}
  export_output="$(aws configure export-credentials --profile "${profile_name}" --format env 2>&1)"
  export_exit_code=${?}
  if [[ "${export_exit_code}" -eq 0 ]]; then
    eval "${export_output}"
    stop_spinner
    printf "\r${CMOCHA_CYAN}  Exporting credentials for ${CMOCHA_PURPLE}${profile_name}${CMOCHA_CYAN}... ${CMOCHA_GREEN}✅${NC}\n"
  else
    stop_spinner
    printf "\r${CMOCHA_CYAN}  Exporting credentials for ${CMOCHA_PURPLE}${profile_name}${CMOCHA_CYAN}... ${CMOCHA_RED}❌${NC}\n"
    if [[ "${export_output}" == *"Token for"* ]] || [[ "${export_output}" == *"Token has expired"* ]] || [[ "${export_output}" == *"SSO Token: Token"* ]]; then
      printf "\r${CMOCHA_CYAN}  Session expired or token missing. Renewing... ${CMOCHA_YELLOW}⚠️${NC}\n"
      login_output="$(aws sso login --profile "${profile_name}" 2>&1)"
      login_exit_code=${?}
      echo "${login_output}" | while IFS= read -r line; do
        printf "  %s\n" "${line}"
      done
      if [[ "${login_exit_code}" -eq 0 ]]; then
        printf "\r${CMOCHA_CYAN}  Retrying export...${NC} "
        spinner & spinner_pid=${!}
        export_output="$(aws configure export-credentials --profile "${profile_name}" --format env 2>&1)"
        if [[ "${?}" -eq 0 ]]; then
          eval "${export_output}"
          stop_spinner
          printf "\r${CMOCHA_CYAN}  Exporting credentials for ${CMOCHA_PURPLE}${profile_name}${CMOCHA_CYAN}... ${CMOCHA_GREEN}✅${NC}\n"
        else
          stop_spinner
          printf "\r${CMOCHA_CYAN}  Renewal failed... ${CMOCHA_RED}❌${NC}\n"
          printf "  ${CMOCHA_YELLOW}%s${NC}\n" "${export_output}"
          set -m
          return 1
        fi
      else
        printf "\r${CMOCHA_CYAN}  Auto-renew failed... ${CMOCHA_RED}❌${NC}\n"
        set -m
        return 1
      fi
    else
      printf "  ${CMOCHA_YELLOW}⚠️ Error: %s${NC}\n" "${export_output}"
      set -m
      return 1
    fi
  fi

  printf "\r${CMOCHA_CYAN}  Validating credentials for ${CMOCHA_PURPLE}${profile_name}${CMOCHA_CYAN}...${NC} "
  spinner & spinner_pid=${!}
  error_output="$(aws sts get-caller-identity --query 'Account' --output text 2>&1 > /dev/null)"
  if AWS_ACCOUNT="$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)"; then
    export AWS_ACCOUNT
    if AWS_ACCOUNT_ALIAS="$(aws iam list-account-aliases --query 'AccountAliases' --output text 2>/dev/null)"; then
      export AWS_ACCOUNT_ALIAS
      stop_spinner
      printf "\r${CMOCHA_CYAN}  Validating credentials for ${CMOCHA_PURPLE}${profile_name}${CMOCHA_CYAN}... ${CMOCHA_GREEN}✅${NC}\n"
      printf "  Account ID: ${CMOCHA_CYAN}%s${NC}\n" "${AWS_ACCOUNT}"
    else
      stop_spinner
      printf "\r${CMOCHA_CYAN}  Validating credentials for ${CMOCHA_PURPLE}${profile_name}${CMOCHA_CYAN}... Could not retrieve AWS account alias ${CMOCHA_YELLOW}⚠️${NC}\n"
      export AWS_ACCOUNT_ALIAS=""
    fi
  else
    stop_spinner
    if echo "${error_output}" | grep -q -e "ExpiredToken"; then
      printf "\r${CMOCHA_CYAN}  Validation failed... ${CMOCHA_RED}❌${NC}\n"
      printf "  ${CMOCHA_YELLOW}⚠️ Detected late expiry. Forcing renewal...${NC}\n"
      setaws "${profile_name}"
    else
      printf "\r${CMOCHA_CYAN}  Validation failed... ${CMOCHA_RED}❌${NC}\n"
      printf "  ${CMOCHA_YELLOW}%s${NC}\n" "${error_output}"
      set -m
      return 1
    fi
  fi

  set -m
}

# --- Public Function: awsconsole ---

function awsconsole {
  local profile_name="${1}"
  local container_name="${2}"
  set +m

  local container_icon="briefcase"

  # Profile picker
  if [[ -z "${profile_name}" ]]; then
    profile_name="$(_pick_aws_profile)" || { set -m; return 1; }
  fi

  # If no container name specified, use the profile name
  if [[ -z "${container_name}" ]]; then
    container_name="${profile_name}"
  fi

  local container_color="$(_get_container_color "${container_name}")"

  # Detect SSO profile and resolve sso-session
  local sso_account_id sso_role_name sso_url region
  sso_account_id="$(aws configure get sso_account_id --profile "${profile_name}" 2>/dev/null)"
  sso_role_name="$(aws configure get sso_role_name --profile "${profile_name}" 2>/dev/null)"
  region="$(aws configure get region --profile "${profile_name}" 2>/dev/null)"
  sso_url="$(_get_sso_start_url "${profile_name}")"

  local url

  if [[ -n "${sso_url}" && -n "${sso_account_id}" && -n "${sso_role_name}" ]]; then
    spinner & spinner_pid=$!
    local destination="https://console.aws.amazon.com/"
    local destination_enc
    destination_enc=$(_urlencode "${destination}")
    url="${sso_url}/#/console?account_id=${sso_account_id}&role_name=${sso_role_name}&destination=${destination_enc}"
    stop_spinner
    printf "${CMOCHA_GREEN}  Opening AWS Console for SSO profile %s in container '%s' (color: %s, icon: %s)${NC}\n" "${profile_name}" "${container_name}" "${container_color}" "${container_icon}"
  else
    spinner & spinner_pid=$!
    local creds_json
    creds_json="$(aws --profile "${profile_name}" sts get-caller-identity --output json 2>/dev/null)"
    stop_spinner
    if [[ -z "${creds_json}" ]]; then
      printf "${CMOCHA_RED}  Could not retrieve credentials for profile %s${NC}\n" "${profile_name}"
      set -m
      return 1
    fi

    local access_key secret_key session_token
    access_key="$(aws configure get aws_access_key_id --profile "${profile_name}")"
    secret_key="$(aws configure get aws_secret_access_key --profile "${profile_name}")"
    session_token="$(aws configure get aws_session_token --profile "${profile_name}")"

    if [[ -z "${session_token}" ]]; then
      spinner & spinner_pid=$!
      local session_json
      session_json="$(aws --profile "${profile_name}" sts get-session-token --duration-seconds 3600 --output json 2>/dev/null)"
      stop_spinner
      access_key="$(echo "${session_json}" | jq -r '.Credentials.AccessKeyId')"
      secret_key="$(echo "${session_json}" | jq -r '.Credentials.SecretAccessKey')"
      session_token="$(echo "${session_json}" | jq -r '.Credentials.SessionToken')"
    fi

    if [[ -z "${access_key}" || -z "${secret_key}" || -z "${session_token}" ]]; then
      printf "${CMOCHA_RED}  Could not retrieve valid AWS credentials for profile %s${NC}\n" "${profile_name}"
      set -m
      return 1
    fi

    spinner & spinner_pid=$!
    local session
    session="{\"sessionId\":\"${access_key}\",\"sessionKey\":\"${secret_key}\",\"sessionToken\":\"${session_token}\"}"
    local signin_token
    signin_token="$(curl -s "https://signin.aws.amazon.com/federation?Action=getSigninToken&Session=$(_urlencode "${session}")" | jq -r .SigninToken)"
    url="https://signin.aws.amazon.com/federation?Action=login&Issuer=Example.org&Destination=https%3A%2F%2Fconsole.aws.amazon.com%2F&SigninToken=${signin_token}"
    stop_spinner
    printf "${CMOCHA_GREEN}  Opening federated AWS Console for IAM/role profile %s in container '%s' (color: %s, icon: %s)${NC}\n" "${profile_name}" "${container_name}" "${container_color}" "${container_icon}"
  fi

  # Build the container URL for the Firefox extension
  local container_url="ext+container:name=${container_name}&color=${container_color}&icon=${container_icon}&url=${url}"

  # Open in Firefox container tab
  case "$(uname -s)" in
    Linux*)
      if command -v firefox &>/dev/null; then
        printf "${CMOCHA_CYAN}  Launching Firefox...${NC}\n"
        nohup firefox "${container_url}" > /dev/null 2>&1
      else
        printf "${CMOCHA_RED}  Firefox not found. Please install Firefox to use container tabs.${NC}\n"
        set -m
        return 1
      fi
      ;;
    Darwin*)
      printf "${CMOCHA_CYAN}  Launching Firefox...${NC}\n"
      open -a Firefox "${container_url}" > /dev/null 2>&1
      ;;
    *)
      printf "${CMOCHA_RED}  Unsupported operating system.${NC}\n"
      set -m
      return 1
      ;;
  esac

  set -m
}
