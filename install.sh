#!/bin/bash

# ==============================================================================
# Aegis-Proxy-Stack Installer
# ==============================================================================

# [Locale Setup]
export LC_ALL=C
export LANG=C

# [Constraint] Version is fixed until explicit user update
RELEASE_VERSION="v0.4.0"

# --- [Universal Color Palette] ---
TXT_RED='\033[1;31m'
TXT_GREEN='\033[1;32m'
TXT_YELLOW='\033[1;33m'
TXT_BLUE='\033[1;34m'
TXT_MAGENTA='\033[1;35m'
TXT_CYAN='\033[1;36m'
TXT_WHITE='\033[1;37m'
TXT_GRAY='\033[0;90m'

# Background Colors
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_MAGENTA='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# Formatting
BOLD='\033[1m'
RESET='\033[0m'

# --- [Visual Helper Functions] ---

print_banner() {
    clear
    local width=64
    local title="Aegis-Proxy-Stack Installer $RELEASE_VERSION"
    local title_len=${#title}
    
    local inner_width=$((width - 2))
    local pad_left=$(( (inner_width - title_len) / 2 ))
    local pad_right=$(( inner_width - title_len - pad_left ))
    
    local padding_l=$(printf '%*s' "$pad_left" "")
    local padding_r=$(printf '%*s' "$pad_right" "")
    local horizontal_line=$(printf '%*s' "$width" "" | tr ' ' '#')
    local empty_line=$(printf '%*s' "$inner_width" "")

    echo ""
    echo -e "${TXT_BLUE}   ${horizontal_line}${RESET}"
    echo -e "${TXT_BLUE}   #${RESET}${empty_line}${TXT_BLUE}#${RESET}"
    echo -e "${TXT_BLUE}   #${RESET}${padding_l}${TXT_WHITE}${BOLD}${title}${RESET}${padding_r}${TXT_BLUE}#${RESET}"
    echo -e "${TXT_BLUE}   #${RESET}${empty_line}${TXT_BLUE}#${RESET}"
    echo -e "${TXT_BLUE}   ${horizontal_line}${RESET}"
    echo -e "    ${TXT_CYAN}Automated Security Stack Deployment (Core)${RESET}"
    echo ""
}

log_step() {
    echo -e "\n${TXT_WHITE}[ Step $1 ] $2${RESET}"
    echo -e "${TXT_GRAY}----------------------------------------------------------------${RESET}"
}

log_info() {
    echo -e "   ${BG_CYAN}${TXT_WHITE}${BOLD} INFO ${RESET} $1"
}

log_task() {
    echo -e "   ${BG_BLUE}${TXT_WHITE}${BOLD} TASK ${RESET} $1"
}

log_success() {
    echo -e "   ${BG_GREEN}${TXT_WHITE}${BOLD} DONE ${RESET} $1"
}

log_warn() {
    echo -e "   ${BG_YELLOW}${TXT_WHITE}${BOLD} WARN ${RESET} $1"
}

log_error() {
    echo -e "   ${BG_RED}${TXT_WHITE}${BOLD} FAIL ${RESET} $1"
}

log_wait() {
    echo -ne "   ${BG_MAGENTA}${TXT_WHITE}${BOLD} WAIT ${RESET} $1"
}

# [FIX] Inline Input Style (Removed newline)
log_input() {
    echo -ne "   ${BG_MAGENTA}${TXT_WHITE}${BOLD} INPUT ${RESET} $1 "
}

# --- [Advanced Spinner Logic] ---
execute_with_spinner() {
    local msg="$1"
    shift
    local cmd="$@"
    
    tput civis
    eval "$cmd" > /dev/null 2>&1 &
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    local temp
    
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf "\r   ${BG_MAGENTA}${TXT_WHITE}${BOLD}  %c  ${RESET} %s" "$spinstr" "$msg"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    wait $pid
    local exit_code=$?
    
    tput cnorm
    printf "\r\033[K" # Clear line

    if [ $exit_code -eq 0 ]; then
        echo -e "   ${BG_GREEN}${TXT_WHITE}${BOLD} DONE ${RESET} $msg"
    else
        echo -e "   ${BG_RED}${TXT_WHITE}${BOLD} FAIL ${RESET} $msg"
        return 1
    fi
    echo ""
}

# --- [Main Script Start] ---

print_banner

# ------------------------------------------------------------------------------
# 0. Check Prerequisites
# ------------------------------------------------------------------------------
for pkg in jq curl node; do
    if ! command -v $pkg &> /dev/null; then
        log_error "Missing required package: '$pkg'"
        echo -e "            Please install it first (e.g., sudo apt install $pkg)"
        exit 1
    fi
done

if [ ! -f "docker-compose.yml" ]; then
    log_error "File not found: docker-compose.yml"
    exit 1
fi

# ------------------------------------------------------------------------------
# 1. Initialize Runtime Directories
# ------------------------------------------------------------------------------
log_step 1 "Initializing Data Directories"

if [ -d "aegis-data/db" ] && [ "$(ls -A aegis-data/db)" ]; then
    log_warn "Existing database detected."
    echo "            (To reinstall cleanly, run 'docker compose down' and 'sudo rm -rf aegis-data')"
fi

mkdir -p aegis-config/agent
mkdir -p aegis-config/scripts
mkdir -p aegis-config/policy

if [ ! -f "aegis-config/policy/local_policy.yaml" ]; then
    touch aegis-config/policy/local_policy.yaml
    log_task "Created placeholder policy file."
fi

if [ -f "aegis-config/advanced-model/open-appsec-advanced-model.tgz" ]; then
    chmod 640 aegis-config/advanced-model/open-appsec-advanced-model.tgz
    log_task "Secured Advanced ML Model binary."
fi

mkdir -p aegis-data/{certs,db,learning,npm}
mkdir -p aegis-logs/{npm,waf}
log_task "Created data and log directories."

chmod -R 750 aegis-config aegis-data aegis-logs
log_success "Directory permissions set (750)."


# ------------------------------------------------------------------------------
# 2. User Configuration Input (Unified)
# ------------------------------------------------------------------------------
log_step 2 "Unified Configuration Setup"

echo -e "   ${TXT_GRAY}Note: This email and password will be used for ALL services.${RESET}\n"

# 1. Master Email Input
while true; do
    log_input "Enter Master Email (ID):"
    read -r MASTER_EMAIL
    echo "" # Spacing after input
    
    if [[ "$MASTER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        break
    else
        log_warn "Invalid email format. Please try again."
        echo ""
    fi
done

# 2. Master Password Input (With Verification)
while true; do
    log_input "Enter Master Password:"
    read -rs MASTER_PASS_1
    echo "" # Newline for hidden input
    echo "" # Spacing gap

    if [ -z "$MASTER_PASS_1" ]; then
        log_warn "Password cannot be empty."
        echo ""
        continue
    fi

    log_input "Confirm Master Password:"
    read -rs MASTER_PASS_2
    echo "" # Newline for hidden input
    echo "" # Spacing gap

    if [ "$MASTER_PASS_1" == "$MASTER_PASS_2" ]; then
        MASTER_PASSWORD="$MASTER_PASS_1"
        log_success "Password verified."
        break
    else
        log_error "Passwords do not match. Please try again."
        echo ""
    fi
done

INPUT_EMAIL="$MASTER_EMAIL"
INPUT_DB_ROOT="$MASTER_PASSWORD"
INPUT_NPM_PASS="$MASTER_PASSWORD"


# ------------------------------------------------------------------------------
# 3. Environment & Version Files
# ------------------------------------------------------------------------------
log_step 3 "Generating Environment Files"

if [ -f ".env" ]; then
    cp .env .env.bak
fi

cat <<EOF > .env
# [Aegis-Proxy-Stack Environment Variables]
AGENT_EMAIL=${INPUT_EMAIL}
DB_ROOT_PASSWORD=${INPUT_DB_ROOT}
NPM_DB_PASSWORD=${INPUT_NPM_PASS}
EOF
chmod 600 .env
log_success ".env file generated."

echo "$RELEASE_VERSION" > VERSION
log_success "VERSION file generated ($RELEASE_VERSION)."


# ------------------------------------------------------------------------------
# 4. Policy Controller Setup
# ------------------------------------------------------------------------------
log_step 4 "Setting up Policy Controller"

# [Check] Ensure static script exists
if [ ! -f "aegis-config/scripts/policy_generator.js" ]; then
    log_error "File not found: aegis-config/scripts/policy_generator.js"
    echo -e "            Please ensure the policy generator script is present."
    exit 1
else
    log_success "Found policy_generator.js."
fi

log_task "Installing NPM dependencies (axios, js-yaml, lodash)..."
npm install axios js-yaml lodash --prefix aegis-config/scripts --silent >/dev/null 2>&1
log_success "Policy Controller dependencies installed."


# ------------------------------------------------------------------------------
# 5. Docker Service Startup & Account Config
# ------------------------------------------------------------------------------
log_step 5 "Docker Service Startup & Configuration"

while true; do
    log_input "Start services now? (Y/n):"
    read -r CONFIRM
    echo "" 
    CONFIRM=${CONFIRM:-Y}
    case $CONFIRM in
        [yY]*)
            echo -e "   ${TXT_YELLOW}🔄 Starting Docker Compose...${RESET}"
            docker compose up -d
            if [ $? -ne 0 ]; then log_error "Docker launch failed."; exit 1; fi
            
            echo ""
            log_success "Core services started."
            
            # --- [CRITICAL FIX: Initial Account Configuration] ---
            # Wait for NPM API
            NPM_API="http://localhost:81/api"
            check_api() {
                local count=0
                while [ $count -lt 90 ]; do
                    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "$NPM_API/schema")
                    if [ "$code" == "200" ]; then return 0; fi
                    sleep 2
                    count=$((count+1))
                done
                return 1
            }
            
            execute_with_spinner "Waiting for NPM API to initialize..." check_api || { log_error "NPM API timed out."; exit 1; }
            
            # Helper to get token
            get_token() {
                local u=$1; local p=$2
                curl -s -X POST "$NPM_API/tokens" \
                    -H "Content-Type: application/json" \
                    -d "{\"identity\":\"$u\",\"secret\":\"$p\"}"
            }
            
            # 1. Login with DEFAULT credentials
            log_task "Configuring Admin Account..."
            DEFAULT_USER="admin@example.com"
            DEFAULT_PASS="changeme"
            
            # Try Default Login
            RAW_RES=$(get_token "$DEFAULT_USER" "$DEFAULT_PASS")
            TOKEN=$(echo "$RAW_RES" | jq -r '.token // empty')
            
            if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
                # 2. Change Password
                PW_PAYLOAD=$(jq -n --arg s "$INPUT_NPM_PASS" --arg c "$DEFAULT_PASS" '{type: "password", secret: $s, current: $c}')
                curl -s -o /dev/null -X PUT "$NPM_API/users/1/auth" \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/json" \
                    -d "$PW_PAYLOAD"
                
                # 3. Change Email/Name (Re-login required? usually token is still valid for user update)
                # Re-login with NEW password to be safe and verify change
                RAW_RES_2=$(get_token "$DEFAULT_USER" "$INPUT_NPM_PASS")
                TOKEN_2=$(echo "$RAW_RES_2" | jq -r '.token // empty')
                
                if [ -n "$TOKEN_2" ]; then
                    UPDATE_PAYLOAD=$(jq -n --arg e "$INPUT_EMAIL" '{name: "Administrator", nickname: "Admin", email: $e}')
                    curl -s -o /dev/null -X PUT "$NPM_API/users/1" \
                        -H "Authorization: Bearer $TOKEN_2" \
                        -H "Content-Type: application/json" \
                        -d "$UPDATE_PAYLOAD"
                    log_success "Admin account updated to: $INPUT_EMAIL"
                else
                    log_error "Failed to verify new password."
                    exit 1
                fi
            else
                # Login failed. Assuming already configured?
                # Try logging in with the Master Password provided
                RAW_RES_CHECK=$(get_token "$INPUT_EMAIL" "$INPUT_NPM_PASS")
                TOKEN_CHECK=$(echo "$RAW_RES_CHECK" | jq -r '.token // empty')
                
                if [ -n "$TOKEN_CHECK" ]; then
                    log_success "Account already configured. Skipping setup."
                else
                    log_warn "Could not login with default OR new credentials. Check logs."
                fi
            fi
            
            echo ""
            log_success "Installation Complete."
            
            # --- [Launch Verification] ---
            log_input "Run verification script (verify_all.sh) now? (Y/n):"
            read -r RUN_VERIFY
            echo ""
            RUN_VERIFY=${RUN_VERIFY:-Y}
            
            if [[ "$RUN_VERIFY" =~ ^[yY] ]]; then
                if [ -f "./verify_all.sh" ]; then
                    chmod +x ./verify_all.sh
                    # Pass credentials to verify script
                    export MASTER_EMAIL="$INPUT_EMAIL"
                    export MASTER_PASSWORD="$INPUT_DB_ROOT"
                    ./verify_all.sh
                else
                    log_error "verify_all.sh not found."
                fi
            else
                echo -e "   ${TXT_CYAN}➜ Run './verify_all.sh' manually when ready.${RESET}"
                echo ""
            fi
            break ;;
        [nN]*) log_info "Installation aborted by user."; exit 0 ;;
        *) echo "   ${TXT_YELLOW}[WARN] Please enter Y or N.${RESET}" ;;
    esac
done