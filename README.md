# CCUsage

Claude Code 사용량을 macOS 메뉴바에서 실시간으로 모니터링하는 미니멀 앱입니다.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## 주요 기능

- **5시간 / 주간** 사용량을 메뉴바에서 퍼센트로 실시간 표시
- 색상으로 상태 구분: 🟢 정상 → 🟠 70% 이상 → 🔴 90% 이상
- 리셋까지 남은 시간 표시 (24시간 초과 시 정확한 날짜/시간으로 표시)
- 30초마다 자동 갱신
- 설정 불필요 — Claude Code 로그인 정보를 자동으로 읽음

## 사전 조건

- **macOS 14 (Sonoma)** 이상
- **Claude Code CLI**가 설치되어 있고 로그인된 상태
- Claude Code 구독 (Pro / Max5 / Max20)

> Claude Code CLI에 로그인하면 macOS 키체인에 인증 정보가 자동 저장됩니다.  
> CCUsage는 이 정보를 읽어 Anthropic API에서 사용량을 조회합니다.

---

## 설치 방법

### 방법 1: 터미널 한 줄로 설치 (권장)

터미널을 열고 아래 명령어를 붙여넣으세요:

```bash
curl -sL https://raw.githubusercontent.com/NewTurn2017/ccusage/main/install.sh | bash
```

자동으로 최신 버전을 다운로드하고 `/Applications`에 설치합니다.

### 방법 2: 직접 다운로드

1. [Releases 페이지](https://github.com/NewTurn2017/ccusage/releases/latest)에서 `CCUsage.zip` 다운로드
2. 압축 해제
3. `CCUsage.app`을 `/Applications` (응용 프로그램) 폴더로 이동
4. **처음 실행 시**: `CCUsage.app`을 **우클릭 → 열기** 클릭  
   (서명되지 않은 앱이므로 최초 1회만 이 과정이 필요합니다)

### 방법 3: 소스에서 직접 빌드

Xcode Command Line Tools가 설치되어 있어야 합니다.

```bash
# 1. 소스 코드 다운로드
git clone https://github.com/NewTurn2017/ccusage.git
cd ccusage

# 2. 빌드 + /Applications에 설치 + 자동 실행
make install
```

---

## 사용법

설치 후 앱을 실행하면 메뉴바 오른쪽에 게이지 아이콘과 사용량 퍼센트가 나타납니다.

**아이콘 클릭** → 상세 사용량 팝오버:
- **5-Hour**: 5시간 롤링 윈도우 사용량 및 리셋 시간
- **Weekly**: 주간 사용량 및 리셋 시간

## 작동 원리

CCUsage는 macOS 키체인(`Claude Code-credentials`)에서 OAuth 인증 정보를 읽고, Anthropic 공식 API(`api.anthropic.com/api/oauth/usage`)를 호출하여 실시간 사용률을 조회합니다.

**개인정보**: Anthropic 공식 API 외에 어떤 곳에도 데이터를 전송하거나 저장하지 않습니다.

## 삭제

```bash
# 소스에서 빌드한 경우
make uninstall
```

또는 `/Applications`에서 `CCUsage.app`을 휴지통으로 이동하면 됩니다.

## License

MIT
