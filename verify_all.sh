#!/bin/bash

# ==============================================================================
# Aegis-Proxy-Stack Verifier
# ==============================================================================

# [Locale Setup]
export LC_ALL=C
export LANG=C

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
BLINK='\033[5m'
RESET='\033[0m'

# --- [Visual Helper Functions] ---

print_banner() {
    clear
    local width=64
    local title="Aegis-Proxy-Stack Verifier"
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
    echo -e "    ${TXT_CYAN}Automated Configuration & Security Verification${RESET}"
    echo ""
}

log_step() {
    echo -e "\n${TXT_WHITE}[ Step $1 ] $2${RESET}"
    echo -e "${TXT_GRAY}----------------------------------------------------------------${RESET}"
}

log_info() {
    echo -e "   ${BG_CYAN}${TXT_WHITE}${BOLD} INFO ${RESET} $1"
    echo ""
}

log_task() {
    echo -e "   ${BG_BLUE}${TXT_WHITE}${BOLD} TASK ${RESET} $1"
    echo ""
}

log_success() {
    echo -e "   ${BG_GREEN}${TXT_WHITE}${BOLD} DONE ${RESET} $1"
    echo ""
}

log_warn() {
    echo -e "   ${BLINK}${BG_YELLOW}${TXT_WHITE}${BOLD} WARN ${RESET} $1"
    echo ""
}

log_error() {
    echo -e "   ${BLINK}${BG_RED}${TXT_WHITE}${BOLD} FAIL ${RESET} $1"
    echo ""
}

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
# 0. Load Configuration & Initialize Credentials
# ------------------------------------------------------------------------------
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Initialize with environment variables if passed
NPM_USER="${MASTER_EMAIL:-}"
NPM_PASS="${MASTER_PASSWORD:-}"

# Logic: If missing, prompt immediately
if [ -z "$NPM_USER" ] || [ -z "$NPM_PASS" ]; then
    while true; do
        log_input "Enter NPM Admin Email:"
        read -r NPM_USER
        echo ""
        if [ -n "$NPM_USER" ]; then break; fi
    done

    while true; do
        log_input "Enter NPM Admin Password:"
        read -rs NPM_PASS
        echo ""
        echo ""
        if [ -n "$NPM_PASS" ]; then break; fi
    done
fi

# ------------------------------------------------------------------------------
# 1. Container Status Check
# ------------------------------------------------------------------------------
log_step 1 "Docker Container & Agent Status Check"

echo -e "   ${TXT_WHITE}[ Docker Container Status ]${RESET}"
echo -e "   ${TXT_GRAY}------------------------------------------------${RESET}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

if docker compose ps agent | grep -q "Up"; then
    execute_with_spinner "Retrieving open-appsec Agent Status..." "sleep 1"
    
    echo -e "   ${TXT_WHITE}[ open-appsec Agent Status ]${RESET}"
    echo -e "   ${TXT_GRAY}------------------------------------------------${RESET}"
    docker compose exec agent open-appsec-ctl --status
    echo ""
    
    log_success "Agent container is running and accessible."
else
    log_error "Agent container is NOT running. Please check logs."
    exit 1
fi


# ------------------------------------------------------------------------------
# 2. NPM Authentication & Policy Sync
# ------------------------------------------------------------------------------
log_step 2 "NPM Authentication & Policy Sync"

NPM_API="http://localhost:81/api"

# 2-1. Service Wait
check_api() {
    local max_retries=90
    local count=0
    while [ $count -lt $max_retries ]; do
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "$NPM_API/schema")
        if [ "$code" == "200" ]; then return 0; fi
        sleep 2
        count=$((count+1))
    done
    return 1
}

execute_with_spinner "Waiting for NPM API (max 180s)..." check_api || { log_error "NPM API timed out."; exit 1; }

# [Helper] JSON Generator
get_token() {
    local u=$1
    local p=$2
    export _JQ_USER="$u"
    export _JQ_PASS="$p"
    local payload=$(jq -n '{identity: env._JQ_USER, secret: env._JQ_PASS}')
    curl -s -X POST "$NPM_API/tokens" -H "Content-Type: application/json" -d "$payload"
    unset _JQ_USER _JQ_PASS
}

