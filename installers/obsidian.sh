#!/bin/bash
# installers/obsidian.sh — Obsidian app + AI vault tooling (@vl hook, vault path)
# source'd by install.sh; called from install_ai_tools after the AI menu exits.

install_obsidian() {
  log_start "Obsidian + vault tooling setup…"

  if ! command -v brew &>/dev/null; then
    log_fail "Homebrew not found. Please install convenience tools first."
    return 1
  fi

  # 1. Install Obsidian (consent implied by entering this step)
  log_step "brew install --cask obsidian…"
  brew list --cask obsidian &>/dev/null || brew install --cask obsidian || {
    log_fail "Obsidian install failed"
    return 1
  }
  log_done "Obsidian installed."

  # 2. Vault storage type
  local storage=""
  ui_menu "Vault storage type" storage \
    "Local" \
    "iCloud Drive" \
    "Git"

  if [ "$storage" = "255" ]; then
    log_step "Obsidian vault setup cancelled."
    return 0
  fi

  # 3. Vault path prompt with per-storage guidance
  ui_clear_screen
  echo -e "${UI_BLUE_BOLD} Vault path${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}Enter the local directory path for the vault (Tab to autocomplete).${UI_RESET}" > /dev/tty
  case "$storage" in
    0)
      echo -e " ${UI_DIM}  Local vault — any directory works.${UI_RESET}\n" > /dev/tty
      ;;
    1)
      echo -e " ${UI_DIM}  iCloud Drive vault — standard path:${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}    ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/<vault-name>${UI_RESET}\n" > /dev/tty
      ;;
    2)
      echo -e " ${UI_DIM}  Git vault — clone the repo to a local directory first, then enter${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}  that local path here (NOT a git URL). git config / ssh key may${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}  need to be configured beforehand.${UI_RESET}\n" > /dev/tty
      ;;
  esac
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
  local prompt=$'\001\033[33;1m\002 vault path: \001\033[0m\002'
  local vault_path
  read -e -r -p "$prompt" vault_path < /dev/tty

  # Expand leading ~ and strip trailing slash for Unix convention consistency.
  vault_path="${vault_path/#\~/$HOME}"
  vault_path="${vault_path%/}"
  if [ -z "$vault_path" ]; then
    log_fail "Empty vault path. Skipping vault setup."
    return 1
  fi

  # 4. Create vault directory if missing (no validation beyond creation)
  if [ ! -d "$vault_path" ]; then
    mkdir -p "$vault_path" || { log_fail "Failed to create $vault_path"; return 1; }
    log_done "Created new vault directory: $vault_path"
  else
    log_step "Using existing vault directory: $vault_path"
  fi

  # 5. Persist OBSIDIAN_VAULT_PATH in zshrc (read by vl-trigger.sh)
  local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
  rc_upsert_block "$ZSHRC" "obsidian-vault-path" "export OBSIDIAN_VAULT_PATH=\"$vault_path\""
  export ZSHRC_MODIFIED=true
  log_done "OBSIDIAN_VAULT_PATH=\"$vault_path\" added to .zshrc"

  # 6. Sync vault hook script + register @vl matcher in settings.json
  _sync_obsidian_vault_files
  _setup_vault_hook

  # 7. Wire vault context into globally-installed coding agents' instruction
  # files (Claude / Codex / OpenCode). Detection is per-binary; prompt is
  # single, mapping is fan-out.
  _wire_vault_into_ai_tools

  log_done "Obsidian + vault tooling configured."

  # 8. obsidian-skills plugin guidance — printed AFTER ✔ as a follow-up hint,
  # matching ui_print_completion 의 "Please run …" 스타일 (indent, 아이콘 X).
  printf "  After first Claude Code launch, manually install the obsidian-skills plugin:\n"
  printf "    /plugin marketplace add kepano/obsidian-skills\n"
  printf "    /plugin install obsidian@obsidian-skills\n"
}

# Wire ai-logs vault context into the global instruction files of any coding
# agents detected in PATH. Idempotent — re-running just refreshes the MYTERM
# block via md_upsert_myterm_block (from lib/instructions-block.sh).
_wire_vault_into_ai_tools() {
  local detected=()  # "Label:dst_path" pairs
  command -v claude   &>/dev/null && detected+=("Claude:$HOME/.claude/CLAUDE.md")
  command -v codex    &>/dev/null && detected+=("Codex:$HOME/.codex/AGENTS.md")
  command -v opencode &>/dev/null && detected+=("OpenCode:$HOME/.config/opencode/AGENTS.md")

  if [ ${#detected[@]} -eq 0 ]; then
    log_step "no coding agents detected — skip vault wiring."
    return 0
  fi

  local choice=""
  ui_menu "Coding agents detected. Wire vault into AI instructions?" choice \
    "Yes" \
    "No"

  if [ "$choice" != "0" ]; then
    log_step "vault wiring skipped."
    return 0
  fi

  local entry label dst
  for entry in "${detected[@]}"; do
    label="${entry%%:*}"
    dst="${entry#*:}"
    md_upsert_myterm_block "$dst"
    log_done "vault context wired into ${label} (${dst})"
  done
}

# Sync my-claude/vault/ scripts to ~/.claude/my-vault/. Reused by
# update_my_claude when vault tooling is already installed.
_sync_obsidian_vault_files() {
  local _old_umask
  _old_umask=$(umask)
  umask 077

  if [[ -L "$HOME/.claude/my-vault" ]]; then
    log_fail "symlink detected at $HOME/.claude/my-vault — aborting for safety."
    umask "$_old_umask"
    return 1
  fi

  mkdir -p "$HOME/.claude/my-vault"
  chmod 700 "$HOME/.claude/my-vault"
  if [ -d "$SCRIPT_DIR/my-claude/vault" ]; then
    cp -f "$SCRIPT_DIR/my-claude/vault/"* "$HOME/.claude/my-vault/"
    chmod +x "$HOME/.claude/my-vault/"*.sh
  fi

  umask "$_old_umask"
  log_done "vault hook synced."
}

# Add @vl UserPromptSubmit hook to ~/.claude/settings.json if not present.
# Idempotent — checks for existing matcher before adding.
_setup_vault_hook() {
  local SETTINGS="$HOME/.claude/settings.json"
  if [ ! -f "$SETTINGS" ]; then
    log_step "skip @vl hook — ~/.claude/settings.json not found (install Claude Code first)."
    return 0
  fi

  if jq -e '.hooks.UserPromptSubmit[]? | select(.matcher == "@vl")' "$SETTINGS" >/dev/null 2>&1; then
    log_step "@vl hook already registered."
    return 0
  fi

  local _old_umask
  _old_umask=$(umask)
  umask 077
  local hook_tmp
  hook_tmp=$(mktemp)
  if jq '.hooks.UserPromptSubmit //= [] | .hooks.UserPromptSubmit += [{
    "matcher": "@vl",
    "hooks": [{
      "type": "command",
      "command": "bash $HOME/.claude/my-vault/vl-trigger.sh"
    }]
  }]' "$SETTINGS" > "$hook_tmp"; then
    mv "$hook_tmp" "$SETTINGS"
    log_done "@vl hook registered in settings.json."
  else
    rm -f "$hook_tmp"
    log_fail "Failed to register @vl hook (jq error)"
  fi
  umask "$_old_umask"
}
