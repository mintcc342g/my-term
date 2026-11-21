#!/bin/bash
# installers/obsidian.sh — Obsidian app + wiki tooling (@wk hook, wiki path)
# source'd by install.sh; called when Obsidian is selected in the AI tools checklist.

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

  # 2. Choose the Obsidian vault storage type.
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
  # macOS Bash 3.2 does not support read -i, so the prefix appears in the instructions.
  # By default, Readline completes the common prefix on the first Tab and lists matches on the second.
  # show-all-if-ambiguous displays matches immediately.
  # completion-ignore-case matches paths such as ~/documents and ~/Documents.
  # Enable Emacs mode before binding keys because noninteractive shells start with Readline disabled.
  # Use || true so a failed binding is harmless under set -euo pipefail.
  # menu-complete cycles through matches inline with Tab.
  # Shift+Tab (\e[Z) cycles backward.
  # Keep completion case-insensitive for common directory name variations.
  # Keep hidden names out of the cycle unless the user types a leading dot.
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

  # 5. Share one wiki workflow with each installed agent.
  _save_wiki_path "$wiki_path"
  if command -v claude &>/dev/null; then
    _sync_claude_wiki "$wiki_path"
  fi
  if command -v codex &>/dev/null; then
    _sync_codex_wiki "$wiki_path"
  fi

  # 6. Install default vault files such as schema.md when they are missing.
  _install_wiki_defaults "$wiki_path"

  log_done "Obsidian + wiki tooling configured."

  # 7. obsidian-skills plugin guidance — printed AFTER ✔ as a follow-up hint,
  # using the same indented, icon-free style as the completion hints.
  printf "  %s\n" "$L_OBS_PLUGIN_HINT"
  printf "    /plugin marketplace add kepano/obsidian-skills\n"
  printf "    /plugin install obsidian@obsidian-skills\n"
}

_configured_wiki_path() {
  local dir path
  for dir in "${XDG_CONFIG_HOME:-$HOME/.config}/my-term" "$HOME/.claude/my-wiki" "${CODEX_HOME:-$HOME/.codex}/my-wiki"; do
    if [ -s "$dir/wiki-path" ]; then
      cat "$dir/wiki-path"
      return
    fi
    if [ -f "$dir/wk-trigger.sh" ]; then
      # Earlier installations embedded the selected path in the script.
      path="$(sed -nE 's/^WIKI_PATH="(.*)"$/\1/p' "$dir/wk-trigger.sh")"
      if [ -n "$path" ]; then
        printf '%s\n' "$path"
        return
      fi
    fi
  done
}

_save_wiki_path() (
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/my-term" tmp
  umask 077
  mkdir -p "$dir"
  tmp="$(mktemp "$dir/.wiki-path.XXXXXX")"
  trap 'rm -f "$tmp"' EXIT
  printf '%s\n' "$1" > "$tmp"
  mv -f "$tmp" "$dir/wiki-path"
)

_update_agent_wiki() {
  local wiki_path
  wiki_path="$(_configured_wiki_path)"
  if [ -n "$wiki_path" ] && [ -d "$wiki_path" ]; then
    "$1" "$wiki_path"
  fi
}

_sync_claude_wiki() {
  _sync_wiki_files "$1" "$HOME/.claude/my-wiki"
  _setup_wiki_hook
  _sync_wk_skill "$HOME/.claude/my-wiki" "$HOME/.claude/skills/wk"
}

_sync_wiki_files() (
  local wiki_path="$1" dest="$2"
  umask 077

  if [ -L "$dest" ]; then
    log_fail "Cannot update symlinked wiki directory: $dest"
    return 1
  fi

  mkdir -p "$dest"
  chmod 700 "$dest"
  local tmp
  tmp="$(mktemp -d "$dest/.sync.XXXXXX")"
  trap 'rm -f "$tmp/wiki-path" "$tmp/wk-directive.md" "$tmp/wk-trigger.sh"; rmdir "$tmp"' EXIT
  printf '%s\n' "$wiki_path" > "$tmp/wiki-path"
  sed "s|{{RESPONSE_LANG}}|$(lang_response_name)|g" "$SCRIPT_DIR/my-ai/wiki/wk-directive.md" \
    > "$tmp/wk-directive.md"
  cp "$SCRIPT_DIR/my-ai/wiki/wk-trigger.sh" "$tmp/wk-trigger.sh"
  chmod 700 "$tmp/wk-trigger.sh"
  mv -f "$tmp/wiki-path" "$tmp/wk-directive.md" "$tmp/wk-trigger.sh" "$dest/"
)

_has_wk_skill() {
  [ ! -L "$1" ] && [ ! -L "$1/SKILL.md" ] &&
    grep -qxF '<!-- managed by my-term -->' "$1/SKILL.md" 2>/dev/null
}

_sync_wk_skill() (
  local wiki_dir="$1" dest="$2" tmp
  if [ -L "$dest" ] || { { [ -e "$dest/SKILL.md" ] || [ -L "$dest/SKILL.md" ]; } && ! _has_wk_skill "$dest"; }; then
    log_step "Keeping existing wk skill: $dest"
    return 0
  fi

  umask 077
  mkdir -p "$dest"
  tmp="$(mktemp "$dest/.skill.XXXXXX")"
  trap 'rm -f "$tmp"' EXIT
  cat "$SCRIPT_DIR/my-ai/wiki/wk/SKILL.md" > "$tmp"
  printf '\n' >> "$tmp"
  /bin/bash "$wiki_dir/wk-trigger.sh" --instructions >> "$tmp"
  mv -f "$tmp" "$dest/SKILL.md"
)

_delete_wk_skill() {
  local dest="$1"
  if _has_wk_skill "$dest"; then
    rm -f "$dest/SKILL.md"
    rmdir "$dest" 2>/dev/null || true
  fi
}

# Install default vault files such as schema.md when they are missing.
# Keep existing vault files to preserve user edits.
# Used on initial installation and on Update to restore missing defaults.
#
# $1: wiki_path
# Replace these placeholders:
#   {{WIKI_NAME}}    → basename of wiki_path
#   {{INSTALL_DATE}} — current date (YYYY-MM-DD)
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

  local wiki_dir="$SCRIPT_DIR/my-ai/wiki"
  if [ ! -d "$wiki_dir" ]; then
    return 0
  fi

  local wiki_name install_date
  wiki_name=$(basename "$wiki_path")
  install_date=$(date +%Y-%m-%d)

  # The installer deploys wk-* through _sync_wiki_files.
  # This step copies the remaining default files into the vault.
  local _lang_name; _lang_name="$(lang_response_name)"
  local src dst base escaped_name
  escaped_name="$(printf '%s' "$wiki_name" | sed 's/[\\&|]/\\&/g')"
  for src in "$wiki_dir"/*; do
    [ -f "$src" ] || continue
    base=$(basename "$src")
    case "$base" in
      wk-*) continue ;;                 # Skip the files deployed with the hook.
    esac
    # Keep any existing vault file, such as a customized schema.md.
    dst="$wiki_path/$base"
    if [ -e "$dst" ]; then
      log_step "wiki default exists, keep user copy: $base"
      continue
    fi
    sed -e "s|{{WIKI_NAME}}|${escaped_name}|g" \
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
