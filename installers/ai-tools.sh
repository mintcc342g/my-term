#!/bin/bash
# installers/ai-tools.sh — AI tools (claude-code, opencode, codex)
# source'd by install.sh

install_ai_tools() {
  log_start "AI tools setup…"

  if ! command -v brew &>/dev/null; then
    log_fail "Homebrew not found. Please install convenience tools first."
    return 1
  fi

  local choice=""

  while true; do
    ui_menu "AI tools — select to install" choice \
      "Claude Code" \
      "OpenCode" \
      "Codex" \
      "Exit"

    case "$choice" in
      0) _install_claude_code ;;
      1)
        log_step "brew install opencode…"
        brew install opencode
        log_done "opencode installed."
        sleep 1
        ;;
      2)
        log_step "brew install codex…"
        brew install codex
        log_done "codex installed."
        sleep 1
        ;;
      3|255)
        # oh-my-opencode: 버전 미고정 시 공급망 위험이 있으므로 수동 설치 권장
        # 최신 버전 확인: npm view oh-my-opencode version
        # 설치: bunx oh-my-opencode@<version> install
        break
        ;;
    esac
  done
}

_install_claude_code() {
  log_step "brew install/update claude-code…"
  brew install --cask claude-code 2>/dev/null || brew upgrade --cask claude-code 2>/dev/null || log_fail "claude-code install/upgrade failed"
  log_done "claude-code ready."

  # Claude alias
  printf '\033[2J\033[H' > /dev/tty
  echo -e "${UI_BLUE_BOLD} Claude alias setup${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}Enter alias for claude command (default: c)${UI_RESET}\n" > /dev/tty
  echo -ne " ${UI_YELLOW_BOLD}alias: ${UI_RESET}" > /dev/tty
  local alias_name
  read -r alias_name < /dev/tty
  [ -z "$alias_name" ] && alias_name="c"

  # Sanitize: only allow valid shell identifier chars
  if [[ ! "$alias_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    log_fail "Invalid alias name. Using default: c"
    alias_name="c"
  fi

  local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
  if ! grep -q "^alias ${alias_name}=" "$ZSHRC" 2>/dev/null; then
    echo "alias ${alias_name}=\"claude\"" >> "$ZSHRC"
    export ZSHRC_MODIFIED=true
  fi
  log_done "alias '${alias_name}=claude' added."

  # Claude settings (memory, CLAUDE.md, settings.json, hooks, collab)
  _install_claude_settings

  # HUD install offer
  local hud_choice=""
  ui_menu "Install HUD statusline?" hud_choice \
    "Yes" \
    "No"

  case "$hud_choice" in
    0) _install_hud ;;
    *) log_step "skipping HUD install." ;;
  esac
}

