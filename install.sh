#!/bin/bash

# ==========================================
# Aegis-Proxy-Stack Installer (Phase 1)
# ==========================================

echo "****************************************************"
echo "*                                                  *"
echo "*      Aegis-Proxy-Stack 설치 환경을 구성합니다.      *"
echo "*                                                  *"
echo "****************************************************"
echo ""

# 현재 위치가 프로젝트 루트인지 확인
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 오류: docker-compose.yml 파일을 찾을 수 없습니다."
    echo "    git clone 받은 디렉토리 내부에서 스크립트를 실행해주세요."
    echo ""
    exit 1
fi

# ------------------------------------------------------------------------------
# 1. 런타임 데이터 디렉토리 생성 및 초기화
# ------------------------------------------------------------------------------
echo ""
echo "[Step 1] 통합 데이터 디렉토리 구조를 생성합니다."
echo "----------------------------------------------------"

# 1-1. Aegis Config (설정 저장소)
if [ ! -d "aegis-config/agent" ]; then
    mkdir -p aegis-config/agent
    echo "  + Created: aegis-config/agent"
fi

# [정책 파일 초기화]
# GitHub에서 받은 template을 기반으로 실제 운영에 사용할 local_policy.yaml을 생성합니다.
# 이미 파일이 존재한다면(업데이트 상황), 기존 설정을 보호하기 위해 덮어쓰지 않습니다.
if [ ! -f "aegis-config/policy/local_policy.yaml" ]; then
    if [ -f "aegis-config/policy/local_policy.yaml.template" ]; then
        cp aegis-config/policy/local_policy.yaml.template aegis-config/policy/local_policy.yaml
        echo "  + Created: initial local_policy.yaml from template"
    fi
fi

# [고급 ML 모델 파일 권한 설정]
# GitHub에서 함께 내려받은 모델 바이너리(.tgz) 파일의 권한을 보안 표준에 맞춰 조정합니다.
if [ -f "aegis-config/advanced-model/open-appsec-advanced-model.tgz" ]; then
    chmod 640 aegis-config/advanced-model/open-appsec-advanced-model.tgz
    echo "  + Secured: Advanced ML Model binary"
fi

# 1-2. Aegis Data (데이터 저장소)
mkdir -p aegis-data/npm
mkdir -p aegis-data/db
mkdir -p aegis-data/certs
mkdir -p aegis-data/learning
echo "  + Created: aegis-data structure (npm, db, certs, learning)"

# 1-3. Aegis Logs (로그 저장소)
mkdir -p aegis-logs/waf
mkdir -p aegis-logs/npm
echo "  + Created: aegis-logs structure (waf, npm)"

# [보안 강화] 디렉토리 권한 설정 (750: 소유자/그룹 외 접근 원천 차단)
chmod -R 750 aegis-config aegis-data aegis-logs
echo "✅ 디렉토리 보안 권한 설정 완료 (750)"
echo ""

# ------------------------------------------------------------------------------
# 2. 사용자 입력 받기 (Interactive)
# ------------------------------------------------------------------------------
echo ""
echo "[Step 2] 보안 설정을 위해 정보를 입력해주세요."
echo "----------------------------------------------------"

# 2-1. E-Mail 입력
while true; do
    read -p "👉 사용자의 E-Mail 주소를 입력하세요 (필수): " INPUT_EMAIL
    if [ -z "$INPUT_EMAIL" ]; then
        echo "    ⚠️  E-Mail은 필수 입력 항목입니다."
    else
        break
    fi
done

# 2-2. DB Password 입력
echo ""
# -s 옵션: 입력값 숨김 (비밀번호 보안)
read -s -p "👉 데이터베이스 Root 비밀번호를 설정하세요 (엔터 시 기본값 사용): " INPUT_DB_ROOT
echo ""
if [ -z "$INPUT_DB_ROOT" ]; then
    INPUT_DB_ROOT="root_password_change_me"
    echo "    ℹ️  기본값으로 설정되었습니다."
fi

echo ""
read -s -p "👉 NPM Database 비밀번호를 설정하세요 (엔터 시 기본값 사용): " INPUT_NPM_PASS
echo ""
if [ -z "$INPUT_NPM_PASS" ]; then
    INPUT_NPM_PASS="npm_password"
    echo "    ℹ️  기본값으로 설정되었습니다."
