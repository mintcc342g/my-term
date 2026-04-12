#!/bin/bash
# render-compact.sh — compact powerline-style 1-line HUD renderer
# source'd by statusline.sh — requires render.sh + theme already loaded
#
# Powerlevel10k style:  my-term  main  Opus 4.6  5H:56%

PL_SEP=$'\xee\x82\xb0'  # U+E0B0 powerline right triangle
TERM_BG_R=46; TERM_BG_G=52; TERM_BG_B=64  # Nord0

# Print a powerline segment:  text
# _pl_seg "text" bg_r bg_g bg_b fg_r fg_g fg_b next_bg_r next_bg_g next_bg_b
_pl_seg() {
  local text="$1"
  local br="$2" bgc="$3" bb="$4"
  local fr="$5" fgc="$6" fb="$7"
  local nr="$8" ngc="$9" nb="${10}"

  printf '%s%s %s %s%s%s' \
    "$(bg $br $bgc $bb)$(fg $fr $fgc $fb)" \
    "" "$text" "" \
    "$(fg $br $bgc $bb)$(bg $nr $ngc $nb)" \
    "$PL_SEP"
}

# Last segment (transitions to terminal bg)
_pl_seg_last() {
  local text="$1"
  local br="$2" bgc="$3" bb="$4"
  local fr="$5" fgc="$6" fb="$7"

  printf '%s%s %s %s%s%s%s' \
    "$(bg $br $bgc $bb)$(fg $fr $fgc $fb)" \
    "" "$text" "" \
    "$(fg $br $bgc $bb)$(bg $TERM_BG_R $TERM_BG_G $TERM_BG_B)" \
    "$PL_SEP" "$rst"
}

render_compact() {
  local cwd="$1" git_branch="$2" model="$3" rl_5h="$4"

  # Compact dir: current dir name only
  local compact_dir
  compact_dir=$(basename "$cwd")
  [ "$compact_dir" = "~" ] && compact_dir="~"

  # Calculate total visible width to decide what to show
  # Each segment: 1(space) + text + 1(space) + 1(separator) = text+3
  local dir_len=$(( ${#compact_dir} + 3 ))
  local branch_len=0
  [ -n "$git_branch" ] && branch_len=$(( ${#git_branch} + 3 ))
  local model_len=$(( ${#model} + 3 ))
  local rl_text="5H:${rl_5h}%"
  local rl_len=$(( ${#rl_text} + 3 ))

  local total=$(( dir_len + branch_len + model_len + rl_len ))

  # Progressive truncation
  if [ "$total" -gt "$OW" ]; then
    # Drop model
    model=""
    model_len=0
    total=$(( dir_len + branch_len + rl_len ))
  fi
  if [ "$total" -gt "$OW" ] && [ -n "$git_branch" ]; then
    # Truncate branch
    local avail=$(( OW - dir_len - rl_len - 3 ))
    if [ "$avail" -lt 4 ]; then
      git_branch=""
      branch_len=0
    else
      git_branch="${git_branch:0:$avail}.."
      branch_len=$(( ${#git_branch} + 3 ))
    fi
    total=$(( dir_len + branch_len + rl_len ))
  fi

  # Render segments
  if [ -n "$git_branch" ] && [ -n "$model" ]; then
    # 4 segments: dir → branch → model → 5H
    _pl_seg "$compact_dir" "${CSEG1_BG[@]}" "${CSEG1_FG[@]}" "${CSEG2_BG[@]}"
    _pl_seg "$git_branch" "${CSEG2_BG[@]}" "${CSEG2_FG[@]}" "${CSEG3_BG[@]}"
    _pl_seg "$model" "${CSEG3_BG[@]}" "${CSEG3_FG[@]}" "${CSEG4_BG[@]}"
    _pl_seg_last "$rl_text" "${CSEG4_BG[@]}" "${CSEG4_FG[@]}"
  elif [ -n "$git_branch" ]; then
    # 3 segments: dir → branch → 5H
    _pl_seg "$compact_dir" "${CSEG1_BG[@]}" "${CSEG1_FG[@]}" "${CSEG2_BG[@]}"
    _pl_seg "$git_branch" "${CSEG2_BG[@]}" "${CSEG2_FG[@]}" "${CSEG4_BG[@]}"
    _pl_seg_last "$rl_text" "${CSEG4_BG[@]}" "${CSEG4_FG[@]}"
  else
    # 2 segments: dir → 5H
    _pl_seg "$compact_dir" "${CSEG1_BG[@]}" "${CSEG1_FG[@]}" "${CSEG4_BG[@]}"
    _pl_seg_last "$rl_text" "${CSEG4_BG[@]}" "${CSEG4_FG[@]}"
  fi
  printf '\n'
}