# 2-2. Authenticate (Loop until success)
log_task "Authenticating with NPM..."

TOKEN=""
while true; do
    RAW_RES=$(get_token "$NPM_USER" "$NPM_PASS")
    TOKEN=$(echo "$RAW_RES" | jq -r '.token // empty')

    if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
        log_success "Login successful."
        break
    else
        log_warn "Login failed. Credentials might be incorrect."
        echo -e "   ${TXT_GRAY}Please re-enter valid credentials to proceed.${RESET}\n"
        
        NPM_USER=""
        NPM_PASS=""
        
        while true; do
            log_input "Enter NPM Admin Email:"
            read -r NPM_USER
            echo ""
            if [ -n "$NPM_USER" ]; then break; fi
        done

        while true; do
            log_input "Enter NPM Admin Password:"
            read -rs NPM_PASS
            echo ""
            echo ""
            if [ -n "$NPM_PASS" ]; then break; fi
        done
    fi
done

# 2-3. Register Test Host (with FORCE Update)
log_task "Registering Test Host (test.aegis.local)..."

if [ -n "$TOKEN" ]; then
    PAYLOAD=$(jq -n '{
      domain_names: ["test.aegis.local"],
      forward_scheme: "http",
      forward_host: "127.0.0.1",
      forward_port: 81,
      access_list_id: "0",
      certificate_id: 0,
      ssl_forced: false,
      meta: { openappsec: { enabled: true, mode: "prevent-learn", minimum_confidence: "medium" } },
      advanced_config: "",
      locations: [],
      block_exploits: false
    }')
    
    EXIST_HOST=$(curl -s -X GET "$NPM_API/nginx/proxy-hosts" -H "Authorization: Bearer $TOKEN" | jq -r '.[] | select(.domain_names[] | contains("test.aegis.local"))')
    
    if [ -z "$EXIST_HOST" ]; then
        curl -s -o /dev/null -X POST "$NPM_API/nginx/proxy-hosts" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD"
        log_success "Host Registered (Mode: Prevent-Learn)."
    else
        HOST_ID=$(echo "$EXIST_HOST" | jq -r '.id')
        curl -s -o /dev/null -X PUT "$NPM_API/nginx/proxy-hosts/$HOST_ID" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD"
        log_success "Host Updated: Enforced 'Prevent-Learn' Mode."
    fi
else
    log_error "Authentication failed. Cannot register host."
    exit 1
fi

# 2-4. Execute Policy Controller
log_task "Executing Policy Controller..."

# Inject Configuration for Node Script
export NPM_USER="$NPM_USER"
export NPM_PASS="$NPM_PASS"
export NPM_API="$NPM_API"
export APPSEC_MODE="prevent-learn"      # [Config] Mode
export APPSEC_CONFIDENCE="medium"       # [Config] Confidence
export POLICY_FILE="../policy/local_policy.yaml"

# Node Path Setup
export NODE_PATH="./aegis-config/scripts/node_modules"

# Check if script exists
SCRIPT_PATH="aegis-config/scripts/policy_generator.js"
if [ ! -f "$SCRIPT_PATH" ]; then
    log_error "Policy Generator script not found at $SCRIPT_PATH"
    exit 1
fi

# Execute Static Script
cd aegis-config/scripts
node policy_generator.js
CD_RES=$?
cd ../..

if [ $CD_RES -ne 0 ]; then
    log_error "Policy generation failed."
    exit 1
fi
echo "" 

# Apply Policy
execute_with_spinner "Applying WAF Policy (Reloading)..." "docker compose exec -T agent open-appsec-ctl --apply-policy /etc/cp/conf/local_policy.yaml"


# ------------------------------------------------------------------------------
# 3. Security Function Verification
# ------------------------------------------------------------------------------
log_step 3 "Security Function Verification (WAF Test)"

TEST_URL="http://test.aegis.local/?id=1%27%20OR%20%271%27=%271"
RESOLVE="test.aegis.local:80:127.0.0.1"

