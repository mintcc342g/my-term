#!/usr/bin/env bash
#
# SF-HUD bordered statusline for Claude Code
# Modular: themes/ for colors, render.sh for drawing, config.json for settings
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Config handling (--config mode) ─────────────────────────────
if [ "${1:-}" = "--config" ]; then
  exec "$SCRIPT_DIR/configure.sh"
fi

# ── Read stdin JSON ─────────────────────────────────────────────
input=$(cat)

umask 077
cache_dir="$HOME/.claude/my-hud/cache"
tmp_dir="$HOME/.claude/my-hud/tmp"
mkdir -p "$cache_dir" "$tmp_dir" 2>/dev/null || true
chmod 700 "$cache_dir" "$tmp_dir" 2>/dev/null || true

# ── Parse stdin JSON ────────────────────────────────────────────
IFS=$'\t' read -r cwd model_name pct input_tokens cache_create cache_read total_duration_ms < <(
  printf '%s' "$input" | jq -r '[
    (.cwd // ""),
    (.model.display_name // "Unknown"),
    (.context_window.used_percentage // 0),
    (.context_window.current_usage.input_tokens // 0),
    (.context_window.current_usage.cache_creation_input_tokens // 0),
    (.context_window.current_usage.cache_read_input_tokens // 0),
    (.cost.total_duration_ms // 0)
  ] | @tsv'
)

[ -z "$cwd" ] && cwd="$PWD"
[ -z "$model_name" ] && model_name="Unknown"
[ -z "$pct" ] && pct=0
pct=$(printf "%.0f" "$pct" 2>/dev/null || echo 0)
[ -z "$pct" ] && pct=0
[ -z "$input_tokens" ] && input_tokens=0
[ -z "$cache_create" ] && cache_create=0
[ -z "$cache_read" ] && cache_read=0

# ── Shorten path (3 depth max, truncate if too long) ───────────
MAX_DIR_LEN=20  # visible chars for dir inside │ ... │
short_dir=$(printf '%s' "$cwd" | sed "s|^$HOME|~|" | awk -F/ '{
  if (NF <= 3) print $0
  else printf "%s/%s/%s", $(NF-2), $(NF-1), $NF
}')
# If still too long, collapse middle to ..
if [ ${#short_dir} -gt $MAX_DIR_LEN ]; then
  short_dir=$(printf '%s' "$cwd" | sed "s|^$HOME|~|" | awk -F/ '{
    if (NF <= 2) print $0
    else printf "%s/../%s", $1, $NF
  }')
fi

# ── Cache hit rate ──────────────────────────────────────────────
total_for_cache=$((input_tokens + cache_create))
if [ $((total_for_cache + cache_read)) -gt 0 ]; then
  cache_pct=$(awk "BEGIN {printf \"%.0f\", ($cache_read / ($total_for_cache + $cache_read)) * 100}")
else
  cache_pct=0
fi

# ── Git branch ──────────────────────────────────────────────────
git_branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null | tr -d '\n')
fi

# ── Rate limits (reuse existing refresh logic) ──────────────────
RL_CACHE="$cache_dir/ratelimit.json"
RL_ERR_MARKER="$cache_dir/ratelimit.err"
rl_5h_pct=""
rl_wk_pct=""

RL_NORMAL_TTL=30
RL_ERROR_TTL=300

refresh_rl=false
_now=$(date +%s)

if [ -f "$RL_ERR_MARKER" ]; then
  _err_age=$((_now - $(stat -f %m "$RL_ERR_MARKER" 2>/dev/null || echo 0)))
  if [ "$_err_age" -gt "$RL_ERROR_TTL" ]; then
    rm -f "$RL_ERR_MARKER" 2>/dev/null || true
    refresh_rl=true
  fi
elif [ ! -f "$RL_CACHE" ]; then
  refresh_rl=true
elif [ $((_now - $(stat -f %m "$RL_CACHE" 2>/dev/null || echo 0))) -gt "$RL_NORMAL_TTL" ]; then
  refresh_rl=true
fi
unset _now _err_age

RL_LOCK="$cache_dir/ratelimit.lock"
if $refresh_rl; then
  if mkdir "$RL_LOCK" 2>/dev/null; then
    trap 'rm -rf "$RL_LOCK" 2>/dev/null' EXIT
    cache_dir="$cache_dir" tmp_dir="$tmp_dir" "$SCRIPT_DIR/refresh-ratelimit.sh"
    rm -rf "$RL_LOCK" 2>/dev/null
    trap - EXIT
  else
    _lock_age=$(($(date +%s) - $(stat -f %m "$RL_LOCK" 2>/dev/null || echo 0)))
    [ "$_lock_age" -gt 15 ] && rm -rf "$RL_LOCK" 2>/dev/null || true
    unset _lock_age
  fi
fi

if [ -f "$RL_CACHE" ] && jq -e '.five_hour' < "$RL_CACHE" >/dev/null 2>&1; then
  rl_5h_pct=$(jq -r '.five_hour.utilization // ""' < "$RL_CACHE" 2>/dev/null)
  rl_wk_pct=$(jq -r '.seven_day.utilization // ""' < "$RL_CACHE" 2>/dev/null)
fi

if [ -n "$rl_5h_pct" ]; then
  rl_5h_pct=$(printf "%.0f" "$rl_5h_pct" 2>/dev/null)
else
  rl_5h_pct=0
fi
if [ -n "$rl_wk_pct" ]; then
  rl_wk_pct=$(printf "%.0f" "$rl_wk_pct" 2>/dev/null)
else
  rl_wk_pct=0
fi

# ── Session duration ────────────────────────────────────────────
[ -z "$total_duration_ms" ] && total_duration_ms=0
total_duration_ms=${total_duration_ms%%.*}
[ -z "$total_duration_ms" ] && total_duration_ms=0
sess_minutes=$((total_duration_ms / 60000))
if [ "$sess_minutes" -lt 60 ]; then
  sess_fmt="${sess_minutes}m"
else
  sess_fmt="$((sess_minutes / 60))h$((sess_minutes % 60))m"
fi

# ── Codex usage (from cache) ────────────────────────────────────
CODEX_USAGE_CACHE="$cache_dir/codex-usage.json"
codex_left_pct=""
codex_model="codex-mini"
codex_reset_fmt=""

format_relative() {
  local epoch="${1//[^0-9]/}"
  [ -z "$epoch" ] && return
  local now diff mins hrs days
  now=$(date +%s)
  diff=$((epoch - now))
  [ "$diff" -le 0 ] && return
  mins=$((diff / 60))
  hrs=$((mins / 60))
  days=$((hrs / 24))
  if [ "$days" -gt 0 ]; then
    printf "%dd%dh" "$days" $((hrs % 24))
  elif [ "$hrs" -gt 0 ]; then
    printf "%dh%dm" "$hrs" $((mins % 60))
  else
    printf "%dm" "$mins"
  fi
}

if [ -f "$CODEX_USAGE_CACHE" ] && jq -e '.primary.left_percent' < "$CODEX_USAGE_CACHE" >/dev/null 2>&1; then
  IFS=$'\t' read -r codex_left_pct codex_reset_epoch < <(
    jq -r '[
      (.primary.left_percent // ""),
      (.primary.resets_at // "")
    ] | @tsv' < "$CODEX_USAGE_CACHE" 2>/dev/null
  )
  codex_left_pct=$(printf "%.0f" "$codex_left_pct" 2>/dev/null)
  [[ "$codex_left_pct" =~ ^[0-9]+$ ]] || codex_left_pct=""
  codex_reset_fmt=$(format_relative "$codex_reset_epoch")
fi
[ -z "$codex_left_pct" ] && codex_left_pct=0
[ -z "$codex_reset_fmt" ] && codex_reset_fmt="--"

# ── Load config ─────────────────────────────────────────────────
CONFIG="$SCRIPT_DIR/config.json"
theme=$(jq -r '.theme // "mygo"' < "$CONFIG" 2>/dev/null)
CONFIG_OW=$(jq -r '.outer_width // 60' < "$CONFIG" 2>/dev/null)

# ── Detect terminal width (walk parent processes to find TTY) ───
detect_term_width() {
  local pid=$$ tty_dev="" width=""
  local i=0
  while [ $i -lt 8 ] && [ -n "$pid" ] && [ "$pid" != "0" ]; do
    tty_dev=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$tty_dev" ] && [ "$tty_dev" != "??" ] && [ "$tty_dev" != "-" ]; then
      # Normalize: add /dev/ prefix if missing
      case "$tty_dev" in
        /dev/*) ;;
        *) tty_dev="/dev/$tty_dev" ;;
      esac
      width=$(stty size < "$tty_dev" 2>/dev/null | awk '{print $2}')
      [ -n "$width" ] && [ "$width" -gt 0 ] 2>/dev/null && { echo "$width"; return; }
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    i=$((i + 1))
  done
  # Fallback
  tput cols 2>/dev/null || echo 80
}

TERM_WIDTH=$(detect_term_width)
[[ "$TERM_WIDTH" =~ ^[0-9]+$ ]] || TERM_WIDTH=80
# Use smaller of config width and terminal width
if [ "$TERM_WIDTH" -lt "$CONFIG_OW" ] 2>/dev/null; then
  OW=$TERM_WIDTH
else
  OW=$CONFIG_OW
fi
# Minimum width to render HUD — below this, output nothing
MIN_OW=50
if [ "$OW" -lt "$MIN_OW" ] 2>/dev/null; then
  exit 0
fi

BW=$(jq -r '.bar_width // 14' < "$CONFIG" 2>/dev/null)
IW=$(( OW - 2 ))

sec_workspace=$(jq -r '.sections.workspace.enabled // true' < "$CONFIG" 2>/dev/null)
sec_claude=$(jq -r '.sections.claude.enabled // true' < "$CONFIG" 2>/dev/null)
sec_codex=$(jq -r '.sections.codex.enabled // false' < "$CONFIG" 2>/dev/null)

# ── Load theme + render engine ──────────────────────────────────
source "$SCRIPT_DIR/render.sh"
theme_file="$SCRIPT_DIR/themes/${theme}.sh"
if [ ! -f "$theme_file" ]; then
  theme="mygo"
  theme_file="$SCRIPT_DIR/themes/mygo.sh"
fi
source "$theme_file"

# ── Render HUD ──────────────────────────────────────────────────
nbsp=$(printf '\302\240')

render_hud() {
  build_top

  if [ "$sec_workspace" = "true" ]; then
    render_workspace "$short_dir" "$git_branch"
  fi

  if [ "$sec_claude" = "true" ]; then
    render_claude "$model_name" "$sess_fmt" "${cache_pct}" "$rl_5h_pct" "$rl_wk_pct" "$pct"
  fi

  if [ "$sec_codex" = "true" ]; then
    render_codex "$codex_model" "$codex_reset_fmt" "$codex_left_pct"
  fi

  build_bottom
}

# Pipe: replace spaces with nbsp, prefix each line with ANSI reset
rst_prefix=$'\033[0m'
render_hud | sed "s/ /${nbsp}/g; s/^/${rst_prefix}/"
