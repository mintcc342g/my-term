#!/bin/bash
# render.sh — SF-HUD bordered rendering engine
# source'd by statusline.sh after theme is loaded

# ── ANSI helpers ────────────────────────────────────────────────
fg() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
bg() { printf '\033[48;2;%d;%d;%dm' "$1" "$2" "$3"; }
rst=$'\033[0m'
bold=$'\033[1m'

BG="$(bg 46 52 64)"  # Nord0

# ── Nerd Font icons ─────────────────────────────────────────────
ICON_DIR=$'\xef\x81\xbc'       # U+F07C folder open
ICON_GIT=$'\xee\x82\xa0'       # U+E0A0 git branch
ICON_SESS=$'\xef\x80\x97'      # U+F017 clock

# ── Gradient ────────────────────────────────────────────────────
grad_fg() {
  local pos=$1 max=$2
  [ "$max" -lt 1 ] && max=1
  local r=$(( GRAD_START_R + (GRAD_END_R - GRAD_START_R) * pos / max ))
  local g=$(( GRAD_START_G + (GRAD_END_G - GRAD_START_G) * pos / max ))
  local b=$(( GRAD_START_B + (GRAD_END_B - GRAD_START_B) * pos / max ))
  fg "$r" "$g" "$b"
}

# ── Bar builder ─────────────────────────────────────────────────
bar() {
  local pct=$1 w=$2
  local filled=$(( pct * w / 100 ))
  [ "$filled" -lt 0 ] && filled=0
  [ "$filled" -gt "$w" ] && filled=$w
  local empty=$(( w - filled ))
  local color
  if [ "$pct" -ge 80 ]; then color="$C_CRIT"
  elif [ "$pct" -ge 50 ]; then color="$C_WARN"
  else color="$C_BAR"
  fi
  printf '%s' "$color"
  for ((i=0; i<filled; i++)); do printf '▰'; done
  printf '%s' "$BOFF"
  for ((i=0; i<empty; i++)); do printf '▱'; done
  printf '%s' "$rst$BG"
}

sev_color() {
  local pct=$1
  if [ "$pct" -ge 80 ]; then printf '%s' "$C_CRIT"
  elif [ "$pct" -ge 50 ]; then printf '%s' "$C_WARN"
  else printf '%s' "$HI"
  fi
}

# ── Row builder ─────────────────────────────────────────────────
row() {
  local content="$1" vw=$2
  local pad=$(( IW - vw ))
  [ "$pad" -lt 0 ] && pad=0
  printf '%s│%s%s%*s%s│%s\n' \
    "$(grad_fg 0 $OW)" "$rst$BG" "$content" "$pad" "" \
    "$(grad_fg $((OW-1)) $OW)" "$rst"
}

