#!/usr/bin/env bash
#
# SF-HUD configuration UI — arrow key navigation
# File sync is handled by the top-level Update menu (installers/ai-tools.sh).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Capture the installer language before ui.sh resets MYTERM_LANG.
# When launched independently, fall back to the language in the installed config.json.
_ENV_LANG="${MYTERM_LANG:-}"

# Config location: use installed config if exists, else project
if [ -f "$HOME/.claude/my-hud/config.json" ]; then
  CONFIG="$HOME/.claude/my-hud/config.json"
elif [ -f "$SCRIPT_DIR/config.json" ]; then
  CONFIG="$SCRIPT_DIR/config.json"
else
  echo "Error: config.json not found" >&2
  exit 1
fi

# Source shared UI
if [ -f "$SCRIPT_DIR/../../lib/ui.sh" ]; then
  source "$SCRIPT_DIR/../../lib/ui.sh"
elif [ -f "$HOME/.claude/my-hud/lib/ui.sh" ]; then
  source "$HOME/.claude/my-hud/lib/ui.sh"
else
  echo "Error: lib/ui.sh not found" >&2
  exit 1
fi

# ── Load / Save config ──────────────────────────────────────────
load_config() {
  theme=$(jq -r '.theme // "mygo"' < "$CONFIG" 2>/dev/null)
  sec_workspace=$(jq -r '.sections.workspace.enabled // true' < "$CONFIG" 2>/dev/null)
  sec_claude=$(jq -r '.sections.claude.enabled // true' < "$CONFIG" 2>/dev/null)
  sec_codex=$(jq -r '.sections.codex.enabled // false' < "$CONFIG" 2>/dev/null)
}

save_config() {
  local tmp
  tmp=$(mktemp)
  jq --arg theme "$theme" \
     --argjson ws "$sec_workspace" \
     --argjson cl "$sec_claude" \
     --argjson cx "$sec_codex" \
     '.theme = $theme | .sections.workspace.enabled = $ws | .sections.claude.enabled = $cl | .sections.codex.enabled = $cx' \
     < "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
}

toggle() {
  if [ "$1" = "true" ]; then echo "false"; else echo "true"; fi
}

on_off() {
  if [ "$1" = "true" ]; then echo "ON"; else echo "OFF"; fi
}

# ── Theme submenu ───────────────────────────────────────────────
select_theme() {
  # Prefer themes/themes.json for IDs, names, and descriptions. Fall back to themes/*.sh.
  local themes_dir="$SCRIPT_DIR/themes"
  local manifest="$themes_dir/themes.json"
  local -a themes=() opts=() descs=()
  local id name d f

  # Prefer the installer language, then the installed config.json language, then English.
  local lang="${_ENV_LANG:-}"
  [ -z "$lang" ] && lang=$(jq -r '.lang // ""' "$CONFIG" 2>/dev/null)
  [ -z "$lang" ] && lang="en"
  lang_is_known "$lang" || lang="en"

  if [ -f "$manifest" ] && jq -e '.themes' "$manifest" >/dev/null 2>&1; then
    # Prefer the requested description language, then the first available of en, ja, and ko.
    while IFS=$'\t' read -r id name d; do
      [ -z "$id" ] && continue
      [ -f "$themes_dir/${id}.sh" ] || continue   # Skip entries whose script is missing.
      themes+=("$id")
      if [ "$id" = "$theme" ]; then opts+=("${name:-$id} (current)"); else opts+=("${name:-$id}"); fi
      if [ -n "$d" ]; then descs+=("“${d}”"); else descs+=(""); fi
    done < <(jq -r --arg lang "$lang" '
      .themes[] | [
        .id,
        (.name // .id),
        ([.desc[$lang], .desc.en, .desc.ja, .desc.ko] | map(select(. != null and . != "")) | (.[0] // ""))
      ] | @tsv' "$manifest")
  else
    for f in "$themes_dir"/*.sh; do
      [ -e "$f" ] || continue
      id=$(basename "$f" .sh)
      themes+=("$id")
      if [ "$id" = "$theme" ]; then opts+=("$id (current)"); else opts+=("$id"); fi
      descs+=("")
    done
  fi
  opts+=("← Back"); descs+=("")

  local choice
  UI_MENU_DESC=("${descs[@]}")
  ui_menu "Select Theme" choice "${opts[@]}"

  # Use valid theme indices. Ignore Back and cancellation (255).
  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -lt "${#themes[@]}" ]; then
    theme="${themes[$choice]}"
  fi
}

# ── Main loop ───────────────────────────────────────────────────
load_config

while true; do
  choice=""

  ui_menu "CLAUDE HUD configure" choice \
    "Theme: ${theme}" \
    "Workspace: $(on_off "$sec_workspace")" \
    "Claude: $(on_off "$sec_claude")" \
    "Codex: $(on_off "$sec_codex")" \
    "✓ Save & Exit"

  case "$choice" in
    0) select_theme ;;
    1) sec_workspace=$(toggle "$sec_workspace") ;;
    2) sec_claude=$(toggle "$sec_claude") ;;
    3) sec_codex=$(toggle "$sec_codex") ;;
    4)
      save_config
      echo "${UI_GREEN_BOLD}✔${UI_RESET} Settings saved."
      exit 0
      ;;
    255)
      echo "${UI_DIM}Cancelled.${UI_RESET}"
      exit 0
      ;;
  esac
done
