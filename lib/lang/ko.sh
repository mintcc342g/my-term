#!/bin/bash
# lib/lang/ko.sh — 한국어 메시지 카탈로그.
# en.sh 와 동일한 키/함수 집합을 정의해야 한다 (검증: lib/lang 패리티 체크).
# 색상은 ui.sh 의 UI_* 만 사용 (source 시점에 이미 정의됨).
# 작성 기준: im-not-ai(번역투·AI 티 회피). 기존 자연스러운 문구는 그대로 추출.

# ── 공통 ────────────────────────────────────────────────────────
L_YES="예"
L_NO="아니요"
L_NO_SKIP="아니요 (건너뛰기)"
L_NO_EXIT="아니요 (종료)"
L_NO_DONE="아니요 (완료)"
L_DONE_ITEM="✓ 완료"
L_UI_HINT="↑↓ 이동 │ Enter 선택 │ Ctrl+C 종료"
L_EXIT_ABORTED="설치를 중단하고 종료합니다."

# ── 메인 메뉴 (install.sh) ──────────────────────────────────────
L_MENU_TITLE="my-term 설치 도구"
L_MENU_INSTALL="설치"
L_MENU_UPDATE="업데이트"
L_MENU_HUD_CONFIG="HUD 설정"
L_MENU_EXIT="✗ 종료"

# ── 단계 라벨 (install.sh ui_confirm_run / ai-tools) ────────────
L_STEP_CONVENIENCE="편의 도구 (CLI, macOS 앱, DevOps)"
L_STEP_GIT_SSH="Git SSH 키 (멀티 계정)"
L_STEP_OMZ="Oh-my-zsh + zsh 플러그인"
L_STEP_THEME="셸 테마 (newro)"
L_STEP_ASDF="asdf + 언어"
L_STEP_PYENV="pyenv"
L_STEP_AI="AI 도구 (Claude, OpenCode, Codex)"
L_STEP_OBSIDIAN="Obsidian + vault 도구"

# ── 완료 배너 (ui.sh ui_print_completion) ───────────────────────
L_DONE_INSTALL="설치 완료!"
L_DONE_UPDATE="업데이트 완료!"
L_DONE_HUDCFG="HUD 설정 완료."
L_DONE_RESTART_CC="적용하려면 Claude Code 세션을 다시 시작하세요."

# 여러 색상이 섞인 안내 (literal ${HOME} 는 \$ 로 유지).
lang_done_source_zshrc() {
  printf "  ${UI_YELLOW_BOLD}'source \${HOME}/.zshrc'${UI_RESET} 를 실행하거나 셸을 ${UI_YELLOW_BOLD}다시 시작${UI_RESET}하세요.\n\n"
}

# ── 공용 오류 안내 ──────────────────────────────────────────────
L_ERR_NO_BREW="Homebrew 를 찾지 못했습니다. 먼저 편의 도구를 설치하세요."
L_ERR_NO_OMZ="oh-my-zsh 를 찾지 못했습니다. 먼저 oh-my-zsh 를 설치하세요."

# ── 필수 도구 (required.sh) ─────────────────────────────────────
L_REQ_TITLE="필수 도구를 설치할까요? (Homebrew + jq)"
L_REQ_NOTE="⚠ 필수 항목입니다 — 거절하면 설치 도구가 바로 종료됩니다."

# ── IDE (ides.sh) ───────────────────────────────────────────────
L_IDE_MENU_TITLE="IDE — 설치할 항목 선택"
L_IDE_CMD_HEADER="Antigravity 명령어 설정"
L_IDE_CMD_PROMPT="antigravity 의 짧은 명령어 이름을 입력하세요 (기본값: agy)"
L_IDE_INVALID_NAME="이름이 올바르지 않습니다. 기본값 agy 를 사용합니다."
L_IDE_BINDIR_NOTFOUND="Antigravity bin 디렉토리를 찾지 못했습니다. IDE 를 한 번 실행한 뒤 이 단계를 다시 진행하세요."
L_PROMPT_NAME="이름: "

# ── asdf (asdf-langs.sh) ────────────────────────────────────────
L_ASDF_MENU_TITLE="asdf — 설정할 언어 선택"
# [경고] <name> 설치 후 .zprofile 주석 해제
lang_asdf_warning() {
  local name="$1"
  echo "${UI_YELLOW_BOLD}[경고]${UI_RESET} ${UI_RED_BOLD}${name} 설치 후${UI_RESET} .zprofile 에서 ${name} 환경 설정의 ${UI_RED_BOLD}주석을 해제${UI_RESET}하세요."
}

