#!/bin/bash
# installers/ai-tools.sh — AI tools (claude-code, opencode, codex)
# source'd by install.sh

_setup_codex_mcp() {
  local _old_umask_mcp
  _old_umask_mcp=$(umask)
  umask 077
  # Add codex MCP server to ~/.claude.json
  local CLAUDE_JSON="$HOME/.claude.json"
  if [ ! -f "$CLAUDE_JSON" ]; then
    printf '%s\n' '{}' > "$CLAUDE_JSON"
  fi
  local mcp_tmp
  mcp_tmp=$(mktemp)
  if jq '.mcpServers.codex //= {"command":"codex","args":["mcp-server"]}' \
    "$CLAUDE_JSON" > "$mcp_tmp"; then
    mv "$mcp_tmp" "$CLAUDE_JSON"
  else
    rm -f "$mcp_tmp"
    umask "$_old_umask_mcp"
    return 1
  fi

  # Add PostToolUse hook for codex usage refresh (if not already present)
  local SETTINGS="$HOME/.claude/settings.json"
  if [ -f "$SETTINGS" ] && ! jq -e '.hooks.PostToolUse[]? | select(.matcher == "mcp__codex__codex")' "$SETTINGS" >/dev/null 2>&1; then
    local hook_tmp
    hook_tmp=$(mktemp)
    if jq '.hooks.PostToolUse += [{
      "matcher": "mcp__codex__codex",
      "hooks": [{
        "type": "command",
        "command": "cache_dir=\"$HOME/.claude/my-hud/cache\" bash \"$HOME/.claude/my-hud/refresh-codex-usage.sh\"",
        "async": true
      }]
    }]' "$SETTINGS" > "$hook_tmp"; then
      mv "$hook_tmp" "$SETTINGS"
    else
      rm -f "$hook_tmp"
    fi
  fi

  umask "$_old_umask_mcp"
  log_done "codex MCP server configured."
}

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
      "Codex"

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
        _setup_codex_mcp
        sleep 1
        ;;
      255)
        # oh-my-opencode: 버전 미고정 시 공급망 위험이 있으므로 수동 설치 권장
        # 최신 버전 확인: npm view oh-my-opencode version
        # 설치: bunx oh-my-opencode@<version> install
        break
        ;;
    esac
  done
}

_install_claude_code() {
  local method=""
  ui_menu "Claude Code install method" method \
    "Stable (brew cask — manual upgrade)" \
    "Latest (brew cask @latest — always newest)"

  case "$method" in
    0)
      log_step "brew install claude-code (stable)…"
      brew install --cask claude-code || { log_fail "claude-code install failed"; return 1; }
      log_done "claude-code ready (stable)."
      ;;
    1)
      log_step "brew install claude-code@latest…"
      brew install --cask claude-code@latest || { log_fail "claude-code@latest install failed"; return 1; }
      log_done "claude-code ready (@latest)."
      ;;
    255)
      return 0
      ;;
  esac

  # Claude alias
  ui_clear_screen
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
  _sync_claude_files

  # Per-language PostToolUse hooks (e.g. gofmt). Fresh-install only —
  # Update no longer touches user-defined hooks.
  _setup_language_hooks

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

