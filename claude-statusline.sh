#!/usr/bin/env bash

input=$(cat)

# Parse ALL needed fields with a single jq (faster than multiple jq calls)
# Order: current_dir, model_name, cost, pct, total_input, total_output
IFS=$'\t' read -r current_dir model_name cost pct total_input total_output < <(
  printf '%s' "$input" | jq -r '[
      .workspace.current_dir,
      .model.display_name,
      (.cost.total_cost_usd // 0),
      (.context_window.used_percentage // 0),
      (.context_window.total_input_tokens // 0),
      (.context_window.total_output_tokens // 0)
    ] | @tsv'
)

username=$(whoami)

# Fallbacks for null/empty
[ -z "$pct" ] && pct=0
[ -z "$total_input" ] && total_input=0
[ -z "$total_output" ] && total_output=0
[ -z "$cost" ] && cost=0
[ -z "$model_name" ] && model_name=""

# Ensure pct is numeric and clamped to 0..100
pct=${pct//[^0-9]/}
[ -z "$pct" ] && pct=0
[ "$pct" -gt 100 ] 2>/dev/null && pct=100

# Short directory (like zsh %3~)
short_dir=$(echo "$current_dir" | sed "s|^$HOME|~|" | awk -F/ '{
    if (NF <= 3) print $0
    else printf "%s/%s/%s", $(NF-2), $(NF-1), $NF
}')

# Format token counts (K/M suffix)
format_tokens() {
    local tokens=$1
    tokens=${tokens//[^0-9]/}
    [ -z "$tokens" ] && tokens=0

    if [ "$tokens" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fM\", $tokens / 1000000}"
    elif [ "$tokens" -ge 1000 ]; then
        awk "BEGIN {printf \"%.1fK\", $tokens / 1000}"
    else
        printf "%d" "$tokens"
    fi
}

input_fmt=$(format_tokens "$total_input")
output_fmt=$(format_tokens "$total_output")

# Cost formatting (keep numeric)
cost=$(printf '%s' "$cost" | sed 's/[^0-9.].*$//')
[ -z "$cost" ] && cost=0
cost_fmt=$(printf '$%.2f' "$cost")

# ---------------- p10k-like segments (truecolor Nord) ----------------
reset=$'\033[0m'

# Angular separator (paste glyph directly; avoids bash/sh escape differences)
SEP=''

# Truecolor helpers
fg_true() { printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
bg_true() { printf '\033[48;2;%s;%s;%sm' "$1" "$2" "$3"; }

# Terminal background (Nord0): #2E3440  (endcap BG to avoid gray)
TERM_BG_R=46
TERM_BG_G=52
TERM_BG_B=64

# Text colors: Nord0 (dark) and Nord6 (light)
FG_DARK_R=46;   FG_DARK_G=52;   FG_DARK_B=64     # #2E3440
FG_LIGHT_R=236; FG_LIGHT_G=239; FG_LIGHT_B=244   # #ECEFF4

# Segment background colors (Nord exact)
# USER: green  (Aurora)  #A3BE8C
USER_BG_R=163; USER_BG_G=190; USER_BG_B=140
# DIR: blue   (Frost)   #81A1C1
DIR_BG_R=129;  DIR_BG_G=161;  DIR_BG_B=193
# GIT: purple (Aurora)  #B48EAD   <-- changed from red
GIT_BG_R=180;  GIT_BG_G=142;  GIT_BG_B=173
# TOK: yellow (Aurora)  #EBCB8B
TOK_BG_R=235;  TOK_BG_G=203;  TOK_BG_B=139

# Nord-style FG per segment (contrast)
USER_FG_R=$FG_DARK_R;  USER_FG_G=$FG_DARK_G;  USER_FG_B=$FG_DARK_B
DIR_FG_R=$FG_LIGHT_R;  DIR_FG_G=$FG_LIGHT_G;  DIR_FG_B=$FG_LIGHT_B
GIT_FG_R=$FG_LIGHT_R;  GIT_FG_G=$FG_LIGHT_G;  GIT_FG_B=$FG_LIGHT_B
TOK_FG_R=$FG_DARK_R;   TOK_FG_G=$FG_DARK_G;   TOK_FG_B=$FG_DARK_B

# 8-level 1-char gauge (▁▂▃▄▅▆▇█)
gauge_from_pct() {
  local p="$1"
  p=${p//[^0-9]/}
  [ -z "$p" ] && p=0
  [ "$p" -gt 100 ] 2>/dev/null && p=100

  local i=$(( p*8/100 + 1 ))
  [ "$i" -gt 8 ] && i=8

  set -- ▁ ▂ ▃ ▄ ▅ ▆ ▇ █
  eval "printf '%s' \${$i}"
}
gauge="$(gauge_from_pct "$pct")"

# Gauge color: <= 50% green (Nord #A3BE8C), > 50% red (Nord #BF616A)
# if [ "$pct" -le 50 ]; then
#   GAUGE_ON="$(fg_true 163 190 140)"  # green
# else
#   GAUGE_ON="$(fg_true 191 97 106)"   # red
# fi
GAUGE_ON="$(fg_true 191 97 106)"   # red (Nord #BF616A)

# seg(text, bg_rgb, fg_rgb, next_bg_rgb, has_next)
# IMPORTANT: no reset before separator; reset only after.
seg() {
  local text="$1"

  local bg_r="$2" bg_g="$3" bg_b="$4"
  local fg_r="$5" fg_g="$6" fg_b="$7"

  local next_r="$8" next_g="$9" next_b="${10}"
  local has_next="${11}"   # "1" or "0"

  # body (NO reset here)
  printf '%s%s %s ' \
    "$(bg_true "$bg_r" "$bg_g" "$bg_b")" \
    "$(fg_true "$fg_r" "$fg_g" "$fg_b")" \
    "$text"

  # separator
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

# ---------------- Git info (with cache for performance) ----------------
CACHE_FILE="/tmp/claude-statusline-git-cache"
CACHE_MAX_AGE=5

has_git=false
branch=""
hash=""
remote=""
remote_name=""

if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
    has_git=true
    refresh=false
    if [ ! -f "$CACHE_FILE" ]; then
        refresh=true
    elif [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]; then
        refresh=true
    fi

    if $refresh; then
        _branch=$(git -C "$current_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
        _hash=$(git -C "$current_dir" rev-parse --short=7 HEAD 2>/dev/null)
        _remote=$(git -C "$current_dir" rev-parse --verify "${_branch}@{upstream}" --symbolic-full-name --abbrev-ref 2>/dev/null)
        printf '%s|%s|%s\n' "$_branch" "$_hash" "$_remote" > "$CACHE_FILE"
    fi

    IFS='|' read -r branch hash remote < "$CACHE_FILE"
    if [ -n "$remote" ]; then
        remote_name="${remote%%/${branch}}"
    fi
fi

# ---------------- Segment texts ----------------
seg_user_txt="$username"
seg_dir_txt="$short_dir"

# Token segment: colorize gauge only, then revert to TOK text fg
TOK_FG_ON="$(fg_true "$TOK_FG_R" "$TOK_FG_G" "$TOK_FG_B")"
seg_tok_txt="${model_name} ${GAUGE_ON}${gauge}${TOK_FG_ON}${pct}% ⇡${input_fmt} ⇣${output_fmt} ${cost_fmt}"

# Git segment plain
seg_git_txt=""
if $has_git; then
  if [ -n "$remote_name" ]; then
    seg_git_txt="${branch} ⇡${remote_name} [${hash}]"
  else
    seg_git_txt="${branch} [${hash}]"
  fi
fi

# ---------------- Build output (USER -> DIR -> GIT -> TOK) ----------------
out=""

if $has_git; then
  out+=$(seg "$seg_user_txt" \
    "$USER_BG_R" "$USER_BG_G" "$USER_BG_B" \
    "$USER_FG_R" "$USER_FG_G" "$USER_FG_B" \
    "$DIR_BG_R"  "$DIR_BG_G"  "$DIR_BG_B"  1)

  out+=$(seg "$seg_dir_txt" \
    "$DIR_BG_R" "$DIR_BG_G" "$DIR_BG_B" \
    "$DIR_FG_R" "$DIR_FG_G" "$DIR_FG_B" \
    "$GIT_BG_R" "$GIT_BG_G" "$GIT_BG_B"  1)

  out+=$(seg "$seg_git_txt" \
    "$GIT_BG_R" "$GIT_BG_G" "$GIT_BG_B" \
    "$GIT_FG_R" "$GIT_FG_G" "$GIT_FG_B" \
    "$TOK_BG_R" "$TOK_BG_G" "$TOK_BG_B"  1)

  out+=$(seg "$seg_tok_txt" \
    "$TOK_BG_R" "$TOK_BG_G" "$TOK_BG_B" \
    "$TOK_FG_R" "$TOK_FG_G" "$TOK_FG_B" \
    0 0 0 0)
else
  out+=$(seg "$seg_user_txt" \
    "$USER_BG_R" "$USER_BG_G" "$USER_BG_B" \
    "$USER_FG_R" "$USER_FG_G" "$USER_FG_B" \
    "$DIR_BG_R"  "$DIR_BG_G"  "$DIR_BG_B"  1)

  out+=$(seg "$seg_dir_txt" \
    "$DIR_BG_R" "$DIR_BG_G" "$DIR_BG_B" \
    "$DIR_FG_R" "$DIR_FG_G" "$DIR_FG_B" \
    "$TOK_BG_R" "$TOK_BG_G" "$TOK_BG_B"  1)

  out+=$(seg "$seg_tok_txt" \
    "$TOK_BG_R" "$TOK_BG_G" "$TOK_BG_B" \
    "$TOK_FG_R" "$TOK_FG_G" "$TOK_FG_B" \
    0 0 0 0)
fi

printf '%s%s\n' "$out" "$reset"
