#!/bin/bash
# installers/obsidian.sh — Obsidian app + wiki tooling (@wk hook, wiki path)
# source'd by install.sh; called from install_ai_tools after the AI menu exits.

install_obsidian() {
  log_start "Obsidian + wiki tooling setup…"

  if ! command -v brew &>/dev/null; then
    log_fail "$L_ERR_NO_BREW"
    return 1
  fi

  # 1. Install Obsidian (consent implied by entering this step). --adopt takes
  # over an Obsidian.app already in /Applications instead of erroring with
  # "It seems there is already an App at …" (see convenience.sh).
  log_step "brew install --cask --adopt obsidian…"
  brew list --cask obsidian &>/dev/null || brew install --cask --adopt obsidian || {
    log_fail "Obsidian install failed"
    return 1
  }
  log_done "Obsidian installed."

  # 2. Wiki storage type (Obsidian vault 의 저장 방식 선택)
  local storage=""
  ui_menu "$L_OBS_STORAGE_TITLE" storage \
    "$L_OBS_STORAGE_LOCAL" \
    "iCloud Drive" \
    "Git"

  if [ "$storage" = "255" ]; then
    log_step "$L_OBS_CANCELLED"
    return 0
  fi

  # 3. Wiki path prompt with per-storage guidance
  ui_clear_screen
  lang_obs_wikipath_help "$storage"
  # Prompt embedded in `read -p` so readline knows its length and can't
  # backspace-erase past it. \001\002 mark non-printing escape sequences
  # (color codes) so readline accounts for visible width correctly.
  # bash 3.2 (macOS 기본) 는 -i (prefill) 미지원이라 prefix 안내는 위 텍스트로만.
  # readline 기본은 첫 Tab → 공통 prefix 만 완성하고 침묵 → 두 번째 Tab 에 목록.
  # show-all-if-ambiguous 로 첫 Tab 에 바로 후보 목록 노출.
  # completion-ignore-case 로 `~/documents` ↔ `~/Documents` 대소문자 무시.
  # 비대화형 스크립트는 readline 이 기본 비활성 → `set -o emacs` 로 enable 후 bind.
  # `|| true` 로 set -euo pipefail 환경에서도 안전.
  # Tab → menu-complete: 후보 목록 출력 X, 인라인으로 후보 하나씩 교체 cycling.
  # Shift+Tab (\e[Z) → 역방향 cycling 으로 overshoot 복구.
  # completion-ignore-case 로 `~/documents` ↔ `~/Documents` 대소문자 무시.
  # match-hidden-files off 로 cycling 에 `.foo` 류 숨김 제외 (사용자가 `.` 입력 시 포함).
  set -o emacs 2>/dev/null || true
  bind '"\t": menu-complete' 2>/dev/null || true
  bind '"\e[Z": menu-complete-backward' 2>/dev/null || true
  bind 'set completion-ignore-case on' 2>/dev/null || true
  bind 'set match-hidden-files off' 2>/dev/null || true
  local prompt=$'\001\033[33;1m\002'" ${L_OBS_WIKIPATH_LABEL}"$'\001\033[0m\002'
  local wiki_path
  read -e -r -p "$prompt" wiki_path < /dev/tty

  # Expand leading ~ and strip trailing slash for Unix convention consistency.
  wiki_path="${wiki_path/#\~/$HOME}"
  wiki_path="${wiki_path%/}"
  if [ -z "$wiki_path" ]; then
    log_fail "$L_OBS_EMPTY_PATH"
    return 1
  fi

  # 4. Create wiki directory if missing (no validation beyond creation)
  if [ ! -d "$wiki_path" ]; then
    mkdir -p "$wiki_path" || { log_fail "Failed to create $wiki_path"; return 1; }
    log_done "Created new wiki directory: $wiki_path"
  else
    log_step "Using existing wiki directory: $wiki_path"
  fi

  # 5. Sync wiki hook script (path 가 sed 로 치환되어 deploy 됨) + register @wk matcher in settings.json
  _sync_obsidian_wiki_files "$wiki_path"
  _setup_wiki_hook

  # 6. Install default wiki content (schema.md 등) — 기존 파일 있으면 skip.
  _install_wiki_defaults "$wiki_path"

  log_done "Obsidian + wiki tooling configured."

  # 7. obsidian-skills plugin guidance — printed AFTER ✔ as a follow-up hint,
  # matching ui_print_completion 의 "Please run …" 스타일 (indent, 아이콘 X).
  printf "  %s\n" "$L_OBS_PLUGIN_HINT"
  printf "    /plugin marketplace add kepano/obsidian-skills\n"
  printf "    /plugin install obsidian@obsidian-skills\n"
}

