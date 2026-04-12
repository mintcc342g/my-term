#!/bin/bash
# render-compact.sh — compact 1-line HUD renderer
# source'd by statusline.sh — requires render.sh + theme already loaded
#
# ┌──  ~/my-term (main) │ Opus 4.6 │ 5H:56% ── ··✧★ ─┐

render_compact() {
  local cwd="$1" git_branch="$2" model="$3" rl_5h="$4"

  # Build content segments
  local seg1="${ICON_DIR} ${cwd}"
  [ -n "$git_branch" ] && seg1="${seg1} (${git_branch})"
  local seg2="${model}"
  local seg3="5H:${rl_5h}%"
  local content_vw=$(( ${#seg1} + 3 + ${#seg2} + 3 + ${#seg3} ))

  # Truncate if content won't fit: OW - 5 (┌─ ... ─┐) - DECO_LEN
  local max_content=$(( OW - DECO_LEN - 5 ))
  if [ "$content_vw" -gt "$max_content" ]; then
    # Drop model name first
    seg2=""
    content_vw=$(( ${#seg1} + 3 + ${#seg3} ))
    if [ "$content_vw" -gt "$max_content" ]; then
      # Still too long — truncate dir
      local avail=$(( max_content - 3 - ${#seg3} ))
      [ "$avail" -lt 5 ] && avail=5
      seg1="${seg1:0:$avail}.."
      content_vw=$(( ${#seg1} + 3 + ${#seg3} ))
    fi
  fi

  # ┌─ content ──...── deco ─┐
  printf '%s┌' "$(grad_fg 0 $OW)"
  printf '%s─' "$(grad_fg 1 $OW)"
  printf '%s ' "$(grad_fg 2 $OW)"

  # Print segments with separators
  printf '%s%s%s' "${HI2}" "$seg1" "${rst}"
  if [ -n "$seg2" ]; then
    printf ' %s│%s %s%s%s' "${FD}" "${rst}" "${HI2}" "$seg2" "${rst}"
  fi
  printf ' %s│%s %s%s%s' "${FD}" "${rst}" "${HI2}" "$seg3" "${rst}"
  printf ' '

  local pos=$(( 3 + content_vw + 1 ))
  local fill=$(( OW - pos - DECO_LEN - 2 ))
  [ "$fill" -lt 0 ] && fill=0
  for ((i=0; i<fill; i++)); do
    printf '%s─' "$(grad_fg $((pos + i)) $OW)"
  done

  local deco_pos=$(( pos + fill + 1 ))
  local deco_color
  if [ "${DECO_USE_GRAD:-0}" = "1" ]; then
    deco_color="$(grad_fg $deco_pos $OW)"
  else
    deco_color="${DECO_COLOR:-$(grad_fg $deco_pos $OW)}"
  fi
  # shellcheck disable=SC2059
  printf "${deco_color}$(printf "$DECO_FMT" "$DECO_ICON")${rst}"

  printf '%s─' "$(grad_fg $((OW-2)) $OW)"
  printf '%s┐%s\n' "$(grad_fg $((OW-1)) $OW)" "$rst"
}
