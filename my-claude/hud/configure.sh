#!/usr/bin/env bash
#
# SF-HUD configuration UI — arrow key navigation
# File sync is handled by the top-level Update menu (installers/ai-tools.sh).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# install.sh 가 넘긴 언어를 ui.sh(MYTERM_LANG 덮어씀)보다 먼저 캡처.
# 비어있으면 단독 실행 → 설치본 config.json .lang 으로 폴백.
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
  # themes/themes.json manifest 우선(id·name·언어별 desc), 없으면 themes/*.sh glob 폴백
  local themes_dir="$SCRIPT_DIR/themes"
  local manifest="$themes_dir/themes.json"
  local -a themes=() opts=() descs=()
  local id name d f

  # 언어: install.sh가 넘긴 값 우선(프로젝트/설치 맥락) → 없으면 설치본 config.json .lang → en
  local lang="${_ENV_LANG:-}"
  [ -z "$lang" ] && lang=$(jq -r '.lang // ""' "$CONFIG" 2>/dev/null)
  [ -z "$lang" ] && lang="en"
  lang_is_known "$lang" || lang="en"

  if [ -f "$manifest" ] && jq -e '.themes' "$manifest" >/dev/null 2>&1; then
    # desc 는 요청 언어 우선, 없으면 en→ja→ko 중 첫 비어있지 않은 값
    while IFS=$'\t' read -r id name d; do
      [ -z "$id" ] && continue
      [ -f "$themes_dir/${id}.sh" ] || continue   # .sh 없는 항목은 건너뜀
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

  # choice가 테마 인덱스 범위면 선택, 마지막(← Back)·취소(255)는 무시
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