# Sync my-claude/wiki/ hook scripts to ~/.claude/my-wiki/. Reused by
# update_my_claude when wiki tooling is already installed.
#
# $1: wiki_path — {{WIKI_PATH}} placeholder 치환에 사용.
#     install 시에는 사용자 입력값, update 시에는 기존 deploy 된 wk-trigger.sh 에서 추출한 값.
_sync_obsidian_wiki_files() {
  local wiki_path="${1:-}"

  if [ -z "$wiki_path" ]; then
    log_fail "_sync_obsidian_wiki_files called without wiki_path argument"
    return 1
  fi

  local _old_umask
  _old_umask=$(umask)
  umask 077

  if [[ -L "$HOME/.claude/my-wiki" ]]; then
    log_fail "symlink detected at $HOME/.claude/my-wiki — aborting for safety."
    umask "$_old_umask"
    return 1
  fi

  mkdir -p "$HOME/.claude/my-wiki"
  chmod 700 "$HOME/.claude/my-wiki"
  if [ -d "$SCRIPT_DIR/my-claude/wiki" ]; then
    # wk-* 만 ~/.claude/my-wiki/ 로 deploy (schema.md 는 _install_wiki_defaults 담당).
    #   - wk-trigger.sh: install 시점에 WIKI_PATH 치환
    #   - wk-directive.md: 응답 언어({{RESPONSE_LANG}}) 를 설치 언어로 치환
    local _lang_name="English"; [ "${MYTERM_LANG:-en}" = "ko" ] && _lang_name="Korean"
    sed "s|{{WIKI_PATH}}|${wiki_path}|g" "$SCRIPT_DIR/my-claude/wiki/wk-trigger.sh" \
      > "$HOME/.claude/my-wiki/wk-trigger.sh"
    sed "s|{{RESPONSE_LANG}}|${_lang_name}|g" "$SCRIPT_DIR/my-claude/wiki/wk-directive.md" \
      > "$HOME/.claude/my-wiki/wk-directive.md"
    chmod +x "$HOME/.claude/my-wiki/"*.sh 2>/dev/null || true
  fi

  umask "$_old_umask"
  log_done "wiki hook synced."
}

# Install default wiki content (schema.md 등) into user wiki if missing.
# 기존 파일이 있으면 절대 덮어쓰지 않음 — 사용자 수정분 보호.
# Reused by install_obsidian (최초) 와 update_my_claude (실수 삭제 복구) 양쪽에서.
#
# $1: wiki_path
# Placeholders 치환:
#   {{WIKI_NAME}}    → basename of wiki_path
#   {{INSTALL_DATE}} → 오늘 (YYYY-MM-DD)
_install_wiki_defaults() {
  local wiki_path="${1:-}"

  if [ -z "$wiki_path" ]; then
    log_fail "_install_wiki_defaults called without wiki_path argument"
    return 1
  fi
  if [ ! -d "$wiki_path" ]; then
    log_fail "wiki path does not exist: $wiki_path"
    return 1
  fi

  local wiki_dir="$SCRIPT_DIR/my-claude/wiki"
  if [ ! -d "$wiki_dir" ]; then
    return 0
  fi

  local wiki_name install_date
  wiki_name=$(basename "$wiki_path")
  install_date=$(date +%Y-%m-%d)

  # my-claude/wiki/ 안의 wk-* 는 훅 파일 (_sync_obsidian_wiki_files 가 처리),
  # 나머지는 사용자 wiki 로 들어가는 default content (schema.md 등).
  local _lang_name="English"; [ "${MYTERM_LANG:-en}" = "ko" ] && _lang_name="Korean"
  local src dst base
  for src in "$wiki_dir"/*; do
    [ -f "$src" ] || continue
    base=$(basename "$src")
    case "$base" in
      wk-*) continue ;;                 # 훅 지시문은 _sync_obsidian_wiki_files 담당
    esac
    # 사용자 wiki 에 같은 파일(예: schema.md)이 이미 있으면 절대 안 덮음.
    dst="$wiki_path/$base"
    if [ -e "$dst" ]; then
      log_step "wiki default exists, keep user copy: $base"
      continue
    fi
    sed -e "s|{{WIKI_NAME}}|${wiki_name}|g" \
        -e "s|{{INSTALL_DATE}}|${install_date}|g" \
        -e "s|{{RESPONSE_LANG}}|${_lang_name}|g" \
        "$src" > "$dst"
    log_done "installed wiki default: $base"
  done
}

# Add @wk UserPromptSubmit hook to ~/.claude/settings.json if not present.
# Idempotent — checks for existing matcher before adding.
_setup_wiki_hook() {
  local SETTINGS="$HOME/.claude/settings.json"
  if [ ! -f "$SETTINGS" ]; then
    log_step "skip @wk hook — ~/.claude/settings.json not found (install Claude Code first)."
    return 0
  fi

  if jq -e '.hooks.UserPromptSubmit[]? | select(.matcher == "@wk")' "$SETTINGS" >/dev/null 2>&1; then
    log_step "@wk hook already registered."
    return 0
  fi

  local _old_umask
  _old_umask=$(umask)
  umask 077
  local hook_tmp
  hook_tmp=$(mktemp)
  if jq '.hooks.UserPromptSubmit //= [] | .hooks.UserPromptSubmit += [{
    "matcher": "@wk",
    "hooks": [{
      "type": "command",
      "command": "bash $HOME/.claude/my-wiki/wk-trigger.sh"
    }]
  }]' "$SETTINGS" > "$hook_tmp"; then
    mv "$hook_tmp" "$SETTINGS"
    log_done "@wk hook registered in settings.json."
  else
    rm -f "$hook_tmp"
    log_fail "Failed to register @wk hook (jq error)"
  fi
  umask "$_old_umask"
}
