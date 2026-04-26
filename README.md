# my-term

터미널 개인 설정 (애플 실리콘 기준)

## 사전 작업
- macOS Command Line Tools(`curl`, `git`) 설치
  - 누락 시 인스톨러가 `xcode-select --install` 안내 후 종료합니다
- 서체 설치 (Nerd Fonts **v3.0.0 이상** 필수
  - HUD가 Material Design Icons codepoint(`U+F062C` 등)을 사용하므로 v3 매핑이 필요합니다)
- iTerm2 설치 및 프로필 설정

## 설치

```bash
git clone https://github.com/mintcc342g/my-term.git
cd my-term
./install.sh
```

## 업데이트
이 프로젝트 코드가 변경된 경우 업데이트를 진행해주세요.  
업데이트는 brew 설치/alias 설정 같은 인스톨 단계를 모두 건너뛰고 `~/.claude/`로 파일 sync만 수행합니다. 현재는 AI 어시스턴트 설정과 HUD가 sync 대상입니다.

> ⚠️ **주의**: `~/.claude/` 안의 `my-hooks/`, `my-collab/`, `CLAUDE.md`는 `cp -f`로 덮어쓰므로 직접 수정한 내용은 사라집니다. (HUD `config.json`과 Claude `settings.json`은 사용자 변경분이 병합·보존됨)

### 하는 법
1. `git pull origin main`으로 최신 코드 받기
2. `./install.sh` → **Update** 선택
3. **새 Claude Code 세션부터 반영** — 현재 열린 세션은 재시작 필요

## 설치 프로그램 목록

### 필수
필수 툴 설치를 거절할 경우, 설치를 즉시 종료합니다.
- Homebrew, jq

### 선택
각 단계별로 의존성 툴이 설치되어 있지 않을 경우, 설치하지 않고 자동으로 스킵합니다.
- Convenience tools — ripgrep, fd, bat, television, tmux, maccy, rectangle, k9s, bun 등
- oh-my-zsh + zsh plugins (syntax-highlighting, autosuggestions)
- newro theme
- asdf + 언어 플러그인 (Golang, Java)
- pyenv + pyenv-virtualenv
- AI tools — Claude Code, OpenCode, Codex

## AI 어시스턴트 (Claude Code & Codex)
`my-claude/` 디렉토리의 설정을 `~/.claude`에 동기화하여 사용

### 설치 시 자동 처리
- hooks, collab 스크립트 배포 (`~/.claude/my-hooks/`, `~/.claude/my-collab/`)
- `settings.json` hooks/permissions 병합
- Codex가 이미 설치되어 있으면 MCP 서버 자동 설정
  - Codex가 필요하면 AI tools 단계에서 Codex 선택

### 주요 기능
- 멀티 에이전트 협업 (`@co`): 프롬프트에 `@co` 붙이면 Codex를 MCP 도구로 병렬 호출 후 종합 답변 (토론 루프 지원)
- SessionStart 훅: asdf 언어 환경변수(GOROOT, JAVA_HOME 등)를 Claude Code 세션에 자동 주입
- 언어별 자동 포맷팅 훅 (PostToolUse): Claude가 파일을 수정하면 언어 표준 포매터 자동 실행. 현재는 Go(`gofmt`)만 지원, 다른 언어 추가 가능
- 상태줄 보호 훅 및 캐시 자동 정리 스크립트 포함

### HUD Statusline
- 3종 테마(mygo, ave-mujica, eimes) 선택 가능
- 터미널 폭에 따라 full/compact 자동 전환

#### HUD 설정 변경
1. `./install.sh` 실행
2. **HUD configure** 선택 (HUD가 설치되어 있을 때만 메뉴에 표시됨)
3. 테마 변경: Theme 선택 → 원하는 테마 선택 → Save & Exit
4. 섹션 on/off: Workspace, Claude, Codex 각각 토글 가능

### 민감 파일 접근 차단
- 기본적으로 .env, .ssh, .pem, .key 등 주요 민감 파일의 읽기/수정이 차단되어 있음
- 추가가 필요하면 `my-claude/settings/settings.json`의 `permissions.deny`에 패턴 추가

## 각 프로그램 설정값
### iTerm2
- 한글 자소분리 해결
  - Settings → Profiles → 프로필 선택 → Text → `Unicode normalization form` → HFS+
- Nerd 폰트 설정
  - Settings → Profile → Text → Text Rendering → Use built-in Powerline glyphs 체크
- 커서 깜박임 활성화
  - Settings → Profiles → 프로필 선택 → Text → Cursor → Blink 체크
- tmux split spans 활성화
  - Settings → General → Magic → Python API 활성화 후 재시작
  - claude code 팀 모드 활성화 후 `c --teammate-mode tmux`로 실행

### maccy
- General
  - Search: Fuzzy
  - Behavior: Past without formatting
  - Open: Option + Command + v
- Appearance
  - Popup at: Menu icon
  - Pin to: Top
  - 체크박스 Show recent copy next to menu icon 빼고 전부 선택
- Advanced
  - 전부 선택 해제

### rectangle
- `RectangleConfig.json` 파일 사용
