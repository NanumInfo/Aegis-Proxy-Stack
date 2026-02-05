#!/bin/bash

# ==========================================
# Aegis-Proxy-Stack Installer (Phase 1)
# ==========================================

echo "*****************************************************"
echo "* *"
echo "* Aegis-Proxy-Stack 설치 환경을 구성합니다.     *"
echo "* *"
echo "*****************************************************"
echo ""

# 현재 위치가 프로젝트 루트인지 확인
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 오류: docker-compose.yml 파일을 찾을 수 없습니다."
    echo "    git clone 받은 디렉토리 내부에서 스크립트를 실행해주세요."
    echo ""
    exit 1
fi

# 1. 런타임 데이터 디렉토리 생성
echo ""
echo "[Step 1] 통합 데이터 디렉토리 구조를 생성합니다."
echo "----------------------------------------------------"

# 1. Aegis Config (설정 저장소)
if [ ! -d "aegis-config/agent" ]; then
    mkdir -p aegis-config/agent
    echo "  + Created: aegis-config/agent"
fi

# 2. Aegis Data (데이터 저장소)
mkdir -p aegis-data/npm
mkdir -p aegis-data/db
mkdir -p aegis-data/certs
mkdir -p aegis-data/learning
echo "  + Created: aegis-data structure (npm, db, certs, learning)"

# 3. Aegis Logs (로그 저장소)
mkdir -p aegis-logs/waf
mkdir -p aegis-logs/npm
echo "  + Created: aegis-logs structure (waf, npm)"

# [보안 강화] 디렉토리 권한 설정 (750: 소유자/그룹 외 접근 원천 차단)
chmod -R 750 aegis-config aegis-data aegis-logs
echo "✅ 디렉토리 보안 권한 설정 완료 (750)"
echo ""
echo ""

# 2. 사용자 입력 받기 (Interactive)
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
echo ""

# 3. .env 파일 생성 및 보안 설정
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
echo ""

# 4. 도커 생성 및 서비스 시작 (자동 실행 로직 추가)
echo ""
echo "[Step 4] 서비스 실행"
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