# ── Git SSH (git-ssh.sh) ────────────────────────────────────────
L_GITSSH_INTRO_TITLE="Git SSH — 멀티 계정 설정"
L_GITSSH_CASEA_TITLE="이미 사용 중인 default 키가 있습니다"
L_GITSSH_CASEB_TITLE="기존 default 키가 감지됐습니다 — 진행할까요?"
L_GITSSH_ANOTHER_TITLE="키를 더 만들까요?"
L_GITSSH_ENTER_NEXT="Enter 로 다음 단계로…"
L_GITSSH_ENTER_DONE="등록을 마쳤으면 Enter…"
L_GITSSH_NICK_LABEL="닉네임: "
L_GITSSH_EMPTY_NICK="닉네임을 입력하세요."
L_GITSSH_INVALID_NICK="닉네임이 올바르지 않습니다 (a-z, 0-9, _, - 만 사용)."
L_GITSSH_KEY_EXISTS="%s 에 이미 키가 있습니다. 다른 닉네임을 입력하세요."
L_GITSSH_EMAIL_LABEL="email (키 주석): "
L_GITSSH_EMPTY_EMAIL="email 을 입력하세요."
L_GITSSH_PUBKEY_LABEL="공개 키:"
L_GITSSH_REGISTER_GH="GitHub Settings → SSH keys 에 등록하세요:"
L_GITSSH_DIR_LABEL="디렉토리: "
L_GITSSH_DIR_REQUIRED="디렉토리는 필수입니다."
L_GITSSH_VERIFY="검증: cd <등록한 디렉토리> && ssh -T git@github.com"

# 진입 안내 (UI_MENU_NOTE; echo -e 용 literal \n).
lang_gitssh_intro() {
  local s=""
  s+=" ─────────────────────\n"
  s+=" 키를 2개 이상 만들 거라면, 만들기 전에 어느\n"
  s+=" 디렉토리에서 어떤 키를 쓸지 먼저 정해두세요.\n"
  s+="\n"
  s+="   예)  ~/Documents/my    →  id_my    (개인)\n"
  s+="        ~/Documents/works →  id_work  (회사)\n"
  s+="\n"
  s+=" 키가 2개 이상이면 ssh 가 github.com 을 인증할 때\n"
  s+=" 어느 키를 쓸지 판단하지 못하므로, 디렉토리별로\n"
  s+=" 키를 지정해줘야 합니다.\n"
  s+="\n"
  s+=" GitHub SSH Key 설정을 진행할까요?"
  printf '%s' "$s"
}

# Case A 안내 (매니지드 default 존재).
lang_gitssh_caseA_note() {
  local managed="$1"
  local s=""
  s+=" ─────────────────────\n"
  s+=" 아래 키를 default 로 이미 사용하고 있습니다.\n"
  s+="    ${managed}\n"
  s+="\n"
  s+=" 새로 만드는 키는 디렉토리별로 매칭해서 추가합니다.\n"
  s+="\n"
  s+=" 키를 새로 추가할까요?"
  printf '%s' "$s"
}

# Case B 안내 (external default 존재).
lang_gitssh_caseB_note() {
  local ext="$1"
  local s=""
  s+=" ${UI_DIM}~/.ssh/config 에 이미 'Host github.com' 설정이 있어요.${UI_RESET}\n"
  s+=" ${UI_DIM}이 키를 그대로 default 로 사용합니다:${UI_RESET}\n"
  s+="    ${ext}\n"
  s+="\n"
  s+=" ${UI_DIM}추가로 키를 등록하실 거라면 진행해주세요.${UI_RESET}"
  printf '%s' "$s"
}

# Case D 충돌 화면 (/dev/tty 출력).
lang_gitssh_conflict() {
  local ext="$1" managed="$2"
  echo -e "${UI_BLUE_BOLD} 'Host github.com' 설정이 둘 다 있습니다${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}~/.ssh/config 에 'Host github.com' 이 매니지드 블록 안팎에 모두${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}존재합니다. ssh 는 둘 중 위쪽 값만 사용하므로 한 쪽이 가려진${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}상태예요.${UI_RESET}" > /dev/tty
  echo > /dev/tty
  echo -e " ${UI_DIM}  매니지드 외부 (직접 작성): ${ext}${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}  매니지드 내부 (installer): ${managed}${UI_RESET}" > /dev/tty
  echo > /dev/tty
  echo -e " ${UI_DIM}~/.ssh/config 를 직접 정리하신 뒤 다시 실행해주세요.${UI_RESET}\n" > /dev/tty
}

