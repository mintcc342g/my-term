#!/bin/bash
# render-compact.sh — compact 1-line HUD with per-char gradient bg
# source'd by statusline.sh — requires render.sh + theme already loaded
#
# Full gradient across entire line. Round caps at start/end.

PL_LEFT=$'\xee\x82\xba'   # U+E0BA lower right triangle (left cap)
PL_RIGHT=$'\xee\x82\xbc'  # U+E0BC upper left triangle (right cap)

# Get gradient color at position
_grad_at() {
  local pos=$1 max=$2
  [ "$max" -lt 1 ] && max=1
  [ "$pos" -ge "$max" ] && pos=$((max - 1))
  [ "$pos" -lt 0 ] && pos=0
  local r=$(( GRAD_START_R + (GRAD_END_R - GRAD_START_R) * pos / max ))
  local g=$(( GRAD_START_G + (GRAD_END_G - GRAD_START_G) * pos / max ))
  local b=$(( GRAD_START_B + (GRAD_END_B - GRAD_START_B) * pos / max ))
  echo "$r $g $b"
}

# Print text with per-character gradient bg, fixed fg from theme
_grad_text() {
  local text="$1" spos=$2 tw=$3
  local i ch
  for ((i=0; i<${#text}; i++)); do
    ch="${text:$i:1}"
    read -r bgr bgg bgb <<< "$(_grad_at $((spos + i)) $tw)"
    printf '%s%s' "$(bg $bgr $bgg $bgb)${COMPACT_FG}" "$ch"
  done
}

render_compact() {
  local cwd="$1" git_branch="$2" model="$3" rl_5h="$4"

  # Dir: ../current_dir
  local dir_name
  dir_name=$(basename "$cwd")
  [ "$dir_name" = "~" ] && dir_name="~"
  local compact_dir="../${dir_name}"
  [ "$cwd" = "$HOME" ] || [ "$cwd" = "~" ] && compact_dir="~"

  # Branch: max 7 chars
  if [ -n "$git_branch" ] && [ ${#git_branch} -gt 7 ]; then
    git_branch="${git_branch:0:7}.."
  fi

  # Build segment texts with padding spaces
  local -a segs
  segs+=(" ${compact_dir} ")
  [ -n "$git_branch" ] && segs+=(" ${git_branch} ")
  [ -n "$model" ] && segs+=(" ${model} ")
  segs+=(" 5H:${rl_5h}% ")

  # Calculate total width (+2 for round caps)
  local total_w=2 count=${#segs[@]}
  for ((s=0; s<count; s++)); do
    total_w=$(( total_w + ${#segs[$s]} ))
  done

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
  fi
  if [ "$total_w" -gt "$OW" ] && [ "$count" -gt 2 ]; then
    segs=(" ${compact_dir} " " 5H:${rl_5h}% ")
    count=2
    total_w=2
    for ((s=0; s<count; s++)); do
      total_w=$(( total_w + ${#segs[$s]} ))
    done
  fi

  # Left round cap: fg=first segment grad color, bg=terminal
  read -r first_bgr first_bgg first_bgb <<< "$(_grad_at 0 $OW)"
  printf '%s%s' "$(fg $first_bgr $first_bgg $first_bgb)" "$PL_LEFT"

  # Render segments (content area mapped to positions 1..total_w-1)
  local cursor=1
  for ((s=0; s<count; s++)); do
    local seg="${segs[$s]}"
    local seg_len=${#seg}
    local grad_start=$(( cursor * OW / total_w ))
    _grad_text "$seg" "$grad_start" "$OW"
    printf '%s' "$rst"
    cursor=$((cursor + seg_len))
  done

  # Right round cap: fg=last segment grad color, bg=terminal
  read -r last_bgr last_bgg last_bgb <<< "$(_grad_at $((OW - 1)) $OW)"
  printf '%s%s%s\n' "$(fg $last_bgr $last_bgg $last_bgb)" "$PL_RIGHT" "$rst"
}
