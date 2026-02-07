#!/bin/bash

# ==============================================================================
# Aegis Proxy Stack - Intelligent Release Manager (Self-Updating)
# ==============================================================================
# Description: 1. 스크립트 자체 업데이트 (Self-Update)
#              2. 시스템 안전 백업 (Full Backup)
#              3. Git 기반 버전 동기화 (Version Sync)
# Repository: https://github.com/NanumInfo/Aegis-Proxy-Stack
# ==============================================================================

# --- [환경 설정] ---
BASE_DIR=$(pwd)
VERSION_FILE="$BASE_DIR/VERSION"
BACKUP_DIR="$BASE_DIR/backups"
CONFIG_DIR="$BASE_DIR/aegis-config"
DATA_DIR="$BASE_DIR/aegis-data"
LOGS_DIR="$BASE_DIR/aegis-logs"
COMPOSE_FILE="$BASE_DIR/docker-compose.yml"

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- [헬퍼 함수] ---
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ------------------------------------------------------------------------------
# 헬퍼 함수: 버전 확인 및 비교
# ------------------------------------------------------------------------------
get_local_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "v0.2.x" # 기본값
    fi
}

# $1 > $2 이면 성공(0), 아니면 실패(1) 반환 (Semantic Versioning)
ver_gt() {
    [ "$1" = "$2" ] && return 1 || [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ] && return 1 || return 0
}

# ------------------------------------------------------------------------------
# Phase 1: 스크립트 자기 자신 업데이트 (Self-Update Logic)
# ------------------------------------------------------------------------------
perform_self_update() {
    if [ "$1" == "--no-self-update" ]; then return; fi

    log "최신 업데이트 정보를 확인하는 중..."
    git fetch --tags --force > /dev/null 2>&1
    
    # 로컬 버전과 리모트 최신 태그 비교
    LOCAL_VER=$(get_local_version)
    LATEST_TAG=$(git tag -l | sort -V | tail -n 1)

    # [핵심] 리모트 태그가 존재하고, 로컬 버전보다 클 때만 스크립트 갱신 시도
    if [ -n "$LATEST_TAG" ] && ver_gt "$LATEST_TAG" "$LOCAL_VER"; then
        
        TEMP_SCRIPT="/tmp/update_new.sh"
        git show "tags/$LATEST_TAG:update.sh" > "$TEMP_SCRIPT" 2>/dev/null

        # 파일이 있고 내용이 다를 때만 덮어쓰기
        if [ -s "$TEMP_SCRIPT" ] && ! cmp -s "$0" "$TEMP_SCRIPT"; then
            echo -e "${YELLOW}🔄 새로운 업데이트 매니저($LATEST_TAG)가 감지되었습니다.${NC}"
            echo -e "${YELLOW}   스크립트를 최신 상태로 갱신하고 재시작합니다...${NC}"
            mv "$TEMP_SCRIPT" "$0"
            chmod +x "$0"
            exec "$0" "--no-self-update"
        else
            rm -f "$TEMP_SCRIPT"
        fi
    else
        rm -f /tmp/update_new.sh
    fi
}

# ------------------------------------------------------------------------------
# Phase 2: 시스템 업데이트 (System Update Logic)
# ------------------------------------------------------------------------------

# 필수 파일 사후 검증 함수
verify_files_after_pull() {
    local TARGET_VER=$1
    # v0.3.0 이상인 경우 모델 파일 체크
    if [[ "$TARGET_VER" == *"v0.3"* ]]; then
        MODEL_PATH="$CONFIG_DIR/advanced-model/open-appsec-advanced-model.tgz"
        
        # 파일 존재 여부 확인
        if [ ! -f "$MODEL_PATH" ]; then
             warn "모델 파일이 다운로드되지 않았습니다. Git 상태를 확인하세요."
             return
        fi
        
        # 파일 용량 확인 (500KB 미만이면 경고)
        SIZE=$(du -k "$MODEL_PATH" | cut -f1)
        if [ "$SIZE" -lt 500 ]; then
             warn "모델 파일 용량이 너무 작습니다 ($SIZE KB). 파일이 손상되었을 수 있습니다."
        else
             success "Advanced Model 파일 검증 완료 ($SIZE KB)."
        fi
    fi
}

# --- [메인 실행부] ---

# 1. 가장 먼저 자기 자신을 업데이트 시도
perform_self_update "$1"

