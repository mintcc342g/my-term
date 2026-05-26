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
- Git SSH keys (multi-account) — 디렉토리별 GitHub 계정 키 자동 분기
- oh-my-zsh + zsh plugins (syntax-highlighting, autosuggestions)
- newro theme
- asdf + 언어 플러그인 (Golang, Java)
- pyenv + pyenv-virtualenv
- AI tools — Claude Code, OpenCode, Codex
- Obsidian + wiki tooling — AI 기억 관리

## Git SSH 키 (다중 계정)

GitHub 계정을 여러 개 쓸 때, 각 계정 키를 디렉토리 단위로 자동 분기해주는 설정입니다. remote URL 은 표준 `git@github.com:...` 그대로 사용하고, `~/.ssh/config` 에 `Match exec` 블록을 박아 현재 작업 디렉토리에 따라 키를 골라줍니다. SourceTree 처럼 `~/.ssh/config` 를 따르는 git 클라이언트에서도 동일하게 동작합니다.

### 동작 방식

- **최초로 만든 키는 default 키로 등록됩니다.** 디렉토리 매칭 없이 fallback 으로 동작하며, 어느 매칭 규칙에도 해당하지 않는 경로에서 git 작업을 하면 이 키가 사용됩니다.
- **두 번째 키부터는 디렉토리를 지정**합니다. 입력한 경로(및 그 하위)에서 작업할 때만 해당 키가 자동 선택됩니다. 지정한 디렉토리가 존재하지 않으면 함께 생성해줍니다.
- 키 파일명은 입력한 nickname 으로 결정됩니다 (`~/.ssh/id_<nickname>`). 이미 같은 이름의 키가 있으면 거절합니다 — 다른 nickname 으로 다시 입력해주세요.
- 키 생성 후에는 public key 가 클립보드에 자동 복사되므로, [GitHub Settings → SSH keys](https://github.com/settings/ssh/new) 에 바로 붙여넣기 할 수 있습니다.
- GitHub 등록을 마치고 Enter 를 누르면 "키를 더 만들지" 선택지가 나옵니다. 필요한 만큼 반복해서 생성하세요.

### 키 추가

키를 더 만들고 싶을 땐 **installer 를 다시 실행**해서 Git SSH 단계에서 Yes 를 선택하세요. `~/.ssh/config` 에 default 키가 있는 것을 자동으로 감지해서, 첫 등록 단계를 건너뛰고 디렉토리 매칭 키 등록으로 바로 넘어갑니다 (기존 default 키는 덮어쓰지 않습니다).

자동 감지는 두 가지 경우 모두 동작합니다:
- 이전에 installer 로 등록한 default 키 (installer 매니지드 블록 안의 `Host github.com`)
- 사용자가 `~/.ssh/config` 에 직접 작성한 `Host github.com` 설정

후자의 경우, 새 디렉토리 매칭 키가 기존 설정에 가려지지 않도록 installer 매니지드 블록이 `~/.ssh/config` 맨 위쪽으로 이동합니다. 진행 전에 안내 화면에서 확인을 받습니다.

만약 매니지드 블록 안팎에 `Host github.com` 이 둘 다 있는 충돌 상태가 감지되면 installer 는 정리 안내 후 종료합니다 (한쪽이 ssh 의 first-match 규칙으로 가려져 있는 상태이므로 직접 정리가 필요합니다).

### 검증

```bash
cd <등록한 디렉토리>
ssh -T git@github.com
```

`Hi <github-username>!` 메시지가 나오면 그 디렉토리에 매칭된 키로 정상 인증된 것입니다.

### 제약

- 디렉토리 매칭은 키 생성 시 입력한 경로(및 하위)에서만 동작합니다. 그 외 경로에서는 default 키로 폴백됩니다.
- 같은 디렉토리를 두 번 등록하면 더 최근에 등록한 키가 우선 적용됩니다 (이전 등록은 `~/.ssh/config` 에 남지만 무시됨). 정리는 직접 편집해주세요.

## AI 어시스턴트 (Claude Code & Codex)
`my-claude/` 디렉토리의 설정을 `~/.claude`에 동기화하여 사용

### 설치 시 자동 처리
- hooks, collab 스크립트 배포 (`~/.claude/my-hooks/`, `~/.claude/my-collab/`)
- `settings.json` hooks/permissions 병합
- Codex가 이미 설치되어 있으면 MCP 서버 자동 설정
  - Codex가 필요하면 AI tools 단계에서 Codex 선택

### 주요 기능
- 멀티 에이전트 협업 (`@co`): 프롬프트에 `@co` 붙이면 Codex를 MCP 도구로 병렬 호출 후 종합 답변 (토론 루프 지원).
  - 에이전트 추가: `~/.claude/my-collab/co-agents.json` 편집. 예시:
    ```json
    [
      { "name": "Codex", "command": "codex exec --skip-git-repo-check" },
      { "name": "AnotherAgent", "command": "another-cli exec" }
    ]
    ```
- SessionStart 훅: asdf 언어 환경변수(GOROOT, JAVA_HOME 등)를 Claude Code 세션에 자동 주입
- 언어별 자동 포맷팅 훅 (PostToolUse): Claude가 파일을 수정하면 언어 표준 포매터 자동 실행. 현재는 Go(`gofmt`)만 지원, 다른 언어 추가 가능
- 상태줄 보호 훅 및 캐시 자동 정리 스크립트 포함
- Obsidian wiki (`@wk`): `@wk` 프롬프트가 감지되면 UserPromptSubmit 훅이 wiki 활용 지시문을 주입합니다. 운영 규칙은 wiki의 `schema.md`에 있으며, wiki 경로는 install 시 입력받은 값이 사용됩니다.

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