fi
echo ""

# ------------------------------------------------------------------------------
# 3. .env 파일 생성 및 보안 설정
# ------------------------------------------------------------------------------
echo ""
echo "[Step 3] 환경 설정 파일(.env)을 생성합니다."
echo "----------------------------------------------------"

# 기존 .env 파일이 있으면 백업
if [ -f ".env" ]; then
    echo "    ℹ️  기존 .env 파일이 발견되어 .env.bak 으로 백업합니다."
    cp .env .env.bak
fi

cat <<EOF > .env
# [Aegis-Proxy-Stack Environment Variables]
# Created automatically by install.sh
# WARNING: Do not share this file.

AGENT_EMAIL=${INPUT_EMAIL}
DB_ROOT_PASSWORD=${INPUT_DB_ROOT}
NPM_DB_PASSWORD=${INPUT_NPM_PASS}
EOF

# [중요] .env 파일 권한 제한 (소유자만 읽기/쓰기 가능)
chmod 600 .env
echo "✅ .env 파일이 안전하게 생성되었습니다 (권한: 600)"
echo ""

# ------------------------------------------------------------------------------
# 4. 버전 파일 생성 (Git 태그 기반 자동 감지) - [새로 추가됨]
# ------------------------------------------------------------------------------
echo ""
echo "[Step 4] Versioning..."

# Git 저장소(.git 폴더)가 존재하는지 확인
if [ -d ".git" ]; then
    # 태그 목록을 버전 순(Semantic Versioning)으로 정렬하고 가장 최신 태그 추출
    LATEST_TAG=$(git tag -l | sort -V | tail -n 1)
    
    if [ -n "$LATEST_TAG" ]; then
        echo "$LATEST_TAG" > VERSION
        echo "  + Auto-detected Version: $LATEST_TAG"
    else
        # 태그가 하나도 없는 경우 (초기 개발 상태 등) 안전 장치
        echo "v0.3.0" > VERSION
        echo "  + Warning: No Git tags found. Defaulting to v0.3.0"
    fi
else
    # .git 폴더가 없는 경우 (Zip 다운로드 등) 안전 장치
    echo "v0.3.0" > VERSION
    echo "  + Created: VERSION file (Fallback: v0.3.0)"
fi
echo ""

# ------------------------------------------------------------------------------
# 5. 도커 생성 및 서비스 시작 (자동 실행)
# ------------------------------------------------------------------------------
echo ""
echo "[Step 5] 서비스 실행"
echo "----------------------------------------------------"
echo "🎉 모든 설정 파일과 디렉토리 준비가 완료되었습니다!"
echo ""

while true; do
    read -p "🚀 지금 바로 Aegis-Proxy-Stack 서비스를 시작하시겠습니까? (Y/n): " CONFIRM
    # 엔터 입력 시 기본값 Y
    CONFIRM=${CONFIRM:-Y}

    case $CONFIRM in
        [yY][eE][sS]|[yY])
            echo ""
            echo "🔄 Docker Compose를 실행하여 컨테이너를 생성합니다..."
            echo "----------------------------------------------------"
            docker compose up -d
            
            if [ $? -eq 0 ]; then
                echo ""
                echo "✅ 서비스가 성공적으로 시작되었습니다!"
                echo "📊 현재 실행 상태:"
                echo ""
                docker compose ps
                echo ""
                echo "🌐 접속 주소: http://localhost:81 (관리자 페이지)"
            else
                echo ""
                echo "❌ 오류: Docker 실행 중 문제가 발생했습니다."
                echo "    로그를 확인하거나 'docker compose up -d'를 수동으로 실행해보세요."
            fi
            break
            ;;
        [nN][oO]|[nN])
            echo ""
            echo "ℹ️  자동 실행을 취소했습니다."
            echo "    나중에 아래 명령어로 서비스를 시작해주세요:"
            echo ""
            echo "    docker compose up -d"
            echo ""
            break
            ;;
        *)
            echo "⚠️  Y 또는 N을 입력해주세요."
            ;;
    esac
done