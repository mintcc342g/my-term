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
      "Done"

    case "$choice" in
      0) _install_claude_code ;;
      1)
        log_step "install opencode…"
        brew install opencode
        log_done "opencode installed."
        sleep 1
        ;;
      2)
        log_step "install codex…"
        brew install codex
        log_done "codex installed."
        sleep 1
        ;;
      3|255)
        break
        ;;
    esac
  done
}

_install_claude_code() {
  log_step "install claude-code…"
  brew install --cask claude-code
  log_done "claude-code installed."

  # Claude alias
  printf '\033[2J\033[H' > /dev/tty
  echo -e "${UI_BLUE_BOLD} Claude alias setup${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}Enter alias for claude command (default: c)${UI_RESET}\n" > /dev/tty
  echo -ne " ${UI_YELLOW_BOLD}alias: ${UI_RESET}" > /dev/tty
  local alias_name
  read -r alias_name < /dev/tty
  [ -z "$alias_name" ] && alias_name="c"

  ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
  if ! grep -q "^alias ${alias_name}=" "$ZSHRC" 2>/dev/null; then
    echo "alias ${alias_name}=\"claude\"" >> "$ZSHRC"
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

  tmp="$(mktemp)"
  if jq -s '.[0] * .[1]' "$SETTINGS" "$SCRIPT_DIR/my-claude/settings/settings.json" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
  else
    rm -f "$tmp"
    log_fail "Failed to update $SETTINGS (jq error)"
  fi

  # gofmt hook (if golang was installed)
  if [[ "${install_golang:-}" =~ [yY] ]]; then
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

  log_done "claude settings configured."
}

_install_hud() {
  log_step "install HUD statusline…"

  mkdir -p "$HOME/.claude/my-hud/themes" "$HOME/.claude/my-hud/lib"
  chmod 700 "$HOME/.claude" "$HOME/.claude/my-hud"
  cp -f "$SCRIPT_DIR/my-claude/hud/"*.sh "$HOME/.claude/my-hud/"
  cp -f "$SCRIPT_DIR/my-claude/hud/"*.json "$HOME/.claude/my-hud/"
  chmod +x "$HOME/.claude/my-hud/"*.sh
  cp -f "$SCRIPT_DIR/my-claude/hud/themes/"*.sh "$HOME/.claude/my-hud/themes/"
  cp -f "$SCRIPT_DIR/lib/ui.sh" "$HOME/.claude/my-hud/lib/"

  # Register slash command
  mkdir -p "$HOME/.claude/commands"
  cp -f "$SCRIPT_DIR/my-claude/commands/my-term:hud.md" "$HOME/.claude/commands/"
  chmod 600 "$HOME/.claude/commands/my-term:hud.md"

  log_done "HUD statusline installed."

  # Run initial configuration
  log_step "configure HUD…"
  bash "$HOME/.claude/my-hud/configure.sh"
}
