# my-term

터미널 개인 설정 (애플 실리콘 기준)

## 사전 작업
- 서체 설치 (Nerd Font 필수 — HUD 아이콘 표시용)
- iTerm2 설치 및 프로필 설정

## 설치

```bash
git clone https://github.com/mintcc342g/my-term.git
cd my-term
./install.sh
```

화살표 키로 항목 선택. 개별 설치 가능.

## 설치 프로그램 목록
- oh-my-zsh + zsh plugins (syntax-highlighting, autosuggestions)
- newro theme
- Convenience tools — ripgrep, fd, bat, television, tmux, maccy, rectangle, k9s 등
- asdf + 언어 플러그인 (Golang, Java)
- pyenv + pyenv-virtualenv
- AI tools — Claude Code, OpenCode, Codex, bun
- brew 설치 프로그램은 스크립트 참고

## AI 어시스턴트 (Claude Code & Codex)
`my-claude/` 디렉토리의 설정을 `~/.claude`에 동기화하여 사용

### 주요 기능
- 멀티 에이전트 협업 (`@co`): 프롬프트에 `@co` 붙이면 외부 에이전트(현재는 Codex) 병렬 호출 후 종합 답변
- SessionStart 훅: asdf 언어 환경변수(GOROOT, JAVA_HOME 등)를 Claude Code 세션에 자동 주입
- gofmt 자동 포맷팅: Golang 설치 시 .go 파일 저장 시 자동 포맷 (PostToolUse 훅)
- 상태줄 보호 훅 및 캐시 자동 정리 스크립트 포함

### HUD 상태줄
- 3종 테마(mygo, ave-mujica, eimes) 선택 가능
- 터미널 폭에 따라 full/compact 자동 전환

#### 설정 변경 (HUD 설치 후)
1. `./install.sh` 실행
2. HUD settings 선택 (HUD가 설치되어 있으면 메뉴에 표시됨)
3. 테마 변경: Theme 선택 → 원하는 테마 선택 → Save & Exit
4. 섹션 on/off: Workspace, Claude, Codex 각각 토글 가능
5. 코드 업데이트 반영: Sync HUD 선택 (유저 설정은 유지됨)

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
