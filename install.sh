#!/bin/bash

# ==========================================
# Aegis-Proxy-Stack Installer (Phase 1)
# ==========================================

echo "🛡️  Aegis-Proxy-Stack 설치 환경을 구성합니다..."

# 현재 위치가 프로젝트 루트인지 확인
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 오류: docker-compose.yml 파일을 찾을 수 없습니다."
    echo "   git clone 받은 디렉토리 내부에서 스크립트를 실행해주세요."
    exit 1
fi

# 1. 런타임 데이터 디렉토리 생성
echo "[Step 1] 데이터 디렉토리를 생성합니다..."
mkdir -p data/logs \
         letsencrypt \
         db \
         waf-config \
         waf-data \
         waf-logs \
         waf-policies

# 2. 사용자 입력 받기 (Interactive)
echo ""
echo "[Step 2] 보안 설정을 위해 정보를 입력해주세요."
echo "----------------------------------------------------"

# 2-1. Agent Token 입력
while true; do
    read -p "👉 open-appsec Agent Token을 입력하세요 (필수): " INPUT_TOKEN
    if [ -z "$INPUT_TOKEN" ]; then
        echo "   ⚠️ 토큰은 필수 입력 항목입니다."
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
    echo "   ℹ️ 기본값으로 설정되었습니다."
fi

read -s -p "👉 NPM Database 비밀번호를 설정하세요 (엔터 시 기본값 사용): " INPUT_NPM_PASS
echo ""
if [ -z "$INPUT_NPM_PASS" ]; then
    INPUT_NPM_PASS="npm_password"
    echo "   ℹ️ 기본값으로 설정되었습니다."
fi

# 3. .env 파일 생성 및 보안 설정
echo ""
echo "[Step 3] 환경 설정 파일(.env)을 생성합니다..."

cat <<EOF > .env
# [Aegis-Proxy-Stack Environment Variables]
# Created automatically by install.sh
# WARNING: Do not share this file.

AGENT_TOKEN=${INPUT_TOKEN}
DB_ROOT_PASSWORD=${INPUT_DB_ROOT}
NPM_DB_PASSWORD=${INPUT_NPM_PASS}
EOF

# [중요] .env 파일 권한 제한 (소유자만 읽기/쓰기 가능, 타인 접근 불가)
chmod 600 .env

echo "✅ .env 파일이 안전하게 생성되었습니다 (권한: 600)."

# 4. 실행 권한 정리
chmod 755 install.sh

echo ""
echo "🎉 모든 설치 준비가 완료되었습니다!"
echo "🚀 다음 명령어로 서비스를 시작하세요:"
echo "   docker-compose up -d"
echo ""