# ── Separator ───────────────────────────────────────────────────
sep_line() {
  local label=" $1 "
  local label_len=${#label}
  printf '%s├' "$(grad_fg 0 $OW)"
  printf '%s─' "$(grad_fg 1 $OW)"
  local lc="${2:-$FD}"
  printf '%s%s%s' "$lc" "$label" "$rst"
  local fill_start=$(( 2 + label_len ))
  local fill_count=$(( OW - 1 - fill_start ))
  for ((i=0; i<fill_count; i++)); do
    printf '%s─' "$(grad_fg $((fill_start + i)) $OW)"
  done
  printf '%s┤%s\n' "$(grad_fg $((OW-1)) $OW)" "$rst"
}

# ── Top border ──────────────────────────────────────────────────
build_top() {
  local title=" CLAUDE HUD "
  local tl=${#title}

  printf '%s┌' "$(grad_fg 0 $OW)"
  printf '%s─' "$(grad_fg 1 $OW)"
  printf '%s%s%s' "$(bg $TITLE_BG_R $TITLE_BG_G $TITLE_BG_B)$(fg $TITLE_FG_R $TITLE_FG_G $TITLE_FG_B)$bold" "$title" "$rst"

  local pos=$(( 2 + tl ))
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
  local deco_str
  # shellcheck disable=SC2059
  deco_str=$(printf "$DECO_FMT" "$DECO_ICON")
  printf '%s%s%s' "$deco_color" "$deco_str" "$rst"

  printf '%s─' "$(grad_fg $((OW-2)) $OW)"
  printf '%s┐%s\n' "$(grad_fg $((OW-1)) $OW)" "$rst"
}

# ── Bottom border ───────────────────────────────────────────────
build_bottom() {
  local user
  user=$(whoami)
  local label=" ${user} "
  local ll=${#label}
  local fill=$(( OW - ll - 3 ))
  [ "$fill" -lt 0 ] && fill=0

  printf '%s└' "$(grad_fg 0 $OW)"
  for ((i=0; i<fill; i++)); do
    printf '%s─' "$(grad_fg $((1 + i)) $OW)"
  done
  printf '%s%s%s' "$(bg $USER_BG_R $USER_BG_G $USER_BG_B)$(fg $USER_FG_R $USER_FG_G $USER_FG_B)$bold" "$label" "$rst"
  local pos=$(( 1 + fill + 1 + ll ))
  printf '%s─' "$(grad_fg $((pos+1)) $OW)"
  printf '%s┘%s\n' "$(grad_fg $((OW-1)) $OW)" "$rst"
}

# ── Metric row builders ─────────────────────────────────────────
metric_row() {
  local label="$1" pct=$2
  local pct_str sc
  pct_str=$(printf "%3d%%" "$pct")
  sc=$(sev_color "$pct")
  local content=" ${LB}${bold}${label}${rst}${BG} $(bar "$pct" "$BW")${rst}${BG}  ${sc}${pct_str}${rst}${BG}"
  local vw=$(( 1 + ${#label} + 1 + BW + 2 + ${#pct_str} ))
  row "$content" "$vw"
}

metric_row_inv() {
  local label="$1" pct=$2
  local pct_str sc bar_color
  [[ "$pct" =~ ^[0-9]+$ ]] || pct=0
  pct_str=$(printf "%3d%%" "$pct")
  if [ "$pct" -le 10 ]; then
    sc="$C_CRIT"; bar_color="$C_CRIT"
  elif [ "$pct" -le 50 ]; then
    sc="$C_WARN"; bar_color="$C_WARN"
  else
    sc="$HI"; bar_color="$C_BAR"
  fi
  local filled=$(( pct * BW / 100 ))
  [ "$filled" -lt 0 ] && filled=0
  [ "$filled" -gt "$BW" ] && filled=$BW
  local empty=$(( BW - filled ))
  local bar_out="${bar_color}"
  for ((i=0; i<filled; i++)); do bar_out+='▰'; done
  bar_out+="${BOFF}"
  for ((i=0; i<empty; i++)); do bar_out+='▱'; done
  local content=" ${LB}${bold}${label}${rst}${BG} ${bar_out}${rst}${BG}  ${sc}${pct_str}${rst}${BG}"
  local vw=$(( 1 + ${#label} + 1 + BW + 2 + ${#pct_str} ))
  row "$content" "$vw"
}

# ── Section renderers ───────────────────────────────────────────
render_workspace() {
  local cwd="$1" git_branch="$2"
  local MAX_OW=$(( OW * 13 / 10 ))
  [ "$MAX_OW" -gt "$TERM_WIDTH" ] && MAX_OW=$TERM_WIDTH

  # workspace row: icon(2) + cwd + spacing(2) + sep(1) + spacing(1) + icon(2) + branch
  local ws_vw=$(( 2 + ${#cwd} + 2 + 1 + 1 + 2 + ${#git_branch} ))

  # Try expanding OW if content is wider
  if [ "$ws_vw" -gt "$((OW - 2))" ] && [ "$OW" -lt "$MAX_OW" ]; then
    local needed=$((ws_vw + 2))
    if [ "$needed" -le "$MAX_OW" ]; then
      OW=$needed
    else
      OW=$MAX_OW
    fi
    IW=$((OW - 2))
  fi

  # If still too wide, truncate branch first (to 7+…)
  if [ "$ws_vw" -gt "$IW" ] && [ ${#git_branch} -gt 8 ]; then
    git_branch="${git_branch:0:7}…"
    ws_vw=$(( 2 + ${#cwd} + 2 + 1 + 1 + 2 + ${#git_branch} ))
  fi

  # If still too wide, truncate dir to current dir only
  if [ "$ws_vw" -gt "$IW" ]; then
    cwd=$(basename "$cwd")
    ws_vw=$(( 2 + ${#cwd} + 2 + 1 + 1 + 2 + ${#git_branch} ))
  fi

  # If STILL too wide (current dir itself is long), truncate dir with …
  if [ "$ws_vw" -gt "$IW" ]; then
    local avail=$(( IW - 2 - 2 - 1 - 1 - 2 - ${#git_branch} - 1 ))
    [ "$avail" -lt 3 ] && avail=3
    cwd="${cwd:0:$avail}…"
    ws_vw=$(( 2 + ${#cwd} + 2 + 1 + 1 + 2 + ${#git_branch} ))
  fi

  local ws_content="${LB}${bold}${ICON_DIR} ${rst}${BG}${HI2}${cwd}${rst}${BG}  ${FD}│${rst}${BG} ${LB}${bold}${ICON_GIT} ${rst}${BG}${HI2}${git_branch}${rst}${BG}"
  sep_line "workspace"
  row "$ws_content" "$ws_vw"
}

render_claude() {
  local model="$1" sess="$2" cache="$3" rl_5h="$4" rl_wk="$5" ctx="$6"
  local cache_str="${cache}%"
  local cl_content="${LB}${bold}MDL ${rst}${BG}${HI2}${model}${rst}${BG}  ${FD}│${rst}${BG} ${LB}${bold}${ICON_SESS} ${rst}${BG}${HI2}${sess}${rst}${BG}  ${FD}│${rst}${BG} ${LB}${bold}CACHE ${rst}${BG}${HI2}${cache_str}${rst}${BG}"
  local cl_vw=$(( 4 + ${#model} + 2 + 1 + 1 + 2 + ${#sess} + 2 + 1 + 1 + 6 + ${#cache_str} ))
  sep_line "claude"
  row "$cl_content" "$cl_vw"
  metric_row "5H  " "$rl_5h"
  metric_row "WK  " "$rl_wk"
  metric_row "CTX " "$ctx"
}

render_codex() {
  local model="$1" reset="$2" left="$3"
  local cx_content="${LB}${bold}MDL ${rst}${BG}${HI2}${model}${rst}${BG}  ${FD}│${rst}${BG} ${LB}${bold}RESET ${rst}${BG}${HI2}${reset}${rst}${BG}"
  local cx_vw=$(( 4 + ${#model} + 2 + 1 + 1 + 6 + ${#reset} ))
  sep_line "codex"
  row "$cx_content" "$cx_vw"
  metric_row_inv "LEFT" "$left"
}

