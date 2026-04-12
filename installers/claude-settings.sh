#!/bin/bash
# installers/claude-settings.sh — claude memory, CLAUDE.md, settings.json, gofmt hook
# source'd by install.sh — uses shared log functions and variables

install_claude_settings() {
  # memory 설정
  log_start "install claude memory…\n"
  mkdir -p "$HOME/.claude/memory"
  chmod 700 "$HOME/.claude/memory"
  cp -f "$SCRIPT_DIR/my-claude/memory/"* "$HOME/.claude/memory/"
  chmod 600 "$HOME/.claude/memory/"*

  # CLAUDE.md 설정 (codex-collab.md → CLAUDE.md)
  cp -f "$SCRIPT_DIR/my-claude/instructions/codex-collab.md" "$HOME/.claude/CLAUDE.md"
  chmod 600 "$HOME/.claude/CLAUDE.md"

  # claude settings.json 설정
  log_start "configure claude settings…\n"
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
    log_fail "Failed to update $SETTINGS (jq error)\n"
  fi

  # gofmt hook 추가 (Golang 설치 시에만)
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