_install_claude_settings() {
  log_step "configure claude settings…"

  # memory
  mkdir -p "$HOME/.claude/memory"
  chmod 700 "$HOME/.claude/memory"
  cp -f "$SCRIPT_DIR/my-claude/memory/"* "$HOME/.claude/memory/"
  chmod 600 "$HOME/.claude/memory/"*

  # CLAUDE.md
  cp -f "$SCRIPT_DIR/my-claude/instructions/codex-collab.md" "$HOME/.claude/CLAUDE.md"
  chmod 600 "$HOME/.claude/CLAUDE.md"

  # hooks
  mkdir -p "$HOME/.claude/my-hooks"
  chmod 700 "$HOME/.claude/my-hooks"
  cp -f "$SCRIPT_DIR/my-claude/hooks/"* "$HOME/.claude/my-hooks/"
  chmod +x "$HOME/.claude/my-hooks/"*.sh

  # collab
  mkdir -p "$HOME/.claude/my-collab"
  chmod 700 "$HOME/.claude/my-collab"
  cp -f "$SCRIPT_DIR/my-claude/collab/"* "$HOME/.claude/my-collab/"
  chmod +x "$HOME/.claude/my-collab/"*.sh
  chmod 600 "$HOME/.claude/my-collab/co-agents.json"
  chmod 600 "$HOME/.claude/my-collab/co-directive.md"

  # settings.json
  SETTINGS="$HOME/.claude/settings.json"
  mkdir -p "$HOME/.claude"
  if [ ! -f "$SETTINGS" ]; then
    printf "%s\n" "{}" > "$SETTINGS"
  fi
  chmod 600 "$SETTINGS"

  # Per-key merge: handle each top-level key with appropriate strategy
  local proj_settings="$SCRIPT_DIR/my-claude/settings/settings.json"
  tmp="$(mktemp)"
  cp "$SETTINGS" "$tmp"

  # mcpServers: add missing servers only
  if jq -e '.mcpServers' "$proj_settings" >/dev/null 2>&1; then
    local mcp_tmp
    mcp_tmp=$(mktemp)
    jq -s '.[0].mcpServers as $user | .[1].mcpServers as $proj |
      .[0] | .mcpServers = ($proj * ($user // {}))
    ' "$tmp" "$proj_settings" > "$mcp_tmp" && mv "$mcp_tmp" "$tmp"
  fi

  # permissions.deny: union (add new items, keep existing)
  if jq -e '.permissions.deny' "$proj_settings" >/dev/null 2>&1; then
    local perm_tmp
    perm_tmp=$(mktemp)
    jq -s '.[0].permissions.deny as $user | .[1].permissions.deny as $proj |
      .[0] | .permissions.deny = (($user // []) + ($proj // []) | unique)
    ' "$tmp" "$proj_settings" > "$perm_tmp" && mv "$perm_tmp" "$tmp"
  fi

  # hooks: keep user hooks, add project hooks that are missing
  if jq -e '.hooks' "$proj_settings" >/dev/null 2>&1; then
    local hooks_tmp
    hooks_tmp=$(mktemp)
    jq -s '
      .[0].hooks as $user_hooks | .[1].hooks as $proj_hooks |
      .[0] | .hooks = ($proj_hooks * ($user_hooks // {}))
    ' "$tmp" "$proj_settings" > "$hooks_tmp" && mv "$hooks_tmp" "$tmp"

    # Restore any extra user hooks inside PostToolUse[0].hooks that project doesnt have
    local restore_tmp
    restore_tmp=$(mktemp)
    jq -s '
      (.[0].hooks.PostToolUse[0].hooks // []) as $merged |
      (.[1].hooks.PostToolUse[0].hooks // []) as $user_extra |
      .[0] | .hooks.PostToolUse[0].hooks = ($merged + [$user_extra[] | select(. as $h | $merged | map(.command) | index($h.command) | not)])
    ' "$tmp" "$SETTINGS" > "$restore_tmp" && mv "$restore_tmp" "$tmp"
  fi

  # statusLine: skip (handled by HUD installer separately)

  mv "$tmp" "$SETTINGS"

  # gofmt hook — ask independently, skip if already added
  if command -v gofmt &>/dev/null || command -v go &>/dev/null; then
    if ! grep -q 'gofmt' "$SETTINGS" 2>/dev/null; then
      local gofmt_choice=""
      ui_menu "Go detected — add gofmt hook to Claude?" gofmt_choice \
        "Yes" \
        "No"
      if [ "$gofmt_choice" = "0" ]; then
        GOFMT_CMD='echo "$TOOL_INPUT" | jq -r '"'"'.file_path // empty'"'"' | while IFS= read -r f; do [[ -n "$f" && "$f" == *.go ]] && gofmt -w -- "$f"; done'
        gofmt_tmp="$(mktemp)"
        if jq --arg gofmtCmd "$GOFMT_CMD" \
          '.hooks.PostToolUse[0].hooks += [{"type": "command", "command": $gofmtCmd}]' \
          "$SETTINGS" > "$gofmt_tmp"; then
          mv "$gofmt_tmp" "$SETTINGS"
          log_done "Added gofmt hook to Claude settings."
        else
          rm -f "$gofmt_tmp"
          log_fail "Failed to add gofmt hook (jq error)"
        fi
      fi
    else
      log_step "gofmt hook already configured, skipping."
    fi
  fi

  log_done "claude settings configured."
}

_install_hud() {
  log_step "install HUD statusline…"

  # Remove legacy files if present
  rm -f "$HOME/.claude/my-hud/powerline-statusline.sh" 2>/dev/null || true
  rm -f "$HOME/.claude/my-hud/"*.pl 2>/dev/null || true

  mkdir -p "$HOME/.claude/my-hud/themes" "$HOME/.claude/my-hud/lib"
  chmod 700 "$HOME/.claude" "$HOME/.claude/my-hud"
  cp -f "$SCRIPT_DIR/my-claude/hud/"*.sh "$HOME/.claude/my-hud/"
  chmod +x "$HOME/.claude/my-hud/"*.sh
  cp -f "$SCRIPT_DIR/my-claude/hud/themes/"*.sh "$HOME/.claude/my-hud/themes/"
  cp -f "$SCRIPT_DIR/lib/ui.sh" "$HOME/.claude/my-hud/lib/"

  # config.json — only copy if not exists (preserve user settings)
  if [ ! -f "$HOME/.claude/my-hud/config.json" ]; then
    cp -f "$SCRIPT_DIR/my-claude/hud/config.json" "$HOME/.claude/my-hud/config.json"
  fi


  # Update statusLine command to use new statusline.sh
  SETTINGS="$HOME/.claude/settings.json"
  if [ -f "$SETTINGS" ]; then
    local sl_tmp
    sl_tmp=$(mktemp)
    if jq '.statusLine = {"type": "command", "command": "bash $HOME/.claude/my-hud/statusline.sh"}' \
      "$SETTINGS" > "$sl_tmp"; then
      mv "$sl_tmp" "$SETTINGS"
    else
      rm -f "$sl_tmp"
    fi
  fi

  log_done "HUD statusline installed."

  # Run initial configuration
  log_step "configure HUD…"
  bash "$HOME/.claude/my-hud/configure.sh" --project-root "$SCRIPT_DIR"
}
