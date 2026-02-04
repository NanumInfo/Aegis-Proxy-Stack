# 🛡️ Aegis-Proxy-Stack

NGINX Proxy Manager(NPM)의 사용 및 관리 편의성에 더하여 엔터프라이즈급 보안 솔루션(WAF, IPS, Visualizer)을 결합한 올인원(All-in-One) 보안 통합 패키지로 만들어 누구나 효율적인 방어체계를 손쉽게 구축할 수 있도록 하기 위해 시작한 프로젝트입니다.

'Aegis(이지스)'는 그리스 신화에서 제우스와 아테나가 사용한 방패를 의미하며, 강력한 보호와 방어를 상징합니다. 여러 보안 계층(WAF, IPS, Visualizer)이 겹겹이 쌓여(Stack) 완벽한 방어를 제공한다는 의미를 담았습니다.

리눅스 환경의 Docker 기반으로 설계되어 즉시 배포가 가능하며, 기계 학습 기반의 제로데이 공격 차단, 집단지성 기반의 IP 평판 분석, 그리고 실시간 지리적 시각화 모니터링을 하나의 통합된 환경에서 제공하며, 나아가 **Aegis 통합 관리 UI**까지 개발하는 것이 목표입니다.

## 🌟 Key Features

* **Core Proxy:** [NGINX Proxy Manager](https://nginxproxymanager.com) 기반의 직관적인 도메인 및 TLS Certificates 관리
* **ML-Based WAF:** [open-appsec](https://www.openappsec.io) 탑재로 OWASP Top 10 및 제로데이 공격에 대한 선제적 방어 (서명 업데이트 불필요)
* **Advanced Machine Learning Model:** [고급 머신러닝 모델](https://docs.openappsec.io/getting-started/using-the-advanced-machine-learning-model)을 적용하여 더욱 정확한 방어체계 구축 **(Phase 2 Scheduled)**
* **Crowd-Sourced IPS:** [CrowdSec](https://www.crowdsec.net) 통합을 통해 전 세계 위협 IP 데이터를 실시간 공유 및 차단 **(Phase 3 Scheduled)**
* **Real-time Visualization:** [GoAccess](https://goaccess.io)와 [GeoIP2](https://www.maxmind.com)를 연동하여 트래픽 및 공격 원점을 지도 기반으로 시각화 **(Phase 4 Scheduled)**
* **Aegis 통합 관리 UI:** 상기 보안 솔루션을 통합하여 관리하기 위한 웹 기반 관리 솔루션 개발 **(Phase 5 Scheduled)**

## 📜 Architecture (Roadmap)

1.  **Phase 1:** NGINX Proxy Manager + open-appsec ML-Based WAF Integration (✅ Current)
2.  **Phase 2:** Using the Advanced Machine Learning Model
3.  **Phase 3:** CrowdSec IPS Integration
4.  **Phase 4:** GoAccess + GeoIP Visualization Setup
5.  **Phase 5:** Aegis 통합 관리 UI

---

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

---

## 🚀 Installation & Getting Started

### 📋 Prerequisites (사전 요구 사항 및 환경 점검)

설치를 진행하기 전에 반드시 아래 사항들을 확인해주세요.
**본 프로젝트는 보안상의 이유로 `root` 계정이 아닌 `일반 사용자` 계정으로 설치 및 실행하는 것을 권장합니다.**

#### 1. Docker 설치 및 버전 확인 (필수)
터미널에서 아래 명령어를 입력하여 설치된 버전을 확인합니다.
> ```bash
> docker --version
> # 최소 요구사항: Docker version 20.10.x 이상
> 
> docker compose version
> # 최소 요구사항: Docker Compose version v2.0.x 이상
> ```

**🚨 Docker가 없거나 버전이 낮은 경우 (해결 방법)**

아래와 같은 공식 설치 스크립트를 사용하면 최신 버전의 Docker와 Compose가 자동으로 설치(또는 업데이트)됩니다.
> ```bash
> curl -fsSL https://get.docker.com | sudo sh
> ```

#### 2. 사용자 권한 확인 (Docker 그룹 설정)
일반 계정에서 `sudo` 없이 Docker 명령어를 실행하려면, 해당 계정이 `docker` 그룹에 포함되어 있어야 합니다.

**Step 1. 현재 권한 확인**
터미널에서 아래 명령어를 입력했을 때, 에러 없이 컨테이너 목록(또는 빈 목록)이 나와야 합니다.
> ```bash
> docker ps
> ```
**🚨 `permission denied` 에러가 발생한다면 아래 Step 2를 진행하세요.**

**Step 2. Docker 그룹에 사용자 추가 (필요시)**
> ```bash
> # 1. 현재 사용자를 docker 그룹에 추가
> sudo usermod -aG docker $USER
> 
> # 2. 그룹 변경 사항을 적용하기 위해 로그아웃 후 다시 로그인 (또는 아래 명령어 실행)
> newgrp docker
> ```

#### 3. 필수 포트 확인
Aegis-Proxy-Stack은 다음 포트를 사용합니다. 해당 포트가 이미 사용 중인지 확인하세요.
> * **80 (HTTP):** 웹 서비스 (Let’s Encrypt Certificates 자동 발급)
> * **443 (HTTPS):** 웹 서비스 (TLS)
> * **81 (Admin):** NGINX Proxy Manager 관리자 페이지

#### 4. open-appsec 토큰 발급 (Get Agent Token)
WAF 엔진을 활성화하기 위해 관리 포털에서 에이전트 토큰을 발급 받아야 합니다.
> 1. [open-appsec Portal](https://my.openappsec.io)에 접속하여 회원가입 및 로그인을 진행합니다.
> 2. 대시보드 상단 메뉴에서 **Profiles**를 클릭한 후, **Add Profile** 버튼을 누릅니다.
> 3. **Docker** 유형으로 선택하고, 프로필 이름(예: `aegis-waf`)을 적절하게 입력합니다.
> 4. **Sub Type** 유형은 **NGINX Proxy Manager + open-appsec**으로 선택합니다.
> 5. **Management** 유형은 **Declarative configuration - using open-appsec configuration file**로 선택합니다.
> 6. 화면에 표시되는 **Agent Token** (예: `cp-xxxxxxxx...`)을 복사하여 안전한 곳에 기록합니다.
> 7. 페이지 오른쪽 상단의 **Enforce** 버튼을 클릭하여 정책을 시행합니다.
> * **Note:** 이 토큰은 다음 단계인 `install.sh` 실행 시 입력해야 합니다.

---

### 🛠️ Step-by-Step Install Guide


**1. 작업 환경 구성 (Prepare)**
프로젝트의 체계적인 관리와 향후 확장성을 위해 `aegis` 전용 디렉토리를 생성하여 설치하는 것을 권장합니다.
아래 모든 과정은 반드시 `root`가 아닌 일반 사용자 계정으로 진행해 주세요.

사용자 홈디렉토리에 'aegis' 프로젝트 최상위 폴더 생성 후 해당 폴더로 이동합니다.
> ```bash
> mkdir -p ~/aegis
> cd ~/aegis
> ```

**2. 저장소 복제 (Clone Repository)**
> ```bash
> git clone https://github.com/NanumInfo/aegis-proxy-stack.git
> cd aegis-proxy-stack
> ```

**3. 설치 스크립트 실행 (Run Interactive Installer)**
포함된 `install.sh` 스크립트를 실행하면 필요한 보안 토큰과 비밀번호를 입력받아 자동으로 설정을 완료합니다.
> ```bash
> chmod +x install.sh
> ./install.sh
> ```
> **Info:** 이 스크립트는 `waf-logs`, `db`, `letsencrypt` 등 런타임에 필요한 디렉토리를 생성하고 권한을 설정합니다.

**4. 서비스 실행 (Start Services)**
> ```bash
> docker-compose up -d
> ```

**5. 실행 상태 확인 (Verify)**
모든 컨테이너가 `healthy` 상태인지 확인합니다.
> ```bash
> docker-compose ps
> ```
> **Note:** 초기 실행 시 데이터베이스 및 WAF 엔진 초기화로 인해 `aegis-npm` 컨테이너가 시작되기까지 약 1~2분이 소요될 수 있습니다.

---

## ⚙️ Configuration & Usage

### 1. 관리자 페이지 접속
브라우저를 열고 서버의 81번 포트로 접속합니다.
> * **URL:** `http://your-server-ip:81`
> * **Default Email:** `admin@example.com`
> * **Default Password:** `changeme`

⚠️ **보안 권장사항:** 로그인 즉시 관리자 계정의 이메일과 비밀번호를 변경하십시오.

### 2. WAF(open-appsec) 활성화 확인
> 1. NGINX Proxy Manager 관리자 화면에서 **Proxy Hosts** 메뉴로 이동합니다.
> 2. 호스트를 추가하거나 기존 호스트를 편집합니다.
> 3. 설정 팝업창 상단 탭에 **open-appsec** 항목이 존재하는지 확인합니다.
> 4. `Enable Protection`을 체크하면 해당 도메인에 대한 기계 학습 기반 보호가 즉시 시작됩니다.

### 3. 주요 디렉토리 구조
설치 후 생성되는 주요 데이터 폴더는 다음과 같습니다.
> * `data/`: NPM 설정 및 로그
> * `waf-logs/`: WAF 보안 로그 (open-appsec)
> * `logrotate/`: 로그 자동 순환 설정 파일

---

## 🧪 Verification & Testing (검증 및 테스트)

설치가 완료되었다면, 다음 단계에 따라 시스템이 정상적으로 작동하는지 검증합니다.

### 1. 컨테이너 상태 확인 (Health Check)
모든 컨테이너가 `healthy` 또는 `Up` 상태인지 확인합니다.
```bash
docker-compose ps
```

**정상 결과 예시:**
> * `aegis-npm`: **(healthy)**
> * `aegis-agent`: **(Up)**
> * `aegis-db`: **(healthy)**
> * `aegis-log-rotator`: **(Up)**

### 2. WAF 동작 테스트 (Attack Simulation)
가장 중요한 단계입니다. 실제로 웹 공격 패턴을 전송하여 WAF가 이를 차단하는지 확인합니다.

**Step 1. 테스트용 호스트 생성**

    1. NPM 관리자 페이지(`http://서버IP:81`)에 로그인합니다.
    2. **Proxy Hosts** -> **Add Proxy Host** 클릭합니다.
    3. **Details** 탭:
        * Domain Names: `test.aegis.local` (또는 보유한 실제 도메인)
        * Forward Hostname / IP: `127.0.0.1` (또는 아무 웹서버 IP)
        * Forward Port: `80`
    4. **open-appsec** 탭 (중요):
        * **Enable Protection** 체크 ✅
    5. 저장합니다.

**Step 2. 공격 시뮬레이션 (SQL Injection / XSS)**
터미널에서 `curl` 명령어를 사용하여 공격 패턴이 포함된 요청을 보냅니다.
*(도메인을 실제 등록하지 않았다면 `-H "Host: ..."` 옵션을 사용합니다)*

```bash
# 1. 정상 요청 (통과되어야 함)
curl -I -H "Host: test.aegis.local" http://127.0.0.1/
# 결과: HTTP/1.1 200 OK (또는 302/404 등 웹서버 응답)

# 2. SQL Injection 공격 시도 (차단되어야 함)
curl -I -H "Host: test.aegis.local" "http://127.0.0.1/?id=1' OR '1'='1"
# 결과: HTTP/1.1 403 Forbidden

# 3. XSS 공격 시도 (차단되어야 함)
curl -I -H "Host: test.aegis.local" "http://127.0.0.1/?search=<script>alert(1)</script>"
# 결과: HTTP/1.1 403 Forbidden
```

**🎉 성공 판정:** 공격 패턴이 포함된 요청에 대해 **`403 Forbidden`** 응답이 온다면 WAF가 정상적으로 공격을 방어하고 있는 것입니다.

### 3. 로그 확인 (Log Check)
차단된 공격 기록이 로그 파일에 남는지 확인합니다.

```bash
# WAF 보안 로그 실시간 확인
tail -f waf-logs/waf_security_log.log
```

로그 파일에 방금 실행한 `curl` 명령의 차단 내역(SQL Injection, XSS)이 JSON 형태로 기록되어 있어야 합니다.

---

## ⚖️ License

본 프로젝트는 여러 오픈 소스 프로젝트를 통합한 패키지입니다. 각 구성 요소의 라이선스를 준수합니다.

* **Aegis-Proxy-Stack Configuration:** MIT License
* **open-appsec:** Apache 2.0 (Engine) / Machine Learning Model License (Advanced Model)
* **NGINX Proxy Manager:** MIT License
* **CrowdSec:** MIT License
* **GoAccess:** MIT License