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
    log_fail "$L_ERR_NO_BREW"
    return 1
  fi

  local choice=""

  # 루프는 여러 AI 도구를 순차 설치할 수 있도록 유지. 다음 단계로 가려면
  # "✓ Done" 선택 (또는 q/esc).
  # oh-my-opencode: 버전 미고정 시 공급망 위험이 있으므로 수동 설치 권장
  #   최신 버전 확인: npm view oh-my-opencode version
  #   설치: bunx oh-my-opencode@<version> install
  while true; do
    ui_menu "$L_AI_MENU_TITLE" choice \
      "Claude Code" \
      "OpenCode" \
      "Codex" \
      "$L_DONE_ITEM"

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
      3|255) break ;;
    esac
  done

  # Obsidian + vault tooling — Claude/AI 연계 용도라 AI tools 단계 끝에서 묻습니다.
  ui_confirm_run "$L_STEP_OBSIDIAN" install_obsidian
}

_install_claude_code() {
  local method=""
  ui_menu "$L_AI_METHOD_TITLE" method \
    "$L_AI_METHOD_STABLE" \
    "$L_AI_METHOD_LATEST"

  case "$method" in
    0)
      log_step "brew install claude-code (stable)…"
      brew list --cask claude-code &>/dev/null || brew install --cask claude-code || { log_fail "claude-code install failed"; return 1; }
      log_done "claude-code ready (stable)."
      ;;
    1)
      log_step "brew install claude-code@latest…"
      brew list --cask claude-code@latest &>/dev/null || brew install --cask claude-code@latest || { log_fail "claude-code@latest install failed"; return 1; }
      log_done "claude-code ready (@latest)."
      ;;
    255)
      return 0
      ;;
  esac

  # Claude alias
  ui_clear_screen
  echo -e "${UI_BLUE_BOLD} ${L_AI_ALIAS_HEADER}${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}${L_AI_ALIAS_PROMPT}${UI_RESET}\n" > /dev/tty
  echo -ne " ${UI_YELLOW_BOLD}${L_AI_ALIAS_LABEL}${UI_RESET}" > /dev/tty
  local alias_name
  read -r alias_name < /dev/tty
  [ -z "$alias_name" ] && alias_name="c"

  # Sanitize: only allow valid shell identifier chars
  if [[ ! "$alias_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    log_fail "$L_AI_INVALID_ALIAS"
    alias_name="c"
  fi

  local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
  if ! grep -q "^alias ${alias_name}=" "$ZSHRC" 2>/dev/null; then
    echo "alias ${alias_name}=\"claude\"" >> "$ZSHRC"
    export ZSHRC_MODIFIED=true
  fi
  log_done "alias '${alias_name}=claude' added."

  # Claude settings (memory, CLAUDE.md, settings.json, hooks, collab).
  # Korean-default instruction blocks (response style) are installed inside
  # _sync_claude_files, so they apply on both install and Update.
  _sync_claude_files

  # Per-language PostToolUse hooks (e.g. gofmt). Fresh-install only —
  # Update no longer touches user-defined hooks.
  _setup_language_hooks

  # HUD install offer
  local hud_choice=""
  ui_menu "$L_AI_HUD_TITLE" hud_choice \
    "$L_YES" \
    "$L_NO_SKIP"

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

  # Legacy master MYTERM block cleanup — one-shot migration after the master
  # mechanism was removed. Idempotent (no-op when marker absent). Safe vs
  # OPTIONAL markers because the awk regex is anchored to the exact line.
  # Can be deleted once all users have run Update at least once.
  local _claude_md="$HOME/.claude/CLAUDE.md"
  if [ -f "$_claude_md" ] && grep -qF '<!-- MYTERM:BEGIN -->' "$_claude_md"; then
    local _cleanup_tmp
    _cleanup_tmp=$(mktemp)
    awk '
      /^<!-- MYTERM:BEGIN -->$/ { in_block = 1; next }
      /^<!-- MYTERM:END -->$/   { in_block = 0; next }
      !in_block                 { print }
    ' "$_claude_md" > "$_cleanup_tmp" && mv "$_cleanup_tmp" "$_claude_md"
    chmod 600 "$_claude_md"
    log_done "legacy MYTERM block removed from $_claude_md"
  fi

  # CLAUDE.md managed blocks: refresh existing ones from repo source, then
  # auto-install the default blocks (response style per install language +
  # shared code style). Both are no-ops when nothing applies, so this is safe
  # on install + Update.
  _sync_claude_md_block
  _install_default_instructions "$_claude_md"

  # hooks
  mkdir -p "$HOME/.claude/my-hooks"
  chmod 700 "$HOME/.claude/my-hooks"
  cp -f "$SCRIPT_DIR/my-claude/hooks/"* "$HOME/.claude/my-hooks/"
  chmod +x "$HOME/.claude/my-hooks/"*.sh

  # collab — agents config + hook script (verbatim) + the directive with its
  # response language ({{RESPONSE_LANG}}) baked in for the install language, so
  # the @co flow runs end to end in that language (no translation round-trip).
  mkdir -p "$HOME/.claude/my-collab"
  chmod 700 "$HOME/.claude/my-collab"
  local _lang_name="English"; [ "${MYTERM_LANG:-en}" = "ko" ] && _lang_name="Korean"
  cp -f "$SCRIPT_DIR/my-claude/collab/co-agents.json" \
        "$SCRIPT_DIR/my-claude/collab/codex-collab.sh" "$HOME/.claude/my-collab/"
  sed "s|{{RESPONSE_LANG}}|${_lang_name}|g" "$SCRIPT_DIR/my-claude/collab/co-directive.md" \
    > "$HOME/.claude/my-collab/co-directive.md"
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

# Refresh managed OPTIONAL blocks in user's CLAUDE.md from repo source — so
# repo edits to those files (e.g. response style) propagate on Update. Only
# rebuilds blocks already present; initial install is _install_default_instructions.
_sync_claude_md_block() {
  md_refresh_optional_blocks "$HOME/.claude/CLAUDE.md"
}

# Auto-install the managed instruction blocks from $SCRIPT_DIR/my-claude/optional/
# into the destination CLAUDE.md. File naming decides language handling:
#   <name>.md         — shared block, installed for every language (e.g. code-style)
#   <name>.<lang>.md  — language variant; only the one matching the install
#                       language is installed (e.g. response-style.ko.md)
# Either way the destination block is named <name> (suffix stripped), so the
# marker stays stable across languages and matches already-deployed blocks.
#
# Each block becomes a MYTERM:OPTIONAL:<name>:BEGIN/END pair so that Update
# (md_refresh_optional_blocks) keeps it in sync with the repo source. Opt-out is
# manual — user removes the block from the destination file (already-present
# blocks are skipped here, so a manual removal sticks).
_install_default_instructions() {
  local dst="$1"
  local src_dir="$SCRIPT_DIR/my-claude/optional"
  [ -d "$src_dir" ] || return 0

  local lang="${MYTERM_LANG:-en}"
  local f
  for f in "$src_dir"/*.md; do
    [ -f "$f" ] || continue
    local base suffix name begin end
    base=$(basename "$f" .md)
    # A trailing .en/.ko marks a language variant; install only the matching one.
    # Anything else is a shared block installed for every language.
    suffix="${base##*.}"
    case "$suffix" in
      en|ko)
        [ "$suffix" = "$lang" ] || continue
        name="${base%.*}"
        ;;
      *)
        name="$base"
        ;;
    esac
    begin="<!-- MYTERM:OPTIONAL:${name}:BEGIN -->"
    end="<!-- MYTERM:OPTIONAL:${name}:END -->"

    # Already present (or user re-added manually) — skip. A manual removal of
    # the block therefore persists across Update.
    if [ -f "$dst" ] && grep -qF "$begin" "$dst"; then
      continue
    fi

    mkdir -p "$(dirname "$dst")"
    [ -f "$dst" ] || { : > "$dst"; chmod 600 "$dst"; }
    # Append with a leading blank line for readability.
    {
      printf '\n%s\n' "$begin"
      cat "$f"
      printf '%s\n' "$end"
    } >> "$dst"
    log_done "added instruction: ${name}"
  done
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
      ui_menu "$L_AI_GOFMT_TITLE" gofmt_choice \
        "$L_YES" \
        "$L_NO_SKIP"
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

# Mirror *.sh from src→dst: copy/overwrite the files the repo ships, and prune
# ones it no longer does (renamed/removed). Stops stale themes from lingering
# and defeating statusline's "missing theme → default" fallback. Nothing is
# hardcoded — the repo dir is the source of truth.
_mirror_sh() {
  local src="$1" dst="$2" f base
  mkdir -p "$dst"
  for f in "$dst"/*.sh; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    [ -f "$src/$base" ] || rm -f "$f"
  done
  cp -f "$src"/*.sh "$dst"/
}

# Sync HUD scripts/themes/lib without launching the configure UI.
# Top-level scripts/lib are pure cp; themes are mirrored (prune orphans).
# Legacy layout cleanup lives in _migrate_legacy_hud. Shared by _install_hud
# and update_my_claude.
_sync_hud_files() {
  log_step "syncing HUD files…"

  mkdir -p "$HOME/.claude/my-hud/themes" "$HOME/.claude/my-hud/lib"
  chmod 700 "$HOME/.claude" "$HOME/.claude/my-hud"
  cp -f "$SCRIPT_DIR/my-claude/hud/"*.sh "$HOME/.claude/my-hud/"
  chmod +x "$HOME/.claude/my-hud/"*.sh
  _mirror_sh "$SCRIPT_DIR/my-claude/hud/themes" "$HOME/.claude/my-hud/themes"
  cp -f "$SCRIPT_DIR/lib/ui.sh" "$HOME/.claude/my-hud/lib/"
  # lang catalog — ui.sh bootstraps i18n from lib/lang next to it, so the
  # deployed copy needs it too (keeps HUD configure.sh working standalone).
  mkdir -p "$HOME/.claude/my-hud/lib/lang"
  cp -f "$SCRIPT_DIR/lib/lang/"*.sh "$HOME/.claude/my-hud/lib/lang/"

  # config.json — only copy if not exists (preserve user settings)
  if [ ! -f "$HOME/.claude/my-hud/config.json" ]; then
    cp -f "$SCRIPT_DIR/my-claude/hud/config.json" "$HOME/.claude/my-hud/config.json"
  fi

  # Heal a stale theme: if config.theme points at a theme the repo no longer
  # ships (renamed/removed), reset it to the repo's own default. Only .theme is
  # rewritten; the default is read from the repo config — no theme name is
  # hardcoded, and a valid selection is left untouched.
  local cfg="$HOME/.claude/my-hud/config.json"
  if [ -f "$cfg" ]; then
    local cur def tmp
    cur=$(jq -r '.theme // empty' "$cfg")
    if [ -n "$cur" ] && [ ! -f "$HOME/.claude/my-hud/themes/$cur.sh" ]; then
      def=$(jq -r '.theme' "$SCRIPT_DIR/my-claude/hud/config.json")
      tmp=$(mktemp)
      if jq --arg t "$def" '.theme = $t' "$cfg" > "$tmp"; then
        mv "$tmp" "$cfg"
        log_step "theme '$cur' no longer exists → reset to '$def'"
      else
        rm -f "$tmp"
      fi
    fi
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

  if [ -d "$HOME/.claude/my-wiki" ]; then
    # wiki path 를 기존 deploy 된 wk-trigger.sh 에서 추출 (install 시 sed 치환된 값).
    # 추출 실패 시 wiki sync 만 skip — install 재실행으로 복구해야 함.
    local _wk_trigger="$HOME/.claude/my-wiki/wk-trigger.sh"
    local _wiki_path=""
    if [ -f "$_wk_trigger" ]; then
      _wiki_path=$(sed -nE 's/^WIKI_PATH="(.*)"$/\1/p' "$_wk_trigger" | head -1)
    fi
    if [ -n "$_wiki_path" ] && [ -d "$_wiki_path" ]; then
      _sync_obsidian_wiki_files "$_wiki_path"
      _install_wiki_defaults "$_wiki_path"
    else
      log_fail "wiki path extraction failed (file: $_wk_trigger). Re-run obsidian installer to fix."
    fi
  else
    log_step "Obsidian wiki tooling not installed — skipping wiki sync."
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

# ── Delete: remove my-term's deployed footprint (inverse of install/update) ──
# Pure removal. Explains scope, then requires an explicit Yes before touching
# anything. Re-run Install afterwards to set things up again — Update only
# re-syncs ~/.claude and would NOT restore the removed shell rc / ssh blocks.
#
# Removed:
#   - Owned dirs:  ~/.claude/{my-hud,my-hooks,my-collab,my-wiki} (incl. user-
#                  customized config.json / co-agents.json — true clean slate)
#   - Marker blocks in ~/.zshrc, ~/.zprofile and ~/.ssh/config (#-- my-term:*)
#   - OPTIONAL instruction blocks in ~/.claude/CLAUDE.md
#   - statusLine + my-term hook entries in ~/.claude/settings.json
#   - The codex MCP entry my-term added to ~/.claude.json (exact match only)
#
# Preserved (never touched):
#   - ~/.claude/memory  (user-accumulated; install/update never write it)
#   - SSH key files (~/.ssh/id_*) — credentials; only the config block is removed
#   - permissions.deny security rules in settings.json (additive hardening)
#   - Third-party tools (brew packages, oh-my-zsh, asdf/pyenv, CLI, IDE, Obsidian)
#   - Any user content outside my-term markers
delete_my_claude() {
  # Explain scope, then require explicit confirmation. Nothing is removed yet.
  local choice=""
  UI_MENU_NOTE="$(lang_delete_plan)" ui_menu "$L_DELETE_CONFIRM_TITLE" choice \
    "$L_YES" \
    "$L_NO"
  echo
  if [ "$choice" != "0" ]; then
    # Cancelled — ui_print_completion prints a single line, no banner.
    DELETE_LAST_ACTION="delete-cancelled"
    return 0
  fi

  log_start "Deleting my-term footprint…"
  _delete_owned_dirs
  _delete_settings_json
  _delete_claude_json_codex
  _delete_claude_md_optional
  _delete_rc_blocks
  DELETE_LAST_ACTION="delete"
  log_done "Delete complete. Re-run Install to set things up again."
}

# Remove the dirs my-term fully owns. memory/ is deliberately excluded — it
# holds user-accumulated data that install/update never write. Symlinked
# targets are skipped (defense against symlink-swap into a sensitive path).
_delete_owned_dirs() {
  local d tgt
  for d in my-hud my-hooks my-collab my-wiki; do
    tgt="$HOME/.claude/$d"
    if [ -L "$tgt" ]; then
      log_fail "symlink at $tgt — skipping for safety."
      continue
    fi
    if [ -d "$tgt" ]; then
      rm -rf "$tgt"
      log_done "removed $tgt"
    fi
  done
}

# Strip my-term marker blocks from shell rc files and ~/.ssh/config. All use
# the same `#-- my-term:<tag>:` convention, so rc_remove_block handles each.
# SSH key files referenced by the git-ssh block are left in place.
_delete_rc_blocks() {
  local f t
  local tags="brew-shellenv asdf-shims asdf-golang asdf-java pyenv-path pyenv-init zsh-syntax-highlighting zsh-autosuggestions television git-ssh"
  for f in "$HOME/.zshrc" "$HOME/.zprofile"; do
    [ -f "$f" ] || continue
    for t in $tags; do
      rc_remove_block "$f" "$t"
    done
  done
  if [ -f "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ]; then
    rc_remove_block "$HOME/.ssh/config" "git-ssh"
  fi
  log_done "shell rc / ssh config blocks removed."
}

# Remove my-term's settings.json contributions that would otherwise dangle once
# the owned dirs are gone: statusLine (points at my-hud) and any hook entry whose
# command references a deployed my-* script. permissions.deny is KEPT — it is
# additive security hardening that references no my-term file and breaks nothing.
# Individual non-my-term hooks in shared groups (e.g. gofmt) are preserved.
_delete_settings_json() {
  local SETTINGS="$HOME/.claude/settings.json"
  [ -f "$SETTINGS" ] || return 0
  if [ -L "$SETTINGS" ]; then
    log_fail "symlink at $SETTINGS — skipping settings.json cleanup."
    return 0
  fi

  local tmp
  tmp=$(mktemp)
  if jq '
    (if ((.statusLine.command // "") | test("my-hud/statusline\\.sh")) then del(.statusLine) else . end)
    | (if has("hooks") then
        .hooks |= (
          with_entries(
            .value |= (
              map(.hooks |= map(select((.command // "") | test("my-hooks/|my-collab/|my-hud/") | not)))
              | map(select((.hooks // []) | length > 0))
            )
          )
          | with_entries(select((.value // []) | length > 0))
        )
      else . end)
  ' "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
    chmod 600 "$SETTINGS"
    log_done "settings.json: statusLine + my-term hooks removed (deny rules kept)."
  else
    rm -f "$tmp"
    log_fail "settings.json jq failed — left unchanged."
  fi
}

# Remove the codex MCP server entry my-term added to ~/.claude.json, but only
# when it exactly matches what _setup_codex_mcp writes — never clobber a
# user-customized codex entry. ~/.claude.json also holds Claude session state;
# we touch nothing else.
_delete_claude_json_codex() {
  local CJ="$HOME/.claude.json"
  [ -f "$CJ" ] || return 0
  [ -L "$CJ" ] && return 0
  if jq -e '(.mcpServers.codex // empty) == {"command":"codex","args":["mcp-server"]}' \
      "$CJ" >/dev/null 2>&1; then
    local tmp
    tmp=$(mktemp)
    if jq 'del(.mcpServers.codex)' "$CJ" > "$tmp"; then
      mv "$tmp" "$CJ"
      chmod 600 "$CJ"
      log_done "codex MCP entry removed from ~/.claude.json."
    else
      rm -f "$tmp"
      log_fail "~/.claude.json jq failed — left unchanged."
    fi
  fi
}

# Strip opted-in OPTIONAL instruction blocks from the user's CLAUDE.md.
_delete_claude_md_optional() {
  local md="$HOME/.claude/CLAUDE.md"
  [ -f "$md" ] || return 0
  [ -L "$md" ] && return 0
  md_remove_optional_blocks "$md"
  log_done "CLAUDE.md OPTIONAL blocks removed."
}
