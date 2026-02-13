#!/usr/bin/env bash
#
# Powerline StatusLine for Claude Code (pure bash, no OMC dependency)
#
# Segments: cwd | git | model | 5h rate | wk rate | sess | tokens | cache | ctx
# Nord color theme, truecolor ANSI, powerline separators
#

input=$(cat)

umask 077

cache_dir=""
if [ -n "${TMPDIR:-}" ] && [ -d "${TMPDIR%/}" ]; then
  cache_dir="${TMPDIR%/}/claude-hud"
else
  cache_dir="$HOME/Library/Caches/claude-hud"
fi
mkdir -p "$cache_dir" 2>/dev/null || true
chmod 700 "$cache_dir" 2>/dev/null || true

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

# ── Git branch (cached 5s) ───────────────────────────────────────────────────
GIT_CACHE_SHARED="$cache_dir/git-branch"
git_branch=""

if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  refresh=false
  if [ ! -f "$GIT_CACHE_SHARED" ]; then
    refresh=true
  elif [ $(($(date +%s) - $(stat -f %m "$GIT_CACHE_SHARED" 2>/dev/null || echo 0))) -gt 5 ]; then
    refresh=true
  fi
  if $refresh; then
    tmp_git="$(mktemp "$cache_dir/git-branch.XXXXXX" 2>/dev/null || mktemp)"
    if git -C "$cwd" branch --show-current 2>/dev/null > "$tmp_git"; then
      mv "$tmp_git" "$GIT_CACHE_SHARED"
    else
      rm -f "$tmp_git" 2>/dev/null || true
    fi
  fi
  git_branch=$(tr -d '\n' < "$GIT_CACHE_SHARED" 2>/dev/null || true)
fi

# ── Rate limits (cached 30s) ─────────────────────────────────────────────────
RL_CACHE="$cache_dir/ratelimit.json"
rl_5h_pct=""
rl_5h_reset=""
rl_wk_pct=""
rl_wk_reset=""

refresh_rl=false
if [ ! -f "$RL_CACHE" ]; then
  refresh_rl=true
elif [ $(($(date +%s) - $(stat -f %m "$RL_CACHE" 2>/dev/null || echo 0))) -gt 30 ]; then
  refresh_rl=true
fi

if $refresh_rl; then
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
    esc_token=${ACCESS_TOKEN//\\/\\\\}
    esc_token=${esc_token//\"/\\\"}
    RL_RESP=$(curl -s --max-time 5 --config - 2>/dev/null <<EOF
url = "https://api.anthropic.com/api/oauth/usage"
header = "Authorization: Bearer ${esc_token}"
header = "anthropic-beta: oauth-2025-04-20"
EOF
)
    unset ACCESS_TOKEN
    if [ -n "$RL_RESP" ] && printf '%s' "$RL_RESP" | jq -e '.five_hour' >/dev/null 2>&1; then
      tmp_rl="$(mktemp "$cache_dir/ratelimit.XXXXXX" 2>/dev/null || mktemp)"
      if printf '%s' "$RL_RESP" > "$tmp_rl"; then
        mv "$tmp_rl" "$RL_CACHE"
      else
        rm -f "$tmp_rl" 2>/dev/null || true
      fi
    fi
  fi
  unset RL_RESP
fi

if [ -f "$RL_CACHE" ]; then
  IFS=$'\t' read -r rl_5h_pct rl_5h_reset rl_wk_pct rl_wk_reset < <(
    jq -r '[
      (.five_hour.utilization // ""),
      (.five_hour.resets_at // ""),
      (.seven_day.utilization // ""),
      (.seven_day.resets_at // "")
    ] | @tsv' < "$RL_CACHE" 2>/dev/null
  )
fi

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

# 2. Git branch — Nord7 #8FBCBB, dark fg (optional)
if [ -n "$git_branch" ]; then
  segments+=("${GIT_ICON} ${git_branch}|143|188|187|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")
fi

# 3. Model — Nord4 #D8DEE9, dark fg
segments+=("${model_name}|216|222|233|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")

# 4. 5h rate — Nord15 #B48EAD, light fg (optional)
if [ -n "$rl_5h_pct" ]; then
  rl_5h_txt="5h:${rl_5h_pct}%"
  [ -n "$rl_5h_reset_fmt" ] && rl_5h_txt="${rl_5h_txt}(${rl_5h_reset_fmt})"
  segments+=("${rl_5h_txt}|180|142|173|${FG_LIGHT_R}|${FG_LIGHT_G}|${FG_LIGHT_B}")
fi

# 5. wk rate — Nord12 #D08770, dark fg (optional)
if [ -n "$rl_wk_pct" ]; then
  rl_wk_txt="wk:${rl_wk_pct}%"
  [ -n "$rl_wk_reset_fmt" ] && rl_wk_txt="${rl_wk_txt}(${rl_wk_reset_fmt})"
  segments+=("${rl_wk_txt}|208|135|112|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")
fi

# 6. Session — dynamic color by health
case "$sess_health" in
  critical) S_BR=191; S_BG=97;  S_BB=106; S_FR=$FG_LIGHT_R; S_FG=$FG_LIGHT_G; S_FB=$FG_LIGHT_B ;;
  warning)  S_BR=208; S_BG=135; S_BB=112; S_FR=$FG_DARK_R;  S_FG=$FG_DARK_G;  S_FB=$FG_DARK_B ;;
  *)        S_BR=235; S_BG=203; S_BB=139; S_FR=$FG_DARK_R;  S_FG=$FG_DARK_G;  S_FB=$FG_DARK_B ;;
esac
segments+=("${sess_fmt}|${S_BR}|${S_BG}|${S_BB}|${S_FR}|${S_FG}|${S_FB}")

# 7. Tokens — Nord14 #A3BE8C, dark fg
segments+=("${tok_fmt}|163|190|140|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")

# 8. Cache — Nord9 #81A1C1, dark fg
segments+=("cache:${cache_pct}%|129|161|193|${FG_DARK_R}|${FG_DARK_G}|${FG_DARK_B}")

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