_sync_claude_files() {
  log_step "configure claude settings…"
  local _old_umask
  _old_umask=$(umask)
  umask 077

  # Verify target paths are not symlinks (prevent symlink attacks)
  for _tgt in "$HOME/.claude" "$HOME/.claude/memory" "$HOME/.claude/my-hooks" "$HOME/.claude/my-collab"; do
    if [[ -L "$_tgt" ]]; then
      log_fail "symlink detected at $_tgt — aborting for safety."
      umask "$_old_umask"
      return 1
    fi
  done

  # memory: ensure dir + perms only. Memory files are user-private; never
  # copy from the repo (would overwrite each user's accumulated memory).
  mkdir -p "$HOME/.claude/memory"
  chmod 700 "$HOME/.claude/memory"

  # CLAUDE.md — sync only the MYTERM-marked block, preserving any
  # personal content the user keeps outside the markers.
  _sync_claude_md_block

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
  local SETTINGS="$HOME/.claude/settings.json"
  mkdir -p "$HOME/.claude"
  if [ ! -f "$SETTINGS" ]; then
    printf "%s\n" "{}" > "$SETTINGS"
  fi
  chmod 600 "$SETTINGS"

  # Per-key merge: handle each top-level key with appropriate strategy
  local proj_settings="$SCRIPT_DIR/my-claude/settings/settings.json"
  local tmp
  tmp="$(mktemp)"
  cp "$SETTINGS" "$tmp"

  # codex MCP: auto-configure if codex is installed (migration for existing users)
  if command -v codex &>/dev/null; then
    _setup_codex_mcp
  fi

  # permissions.deny: union (add new items, keep existing)
  if jq -e '.permissions.deny' "$proj_settings" >/dev/null 2>&1; then
    local perm_tmp
    perm_tmp=$(mktemp)
    jq -s '.[0].permissions.deny as $user | .[1].permissions.deny as $proj |
      .[0] | .permissions.deny = (($user // []) + ($proj // []) | unique)
    ' "$tmp" "$proj_settings" > "$perm_tmp" && mv "$perm_tmp" "$tmp"
  fi

  # hooks: migrate legacy paths + add-only merge (never modify existing hooks)
  if jq -e '.hooks' "$proj_settings" >/dev/null 2>&1; then
    # Step 1: Rewrite legacy my-hud/ paths that moved to my-hooks/ or my-collab/
    local rw_tmp
    rw_tmp=$(mktemp)
    if jq '
      def rewrite:
        if type == "string" then
          gsub("my-hud/init-env-bg\\.sh"; "my-hooks/init-env-bg.sh") |
          gsub("my-hud/init-env\\.sh"; "my-hooks/init-env.sh") |
          gsub("my-hud/codex-collab\\.sh"; "my-collab/codex-collab.sh")
        elif type == "object" then with_entries(.value |= rewrite)
        elif type == "array" then map(rewrite)
        else . end;
      .hooks |= rewrite
    ' "$tmp" > "$rw_tmp"; then
      mv "$rw_tmp" "$tmp"
    else
      rm -f "$rw_tmp"
    fi

    # Step 2: Add-only merge — add missing categories/groups, never touch existing
    local hooks_tmp
    hooks_tmp=$(mktemp)
    if jq -s '
      .[0] as $cur | .[1] as $proj |
      reduce (($proj.hooks // {}) | keys[]) as $cat (
        $cur;
        if (.hooks[$cat] // null) == null then
          .hooks[$cat] = $proj.hooks[$cat]
        else
          reduce ($proj.hooks[$cat][]?) as $pg (
            .;
            ($pg.matcher // "") as $m |
            if ([.hooks[$cat][]? | .matcher // ""] | index($m)) then
              .
            else
              .hooks[$cat] += [$pg]
            end
          )
        end
      )
    ' "$tmp" "$proj_settings" > "$hooks_tmp"; then
      mv "$hooks_tmp" "$tmp"
    else
      rm -f "$hooks_tmp"
    fi
  fi

  # statusLine: skip (handled by HUD installer separately)

  mv "$tmp" "$SETTINGS"

  umask "$_old_umask"
  log_done "claude settings configured."
}

# Sync codex-collab.md into ~/.claude/CLAUDE.md while preserving the user's
# own content outside the MYTERM marker block.
#   - file missing            → write source as-is
#   - markers present in dst  → replace block in place
#   - no markers in dst       → backup, then overwrite (legacy migration)
_sync_claude_md_block() {
  local src="$SCRIPT_DIR/my-claude/instructions/codex-collab.md"
  local dst="$HOME/.claude/CLAUDE.md"
  local begin='<!-- MYTERM:BEGIN -->'
  local end='<!-- MYTERM:END -->'

  if [ ! -f "$dst" ]; then
    cp -f "$src" "$dst"
    chmod 600 "$dst"
    return 0
  fi

  if ! grep -qF "$begin" "$dst" || ! grep -qF "$end" "$dst"; then
    local backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
    cp -f "$dst" "$backup"
    chmod 600 "$backup"
    cp -f "$src" "$dst"
    chmod 600 "$dst"
    log_step "legacy CLAUDE.md backed up to $backup"
    return 0
  fi

  local tmp="$dst.tmp.$$"
  awk -v src="$src" -v begin="$begin" -v end="$end" '
    function emit_src(   line) {
      while ((getline line < src) > 0) print line
      close(src)
    }
    index($0, begin) { in_block = 1; emit_src(); next }
    index($0, end)   { in_block = 0; next }
    !in_block        { print }
  ' "$dst" > "$tmp" && mv "$tmp" "$dst"
  chmod 600 "$dst"
}

# Add PostToolUse hooks for languages detected in PATH. Idempotent — never
# touches existing hooks. Called from fresh-install path only (not Update).
_setup_language_hooks() {
  local SETTINGS="$HOME/.claude/settings.json"
  [ -f "$SETTINGS" ] || return 0

  # Go (gofmt) — only add if Go is installed and the hook isn't there yet
  if command -v go &>/dev/null || command -v gofmt &>/dev/null; then
    if ! grep -q 'gofmt' "$SETTINGS" 2>/dev/null; then
      local gofmt_choice=""
      ui_menu "Go detected — add gofmt hook to Claude?" gofmt_choice \
        "Yes" \
        "No"
      if [ "$gofmt_choice" = "0" ]; then
        local GOFMT_CMD='echo "$TOOL_INPUT" | jq -r '"'"'.file_path // empty'"'"' | while IFS= read -r f; do [[ -n "$f" && "$f" == *.go ]] && gofmt -w -- "$f"; done'
        local gofmt_tmp
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
    fi
  fi

  # Future languages (Java, Python, etc.) — add branches here.
}

# One-time cleanup of pre-modular HUD layout. Idempotent — does nothing if
# already on the modular layout. Removes only files that the modular layout
# doesn't ship (powerline-statusline.sh, *.pl); other files are overwritten
# by _sync_hud_files. Run before _sync_hud_files in install/update flows.
_migrate_legacy_hud() {
  local dest="$HOME/.claude/my-hud"
  if [ -f "$dest/powerline-statusline.sh" ] && [ ! -f "$dest/configure.sh" ]; then
    log_step "migrating HUD from legacy powerline layout…"
    rm -f "$dest/powerline-statusline.sh"
    rm -f "$dest/"*.pl 2>/dev/null || true
    log_done "Legacy HUD files removed."
  fi
}

# Sync HUD scripts/themes/lib without launching the configure UI.
# Pure cp (overwrites same-named files); legacy cleanup lives in
# _migrate_legacy_hud. Shared by _install_hud and update_my_claude.
_sync_hud_files() {
  log_step "syncing HUD files…"

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

  # Ensure statusLine points at the (possibly updated) statusline.sh
  local SETTINGS="$HOME/.claude/settings.json"
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

  log_done "HUD files synced."
}

_install_hud() {
  log_step "install HUD statusline…"
  _migrate_legacy_hud
  _sync_hud_files
  log_step "configure HUD…"
  bash "$HOME/.claude/my-hud/configure.sh"
}

# Pull latest Claude/HUD config from this repo into ~/.claude. No brew/alias
# prompts, no interactive HUD configure — just file sync. Idempotent.
update_my_claude() {
  log_start "Updating ~/.claude config from this repo…"

  if [ -d "$HOME/.claude" ] || command -v claude &>/dev/null; then
    _sync_claude_files
  else
    log_step "Claude Code not installed — skipping Claude config sync."
  fi

  if [ -f "$HOME/.claude/my-hud/configure.sh" ] \
     || [ -f "$HOME/.claude/my-hud/statusline.sh" ] \
     || [ -f "$HOME/.claude/my-hud/powerline-statusline.sh" ]; then
    _migrate_legacy_hud
    _sync_hud_files
  else
    log_step "HUD not installed — skipping HUD sync."
  fi
}
