#!/bin/bash
# render-compact.sh — compact 1-line HUD with per-char gradient bg
# source'd by statusline.sh — requires render.sh + theme already loaded
#
# Full gradient across entire line. Round caps at start/end.

PL_CAP=$'\xee\x82\xbc'   # U+E0BC — both caps, fg/bg swapped per side

# Print text with per-character gradient bg, fixed bright fg
# Inline gradient calc to avoid per-char subshell fork
_grad_text() {
  local text="$1" spos=$2 tw=$3
  [ "$tw" -lt 1 ] && tw=1
  local i ch pos bgr bgg bgb
  for ((i=0; i<${#text}; i++)); do
    ch="${text:$i:1}"
    pos=$((spos + i))
    [ "$pos" -ge "$tw" ] && pos=$((tw - 1))
    [ "$pos" -lt 0 ] && pos=0
    bgr=$(( GRAD_START_R + (GRAD_END_R - GRAD_START_R) * pos / tw ))
    bgg=$(( GRAD_START_G + (GRAD_END_G - GRAD_START_G) * pos / tw ))
    bgb=$(( GRAD_START_B + (GRAD_END_B - GRAD_START_B) * pos / tw ))
    printf '\033[48;2;%d;%d;%dm%s%s' "$bgr" "$bgg" "$bgb" "${COMPACT_FG}" "$ch"
  done
}


render_compact() {
  local cwd="$1" git_branch="$2" model="$3" rl_5h="$4"

  # Dir: …/current_dir
  local dir_name
  dir_name=$(basename "$cwd")
  [ "$dir_name" = "~" ] && dir_name="~"
  local compact_dir="…/${dir_name}"
  [ "$cwd" = "$HOME" ] || [ "$cwd" = "~" ] && compact_dir="~"

  # Branch: max 7 chars
  if [ -n "$git_branch" ] && [ ${#git_branch} -gt 7 ]; then
    git_branch="${git_branch:0:7}…"
  fi

  # Model: keep up to version number (e.g. "Opus 4.6..")
  if [ -n "$model" ]; then
    local short_model
    short_model=$(printf '%s' "$model" | sed -E 's/^([A-Za-z]+ [0-9]+\.[0-9]+).*/\1…/')
    # If sed didn't shorten it, keep original
    [ ${#short_model} -lt ${#model} ] && model="$short_model"
  fi

  # Build segment texts with padding spaces
  local -a segs
  segs+=(" ${compact_dir} ")
  [ -n "$git_branch" ] && segs+=(" ${git_branch} ")
  [ -n "$model" ] && segs+=(" ${model} ")
  segs+=(" 5H:${rl_5h}% ")

  # Calculate total width (+2 for caps, +1 per separator between segments)
  local total_w=2 count=${#segs[@]}
  for ((s=0; s<count; s++)); do
    total_w=$(( total_w + ${#segs[$s]} ))
  done
  total_w=$(( total_w + count - 1 ))  # separators

  # Progressive truncation
  if [ "$total_w" -gt "$OW" ] && [ -n "$model" ]; then
    local new_segs=(" ${compact_dir} ")
    [ -n "$git_branch" ] && new_segs+=(" ${git_branch} ")
    new_segs+=(" 5H:${rl_5h}% ")
    segs=("${new_segs[@]}")
    count=${#segs[@]}
    total_w=2
    for ((s=0; s<count; s++)); do
      total_w=$(( total_w + ${#segs[$s]} ))
    done
    total_w=$(( total_w + count - 1 ))
  fi
  if [ "$total_w" -gt "$OW" ] && [ "$count" -gt 2 ]; then
    segs=(" ${compact_dir} " " 5H:${rl_5h}% ")
    count=2
    total_w=2
    for ((s=0; s<count; s++)); do
      total_w=$(( total_w + ${#segs[$s]} ))
    done
    total_w=$(( total_w + count - 1 ))
  fi

  # Left cap: bg=segment, fg=terminal (E0BC diagonal: dark top-left corner)
  printf '\033[48;2;%d;%d;%dm\033[38;2;46;52;64m%s' "$GRAD_START_R" "$GRAD_START_G" "$GRAD_START_B" "$PL_CAP"

  # Render segments with ∣ separator between them
  local cursor=0
  local sep=$'\xe2\x88\xa3'  # U+2223
  for ((s=0; s<count; s++)); do
    local seg="${segs[$s]}"
    local seg_len=${#seg}
    _grad_text "$seg" "$cursor" "$total_w"
    cursor=$((cursor + seg_len))
    # Add separator between segments (not after last)
    if [ $((s + 1)) -lt "$count" ]; then
      local spos=$cursor
      [ "$spos" -ge "$total_w" ] && spos=$((total_w - 1))
      local sbgr=$(( GRAD_START_R + (GRAD_END_R - GRAD_START_R) * spos / total_w ))
      local sbgg=$(( GRAD_START_G + (GRAD_END_G - GRAD_START_G) * spos / total_w ))
      local sbgb=$(( GRAD_START_B + (GRAD_END_B - GRAD_START_B) * spos / total_w ))
      printf '\033[48;2;%d;%d;%dm%s%s' "$sbgr" "$sbgg" "$sbgb" "${COMPACT_SEP}" "$sep"
      cursor=$((cursor + 1))
    fi
  done

  # Right cap: fg=segment at last char position, bg=terminal
  local rpos=$((cursor - 1))
  [ "$rpos" -lt 0 ] && rpos=0
  [ "$rpos" -ge "$total_w" ] && rpos=$((total_w - 1))
  local last_bgr=$(( GRAD_START_R + (GRAD_END_R - GRAD_START_R) * rpos / total_w ))
  local last_bgg=$(( GRAD_START_G + (GRAD_END_G - GRAD_START_G) * rpos / total_w ))
  local last_bgb=$(( GRAD_START_B + (GRAD_END_B - GRAD_START_B) * rpos / total_w ))
  printf '\033[38;2;%d;%d;%dm\033[48;2;46;52;64m%s%s\n' "$last_bgr" "$last_bgg" "$last_bgb" "$PL_CAP" "$rst"
}
