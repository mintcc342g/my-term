#!/usr/bin/env bash
#
# Powerline StatusLine for Claude Code (pure bash, no OMC dependency)
#
# Segments: cwd | git | model | 5h rate | wk rate | sess | tokens | codex | cache | ctx
# Nord color theme, truecolor ANSI, powerline separators
#

input=$(cat)

umask 077

cache_dir="$HOME/.claude/my-hud/cache"
tmp_dir="$HOME/.claude/my-hud/tmp"
mkdir -p "$cache_dir" "$tmp_dir" 2>/dev/null || true
chmod 700 "$cache_dir" "$tmp_dir" 2>/dev/null || true

# ── Parse stdin JSON (single jq call) ────────────────────────────────────────
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
[ -z "$input_tokens" ] && input_tokens=0
[ -z "$cache_create" ] && cache_create=0
[ -z "$cache_read" ] && cache_read=0
pct=$(printf "%.0f" "$pct" 2>/dev/null || echo 0)
[ -z "$pct" ] && pct=0

# ── Shorten path (like zsh %3~) ──────────────────────────────────────────────
short_dir=$(printf '%s' "$cwd" | sed "s|^$HOME|~|" | awk -F/ '{
  if (NF <= 3) print $0
  else printf "%s/%s/%s", $(NF-2), $(NF-1), $NF
}')

# ── Token formatting ─────────────────────────────────────────────────────────
format_tokens() {
  local t="${1//[^0-9]/}"
  [ -z "$t" ] && t=0
  if [ "$t" -ge 1000000 ]; then
    awk "BEGIN {printf \"%.1fM\", $t / 1000000}"
  elif [ "$t" -ge 1000 ]; then
    awk "BEGIN {printf \"%.1fK\", $t / 1000}"
  else
    printf "%d" "$t"
  fi
}

total_tokens=$((input_tokens + cache_create + cache_read))
tok_fmt=$(format_tokens "$total_tokens")

# Cache hit rate
total_for_cache=$((input_tokens + cache_create))
if [ $((total_for_cache + cache_read)) -gt 0 ]; then
  cache_pct=$(awk "BEGIN {printf \"%.0f\", ($cache_read / ($total_for_cache + $cache_read)) * 100}")
else
  cache_pct=0
fi

# ── Git branch (current cwd) ─────────────────────────────────────────────────
git_branch=""

if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null | tr -d '\n')
fi

# ── Rate limits (cached 30s, backoff 5m on error) ────────────────────────────
RL_CACHE="$cache_dir/ratelimit.json"
RL_ERR_MARKER="$cache_dir/ratelimit.err"
rl_5h_pct=""
rl_5h_reset=""
rl_wk_pct=""
rl_wk_reset=""

RL_NORMAL_TTL=30   # seconds between successful refreshes
RL_ERROR_TTL=300   # seconds to wait after an API error before retrying

refresh_rl=false
_now=$(date +%s)

# Check error backoff first
if [ -f "$RL_ERR_MARKER" ]; then
  _err_age=$((_now - $(stat -f %m "$RL_ERR_MARKER" 2>/dev/null || echo 0)))
  if [ "$_err_age" -gt "$RL_ERROR_TTL" ]; then
    rm -f "$RL_ERR_MARKER" 2>/dev/null || true
    refresh_rl=true
  fi
  # else: still in backoff, skip refresh
elif [ ! -f "$RL_CACHE" ]; then
  refresh_rl=true
elif [ $((_now - $(stat -f %m "$RL_CACHE" 2>/dev/null || echo 0))) -gt "$RL_NORMAL_TTL" ]; then
  refresh_rl=true
else
  # Force refresh if any reset time has passed (cached data is stale)
  _cached_5h_reset=$(jq -r '.five_hour.resets_at // ""' < "$RL_CACHE" 2>/dev/null)
  if [ -n "$_cached_5h_reset" ]; then
    _clean=$(printf '%s' "$_cached_5h_reset" | sed -E 's/T/ /; s/\.[0-9]+//; s/Z$/ +0000/; s/([+-][0-9]{2}):([0-9]{2})$/ \1\2/')
    printf '%s' "$_clean" | grep -Eq ' [+-][0-9]{4}$' || _clean="${_clean} +0000"
    _reset_ep=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$_clean" +%s 2>/dev/null)
    [ -n "$_reset_ep" ] && [ "$_now" -ge "$_reset_ep" ] && refresh_rl=true
  fi
  unset _cached_5h_reset _clean _reset_ep
fi
unset _now _err_age

