#!/bin/bash

# ==========================================
# Aegis-Proxy-Stack Installer (Phase 1)
# ==========================================

echo "*****************************************************"
echo "*                                                   *"
echo "*     Aegis-Proxy-Stack 설치 환경을 구성합니다.     *"
echo "*                                                   *"
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
echo "[Step 1] 데이터 디렉토리를 생성합니다."
echo "----------------------------------------------------"
mkdir -p certificate \
         data/logs \
         db \
         aegis-config \
         aegis-data \
         aegis-logs

# [보안 강화] 디렉토리 권한 설정 (750: 소유자/그룹 외 접근 원천 차단)
# 소유자(rwx), 그룹(r-x), 나머지(---)
chmod 750 certificate data/logs db aegis-config aegis-data aegis-logs
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

# 2-2. DB Password 입력 (화면에 표시 안 됨)
echo ""
read -s -p "👉 데이터베이스 Root 비밀번호를 설정하세요 (엔터 시 기본값 사용): " INPUT_DB_ROOT
echo ""
if [ -z "$INPUT_DB_ROOT" ]; then
    INPUT_DB_ROOT="root_password_change_me"
    echo "    ℹ️ 기본값으로 설정되었습니다."
fi

echo ""
read -s -p "👉 NPM Database 비밀번호를 설정하세요 (엔터 시 기본값 사용): " INPUT_NPM_PASS
echo ""
if [ -z "$INPUT_NPM_PASS" ]; then
    INPUT_NPM_PASS="npm_password"
    echo "    ℹ️ 기본값으로 설정되었습니다."
fi
echo ""
echo ""

# 3. .env 파일 생성 및 보안 설정
echo ""
echo "[Step 3] 환경 설정 파일(.env)을 생성합니다."
echo "----------------------------------------------------"

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

# 4. 도커 생성 및 서비스 시작
echo ""
echo "[Step 4] 도커를 생성하고 서비스를 시작합니다."
echo "----------------------------------------------------"
echo "🎉 모든 설치 준비가 완료되었습니다!"
echo ""
echo "🚀 다음 명령어를 실행해 주시기 바랍니다."
echo ""
echo "   docker compose up -d"
echo ""