clear
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Aegis Proxy Stack - Release Manager      ${NC}"
echo -e "${GREEN}============================================${NC}"

# 2. 버전 정보 수집
LOCAL_VER=$(get_local_version)
git fetch --tags --force > /dev/null 2>&1
REMOTE_VER=$(git tag -l | sort -V | tail -n 1)

echo -e "🔹 현재 시스템 버전: ${YELLOW}$LOCAL_VER${NC}"
echo -e "🔹 최신 배포 버전:   ${GREEN}$REMOTE_VER${NC}"
echo ""

if [ "$LOCAL_VER" == "$REMOTE_VER" ]; then
    success "현재 최신 버전을 사용 중입니다."
    exit 0
fi

# 3. 사용자 승인
echo "새로운 버전($REMOTE_VER)으로 업데이트하시겠습니까? (y/n)"
read -p "> " CHOICE

if [[ "$CHOICE" != "y" && "$CHOICE" != "Y" ]]; then
    echo "취소되었습니다."
    exit 0
fi

# [중요 변경] 사전 요구사항 검증(check_requirements) 제거
# 이유: 아직 파일을 다운로드(Git Reset) 하기 전이므로 검사 불가.

# 4. 안전 백업 (Full Backup)
log "시스템 전체 백업을 시작합니다..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/${LOCAL_VER}_to_${REMOTE_VER}_$TIMESTAMP"
mkdir -p "$BACKUP_PATH"

# 서비스 중지 (데이터 정합성 확보)
docker compose down

# 파일 복사
cp -r "$CONFIG_DIR" "$BACKUP_PATH/" 2>/dev/null
cp -r "$DATA_DIR" "$BACKUP_PATH/" 2>/dev/null
cp -r "$LOGS_DIR" "$BACKUP_PATH/" 2>/dev/null
cp "$COMPOSE_FILE" "$BACKUP_PATH/" 2>/dev/null
cp "$VERSION_FILE" "$BACKUP_PATH/" 2>/dev/null

success "백업 완료: $BACKUP_PATH"

# 5. 정책 파일 보호 (Git Reset 대비)
RUNNING_POLICY="$CONFIG_DIR/policy/local_policy.yaml"
TEMP_POLICY="/tmp/local_policy_safe.yaml"
if [ -f "$RUNNING_POLICY" ]; then
    cp "$RUNNING_POLICY" "$TEMP_POLICY"
fi

# 6. 코드 업데이트 (Git Reset)
log "GitHub에서 최신 코드($REMOTE_VER)를 적용합니다..."
git reset --hard "tags/$REMOTE_VER" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    error "코드 업데이트 실패. 네트워크 상태를 확인하세요."
fi

# 7. 정책 파일 복원
if [ -f "$TEMP_POLICY" ]; then
    mv "$TEMP_POLICY" "$RUNNING_POLICY"
    log "사용자 정책 설정 복원 완료."
fi

# 8. [변경됨] 파일 사후 검증 (다운로드 후 검사)
verify_files_after_pull "$REMOTE_VER"

# 9. 자동 패치 (마이그레이션)
# (v0.2.x -> v0.3.x 경로 수정)
if grep -q "\- ./aegis-config/agent:/etc/cp/conf" "$COMPOSE_FILE"; then
    sed -i 's|- ./aegis-config/agent:/etc/cp/conf|- ./aegis-config/policy/local_policy.yaml:/etc/cp/conf/local_policy.yaml|g' "$COMPOSE_FILE"
fi

# (v0.3.x 모델 마운트 주입)
if [[ "$REMOTE_VER" == *"v0.3"* ]]; then
    if ! grep -q "open-appsec-advanced-model.tgz" "$COMPOSE_FILE"; then
         sed -i '/- .\/aegis-logs\/waf:\/var\/log\/nano_agent/a \      - ./aegis-config/advanced-model/open-appsec-advanced-model.tgz:/advanced-model/open-appsec-advanced-model.tgz' "$COMPOSE_FILE"
    fi
fi

# 10. 버전 파일 갱신
echo "$REMOTE_VER" > "$VERSION_FILE"

# 11. 서비스 재시작
log "서비스를 재시작합니다..."
docker compose up -d

log "엔진 초기화 대기 (15초)..."
sleep 15
docker compose exec agent open-appsec-ctl --status

echo ""
success "업데이트가 성공적으로 완료되었습니다! ($LOCAL_VER -> $REMOTE_VER)"