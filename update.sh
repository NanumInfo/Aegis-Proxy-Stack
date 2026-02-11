#!/bin/bash

# ==============================================================================
# Aegis Proxy Stack - Intelligent Release Manager (v0.4.0)
# ==============================================================================
# 1. 설치 여부 확인 및 환경 점검
# 2. 업데이트 타겟 선택 (v0.3.2 -> v0.4.0)
# 3. 안전 백업 및 코드 동기화 (Git Tag)
# 4. Phase 2 완성형 마이그레이션 (Master Account & Test Script)
# ==============================================================================

# --- [환경 설정] ---
BASE_DIR=$(pwd)
VERSION_FILE="$BASE_DIR/VERSION"
BACKUP_DIR="$BASE_DIR/backups"
CONFIG_DIR="$BASE_DIR/aegis-config"
DATA_DIR="$BASE_DIR/aegis-data"
LOGS_DIR="$BASE_DIR/aegis-logs"
COMPOSE_FILE="$BASE_DIR/docker-compose.yml"

# 색상 변수
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

get_local_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------------------------
# 0. 설치 여부 확인
# ------------------------------------------------------------------------------
if [ ! -f "$COMPOSE_FILE" ] && [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Aegis-Proxy-Stack이 설치되지 않았습니다.${NC}"
    read -p "🚀 신규 설치(install.sh)를 진행하시겠습니까? (Y/n): " INSTALL_CONFIRM
    if [[ ${INSTALL_CONFIRM:-Y} =~ ^[yY] ]]; then
        ./install.sh; exit $?
    fi
    exit 0
fi

# ------------------------------------------------------------------------------
# Phase 1: 스크립트 자가 업데이트
# ------------------------------------------------------------------------------
perform_self_update() {
    if [ "$1" == "--no-self-update" ]; then return; fi
    if [ -d ".git" ]; then
        git fetch --tags --force > /dev/null 2>&1
        LATEST_TAG=$(git tag -l | sort -V | tail -n 1)
        if [ -n "$LATEST_TAG" ]; then
            TEMP_SCRIPT="/tmp/update_new.sh"
            git show "tags/$LATEST_TAG:update.sh" > "$TEMP_SCRIPT" 2>/dev/null
            if [ -s "$TEMP_SCRIPT" ] && ! cmp -s "$0" "$TEMP_SCRIPT"; then
                echo -e "${YELLOW}🔄 업데이트 매니저 갱신 중...${NC}"
                mv "$TEMP_SCRIPT" "$0" && chmod +x "$0"
                exec "$0" "--no-self-update"
            fi
        fi
    fi
}
perform_self_update "$1"

# ------------------------------------------------------------------------------
# Phase 2: 버전 선택
# ------------------------------------------------------------------------------
clear
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}    Aegis Proxy Stack - Release Manager     ${NC}"
echo -e "${GREEN}============================================${NC}"

LOCAL_VER=$(get_local_version)
LATEST_TAG=$(git tag -l | sort -V | tail -n 1 2>/dev/null || echo "v0.4.0")

echo -e "🔹 현재 설치 버전: ${YELLOW}$LOCAL_VER${NC}"
echo -e "🔹 최신 배포 버전: ${GREEN}$LATEST_TAG${NC}"
echo ""
echo "----------------------------------------------------"
echo "업데이트 목표 버전을 선택하세요:"
echo "----------------------------------------------------"
echo -e "1) ${BLUE}v0.3.2${NC} : Phase 2 Standard"
echo -e "2) ${BLUE}v0.4.0${NC} : Phase 2 Extended (Automated Test & Unified Auth) ${GREEN}[Recommended]${NC}"
echo -e "3) ${YELLOW}Custom${NC} : 태그 직접 입력"
echo ""
read -p "선택 (번호 입력): " MENU_CHOICE

case $MENU_CHOICE in
    1) TARGET_VER="v0.3.2" ;;
    2) TARGET_VER="v0.4.0" ;;
    3) read -p "버전 입력: " TARGET_VER ;;
    *) error "잘못된 선택입니다." ;;
esac

echo -e "\n선택된 버전: ${GREEN}$TARGET_VER${NC}"
read -p "업데이트를 진행하시겠습니까? (y/n): " CONFIRM
if [[ ! $CONFIRM =~ ^[yY] ]]; then echo "취소되었습니다."; exit 0; fi

# ------------------------------------------------------------------------------
# Phase 3: 백업 및 코드 적용
# ------------------------------------------------------------------------------
log "시스템 백업 및 코드 동기화 시작..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/${LOCAL_VER}_to_${TARGET_VER}_$TIMESTAMP"
mkdir -p "$BACKUP_PATH"

docker compose down

# 백업 실행
[ -d "$CONFIG_DIR" ] && cp -r "$CONFIG_DIR" "$BACKUP_PATH/"
[ -d "$DATA_DIR" ] && cp -r "$DATA_DIR" "$BACKUP_PATH/"
[ -f ".env" ] && cp ".env" "$BACKUP_PATH/"

# Git Tag 적용
if [ -d ".git" ]; then
    git reset --hard "tags/$TARGET_VER" > /dev/null 2>&1
    if [ $? -ne 0 ]; then error "Git Tag 적용 실패 ($TARGET_VER)"; fi
fi

echo "$TARGET_VER" > "$VERSION_FILE"

# ------------------------------------------------------------------------------
# Phase 4: 서비스 재시작 및 상태 확인
# ------------------------------------------------------------------------------
log "서비스를 재시작합니다..."
docker compose up -d

log "엔진 초기화 대기 (15초)..."
sleep 15

# 최종 상태 리포트
if docker compose ps | grep -q "agent"; then
    echo -e "\n${GREEN}[ Final Status ]${NC}"
    docker compose exec agent open-appsec-ctl --status
    echo -e "\n${YELLOW}💡 설치 완료 후 './verify_all.sh'를 실행하여 자동 검증을 진행하세요.${NC}"
fi

success "업데이트 완료: $LOCAL_VER -> $TARGET_VER"