**[한국어](#korean) | [English](#english) | [日本語](#japanese)**

<a id="korean"></a>

# my-term

애플 실리콘 맥에서 터미널과 개발 환경을 한 번에 세팅하는 인스톨러입니다. Homebrew 패키지, zsh 테마, 다중 계정 Git SSH, Claude Code·Codex 설정까지 메뉴를 따라가며 필요한 것만 골라 설치할 수 있습니다.

## 사전 작업

- **macOS Command Line Tools** (`curl`, `git`): 설치돼 있어야 합니다. 없으면 인스톨러가 `xcode-select --install` 을 안내하고 종료합니다.
- **Nerd Fonts v3.0.0 이상**: HUD 가 Material Design Icons codepoint(`U+F062C` 등)를 쓰기 때문에 v3 매핑이 필요합니다. 구버전 폰트는 아이콘이 깨집니다.

## 설치

```bash
git clone https://github.com/mintcc342g/my-term.git
cd my-term
./install.sh
```

인스톨러를 실행하면 가장 먼저 **표시 언어(한국어 / English / 日本語)** 를 고릅니다. 이후 모든 메뉴와 안내가 그 언어로 나옵니다. 메뉴는 화살표(↑↓)로 움직이고 Enter 로 선택하며, 단계마다 건너뛰기와 종료가 따로 있어 원하는 항목만 설치할 수 있습니다.

각종 도구 단계에서는 CLI 도구·macOS 앱·DevOps 도구·패키지 매니저·IDE 및 편집기를 카테고리별 체크박스로 고릅니다. 처음에는 모두 미선택이며, ↑↓로 이동하고 Enter로 체크합니다. 각 카테고리의 `전부 설치`로 전체 선택·해제할 수 있습니다(`[-]`는 일부 선택). 목록 아래의 **설치 / 건너뛰기 / 종료** 행에서는 ←→로 이동하고 Enter로 실행합니다. 선택한 도구만 설치하며, television 셸 연동도 television을 선택했을 때만 설정합니다.

설치 후 새 터미널을 열거나, 현재 zsh 세션에서 아래 명령을 실행해 설정을 반영하세요.

```zsh
source "${HOME}/.zprofile" && source "${HOME}/.zshrc"
```

## 업데이트

프로젝트 코드가 바뀌었을 때 실행합니다. 업데이트는 brew 설치와 alias 설정을 건너뛰고 설치된 Claude Code·Codex 설정과 Claude HUD를 동기화합니다.

> ⚠️ `~/.claude/` 안의 `my-hooks/`, `my-collab/` 는 `cp -f` 로 덮어쓰기 때문에 직접 고친 내용은 사라집니다. `CLAUDE.md` 는 인스톨러가 관리하는 블록(`MYTERM:OPTIONAL:...`)만 갱신하고, 그 밖에 직접 쓴 내용은 보존합니다. (HUD `config.json` 과 Claude `settings.json` 은 사용자 변경분을 병합·보존합니다.)

**하는 법**

1. `git pull origin main` 으로 최신 코드를 받습니다.
2. `./install.sh` 실행 후 **Update** 를 선택합니다.
3. 새 Claude Code 또는 Codex 세션을 시작합니다. Codex에서 @wk 방식을 처음 쓸 때는 `/hooks`에서 검토하고 신뢰합니다.

## 설치 항목

### 필수

필수 툴 설치를 거절하면 인스톨러가 곧바로 종료됩니다.

- Homebrew, jq

### 선택

각 단계는 필요한 의존성 툴이 없으면 설치하지 않고 자동으로 건너뜁니다.

- **oh-my-zsh + zsh plugins** — syntax-highlighting, autosuggestions
- **newro theme**
- **각종 도구** — ripgrep, fd, bat, television, tmux, maccy, rectangle, postman, stats, fork, k9s, bun 등
  Antigravity와 LazyVim을 체크박스로 선택. Antigravity는 짧은 실행 명령(symlink)을 등록합니다. LazyVim은 기존 Neovim 설정, 데이터, 상태, 캐시를 고유한 `.bak.*` 경로에 백업하고 공식 스타터를 설치합니다. 실행 명령은 `nvim`입니다.
- **Git SSH keys (multi-account)** — 디렉토리별로 GitHub 계정 키를 자동 분기 ([자세히](#git-ssh-키-다중-계정))
- **언어 관리 도구** — asdf의 Golang·Java 플러그인과 pyenv + pyenv-virtualenv를 체크박스로 선택합니다. asdf로 언어를 설치한 뒤에는 해당 언어의 `.zprofile` 환경 설정 주석을 해제하세요.
- **AI tools** — AI 코딩 에이전트(Claude Code, Codex, OpenCode), 터미널 멀티플렉서(Herdr), 지식 관리(Obsidian + 위키 도구)를 체크박스로 선택합니다.

## Git SSH 키 (다중 계정)

GitHub 계정을 여러 개 쓸 때, 계정별 키를 디렉토리 단위로 자동 분기해주는 설정입니다. remote URL 은 표준 `git@github.com:...` 그대로 두고, `~/.ssh/config` 에 `Match exec` 블록을 넣어 현재 작업 디렉토리에 맞는 키를 골라줍니다. SourceTree 처럼 `~/.ssh/config` 를 따르는 git 클라이언트에서도 똑같이 동작합니다.

### 동작 방식

- 키를 만들 때 호스트 이름을 입력합니다. 비워 두면 `github.com`을 사용합니다.
- **호스트별로 처음 만든 키가 default 키가 됩니다.** 디렉토리 매칭 없이 fallback 으로 동작하며, 어떤 매칭 규칙에도 걸리지 않는 경로에서는 이 키가 쓰입니다.
- **같은 호스트의 두 번째 키부터는 디렉토리를 지정합니다.** 입력한 경로(및 그 하위)에서 작업할 때만 해당 키가 자동으로 선택됩니다. 지정한 디렉토리가 없으면 함께 만들어줍니다.
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

- **답변·코드 스타일**은 `my-ai/instructions/`에서 관리합니다. 선택한 언어의 응답 스타일과 공통 코딩 규칙을 `~/.claude/CLAUDE.md`와 `$CODEX_HOME/AGENTS.md`(기본 `~/.codex/AGENTS.md`)에 배포합니다.
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

### Obsidian 위키 호출

설치 메뉴에서 **Obsidian**을 선택해 위키 폴더를 지정합니다. 위키를 이미 설정했다면 **Update**가 기존 경로를 사용해 설치된 CLI에 `wk` 스킬과 훅을 배포합니다.

| 호출 방식 | 입력 예 |
|---|---|
| 두 CLI에서 훅 사용 | `지난 회의 기록을 @wk에서 찾아줘` |
| Claude Code 스킬 | `/wk 지난 회의 기록을 찾아줘` |
| Codex 스킬 | `지난 회의 기록을 찾아줘. $wk` |

세 방식은 같은 위키 폴더와 `schema.md`를 사용합니다. Codex의 `/hooks`에서 `my-term wk`를 검토하고 신뢰한 뒤 `@wk`를 사용합니다. `$wk` 스킬은 훅 신뢰 절차 없이 사용할 수 있습니다.

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
- Claude 차단 규칙은 `my-claude/settings/permissions.json`에서 관리합니다. Codex는 `my-codex/settings/permissions.json`의 권한 프로필을 자체 설정 기능으로 적용하고, `my-codex/rules/my-term.rules`를 복사합니다. 설치·업데이트에 Python은 필요하지 않습니다. Codex에 별도의 기본 샌드박스나 권한 프로필이 있으면 충돌을 알리고 해당 설정을 보존합니다.

## 각 프로그램 설정값

### iTerm2 사용시

- **한글 자소분리 해결**: Settings → Profiles → 프로필 선택 → Text → `Unicode normalization form` → HFS+
- **Nerd 폰트**: Settings → Profile → Text → Text Rendering → Use built-in Powerline glyphs 체크
- **커서 깜박임**: Settings → Profiles → 프로필 선택 → Text → Cursor → Blink 체크
- **tmux split spans**: Settings → General → Magic → Python API 활성화 후 재시작 → Claude Code 팀 모드 활성화 후 `c --teammate-mode tmux` 로 실행

### Ghostty 사용시

- 설정값은 자동으로 `~/.config/ghostty/config`에 셋팅되므로, 원하는 설정값으로 바꿔주세요.

### 앱 설정

Rectangle, AltTab, Stats는 설치 후 각 앱의 설정에서 아래 파일을 직접 가져와 주세요.

- [Rectangle](app-configs/rectangle/RectangleConfig.json)은 Settings → App Settings → Import에서 가져올 수 있습니다.
- [AltTab](app-configs/alt-tab/preferences.plist)은 Settings → General → Import…에서 가져올 수 있습니다.
- [Stats](app-configs/stats/preferences.plist)는 Settings → General → Import settings에서 가져올 수 있습니다.

### Maccy

설치 메뉴에서 Maccy를 선택하면 [저장된 설정](app-configs/maccy/preferences.json)을 `defaults write org.p0deje.Maccy`로 항목별로 적용합니다. Maccy를 다시 실행한 뒤 설정이 반영되지 않으면 아래대로 수동 설정해 주세요.

- **General** — Launch at login 켜기, 자동 업데이트 확인 끄기. Open `⌥⌘V`, Pin `⌥P`, Delete `⌥⌫`, Preview `⌃Space`. Fuzzy 검색과 Paste automatically를 켜고 Paste without formatting은 끕니다.
- **Storage** — Files, Images, Text 모두 켜기. Size 200, Time of last copy.
- **Appearance** — Menu icon, Top, 이미지 높이 40, 자동 미리보기 켜기, 지연 1500, Bold. Maccy 아이콘, 특수 기호, 검색창(Always), 제목, 색상 견본, 푸터를 켜고 최근 복사와 앱 아이콘 표시를 끕니다.
- **Advanced** — Turn off는 끄고, Clear history on quit과 Clear the system clipboard too를 켭니다.

<br>

---

<a id="english"></a>

**[한국어](#korean) | [English](#english) | [日本語](#japanese)**

# my-term

A one-shot installer for setting up your terminal and dev environment on Apple Silicon Macs. From Homebrew packages and a zsh theme to multi-account Git SSH and Claude Code / Codex configuration — follow the menu and install only what you need.

## Prerequisites

- **macOS Command Line Tools** (`curl`, `git`): must be installed. If missing, the installer points you to `xcode-select --install` and exits.
- **Nerd Fonts v3.0.0+**: the HUD uses Material Design Icons codepoints (e.g. `U+F062C`), which require the v3 mapping. Older fonts render broken glyphs.

## Install

```bash
git clone https://github.com/mintcc342g/my-term.git
cd my-term
./install.sh
```

The first thing the installer asks is your **display language (한국어 / English / 日本語)**. Every menu and prompt afterward appears in that language. Navigate menus with the arrow keys (↑↓) and select with Enter; each step has its own Skip and Exit, so you can install only the items you want.

The Utilities step groups checkboxes into CLI tools, macOS apps, DevOps tools, package managers, and IDEs and editors. Everything starts unchecked: move with ↑↓ and toggle with Enter. Each category's `Install all` selects or clears its tools (`[-]` means partially selected). Below the list, use ←→ to choose **Install / Skip / Exit**, then press Enter. Only selected tools are installed, and television shell integration is configured only when television is selected.

After installation, open a new terminal or run the following command in your current zsh session to apply the settings.

```zsh
source "${HOME}/.zprofile" && source "${HOME}/.zshrc"
```

## Update

Update syncs the installed Claude Code and Codex settings and the Claude HUD. It skips package installation and alias setup.

> ⚠️ Inside `~/.claude/`, `my-hooks/` and `my-collab/` are overwritten with `cp -f`, so any manual edits there are lost. For `CLAUDE.md`, only the installer-managed blocks (`MYTERM:OPTIONAL:...`) are refreshed — anything you wrote outside them is preserved. (The HUD `config.json` and Claude `settings.json` merge and preserve your changes.)

**How to**

1. Pull the latest code with `git pull origin main`.
2. Run `./install.sh` and choose **Update**.
3. Start a new Claude Code or Codex session. Before first using the Codex @wk hook, review and trust it with `/hooks`.

## What gets installed

### Required

Declining the required tools exits the installer immediately.

- Homebrew, jq

### Optional

Each step auto-skips when its dependency isn't present.

- **oh-my-zsh + zsh plugins** — syntax-highlighting, autosuggestions
- **newro theme**
- **Utilities** — ripgrep, fd, bat, television, tmux, maccy, rectangle, postman, stats, fork, k9s, bun, and more
  choose Antigravity or LazyVim with checkboxes. Antigravity registers a short launch command (symlink). LazyVim backs up existing Neovim config, data, state, and cache to unique `.bak.*` paths and installs the official starter. Launch it with `nvim`.
- **Git SSH keys (multi-account)** — auto-routes GitHub account keys per directory ([details](#git-ssh-keys-multi-account))
- **Language version managers** — select asdf’s Golang and Java plugins and pyenv + pyenv-virtualenv with checkboxes. After installing a language with asdf, uncomment its environment setup in `.zprofile`.
- **AI tools** — choose AI coding agents (Claude Code, Codex, OpenCode), a terminal multiplexer (Herdr), and knowledge management tools (Obsidian + wiki tooling) with checkboxes.

## Git SSH keys (multi-account)

When you use multiple GitHub accounts, this routes each account's key per directory. The remote URL stays the standard `git@github.com:...`, and a `Match exec` block in `~/.ssh/config` picks the right key based on your current working directory. It behaves the same in git clients that honor `~/.ssh/config`, such as SourceTree.

### How it works

- Enter a hostname when creating a key, or press Enter to use `github.com`.
- **The first key you create for each host becomes the default key.** It works as a fallback with no directory matching, and is used in any path that doesn't hit a matching rule.
- **From the second key for the same host on, you specify a directory.** That key is selected automatically only when you work in the given path (and below). If the directory doesn't exist, it's created for you.
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

- **Response and code style** comes from `my-ai/instructions/`. The installer deploys the selected response style and shared coding rules to `~/.claude/CLAUDE.md` and `$CODEX_HOME/AGENTS.md` (default `~/.codex/AGENTS.md`).
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

### Use the Obsidian wiki

Select **Obsidian** in the installer and choose a vault folder. If you already configured a vault, **Update** uses that path to deploy the `wk` skill and hook to the installed CLIs.

| Invocation | Example |
|---|---|
| Hook in either CLI | `Find the last meeting notes with @wk` |
| Claude Code skill | `/wk Find the last meeting notes` |
| Codex skill | `Use $wk to find the last meeting notes` |

All three forms use the same vault and `schema.md`. Review and trust `my-term wk` in Codex’s `/hooks` before using `@wk`. The `$wk` skill is available without hook approval.

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
- Claude deny rules live in `my-claude/settings/permissions.json`. Codex applies the profile in `my-codex/settings/permissions.json` through its own configuration editor and copies `my-codex/rules/my-term.rules`. Install and Update need no Python for permissions. The installer reports conflicts with an existing default sandbox or profile and preserves that configuration.

## Per-app settings

### When using iTerm2

- **Fix Korean jamo decomposition**: Settings → Profiles → select profile → Text → `Unicode normalization form` → HFS+
- **Nerd font**: Settings → Profile → Text → Text Rendering → check Use built-in Powerline glyphs
- **Cursor blink**: Settings → Profiles → select profile → Text → Cursor → check Blink
- **tmux split spans**: Settings → General → Magic → enable Python API and restart → enable Claude Code team mode, then run `c --teammate-mode tmux`

### When using Ghostty

- Settings are installed automatically at `~/.config/ghostty/config`. Change them as needed.

### App settings

After installing Rectangle, AltTab, or Stats, import the corresponding file below from the app’s settings.

- Import [Rectangle settings](app-configs/rectangle/RectangleConfig.json) via Settings → App Settings → Import.
- Import [AltTab settings](app-configs/alt-tab/preferences.plist) via Settings → General → Import….
- Import [Stats settings](app-configs/stats/preferences.plist) via Settings → General → Import settings.

### Maccy

Selecting Maccy in the installer applies the [saved settings](app-configs/maccy/preferences.json) one key at a time using `defaults write org.p0deje.Maccy`. If the settings do not appear after restarting Maccy, apply them below.

- **General** — Enable Launch at login and disable automatic update checks. Open `⌥⌘V`, Pin `⌥P`, Delete `⌥⌫`, Preview `⌃Space`. Use Fuzzy search, enable Paste automatically, and disable Paste without formatting.
- **Storage** — Save Files, Images, and Text. Set Size to 200 and sort by Time of last copy.
- **Appearance** — Menu icon, Top, image height 40, automatic preview with a 1500 delay, and Bold matches. Show the Maccy icon, special symbols, search field (Always), title, color swatch, and footer. Hide recent copy and application icons.
- **Advanced** — Leave Turn off unchecked. Enable Clear history on quit and Clear the system clipboard too.

<br>

---

<a id="japanese"></a>

**[한국어](#korean) | [English](#english) | [日本語](#japanese)**

# my-term

Apple Silicon の Mac で、ターミナルと開発環境をまとめてセットアップするインストーラーです。Homebrew パッケージ、zsh テーマ、複数アカウントの Git SSH、Claude Code・Codex の設定まで、メニューをたどりながら必要なものだけ選んで入れられます。

## 事前準備

- **macOS Command Line Tools**（`curl`、`git`）: 入っている必要があります。無ければインストーラーが `xcode-select --install` を案内して終了します。
- **Nerd Fonts v3.0.0 以上**: HUD が Material Design Icons のコードポイント（`U+F062C` など）を使うので、v3 のマッピングが要ります。古いフォントだとアイコンが化けます。

## インストール

```bash
git clone https://github.com/mintcc342g/my-term.git
cd my-term
./install.sh
```

インストーラーを起動すると、まず **表示言語（한국어 / English / 日本語）** を選びます。以降のメニューと案内はすべてその言語で出ます。メニューは矢印キー（↑↓）で動かして Enter で選びます。ステップごとにスキップと終了が別々にあるので、欲しい項目だけ入れられます。

各種ツールのステップでは、CLI ツール・macOS アプリ・DevOps ツール・パッケージマネージャー・IDE とエディターをカテゴリ別のチェックボックスで選びます。最初はすべて未選択です。↑↓で移動し、Enter でチェックを切り替えます。各カテゴリの `すべてインストール` で全選択・解除できます（`[-]` は一部選択）。一覧の下にある **インストール / スキップ / 終了** の行では、←→で移動して Enter で実行します。選んだツールだけをインストールし、television のシェル連携も television を選んだ場合にのみ設定します。

インストール後は、新しいターミナルを開くか、現在の zsh セッションで以下のコマンドを実行して設定を反映してください。

```zsh
source "${HOME}/.zprofile" && source "${HOME}/.zshrc"
```

## アップデート

プロジェクトのコードを更新したら実行します。パッケージのインストールとエイリアス設定を省略し、インストール済みの Claude Code・Codex の設定と Claude の HUD を同期します。

> ⚠️ `~/.claude/` の中の `my-hooks/`、`my-collab/` は `cp -f` で上書きするので、自分で直した内容は消えます。`CLAUDE.md` はインストーラーが管理するブロック（`MYTERM:OPTIONAL:...`）だけを更新し、それ以外に自分で書いた内容はそのまま残します。（HUD の `config.json` と Claude の `settings.json` はユーザーの変更分をマージして残します。）

**やり方**

1. `git pull origin main` で最新のコードを取得します。
2. `./install.sh` を実行して **Update** を選びます。
3. Claude Code または Codex の新しいセッションを開始します。Codex で初めて @wk フックを使う前に `/hooks` を開き、wiki フックを確認して信頼します。

## インストール項目

### 必須

必須ツールのインストールを断ると、インストーラーはその場で終了します。

- Homebrew、jq

### 任意

各ステップは、必要な依存ツールが無ければインストールせずに自動でスキップします。

- **oh-my-zsh + zsh plugins** — syntax-highlighting, autosuggestions
- **newro theme**
- **各種ツール** — ripgrep, fd, bat, television, tmux, maccy, rectangle, postman, stats, fork, k9s, bun など
  Antigravity と LazyVim をチェックボックスで選択できます。Antigravity は短い起動コマンド（symlink）を登録します。LazyVim は既存の Neovim の設定、データ、状態、キャッシュをそれぞれ固有の `.bak.*` パスにバックアップしてから公式スターターをインストールします。`nvim` で起動します。
- **Git SSH keys (multi-account)** — ディレクトリごとに GitHub アカウントのキーを自動で振り分け（[詳しく](#ja-git-ssh-keys)）
- **言語バージョン管理ツール** — asdf の Golang・Java プラグインと pyenv + pyenv-virtualenv をチェックボックスで選択します。asdf で言語をインストールしたあと、`.zprofile` でその言語の環境設定のコメントを外してください。
- **AI tools** — AI コーディングエージェント（Claude Code、Codex、OpenCode）、ターミナルマルチプレクサ（Herdr）、ナレッジ管理（Obsidian と Wiki ツール）をチェックボックスで選択できます。

<a id="ja-git-ssh-keys"></a>

## Git SSH キー（複数アカウント）

GitHub アカウントを複数使うとき、アカウントごとのキーをディレクトリ単位で自動的に振り分ける設定です。リモート URL は標準の `git@github.com:...` のままにして、`~/.ssh/config` に `Match exec` ブロックを入れ、今の作業ディレクトリに合ったキーを選ばせます。SourceTree のように `~/.ssh/config` に従う git クライアントでも同じように動きます。

### 仕組み

- キーを作るときにホスト名を入力します。空欄のまま Enter を押すと `github.com` を使います。
- **ホストごとに最初に作ったキーが default キーになります。** ディレクトリのマッチングなしに fallback として動き、どのマッチング規則にも当たらないパスではこのキーが使われます。
- **同じホストの 2 つめ以降はディレクトリを指定します。** 入力したパス（とその配下）で作業するときだけ、そのキーが自動的に選ばれます。指定したディレクトリが無ければ一緒に作ります。
- キーのファイル名は入力した nickname で決まります（`~/.ssh/id_<nickname>`）。同じ名前のキーがすでにあると断られるので、別の nickname で入力し直してください。nickname を空のまま Enter を押すと、キーの作成をやめて次のステップに進みます。
- キーを作ると public key が自動でクリップボードにコピーされます。[GitHub Settings → SSH keys](https://github.com/settings/ssh/new) にそのまま貼り付ければ大丈夫です。
- GitHub への登録を終えて Enter を押すと、「キーをもう 1 つ作るか」を聞かれます。必要なだけ繰り返してください。

### キーの追加

キーをもっと作りたいときは、**インストーラーをもう一度実行** して Git SSH のステップで Yes を選んでください。`~/.ssh/config` に default キーがあれば自動で検出し、最初の登録ステップを飛ばしてディレクトリマッチのキー登録へそのまま進みます（既存の default キーは上書きしません）。

自動検出は次のどちらの場合でも動きます。

- 以前インストーラーで登録した default キー（管理ブロック内の `Host github.com`）
- ユーザーが `~/.ssh/config` に直接書いた `Host github.com`

後者の場合は、新しく追加するディレクトリマッチのキーが既存の設定に隠れないよう、インストーラーの管理ブロックを `~/.ssh/config` の一番上へ移します。移す前に案内画面で確認を取ります。

管理ブロックの内と外に `Host github.com` が両方ある競合状態を検出すると、インストーラーは整理の案内だけして終了します。ssh の first-match 規則のせいで片方が隠れている状態なので、手作業での整理が要ります。

### 検証

```bash
cd <登録したディレクトリ>
ssh -T git@github.com
```

`Hi <github-username>!` が出れば、そのディレクトリにマッチしたキーで認証できています。

### 制約

- ディレクトリマッチは、キーを作るときに入力したパス（とその配下）でだけ動きます。それ以外のパスでは default キーにフォールバックします。
- 同じディレクトリを 2 回登録すると、あとから登録したキーが優先されます。前の登録は `~/.ssh/config` に残りますが無視されるので、整理は自分でしてください。

## AI アシスタント（Claude Code & Codex）

`my-claude/` の設定を `~/.claude` に同期して使います。

### インストール時に自動でやること

- hooks・collab スクリプトの配置（`~/.claude/my-hooks/`、`~/.claude/my-collab/`）
- `settings.json` の hooks・permissions のマージ
- Codex がすでに入っていれば MCP サーバーを自動設定（必要なら AI tools のステップで Codex を選んでください）

### 主な機能

- **応答とコードのスタイル**は `my-ai/instructions/` で管理します。選択した応答言語と共通のコーディングルールを `~/.claude/CLAUDE.md` と `$CODEX_HOME/AGENTS.md`（既定は `~/.codex/AGENTS.md`）に配布します。
- **マルチエージェント協調（`@co`）**: プロンプトに `@co` を付けると、Codex を MCP ツールとして並列に呼び出したうえで回答をまとめます（議論ループに対応）。エージェントは `~/.claude/my-collab/co-agents.json` で追加します。
  ```json
  [
    { "name": "Codex", "command": "codex exec --skip-git-repo-check" },
    { "name": "AnotherAgent", "command": "another-cli exec" }
  ]
  ```
- **SessionStart フック**: asdf の言語環境変数（GOROOT、JAVA_HOME など）を Claude Code のセッションに自動で注入します。
- **言語別の自動フォーマットフック（PostToolUse）**: Claude がファイルを直すと、その言語の標準フォーマッターが自動で走ります。今は Go（`gofmt`）だけ対応していて、他の言語も追加できます。
- ステータスラインの保護フックと、キャッシュの自動整理スクリプトが含まれています。

### Obsidian の保管庫を使う

インストーラーで **Obsidian** を選び、保管庫のフォルダーを指定します。設定済みの場合は **Update** がそのパスを使い、インストール済みの CLI に `wk` スキルとフックを配置します。

| 呼び出し方法 | 入力例 |
|---|---|
| 両方の CLI で使えるフック | `@wkで前回の議事録を探して` |
| Claude Code のスキル | `/wk 前回の議事録を探して` |
| Codex のスキル | `$wk で前回の議事録を探して` |

どの方法でも同じ保管庫と `schema.md` を使います。Codex で `@wk` を使う前に、`/hooks` で `my-term wk` を確認して信頼します。`$wk` スキルはフックの承認なしで使えます。

### HUD ステータスライン

- テーマ 4 種（mygo, ave-mujica, aemeath, millsage）から選択
- ターミナルの幅に応じて full / compact を自動で切り替え

**HUD 設定の変更**

1. `./install.sh` を実行
2. **HUD configure** を選択（HUD が入っているときだけメニューに出ます）
3. テーマ変更: Theme → 好きなテーマ → Save & Exit
4. セクションの on/off: Workspace, Claude, Codex をそれぞれトグル

### 機密ファイル・コマンドへのアクセス遮断

- デフォルトで `.env`、`.ssh`、`.pem`、`.key` など主要な機密ファイルの読み取り・編集が遮断されています。
- クラウド/インフラ操作コマンドの `aws`、`kubectl` の実行も遮断されています。
- Claude の拒否ルールは `my-claude/settings/permissions.json` で管理します。Codex は `my-codex/settings/permissions.json` のプロファイルを自身の設定機能で適用し、`my-codex/rules/my-term.rules` をコピーします。インストールとアップデートに Python は不要です。既定のサンドボックスや権限プロファイルが競合する場合は通知し、既存設定を保持します。

<a id="ja-per-app-settings"></a>

## 各プログラムの設定値

### iTerm2 を使う場合

- **ハングルの字母分離を解決**: Settings → Profiles → プロファイル選択 → Text → `Unicode normalization form` → HFS+
- **Nerd フォント**: Settings → Profile → Text → Text Rendering → Use built-in Powerline glyphs にチェック
- **カーソルの点滅**: Settings → Profiles → プロファイル選択 → Text → Cursor → Blink にチェック
- **tmux split spans**: Settings → General → Magic → Python API を有効化して再起動 → Claude Code のチームモードを有効化して `c --teammate-mode tmux` で実行

### Ghostty を使う場合

- 設定は `~/.config/ghostty/config` に自動で配置されます。必要に応じて変更してください。

### アプリ設定

Rectangle、AltTab、Stats は、インストール後に各アプリの設定から以下のファイルを読み込んでください。

- [Rectangle の設定](app-configs/rectangle/RectangleConfig.json)は Settings → App Settings → Import から読み込めます。
- [AltTab の設定](app-configs/alt-tab/preferences.plist)は Settings → General → Import… から読み込めます。
- [Stats の設定](app-configs/stats/preferences.plist)は Settings → General → Import settings から読み込めます。

### Maccy

インストーラーで Maccy を選ぶと、[保存済みの設定](app-configs/maccy/preferences.json)を `defaults write org.p0deje.Maccy` で項目ごとに設定します。Maccy を再起動しても反映されない場合は、以下の項目を手動で設定してください。

- **General** — ログイン時の起動をオン、自動更新チェックをオフ。Open `⌥⌘V`、Pin `⌥P`、Delete `⌥⌫`、Preview `⌃Space`。検索は Fuzzy、自動ペーストをオン、書式なしペーストをオフ。
- **Storage** — Files、Images、Text をすべて保存。Size は 200、並び順は Time of last copy。
- **Appearance** — Menu icon、Top、画像の高さ 40、自動プレビューをオン、遅延 1500、Bold。Maccy アイコン、特殊記号、検索欄（Always）、タイトル、色見本、フッターを表示し、最近のコピーとアプリアイコンは非表示。
- **Advanced** — Turn off はオフ。終了時の履歴消去とシステムクリップボードの消去をオン。