RL_LOCK="$cache_dir/ratelimit.lock"

if $refresh_rl; then
  # Acquire lock (atomic via mkdir) to prevent concurrent API calls across tmux panes
  if mkdir "$RL_LOCK" 2>/dev/null; then
    # Stale lock guard: remove if older than 15s (curl timeout is 5s)
    trap 'rm -rf "$RL_LOCK" 2>/dev/null' EXIT
    ACCESS_TOKEN=""
    # macOS Keychain first
    CRED_JSON=$(/usr/bin/security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    # Fallback to credentials file
    if [ -z "$CRED_JSON" ] && [ -f "$HOME/.claude/.credentials.json" ]; then
      cred_file="$HOME/.claude/.credentials.json"
      perm=$(stat -f '%Lp' "$cred_file" 2>/dev/null || echo "")
      if [ -n "$perm" ] && [ $((8#$perm & 077)) -ne 0 ]; then
        chmod 600 "$cred_file" 2>/dev/null || true
      fi
      CRED_JSON=$(< "$cred_file")
    fi
    if [ -n "$CRED_JSON" ]; then
      ACCESS_TOKEN=$(printf '%s' "$CRED_JSON" | jq -r '.claudeAiOauth.accessToken // .accessToken // empty' 2>/dev/null)
    fi
    unset CRED_JSON
    if [ -n "$ACCESS_TOKEN" ]; then
      RL_RESP=$(printf 'url = "https://api.anthropic.com/api/oauth/usage"\nheader = "Authorization: Bearer %s"\nheader = "anthropic-beta: oauth-2025-04-20"\n' "$ACCESS_TOKEN" | curl -s --max-time 5 --config - 2>/dev/null)
      unset ACCESS_TOKEN
      if [ -n "$RL_RESP" ] && printf '%s' "$RL_RESP" | jq -e '.five_hour' >/dev/null 2>&1; then
        # Success — update cache and clear any error marker
        tmp_rl="$(mktemp "$tmp_dir/ratelimit.XXXXXX")"
        if printf '%s' "$RL_RESP" > "$tmp_rl"; then
          mv "$tmp_rl" "$RL_CACHE"
          rm -f "$RL_ERR_MARKER" 2>/dev/null || true
        else
          rm -f "$tmp_rl" 2>/dev/null || true
        fi
      elif [ -n "$RL_RESP" ] && printf '%s' "$RL_RESP" | jq -e '.error' >/dev/null 2>&1; then
        # API error (e.g. rate limited) — set error marker for backoff
        # Do NOT overwrite RL_CACHE so stale-but-valid data is preserved
        touch "$RL_ERR_MARKER"
      fi
    fi
    unset RL_RESP
    rm -rf "$RL_LOCK" 2>/dev/null
    trap - EXIT
  else
    # Another pane is already fetching — check for stale lock
    _lock_age=$(($(date +%s) - $(stat -f %m "$RL_LOCK" 2>/dev/null || echo 0)))
    if [ "$_lock_age" -gt 15 ]; then
      rm -rf "$RL_LOCK" 2>/dev/null || true
    fi
    unset _lock_age
  fi
fi

rl_error=false
if [ -f "$RL_ERR_MARKER" ]; then
  rl_error=true
fi
if [ -f "$RL_CACHE" ] && jq -e '.five_hour' < "$RL_CACHE" >/dev/null 2>&1; then
  # Valid cached data exists — use it (even if stale during error backoff)
  rl_error=false
  IFS=$'\t' read -r rl_5h_pct rl_5h_reset rl_wk_pct rl_wk_reset < <(
    jq -r '[
      (.five_hour.utilization // ""),
      (.five_hour.resets_at // ""),
      (.seven_day.utilization // ""),
      (.seven_day.resets_at // "")
    ] | @tsv' < "$RL_CACHE" 2>/dev/null
  )
fi

# If in error state (rate limited), force refresh on next invocation by keeping cache age short
# but still show RL indicator this round

# Format reset time (ISO → relative like "2h13m")
format_reset() {
  local iso="$1"
  [ -z "$iso" ] && return
  local clean reset_epoch

  clean=$(printf '%s' "$iso" | sed -E 's/T/ /; s/\.[0-9]+//')
  if printf '%s' "$clean" | grep -q 'Z$'; then
    clean="${clean%Z} +0000"
  else
    clean=$(printf '%s' "$clean" | sed -E 's/([+-][0-9]{2}):([0-9]{2})$/ \1\2/; s/([0-9]{2}:[0-9]{2}:[0-9]{2})([+-][0-9]{4})$/\1 \2/')
  fi
  if ! printf '%s' "$clean" | grep -Eq ' [+-][0-9]{4}$'; then
    clean="${clean} +0000"
  fi

  reset_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$clean" +%s 2>/dev/null)
  [ -z "$reset_epoch" ] && return
  local now diff mins hrs days
  now=$(date +%s)
  diff=$((reset_epoch - now))
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

format_reset_epoch() {
  local reset_epoch="${1//[^0-9]/}"
  [ -z "$reset_epoch" ] && return
  local now diff mins hrs days
  now=$(date +%s)
  diff=$((reset_epoch - now))
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

rl_5h_reset_fmt=$(format_reset "$rl_5h_reset")
rl_wk_reset_fmt=$(format_reset "$rl_wk_reset")

# Round rate limit percentages
[ -n "$rl_5h_pct" ] && rl_5h_pct=$(printf "%.0f" "$rl_5h_pct" 2>/dev/null)
[ -n "$rl_wk_pct" ] && rl_wk_pct=$(printf "%.0f" "$rl_wk_pct" 2>/dev/null)

# ── Session duration (from cost.total_duration_ms) ───────────────────────────
[ -z "$total_duration_ms" ] && total_duration_ms=0
total_duration_ms=${total_duration_ms%%.*}
[ -z "$total_duration_ms" ] && total_duration_ms=0
sess_minutes=$((total_duration_ms / 60000))
sess_health="healthy"

# Session health
if [ "$sess_minutes" -gt 120 ] || [ "$pct" -gt 85 ]; then
  sess_health="critical"
elif [ "$sess_minutes" -gt 60 ] || [ "$pct" -gt 70 ]; then
  sess_health="warning"
fi

# Format session duration
if [ "$sess_minutes" -lt 60 ]; then
  sess_fmt="${sess_minutes}m"
else
  sess_fmt="$((sess_minutes / 60))h$((sess_minutes % 60))m"
fi

# ── ANSI / Powerline rendering ───────────────────────────────────────────────
reset=$'\033[0m'
SEP=$(printf '\xee\x82\xb0')        # U+E0B0 powerline right triangle
GIT_ICON=$(printf '\xee\x82\xa0')   # U+E0A0 git branch icon
fg_true() { printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
bg_true() { printf '\033[48;2;%s;%s;%sm' "$1" "$2" "$3"; }

TERM_BG_R=46;  TERM_BG_G=52;  TERM_BG_B=64     # Nord0 #2E3440
FG_DARK_R=46;  FG_DARK_G=52;  FG_DARK_B=64
FG_LIGHT_R=236; FG_LIGHT_G=239; FG_LIGHT_B=244  # Nord6 #ECEFF4

# seg "text" bg_r bg_g bg_b fg_r fg_g fg_b next_bg_r next_bg_g next_bg_b has_next
seg() {
  local text="$1"
  local bg_r="$2" bg_g="$3" bg_b="$4"
  local fg_r="$5" fg_g="$6" fg_b="$7"
  local next_r="$8" next_g="$9" next_b="${10}"
  local has_next="${11}"

  printf '%s%s %s ' \
    "$(bg_true "$bg_r" "$bg_g" "$bg_b")" \
    "$(fg_true "$fg_r" "$fg_g" "$fg_b")" \
    "$text"

  if [ "$has_next" = "1" ]; then
    printf '%s%s%s' \
      "$(fg_true "$bg_r" "$bg_g" "$bg_b")" \
      "$(bg_true "$next_r" "$next_g" "$next_b")" \
      "$SEP"
  else
    printf '%s%s%s' \
      "$(fg_true "$bg_r" "$bg_g" "$bg_b")" \
      "$(bg_true "$TERM_BG_R" "$TERM_BG_G" "$TERM_BG_B")" \
      "$SEP"
  fi
  printf '%s' "$reset"
}

# ── Build segment list ───────────────────────────────────────────────────────
# Format: "text|bg_r|bg_g|bg_b|fg_r|fg_g|fg_b"
segments=()

# 1. CWD — Nord10 #5E81AC, light fg
segments+=("${short_dir}|94|129|172|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")

# 2. Git branch — Nord3 #4C566A, light fg (optional)
if [ -n "$git_branch" ]; then
  segments+=("${GIT_ICON} ${git_branch}|76|86|106|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")
fi

# 3. Codex usage — global cache based on latest Codex session rate limits
CODEX_USAGE_CACHE="$cache_dir/codex-usage.json"
CODEX_USAGE_LOCK="$cache_dir/codex-usage.lock"
CODEX_USAGE_NORMAL_TTL=30
codex_left_pct=""
codex_used_pct=""
codex_reset_epoch=""

refresh_codex_usage=false
_now=$(date +%s)
if [ ! -f "$CODEX_USAGE_CACHE" ]; then
  refresh_codex_usage=true
elif [ $((_now - $(stat -f %m "$CODEX_USAGE_CACHE" 2>/dev/null || echo 0))) -gt "$CODEX_USAGE_NORMAL_TTL" ]; then
  refresh_codex_usage=true
else
  _cached_codex_reset=$(jq -r '.primary.resets_at // 0' < "$CODEX_USAGE_CACHE" 2>/dev/null)
  if [ -n "$_cached_codex_reset" ] && [ "$_cached_codex_reset" -gt 0 ] 2>/dev/null && [ "$_now" -ge "$_cached_codex_reset" ]; then
    refresh_codex_usage=true
  fi
  unset _cached_codex_reset
fi
unset _now

if $refresh_codex_usage; then
  if mkdir "$CODEX_USAGE_LOCK" 2>/dev/null; then
    trap 'rm -rf "$CODEX_USAGE_LOCK" 2>/dev/null' EXIT
    codex_usage_line=""
    while IFS= read -r session_file; do
      [ -z "$session_file" ] && continue
      codex_usage_line=$(grep '"type":"token_count"' "$session_file" 2>/dev/null | tail -n 1)
      [ -n "$codex_usage_line" ] && break
    done < <(
      find "$HOME/.codex/sessions" "$HOME/.codex/archived_sessions" -type f -name '*.jsonl' -exec stat -f '%m %N' {} + 2>/dev/null \
        | sort -rn \
        | awk 'NR <= 10 { $1 = ""; sub(/^ /, ""); print }'
    )

    if [ -n "$codex_usage_line" ] && printf '%s' "$codex_usage_line" | jq -e '.payload.rate_limits.primary.used_percent' >/dev/null 2>&1; then
      tmp_codex="$(mktemp "$tmp_dir/codex-usage.XXXXXX")"
      if printf '%s' "$codex_usage_line" | jq '{
          primary: {
            used_percent: (.payload.rate_limits.primary.used_percent // 0),
            left_percent: (100 - ((.payload.rate_limits.primary.used_percent // 0) | floor)),
            resets_at: (.payload.rate_limits.primary.resets_at // 0),
            window_minutes: (.payload.rate_limits.primary.window_minutes // 0)
          },
          secondary: {
            used_percent: (.payload.rate_limits.secondary.used_percent // 0),
            left_percent: (100 - ((.payload.rate_limits.secondary.used_percent // 0) | floor)),
            resets_at: (.payload.rate_limits.secondary.resets_at // 0),
            window_minutes: (.payload.rate_limits.secondary.window_minutes // 0)
          },
          plan_type: (.payload.rate_limits.plan_type // null),
          updated_at: now
        }' > "$tmp_codex"; then
        mv "$tmp_codex" "$CODEX_USAGE_CACHE"
      else
        rm -f "$tmp_codex" 2>/dev/null || true
      fi
    fi
    unset codex_usage_line
    rm -rf "$CODEX_USAGE_LOCK" 2>/dev/null
    trap - EXIT
  else
    _lock_age=$(($(date +%s) - $(stat -f %m "$CODEX_USAGE_LOCK" 2>/dev/null || echo 0)))
    if [ "$_lock_age" -gt 15 ]; then
      rm -rf "$CODEX_USAGE_LOCK" 2>/dev/null || true
    fi
    unset _lock_age
  fi
fi

if [ -f "$CODEX_USAGE_CACHE" ] && jq -e '.primary.left_percent' < "$CODEX_USAGE_CACHE" >/dev/null 2>&1; then
  IFS=$'\t' read -r codex_left_pct codex_used_pct codex_reset_epoch < <(
    jq -r '[
      (.primary.left_percent // ""),
      (.primary.used_percent // ""),
      (.primary.resets_at // "")
    ] | @tsv' < "$CODEX_USAGE_CACHE" 2>/dev/null
  )
  codex_left_pct=$(printf "%.0f" "$codex_left_pct" 2>/dev/null)
fi

if [ -n "$codex_left_pct" ]; then
  codex_txt="coLeft:${codex_left_pct}%"
  codex_reset_fmt=$(format_reset_epoch "$codex_reset_epoch")
  if [ -n "$codex_reset_fmt" ]; then
    codex_txt="${codex_txt}(${codex_reset_fmt})"
  else
    codex_txt="${codex_txt}"
  fi
  if [ "$codex_left_pct" -le 10 ] 2>/dev/null; then
    segments+=("${codex_txt}|191|97|106|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")
  elif [ "$codex_left_pct" -le 50 ] 2>/dev/null; then
    segments+=("${codex_txt}|235|213|169|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")
  else
    segments+=("${codex_txt}|143|188|187|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")
  fi
else
  segments+=("coLeft:--|143|188|187|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")
fi

# 4. Model — Nord4 #D8DEE9, dark fg
segments+=("${model_name}|216|222|233|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")

# 5. 5h rate — dynamic color by usage (optional)
if $rl_error; then
  segments+=("5h:--|107|125|150|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")
elif [ -n "$rl_5h_pct" ]; then
  rl_5h_txt="5h:${rl_5h_pct}%"
  [ -n "$rl_5h_reset_fmt" ] && rl_5h_txt="${rl_5h_txt}(${rl_5h_reset_fmt})"
  if [ "$rl_5h_pct" -ge 80 ] 2>/dev/null; then
    segments+=("${rl_5h_txt}|191|97|106|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")
  elif [ "$rl_5h_pct" -ge 50 ] 2>/dev/null; then
    segments+=("${rl_5h_txt}|235|213|169|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")
  else
    segments+=("${rl_5h_txt}|107|125|150|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")
  fi
fi

# 6. wk rate — dynamic color by usage (optional)
if $rl_error; then
  segments+=("wk:--|148|165|190|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")
elif [ -n "$rl_wk_pct" ]; then
  rl_wk_txt="wk:${rl_wk_pct}%"
  [ -n "$rl_wk_reset_fmt" ] && rl_wk_txt="${rl_wk_txt}(${rl_wk_reset_fmt})"
  if [ "$rl_wk_pct" -ge 80 ] 2>/dev/null; then
    segments+=("${rl_wk_txt}|191|97|106|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")
  elif [ "$rl_wk_pct" -ge 50 ] 2>/dev/null; then
    segments+=("${rl_wk_txt}|235|213|169|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")
  else
    segments+=("${rl_wk_txt}|148|165|190|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")
  fi
fi

# 7. Session — dynamic color by health
case "$sess_health" in
  critical) S_BR=191; S_BG=97;  S_BB=106; S_FR=$FG_LIGHT_R; S_FG=$FG_LIGHT_G; S_FB=$FG_LIGHT_B ;;
  warning)  S_BR=235; S_BG=213; S_BB=169; S_FR=$FG_DARK_R;  S_FG=$FG_DARK_G;  S_FB=$FG_DARK_B ;;
  *)        S_BR=195; S_BG=218; S_BB=220; S_FR=$FG_DARK_R;  S_FG=$FG_DARK_G;  S_FB=$FG_DARK_B ;;
esac
segments+=("${sess_fmt}|${S_BR}|${S_BG}|${S_BB}|${S_FR}|${S_FG}|${S_FB}")

# 8. Cache — dynamic color by hit rate (low cache = bad)
if [ "$cache_pct" -le 20 ] 2>/dev/null; then
  segments+=("cache:${cache_pct}%|191|97|106|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")
elif [ "$cache_pct" -le 50 ] 2>/dev/null; then
  segments+=("cache:${cache_pct}%|235|213|169|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")
else
  segments+=("cache:${cache_pct}%|129|161|193|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")
fi

# 9. Context — Nord8 #88C0D0, dark fg
segments+=("ctx:${pct}%|136|192|208|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")

# ── Render ───────────────────────────────────────────────────────────────────
out=""
total=${#segments[@]}
for i in "${!segments[@]}"; do
  IFS='|' read -r text bg_r bg_g bg_b fg_r fg_g fg_b <<< "${segments[$i]}"

  has_next="0"
  next_bg_r=0; next_bg_g=0; next_bg_b=0
  next_idx=$((i + 1))
  if [ "$next_idx" -lt "$total" ]; then
    has_next="1"
    IFS='|' read -r _ nbr nbg nbb _ _ _ <<< "${segments[$next_idx]}"
    next_bg_r=$nbr; next_bg_g=$nbg; next_bg_b=$nbb
  fi

  out+=$(seg "$text" "$bg_r" "$bg_g" "$bg_b" "$fg_r" "$fg_g" "$fg_b" "$next_bg_r" "$next_bg_g" "$next_bg_b" "$has_next")
done

nbsp=$(printf '\302\240')
out=${out// /$nbsp}
printf '%s%s\n' "$out" "$reset"
