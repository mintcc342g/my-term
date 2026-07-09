**[한국어](#korean) | [English](#english)**

<a id="korean"></a>

# my-term

애플 실리콘 맥에서 터미널과 개발 환경을 한 번에 세팅하는 인스톨러입니다. Homebrew 패키지, zsh 테마, 다중 계정 Git SSH, Claude Code·Codex 설정까지 메뉴를 따라가며 필요한 것만 골라 설치할 수 있습니다.

⚠️ 만든 사람 혼자 쓰려고 만든, 취향 가득한 개인 설정입니다. 😅

## 사전 작업

- **macOS Command Line Tools** (`curl`, `git`): 설치돼 있어야 합니다. 없으면 인스톨러가 `xcode-select --install` 을 안내하고 종료합니다.
- **Nerd Fonts v3.0.0 이상**: HUD 가 Material Design Icons codepoint(`U+F062C` 등)를 쓰기 때문에 v3 매핑이 필요합니다. 구버전 폰트는 아이콘이 깨집니다.
- **iTerm2**: 설치 후 프로필을 맞춰주세요. 권장 값은 맨 아래 [각 프로그램 설정값](#각-프로그램-설정값) 에 정리해뒀습니다.

## 설치

```bash
git clone https://github.com/mintcc342g/my-term.git
cd my-term
./install.sh
```

인스톨러를 실행하면 가장 먼저 **표시 언어(한국어 / English)** 를 고릅니다. 이후 모든 메뉴와 안내가 그 언어로 나옵니다. 메뉴는 화살표(↑↓)로 움직이고 Enter 로 선택하며, 단계마다 건너뛰기와 종료가 따로 있어 원하는 항목만 설치할 수 있습니다.

## 업데이트

프로젝트 코드가 바뀌었을 때만 돌리면 됩니다. 업데이트는 brew 설치나 alias 설정 같은 인스톨 단계를 전부 건너뛰고 `~/.claude/` 로 파일을 sync 하는 일만 합니다. 현재 sync 대상은 AI 어시스턴트 설정과 HUD 입니다.

> ⚠️ `~/.claude/` 안의 `my-hooks/`, `my-collab/` 는 `cp -f` 로 덮어쓰기 때문에 직접 고친 내용은 사라집니다. `CLAUDE.md` 는 인스톨러가 관리하는 블록(`MYTERM:OPTIONAL:...`)만 갱신하고, 그 밖에 직접 쓴 내용은 보존합니다. (HUD `config.json` 과 Claude `settings.json` 은 사용자 변경분을 병합·보존합니다.)

**하는 법**

1. `git pull origin main` 으로 최신 코드를 받습니다.
2. `./install.sh` 실행 후 **Update** 를 선택합니다.
3. 변경 사항은 **새 Claude Code 세션부터** 반영됩니다. 열려 있는 세션은 재시작이 필요합니다.

## 설치 항목

### 필수

필수 툴 설치를 거절하면 인스톨러가 곧바로 종료됩니다.

- Homebrew, jq

### 선택

각 단계는 필요한 의존성 툴이 없으면 설치하지 않고 자동으로 건너뜁니다.

- **Convenience tools** — ripgrep, fd, bat, television, tmux, maccy, rectangle, k9s, bun 등
- **Git SSH keys (multi-account)** — 디렉토리별로 GitHub 계정 키를 자동 분기 ([자세히](#git-ssh-키-다중-계정))
- **IDE** — Antigravity IDE 를 설치하고 짧은 실행 명령(symlink)을 등록
- **oh-my-zsh + zsh plugins** — syntax-highlighting, autosuggestions
- **newro theme**
- **asdf + 언어 플러그인** — Golang, Java
- **pyenv + pyenv-virtualenv**
- **AI tools** — Claude Code, OpenCode, Codex
- **Obsidian + wiki tooling** — AI 기억 관리

## Git SSH 키 (다중 계정)

GitHub 계정을 여러 개 쓸 때, 계정별 키를 디렉토리 단위로 자동 분기해주는 설정입니다. remote URL 은 표준 `git@github.com:...` 그대로 두고, `~/.ssh/config` 에 `Match exec` 블록을 넣어 현재 작업 디렉토리에 맞는 키를 골라줍니다. SourceTree 처럼 `~/.ssh/config` 를 따르는 git 클라이언트에서도 똑같이 동작합니다.

### 동작 방식

- **처음 만든 키가 default 키가 됩니다.** 디렉토리 매칭 없이 fallback 으로 동작하며, 어떤 매칭 규칙에도 걸리지 않는 경로에서는 이 키가 쓰입니다.
- **두 번째 키부터는 디렉토리를 지정합니다.** 입력한 경로(및 그 하위)에서 작업할 때만 해당 키가 자동으로 선택됩니다. 지정한 디렉토리가 없으면 함께 만들어줍니다.
- 키 파일명은 입력한 nickname 으로 정해집니다(`~/.ssh/id_<nickname>`). 같은 이름의 키가 이미 있으면 거절하니 다른 nickname 으로 다시 입력해주세요. nickname 을 비우고 Enter 를 누르면 키 생성을 멈추고 다음 단계로 넘어갑니다.
- 키를 만들면 public key 가 클립보드에 자동 복사됩니다. [GitHub Settings → SSH keys](https://github.com/settings/ssh/new) 에 바로 붙여넣으면 됩니다.
- GitHub 등록을 마치고 Enter 를 누르면 "키를 더 만들지" 를 묻습니다. 필요한 만큼 반복하세요.

### 키 추가

키를 더 만들고 싶으면 **인스톨러를 다시 실행**해서 Git SSH 단계에서 Yes 를 고르세요. `~/.ssh/config` 에 default 키가 있으면 자동으로 감지해서, 첫 등록 단계를 건너뛰고 디렉토리 매칭 키 등록으로 바로 넘어갑니다 (기존 default 키는 덮어쓰지 않습니다).

자동 감지는 두 경우 모두 동작합니다.

- 이전에 인스톨러로 등록한 default 키 (매니지드 블록 안의 `Host github.com`)
- 사용자가 `~/.ssh/config` 에 직접 쓴 `Host github.com`

후자라면, 새로 추가하는 디렉토리 매칭 키가 기존 설정에 가려지지 않도록 인스톨러 매니지드 블록을 `~/.ssh/config` 맨 위로 옮깁니다. 옮기기 전에 안내 화면에서 확인을 받습니다.

매니지드 블록 안과 밖에 `Host github.com` 이 둘 다 있는 충돌 상태가 감지되면, 인스톨러는 정리 안내만 하고 종료합니다. ssh 의 first-match 규칙 때문에 한쪽이 가려진 상태라 직접 정리가 필요합니다.

### 검증

```bash
cd <등록한 디렉토리>
ssh -T git@github.com
```

`Hi <github-username>!` 가 나오면 그 디렉토리에 매칭된 키로 인증이 잘 된 것입니다.

### 제약

- 디렉토리 매칭은 키를 만들 때 입력한 경로(및 하위)에서만 동작합니다. 그 밖의 경로에서는 default 키로 폴백됩니다.
- 같은 디렉토리를 두 번 등록하면 더 나중에 등록한 키가 우선합니다. 이전 등록은 `~/.ssh/config` 에 남지만 무시되니 정리는 직접 해주세요.

## AI 어시스턴트 (Claude Code & Codex)

`my-claude/` 의 설정을 `~/.claude` 로 동기화해서 씁니다.

### 설치 시 자동 처리

- hooks·collab 스크립트 배포 (`~/.claude/my-hooks/`, `~/.claude/my-collab/`)
- `settings.json` 의 hooks·permissions 병합
- Codex 가 이미 설치돼 있으면 MCP 서버 자동 설정 (필요하면 AI tools 단계에서 Codex 를 선택하세요)

### 주요 기능

- **답변·코드 스타일 지시문 (`CLAUDE.md`)**: `~/.claude/CLAUDE.md` 에 답변 스타일·코드 스타일 지시문 블록(`MYTERM:OPTIONAL:...`)을 넣습니다. 답변 스타일은 설치 언어에 맞는 버전(한국어판 / 영어판)으로, 코드 스타일은 공용으로 들어갑니다. 원하지 않으면 해당 블록을 지우세요 — 업데이트해도 다시 추가되지 않습니다.
- **멀티 에이전트 협업 (`@co`)**: 프롬프트에 `@co` 를 붙이면 Codex 를 MCP 도구로 병렬 호출한 뒤 답변을 종합합니다(토론 루프 지원). 에이전트는 `~/.claude/my-collab/co-agents.json` 에서 추가합니다.
  ```json
  [
    { "name": "Codex", "command": "codex exec --skip-git-repo-check" },
    { "name": "AnotherAgent", "command": "another-cli exec" }
  ]
  ```
- **SessionStart 훅**: asdf 언어 환경변수(GOROOT, JAVA_HOME 등)를 Claude Code 세션에 자동 주입합니다.
- **언어별 자동 포맷팅 훅 (PostToolUse)**: Claude 가 파일을 고치면 해당 언어 표준 포매터를 자동 실행합니다. 현재는 Go(`gofmt`)만 지원하며 다른 언어도 추가할 수 있습니다.
- 상태줄 보호 훅과 캐시 자동 정리 스크립트가 포함돼 있습니다.
- **Obsidian wiki (`@wk`)**: `@wk` 프롬프트가 감지되면 UserPromptSubmit 훅이 wiki 활용 지시문을 주입합니다. 운영 규칙은 wiki 의 `schema.md` 에 있고, wiki 경로는 설치할 때 입력한 값을 씁니다.

### HUD Statusline

- 테마 4종(mygo, ave-mujica, aemeath, millsage) 중 선택
- 터미널 폭에 따라 full / compact 자동 전환

**HUD 설정 변경**

1. `./install.sh` 실행
2. **HUD configure** 선택 (HUD 가 설치돼 있을 때만 메뉴에 보입니다)
3. 테마 변경: Theme → 원하는 테마 → Save & Exit
4. 섹션 on/off: Workspace, Claude, Codex 를 각각 토글

### 민감 파일·명령어 접근 차단

- 기본적으로 `.env`, `.ssh`, `.pem`, `.key` 등 주요 민감 파일의 읽기·수정이 차단돼 있습니다.
- 클라우드/인프라 조작 명령어인 `aws`, `kubectl` 의 실행도 차단돼 있습니다.
- 패턴을 더 추가하려면 `my-claude/settings/settings.json` 의 `permissions.deny` 에 넣으세요.

## 각 프로그램 설정값

### iTerm2

- **한글 자소분리 해결**: Settings → Profiles → 프로필 선택 → Text → `Unicode normalization form` → HFS+
- **Nerd 폰트**: Settings → Profile → Text → Text Rendering → Use built-in Powerline glyphs 체크
- **커서 깜박임**: Settings → Profiles → 프로필 선택 → Text → Cursor → Blink 체크
- **tmux split spans**: Settings → General → Magic → Python API 활성화 후 재시작 → Claude Code 팀 모드 활성화 후 `c --teammate-mode tmux` 로 실행

### maccy

- General — Search: Fuzzy / Behavior: Paste without formatting / Open: Option + Command + v
- Appearance — Popup at: Menu icon / Pin to: Top / "Show recent copy next to menu icon" 만 빼고 전부 체크
- Advanced — 전부 체크 해제

### rectangle

- `RectangleConfig.json` 파일을 사용합니다.

<br>

---

<a id="english"></a>

**[한국어](#korean) | [English](#english)**

# my-term

A one-shot installer for setting up your terminal and dev environment on Apple Silicon Macs. From Homebrew packages and a zsh theme to multi-account Git SSH and Claude Code / Codex configuration — follow the menu and install only what you need.

⚠️ A personal, taste-packed setup the author built just for themselves. 😅

## Prerequisites

- **macOS Command Line Tools** (`curl`, `git`): must be installed. If missing, the installer points you to `xcode-select --install` and exits.
- **Nerd Fonts v3.0.0+**: the HUD uses Material Design Icons codepoints (e.g. `U+F062C`), which require the v3 mapping. Older fonts render broken glyphs.
- **iTerm2**: install it and configure the profile. Recommended values are in [Per-app settings](#per-app-settings) at the bottom.

## Install

```bash
git clone https://github.com/mintcc342g/my-term.git
cd my-term
./install.sh
```

The first thing the installer asks is your **display language (한국어 / English)**. Every menu and prompt afterward appears in that language. Navigate menus with the arrow keys (↑↓) and select with Enter; each step has its own Skip and Exit, so you can install only the items you want.

## Update

Run this only when the project code has changed. Update skips all install steps (brew installs, alias setup, and so on) and only syncs files into `~/.claude/`. The current sync targets are the AI assistant config and the HUD.

> ⚠️ Inside `~/.claude/`, `my-hooks/` and `my-collab/` are overwritten with `cp -f`, so any manual edits there are lost. For `CLAUDE.md`, only the installer-managed blocks (`MYTERM:OPTIONAL:...`) are refreshed — anything you wrote outside them is preserved. (The HUD `config.json` and Claude `settings.json` merge and preserve your changes.)

**How to**

1. Pull the latest code with `git pull origin main`.
2. Run `./install.sh` and choose **Update**.
3. Changes apply **from the next Claude Code session** — open sessions need a restart.

## What gets installed

### Required

Declining the required tools exits the installer immediately.

- Homebrew, jq

### Optional

Each step auto-skips when its dependency isn't present.

- **Convenience tools** — ripgrep, fd, bat, television, tmux, maccy, rectangle, k9s, bun, and more
- **Git SSH keys (multi-account)** — auto-routes GitHub account keys per directory ([details](#git-ssh-keys-multi-account))
- **IDE** — installs Antigravity IDE and registers a short launch command (symlink)
- **oh-my-zsh + zsh plugins** — syntax-highlighting, autosuggestions
- **newro theme**
- **asdf + language plugins** — Golang, Java
- **pyenv + pyenv-virtualenv**
- **AI tools** — Claude Code, OpenCode, Codex
- **Obsidian + wiki tooling** — AI memory management

## Git SSH keys (multi-account)

When you use multiple GitHub accounts, this routes each account's key per directory. The remote URL stays the standard `git@github.com:...`, and a `Match exec` block in `~/.ssh/config` picks the right key based on your current working directory. It behaves the same in git clients that honor `~/.ssh/config`, such as SourceTree.

### How it works

- **The first key you create becomes the default key.** It works as a fallback with no directory matching, and is used in any path that doesn't hit a matching rule.
- **From the second key on, you specify a directory.** That key is selected automatically only when you work in the given path (and below). If the directory doesn't exist, it's created for you.
- The key filename comes from the nickname you enter (`~/.ssh/id_<nickname>`). If a key with the same name already exists, it's rejected — enter a different nickname. Pressing Enter with an empty nickname stops key creation and moves on to the next step.
- After a key is created, the public key is copied to your clipboard automatically. Paste it straight into [GitHub Settings → SSH keys](https://github.com/settings/ssh/new).
- Once you finish registering on GitHub and press Enter, you're asked whether to create another key. Repeat as many times as you need.

### Adding more keys

To create more keys, **run the installer again** and choose Yes at the Git SSH step. If a default key already exists in `~/.ssh/config`, it's detected automatically — the installer skips the first-registration step and goes straight to directory-matched key registration (your existing default key is never overwritten).

Auto-detection works in both cases:

- A default key previously registered by the installer (`Host github.com` inside the managed block)
- A `Host github.com` you wrote yourself in `~/.ssh/config`

In the latter case, the installer moves its managed block to the top of `~/.ssh/config` so the newly added directory-matched keys aren't shadowed by your existing config. It asks for confirmation before moving anything.

If it detects a conflict — `Host github.com` both inside and outside the managed block — the installer only shows cleanup guidance and exits. Because of ssh's first-match rule one of them is shadowed, so you need to clean it up yourself.

### Verify

```bash
cd <a registered directory>
ssh -T git@github.com
```

If you see `Hi <github-username>!`, authentication succeeded with the key matched to that directory.

### Limitations

- Directory matching only works in the path (and below) you entered when creating the key. Elsewhere it falls back to the default key.
- If you register the same directory twice, the more recently registered key wins. The older entry stays in `~/.ssh/config` but is ignored — clean it up yourself.

## AI assistant (Claude Code & Codex)

Syncs the config in `my-claude/` into `~/.claude`.

### Handled automatically on install

- Deploys hooks and collab scripts (`~/.claude/my-hooks/`, `~/.claude/my-collab/`)
- Merges hooks and permissions into `settings.json`
- Auto-configures the MCP server if Codex is already installed (choose Codex at the AI tools step if you need it)

### Key features

- **Response & code style instructions (`CLAUDE.md`)**: adds response-style and code-style instruction blocks (`MYTERM:OPTIONAL:...`) to `~/.claude/CLAUDE.md`. The response style matches your install language (Korean / English); the code style is shared across languages. Don't want them? Delete the block — Update won't re-add it.
- **Multi-agent collaboration (`@co`)**: prefix a prompt with `@co` to call Codex in parallel as an MCP tool, then synthesize the answers (discussion loop supported). Add agents in `~/.claude/my-collab/co-agents.json`:
  ```json
  [
    { "name": "Codex", "command": "codex exec --skip-git-repo-check" },
    { "name": "AnotherAgent", "command": "another-cli exec" }
  ]
  ```
- **SessionStart hook**: injects asdf language environment variables (GOROOT, JAVA_HOME, etc.) into the Claude Code session.
- **Per-language auto-formatting hook (PostToolUse)**: when Claude edits a file, the language's standard formatter runs automatically. Currently only Go (`gofmt`) is supported; more languages can be added.
- Includes a statusline-protection hook and a cache auto-cleanup script.
- **Obsidian wiki (`@wk`)**: when an `@wk` prompt is detected, a UserPromptSubmit hook injects wiki-usage instructions. The operating rules live in the wiki's `schema.md`, and the wiki path is whatever you entered during install.

### HUD statusline

- Pick one of four themes (mygo, ave-mujica, aemeath, millsage)
- Auto-switches between full / compact based on terminal width

**Changing HUD settings**

1. Run `./install.sh`
2. Choose **HUD configure** (shown only when the HUD is installed)
3. Change theme: Theme → pick a theme → Save & Exit
4. Toggle sections: Workspace, Claude, Codex individually

### Sensitive-file and command access blocking

- By default, reading/editing of major sensitive files (`.env`, `.ssh`, `.pem`, `.key`, etc.) is blocked.
- Running the cloud/infra commands `aws` and `kubectl` is also blocked.
- To add more patterns, put them in `permissions.deny` in `my-claude/settings/settings.json`.

## Per-app settings

### iTerm2

- **Fix Korean jamo decomposition**: Settings → Profiles → select profile → Text → `Unicode normalization form` → HFS+
- **Nerd font**: Settings → Profile → Text → Text Rendering → check Use built-in Powerline glyphs
- **Cursor blink**: Settings → Profiles → select profile → Text → Cursor → check Blink
- **tmux split spans**: Settings → General → Magic → enable Python API and restart → enable Claude Code team mode, then run `c --teammate-mode tmux`

### maccy

- General — Search: Fuzzy / Behavior: Paste without formatting / Open: Option + Command + v
- Appearance — Popup at: Menu icon / Pin to: Top / check everything except "Show recent copy next to menu icon"
- Advanced — uncheck everything

### rectangle

- Uses the `RectangleConfig.json` file.
