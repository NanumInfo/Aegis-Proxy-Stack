# Changelog

## [v0.2.1] - 2026-02-06

### 🚀 Enhancements (기능 개선)
* **Host Timezone Inheritance:** Added `/etc/localtime` volume mount to all services for auto-sync with host time. (호스트 타임존 자동 상속 기능 추가)
* **Alpine Support:** Added `tzdata` installation to log-rotator for proper timezone handling on Alpine. (Alpine 기반 컨테이너의 타임존 처리 로직 개선)