# --- [Smart Wait Logic: Activation + Stability Check] ---
tput civis # Hide cursor
spinstr='|/-\'
WAF_READY=false
CONSECUTIVE_SUCCESS=0
TARGET_SUCCESS=3 # Need 3 consecutive blocks
MAX_WAIT=300     # 300 checks

for ((i=1; i<=MAX_WAIT; i++)); do
    temp=${spinstr#?}
    
    if [ $CONSECUTIVE_SUCCESS -eq 0 ]; then
        MSG="Waiting for WAF Engine activation..."
    else
        MSG="Verifying Stability... ($CONSECUTIVE_SUCCESS/$TARGET_SUCCESS)"
    fi
    
    printf "\r   ${BG_MAGENTA}${TXT_WHITE}${BOLD}  %c  ${RESET} %s" "$spinstr" "$MSG"
    spinstr=$temp${spinstr%"$temp"}
    
    CODE=$(curl --no-keepalive -s -o /dev/null -w "%{http_code}" --resolve "$RESOLVE" "$TEST_URL")
    
    if [ "$CODE" == "403" ]; then
        CONSECUTIVE_SUCCESS=$((CONSECUTIVE_SUCCESS+1))
    else
        CONSECUTIVE_SUCCESS=0
    fi
    
    if [ $CONSECUTIVE_SUCCESS -ge $TARGET_SUCCESS ]; then
        WAF_READY=true
        break
    fi
    
    sleep 1
done

tput cnorm
printf "\r\033[K" # Clear line

if [ "$WAF_READY" = true ]; then
    echo -e "   ${BG_GREEN}${TXT_WHITE}${BOLD} DONE ${RESET} WAF Engine Active & Stable (Ready)."
else
    log_warn "WAF Block verification timed out or unstable (Last HTTP: $CODE)."
fi
echo ""

# 2. Final Security Tests
TEST_FAILED=0

# Test 1: Normal Access
HTTP_CODE_NORMAL=$(curl --no-keepalive -s -o /dev/null -w "%{http_code}" --resolve "$RESOLVE" "http://test.aegis.local/")
if [[ "$HTTP_CODE_NORMAL" == "200" || "$HTTP_CODE_NORMAL" == "302" ]]; then
    log_success "Normal Traffic: Allowed (HTTP $HTTP_CODE_NORMAL)"
else
    log_error "Normal Traffic: Blocked/Failed (HTTP $HTTP_CODE_NORMAL)"
    TEST_FAILED=1
fi

# Test 2: XSS
HTTP_CODE_XSS=$(curl --no-keepalive -s -o /dev/null -w "%{http_code}" --resolve "$RESOLVE" "http://test.aegis.local/?q=<script>alert(1)</script>")
if [ "$HTTP_CODE_XSS" == "403" ]; then
    log_success "XSS Attack: Blocked (HTTP 403)"
else
    log_error "XSS Attack: Failed (HTTP $HTTP_CODE_XSS)"
    TEST_FAILED=1
fi

# Test 3: SQLi
HTTP_CODE_SQLI=$(curl --no-keepalive -s -o /dev/null -w "%{http_code}" --resolve "$RESOLVE" "$TEST_URL")
if [ "$HTTP_CODE_SQLI" == "403" ]; then
    log_success "SQL Injection: Blocked (HTTP 403)"
else
    log_error "SQL Injection: Failed (HTTP $HTTP_CODE_SQLI)"
    TEST_FAILED=1
fi

echo ""
echo -e "${TXT_BLUE}################################################################${RESET}"
if [ $TEST_FAILED -eq 0 ]; then
    echo -e "   ${TXT_GREEN}[ SUCCESS ]${RESET} All checks passed successfully!"
    echo -e "   ${TXT_WHITE}NPM Dashboard:${RESET} http://localhost:81"
    echo -e "   ${TXT_WHITE}Admin ID:${RESET}      $NPM_USER"
else
    echo -e "   ${TXT_YELLOW}[ WARNING ]${RESET} Some security checks failed."
    echo -e "               Check logs: 'docker compose logs agent'"
fi
echo -e "${TXT_BLUE}################################################################${RESET}"