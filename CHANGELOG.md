# Changelog

All notable changes to this project will be documented in this file.

## [v0.3.0] - 2026-02-07

### 🚀 New Features (주요 기능 추가)
* **Phase 2: Advanced Machine Learning Model:** `open-appsec`의 고급 머신러닝(Advanced ML) 엔진을 활성화하여, 서명 없이도 OWASP Top 10 및 제로데이 공격을 정밀하게 탐지하고 차단합니다.
* **Smart Update Manager:** `update.sh` 스크립트를 도입하여 **자동 백업(Full Backup)**, **스크립트 자가 업데이트(Self-Update)**, **버전 마이그레이션**을 원클릭으로 안전하게 수행할 수 있습니다.

### 🛡️ Security & Hardening (보안 및 강화)
* **Policy Preservation:** 업데이트 시 운영 중인 `local_policy.yaml` 설정을 자동으로 감지하고 보호하여, 사용자 정의 보안 정책이 초기화되는 것을 방지했습니다.
* **Binary Integrity:** 고급 ML 엔진 구동에 필수적인 모델 바이너리(`open-appsec-advanced-model.tgz`)를 저장소에 포함하여 배포의 완전성을 확보했습니다.

### ⚙️ Refactoring & Infrastructure (구조 개선)
* **Git-Based Architecture:** `VERSION` 파일과 정책 파일을 `.gitignore`로 관리하여, 로컬 운영 환경과 GitHub 소스 코드 간의 충돌을 원천 차단했습니다.
* **Template System:** 신규 설치 시 `local_policy.yaml.template`을 기반으로 초기 환경을 구성하도록 `install.sh` 로직을 개선했습니다.

## [v0.2.1] - 2026-02-06

### 🚀 Enhancements (기능 개선)
* **Host Timezone Inheritance:** 모든 컨테이너에 `/etc/localtime` 볼륨 마운트를 적용하여 호스트 서버의 시간대(Timezone)와 자동으로 동기화되도록 개선했습니다.
* **Alpine Support:** Alpine Linux 기반 컨테이너(Log Rotator 등)를 위해 `tzdata` 패키지 설치 로직을 추가하여 시간대 처리 오류를 해결했습니다.