#!/bin/bash
# Theme: Ave Mujica — dark crimson → muted white

GRAD_START_R=85;  GRAD_START_G=12;  GRAD_START_B=30
GRAD_END_R=190;   GRAD_END_G=185;   GRAD_END_B=185

TITLE_BG_R=85;  TITLE_BG_G=12;  TITLE_BG_B=30
TITLE_FG_R=190; TITLE_FG_G=185; TITLE_FG_B=185
USER_BG_R=190;  USER_BG_G=185;  USER_BG_B=185
USER_FG_R=85;   USER_FG_G=12;   USER_FG_B=30

DECO_BEFORE=""
DECO_ICON=$'\xef\x86\x86'  # crescent moon
DECO_AFTER=""
DECO_FMT=" %s "
DECO_LEN=3
DECO_USE_GRAD=1

HI="$(fg 200 178 180)"
HI2="$(fg 200 178 180)"
LB="$(fg 200 178 180)"
FD="$(fg 105 50 62)"
BOFF="$(fg 50 45 48)"
C_WARN="$(fg 150 80 95)"
C_CRIT="$(fg 170 35 50)"
C_BAR="$(fg 138 55 68)"

# Compact powerline segment colors (bg R G B, fg R G B)
COMPACT_FG="$(fg 236 239 244)"  # bright white
COMPACT_SEP="$(fg 200 195 195)"  # muted warm white separator
CSEG1_BG=(85 12 30);     CSEG1_FG=(200 178 180)   # dir — crimson bg
CSEG2_BG=(105 50 62);    CSEG2_FG=(200 178 180)   # branch — dark wine bg
CSEG3_BG=(60 45 50);     CSEG3_FG=(155 100 115)   # model — dark bg
CSEG4_BG=(46 52 64);     CSEG4_FG=(138 55 68)     # 5H — Nord0 bg