# 닉네임 안내 화면.
lang_gitssh_nick_help() {
  local has_default="$1"
  echo -e "${UI_BLUE_BOLD} SSH 키 — 닉네임${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}이 닉네임이 키 파일명에 사용됩니다 (~/.ssh/id_<nickname>).${UI_RESET}" > /dev/tty
  if [ "$has_default" = "false" ]; then
    echo -e " ${UI_DIM}최초 입력 키는 default 키로 등록됩니다 (디렉토리 매칭 X, fallback 으로 동작).${UI_RESET}\n" > /dev/tty
  else
    echo -e " ${UI_DIM}이후 키는 디렉토리 매칭 방식으로 등록됩니다.${UI_RESET}\n" > /dev/tty
  fi
}

# 디렉토리 안내 화면.
lang_gitssh_dir_help() {
  echo -e "${UI_BLUE_BOLD} SSH 키 — 디렉토리${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}이 키를 사용할 디렉토리 경로 (Tab 자동완성).${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}해당 경로(및 하위)에서 git 작업 시 이 키가 자동 선택됩니다.${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}경로가 없으면 자동으로 생성됩니다.${UI_RESET}\n" > /dev/tty
}

# ── Obsidian (obsidian.sh) ──────────────────────────────────────
L_OBS_STORAGE_TITLE="위키 저장 방식"
L_OBS_STORAGE_LOCAL="로컬"
L_OBS_CANCELLED="Obsidian 위키 설정을 취소했습니다."
L_OBS_WIKIPATH_LABEL="위키 경로: "
L_OBS_EMPTY_PATH="위키 경로를 입력하지 않아 위키 설정을 건너뜁니다."
L_OBS_PLUGIN_HINT="Claude Code 를 처음 실행한 뒤 obsidian-skills 플러그인을 직접 설치하세요:"

# 위키 경로 안내 화면 (storage: 0=로컬 1=icloud 2=git).
lang_obs_wikipath_help() {
  local storage="$1"
  echo -e "${UI_BLUE_BOLD} 위키 경로${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}위키로 쓸 로컬 디렉토리 경로를 입력하세요 (Tab 자동완성).${UI_RESET}" > /dev/tty
  case "$storage" in
    0)
      echo -e " ${UI_DIM}  로컬 — 아무 디렉토리나 됩니다.${UI_RESET}\n" > /dev/tty
      ;;
    1)
      echo -e " ${UI_DIM}  iCloud Drive — Obsidian 이 쓰는 표준 iCloud 보관함 경로:${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}    ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/<vault-name>${UI_RESET}\n" > /dev/tty
      ;;
    2)
      echo -e " ${UI_DIM}  Git — 먼저 리포지토리를 로컬에 clone 한 다음, 그 로컬 경로를${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}  여기에 입력하세요 (git URL 아님). git config 나 ssh 키를${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}  미리 설정해야 할 수 있습니다.${UI_RESET}\n" > /dev/tty
      ;;
  esac
}

# ── AI 도구 (ai-tools.sh) ───────────────────────────────────────
L_AI_MENU_TITLE="AI 도구 — 설치할 항목 선택 (계속하려면 Done)"
L_AI_METHOD_TITLE="Claude Code 설치 방식"
L_AI_METHOD_STABLE="Stable (brew cask — 수동 업그레이드)"
L_AI_METHOD_LATEST="Latest (brew cask @latest — 항상 최신)"
L_AI_ALIAS_HEADER="Claude alias 설정"
L_AI_ALIAS_PROMPT="claude 명령어의 alias 를 입력하세요 (기본값: c)"
L_AI_ALIAS_LABEL="alias: "
L_AI_INVALID_ALIAS="alias 이름이 올바르지 않습니다. 기본값 c 를 사용합니다."
L_AI_HUD_TITLE="HUD 상태줄을 설치할까요?"
L_AI_OPT_PREVIEW="── %s.md 미리보기 ──"
L_AI_OPT_TITLE="선택 지시문을 추가할까요: %s?"
L_AI_GOFMT_TITLE="Go 가 감지됐습니다 — gofmt 훅을 Claude 에 추가할까요?"
