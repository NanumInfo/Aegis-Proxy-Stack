![Docker](https://img.shields.io/badge/docker-ready-blue)
![Security](https://img.shields.io/badge/security-hardened-green)
![License](https://img.shields.io/badge/license-MIT-blue)
![Version](https://img.shields.io/badge/version-v0.4.0-orange)

# 🛡️ Aegis-Proxy-Stack (v0.4.0)

**Aegis-Proxy-Stack** is an all-in-one integrated security package that combines the exceptional usability of [NGINX Proxy Manager (NPM)](https://nginxproxymanager.com/) with enterprise-grade security solutions (WAF, IPS, Visualizer). It is designed to enable anyone to easily build an efficient web defense system without complex configuration.

'**Aegis(이지스)**'는 그리스 신화에서 제우스와 아테나가 사용한 방패를 의미하며, 강력한 보호와 방어를 상징합니다. 여러 보안 계층(WAF, IPS, Visualizer)이 겹겹이 쌓여(Stack) 완벽한 방어를 제공한다는 의미를 담았습니다.

리눅스 환경의 Docker 기반으로 설계되어 즉시 배포가 가능하며, 기계 학습 기반의 제로데이 공격 차단, 집단지성 기반의 IP 평판 분석, 그리고 실시간 지리적 시각화 모니터링을 하나의 통합된 환경에서 제공하며, 나아가 **Aegis 통합 관리 UI**까지 개발하는 것이 목표입니다.

Defense-in-depth architecture for hardened containerized web services.

![Architecture Diagram](images/architecture.png)


## 🌟 Key Features

* **Core Proxy:** [NGINX Proxy Manager](https://nginxproxymanager.com) 기반의 직관적인 도메인 및 TLS Certificates 관리
* **ML-Based WAF:** [open-appsec](https://www.openappsec.io) 탑재로 OWASP Top 10 및 제로데이 공격에 대한 선제적 방어 (서명 업데이트 불필요)
* **Advanced Machine Learning Model:** [고급 머신러닝 모델](https://docs.openappsec.io/getting-started/using-the-advanced-machine-learning-model)을 적용한 방어체계 구축 **(Phase 2 Completed)**
* **Crowd-Sourced IPS:** [CrowdSec](https://www.crowdsec.net) 통합으로 전 세계 위협 IP 데이터 실시간 공유 및 차단 **(Phase 3 Completed)**
* **Real-time Visualization:** [GoAccess](https://goaccess.io)와 [GeoIP2](https://www.maxmind.com) 연동으로 트래픽 및 공격지점 지도 기반 시각화 **(Phase 4 Scheduled)**
* **Aegis Integrated Management UI:** 상기 보안 솔루션 통합 관리를 위한 웹 기반 관리 솔루션 개발 **(Phase 5 Scheduled)**


## 📜 Architecture (Roadmap)

* ✅ **Phase 1:** NGINX Proxy Manager + open-appsec ML-Based WAF Integration
* ✅ **Phase 2:** Using the Advanced Machine Learning Model
* ✅ **Phase 3:** CrowdSec IPS Integration
* ⬜ **Phase 4:** GoAccess + GeoIP Visualization Setup
* ⬜ **Phase 5:** Aegis Integrated Management UI
* ⬜ **Phase 6:** Integration with other Security Solutions
* ⬜ **Phase 7:** Enhanced Performance and Functionality


## 🛠️ Technical Specifications (기술적 특징)

Aegis-Proxy-Stack은 단순한 통합을 넘어, 운영 안정성과 보안 규제 준수(Compliance)를 고려하여 정교하게 설계되었습니다.

### 1. 보안 강화 아키텍처 (Hardened Security)
* **IPv4 Only & IPv6 Leak Prevention:** IPv6를 통한 우회 공격이나 정보 유출을 방지하기 위해 3중 잠금 장치(Docker Ports, App Environment, Kernel Sysctl)를 적용하여 IPv6 트래픽을 원천 차단했습니다.
* **Isolated Network (네트워크 격리):** `aegis-network`라는 독립된 내부 브리지 네트워크를 사용하여 컨테이너 간 통신을 제어합니다. 특히 데이터베이스(DB)는 호스트 포트를 노출하지 않고 오직 내부망에서만 접근 가능하도록 격리했습니다.

### 2. 규제 준수형 로그 관리 (Compliance-Ready Logging)
* **Log-Rotator Sidecar:** 호스트 OS의 설정에 의존하지 않고, Docker 내부의 독립적인 `log-rotator` 사이드카 컨테이너가 로그를 관리합니다.
* **1-Year Retention:** 보안 규제(ISMS-P 등)를 고려하여 모든 보안 로그는 **365일간 보관**되며, 일 단위(Daily)로 압축(Compress)되어 저장됩니다.
* **Copytruncate Strategy:** 서비스 중단 없는 로그 순환을 위해 `copytruncate` 방식을 채택하여 무중단 운영을 보장합니다.

### 3. 최적화된 데이터베이스 (Optimized Database)
* **MariaDB Aria Engine:** NGINX Proxy Manager에 최적화된 경량화 이미지(`jc21/mariadb-aria`)를 사용하여 리소스 사용량을 최소화했습니다.
* **Modular Init System:** `db-init` 디렉토리를 통해 향후 추가될 보안 모듈(CrowdSec 등)의 DB 스키마를 모듈식으로 자동 확장할 수 있는 구조를 갖추었습니다.


## 📂 Project Structure (디렉토리 구조)

**Aegis-Proxy-Stack**은 관리 효율성을 위해 모든 디렉토리를 **성격(Config, Data, Logs)에 따라 3개의 대분류로 통합**하여 관리합니다.

| 대분류 | 하위 경로 (Sub-path) | 성격 (Role) | 설명 및 주요 내용 |
| :--- | :--- | :--- | :--- |
| 📂 **`aegis-config`**<br>(설정) | `/advanced-model` | **Model** | 고급 머신러닝 모델 구동을 위한 바이너리 파일 보관 |
| | `/agent` | **Brain** | WAF 에이전트 구동을 위한 내부 설정 및 환경 파일 |
| | `/crowdsec` | **Guard** | IPS 위협 분석 엔진 설정 및 차단 시나리오 정의 |
| | `/db-init` | **Init** | 데이터베이스 최초 생성 시 사용되는 모듈별 초기화 SQL 스크립트 |
| | `/logrotate` | **Cron** | 보안 규정 준수를 위한 로그 파일 자동 압축 및 순환 설정 |
| | `/policy` | **Hub** | **[핵심]** NPM-WAF 간 정책 공유 디렉토리 (`local_policy.yaml`) |
| | `/scripts` | **Controller** | 정책 자동 생성 로직(`policy_generator.js`) 및 관련 모듈 |
| 📂 **`aegis-data`**<br>(데이터) | `/certs` | **Vault** | 발급된 SSL 인증서 원본 및 비공개 키 파일 보호 |
| | `/crowdsec` | **Alert** | 위협 IP 데이터베이스 및 탐지된 침입 알람 데이터 |
| | `/db` | **DB** | 서비스 메타데이터가 저장되는 MariaDB 물리 데이터 파일 |
| | `/learning` | **Memory** | AI 기반 보안 엔진의 공격 학습 데이터가 저장되는 영속 공간 |
| | `/npm` | **Core** | Nginx Proxy Manager의 도메인 설정 및 관리자 계정 데이터 |
| 📂 **`aegis-logs`**<br>(로그) | `/crowdsec` | **IPS Log** | 침입 탐지 시스템의 진단 및 IP 차단 이력 기록 |
| | `/npm` | **Web Log** | Nginx 웹 서비스 접속 로그(`access.log`) 및 에러 로그 |
| | `/waf` | **WAF Log** | WAF 엔진의 실시간 차단 내역(`cp-nano-*.log`) 및 시스템 로그 |
| 📂 **`images`** | (Root) | **Asset** | README 및 프로젝트 문서용 이미지 파일 (아키텍처 구성도 등) |


## 🚀 Installation & Getting Started

### 📋 Prerequisites (사전 요구 사항 및 환경 점검)

설치를 진행하기 전에 반드시 아래 사항들을 확인해주세요.

> **보안 권장 사항:** 본 프로젝트는 보안상의 이유로 `root` 계정이 아닌 **`일반 사용자` 계정**으로 설치 및 실행하는 것을 권장합니다.

1. **Docker 설치 및 버전 확인 (필수)**

   터미널에서 아래 명령어를 입력하여 설치된 버전이 아래의 최소 요구사항을 만족하는지 확인합니다.
   * Docker version 20.10.x 이상
   * Docker Compose version v2.0.x 이상
   ```bash
   docker --version
   docker compose version
   ```
   **🚨 Docker가 없거나 버전이 낮은 경우 (해결 방법)**

   아래와 같은 공식 설치 스크립트를 사용하면 최신 버전의 Docker와 Compose가 자동으로 설치(또는 업데이트)됩니다.
   ```bash
   curl -fsSL https://get.docker.com | sudo sh
   ```

2. **사용자 권한 확인 (Docker 그룹 설정)**

   일반 계정에서 `sudo` 없이 Docker 명령어를 실행하려면, 해당 계정이 `docker` 그룹에 포함되어 있어야 합니다.

   **Step 1. 현재 권한 확인**

   터미널에서 아래 명령어를 입력했을 때, 에러 없이 컨테이너 목록(또는 빈 목록)이 나와야 합니다.
   ```bash
   docker ps
   ```
   **🚨 `permission denied` 에러가 발생한다면 아래 Step 2를 진행하세요.**

   **Step 2. Docker 그룹에 사용자 추가 (필요시)**

   현재 사용자를 docker 그룹에 추가 및 그룹 변경 사항 적용을 위해 아래 명령어 실행
   ```bash
   sudo usermod -aG docker $USER 
   newgrp docker
   ```

3. **필수 포트 확인**

   Aegis-Proxy-Stack은 다음 포트를 사용합니다. 해당 포트가 이미 사용 중인지 확인하세요.
   * **80 (HTTP):** 웹 서비스 (Let’s Encrypt Challenge 및 HTTP 트래픽)
   * **81 (Admin):** NGINX Proxy Manager 관리자 웹 콘솔
   * **443 (HTTPS):** 웹 서비스 (TLS 암호화 트래픽)

### 🛠️ Step-by-Step Install Guide

1. **작업 환경 구성 (Prepare)**

   프로젝트의 체계적인 관리와 향후 확장성을 위해 `aegis` 전용 디렉토리를 생성하여 설치하는 것을 권장합니다. 아래 모든 과정은 반드시 `root`가 아닌 일반 사용자 계정으로 진행해 주세요.

   사용자 홈디렉토리에 'aegis' 프로젝트 최상위 폴더 생성 후 해당 폴더로 이동합니다. **(옵션 사항)**
   ```bash
   mkdir -p ~/aegis
   cd ~/aegis
   ```

2. **저장소 복제 (Clone Repository)**
   ```bash
   git clone https://github.com/AegisAX/aegis-proxy-stack.git
   cd aegis-proxy-stack
   ```

3. **설치 스크립트 실행 (Run Interactive Installer)**

   포함된 `install.sh` 스크립트를 실행합니다. 이 과정에서 모든 서비스(NPM, DB, WAF Agent)에 공통으로 사용할 **Master Account(통합 계정)** 설정을 요청받게 됩니다.

   ```bash
   chmod +x install.sh verify_all.sh
   ./install.sh
   ```

   **🔐 Master Account 설정:**

   설치 시 입력하는 **이메일**과 **비밀번호**는 다음 용도로 통합 사용됩니다.
   * **Nginx Proxy Manager:** 관리자(Admin) 로그인 계정
   * **open-appsec:** 에이전트 식별 ID (User Email)
   * **Database:** DB 루트 및 NPM 데이터베이스 비밀번호
   > 🔐 Strong password is strongly recommended. This credential is used for internal service initialization only.
   
   > **Note:** 설치가 완료되면 검증 스크립트(`verify_all.sh`)를 즉시 실행할지 묻는 메시지가 나타납니다.

4. **서비스 실행 (Start Services)**

   설치 스크립트에서 자동 실행을 하지 않았다면 아래 명령어로 실행합니다.
   ```bash
   docker compose up -d
   ```

   > **💡 Dashboard Access Tip:** 
   >
   > 설치 완료 후 **Nginx Proxy Manager 관리자 페이지**에 접속할 때, **설치 과정에서 직접 설정한 Master Email과 Master Password**를 사용하여 즉시 로그인할 수 있습니다.


## ⚠️ Known Issues & Workarounds (알려진 이슈 및 해결 방법)

### 1. SSL 인증서 발급 시 "Test Reachability" 실패 현상
NPM UI에서 SSL 인증서 발급 시 `JSONObject["responsetime"] not found` 또는 `Unexpected status code` 오류와 함께 도메인 연결 테스트가 실패하는 경우가 있습니다.

> **원인:** 이는 Aegis-Proxy-Stack의 결함이 아닌, **Nginx Proxy Manager(NPM) 자체의 고질적인 사전 점검 로직 이슈**입니다. NPM 백엔드가 자기 자신의 공인 IP로 접속하여 응답을 확인하는 과정에서 루프백(Loopback) 경로 문제나 보안 모듈의 응답 헤더 간섭으로 인해 발생합니다.
>
> **증상:** "Test Reachability" 버튼 클릭 시 에러가 발생하거나, 인증서 발급 창에서 저장 시 경고 팝업이 뜸.
>
> **해결 방법 (Workaround):**
> 1. **무시하고 진행:** 사전 테스트 결과와 상관없이 실제 `Certbot`을 통한 인증서 발급은 정상적으로 수행됩니다. 에러 팝업이 뜨더라도 다시 한번 **Save**를 누르면 발급이 완료됩니다.
> 2. **Temporary Disable:** 만약 지속적으로 실패한다면, 해당 Proxy Host를 잠시 **'Disabled'** 상태로 변경한 뒤 인증서를 발급받으세요. 발급 성공 후 다시 'Enabled' 및 'open-appsec ON'으로 설정하면 모든 기능이 정상 작동합니다.


## 🧪 Verification & Testing (검증 및 테스트)

설치가 완료된 후, 시스템이 정상적으로 작동하는지 확인하기 위해 **검증 전용 스크립트**를 제공합니다. 복잡한 수동 설정 없이 명령 한 줄로 모든 상태를 점검할 수 있습니다.

### ✅ 자동 검증 실행 (Automated Verification)

아래 명령어를 실행하면 **상태 점검, 정책 동기화, 테스트 호스트 등록, 공격 차단 테스트**가 한 번에 수행됩니다.

```bash
./verify_all.sh
```

이 스크립트는 다음 작업을 자동으로 수행합니다:
1.  **Health Check:** Docker 컨테이너 및 open-appsec 에이전트 상태 정밀 점검
2.  **Auth & Sync:** NPM에 자동으로 로그인하여 WAF 정책(Policy)을 동기화
3.  **Host Registration:** 테스트용 호스트(`test.aegis.local`)를 `Prevent-Learn` 모드로 강제 등록
4.  **Security Tests:**
      * 🟢 정상 트래픽 (HTTP 200/302) → **허용 (Allowed)**
      * 🔴 XSS 공격 시뮬레이션 → **차단 (Blocked HTTP 403)**
      * 🔴 SQL Injection 공격 시뮬레이션 → **차단 (Blocked HTTP 403)**


## 🔄 Update Guide (Universal)

**Aegis-Proxy-Stack**은 지속적인 보안 강화와 기능 확장을 위해 통합 업데이트 스크립트를 제공합니다. v0.2.0 이상의 어떤 버전을 사용 중이더라도 아래 절차를 통해 **원하는 버전**으로 안전하게 업데이트할 수 있습니다.

### 🏃 How to Update (업데이트 실행 방법)

터미널에서 아래 명령어를 순서대로 입력하세요. 이 명령어는 최신 버전의 **업데이트 매니저(`update.sh`)**만 우선적으로 가져온 후, 안전하게 전체 시스템 업데이트를 수행합니다.

```bash
# 1. 프로젝트 폴더로 이동
cd ~/aegis-proxy-stack

# 2. 최신 업데이트 스크립트 가져오기 (코드 충돌 방지)
git fetch origin
git checkout origin/main -- update.sh
chmod +x update.sh

# 3. 업데이트 매니저 실행
./update.sh
```

**💡 Tip: update.sh를 실행하면 현재 버전을 자동으로 감지하고, 사용 가능한 최신 버전으로의 업그레이드를 안내합니다.**


## ⚖️ License

본 프로젝트는 여러 오픈 소스 프로젝트를 통합한 패키지입니다. 각 구성 요소의 라이선스를 준수합니다.

* **Aegis-Proxy-Stack Configuration:** MIT License
* **open-appsec:** Apache 2.0 (Engine) / Machine Learning Model License (Advanced Model)
* **NGINX Proxy Manager:** MIT License
* **CrowdSec:** MIT License
* **GoAccess:** MIT License
