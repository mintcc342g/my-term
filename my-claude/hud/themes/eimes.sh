#!/bin/bash
# Theme: eimes — Nord8 blue → Nord15 pink

GRAD_START_R=136; GRAD_START_G=192; GRAD_START_B=208
GRAD_END_R=180;   GRAD_END_G=142;   GRAD_END_B=173

TITLE_BG_R=136; TITLE_BG_G=192; TITLE_BG_B=208
TITLE_FG_R=46;  TITLE_FG_G=52;  TITLE_FG_B=64
USER_BG_R=180;  USER_BG_G=142;  USER_BG_B=173
USER_FG_R=46;   USER_FG_G=52;   USER_FG_B=64

DECO_BEFORE=""
DECO_ICON="··✧★"
DECO_AFTER=""
DECO_FMT=" %s "
DECO_LEN=6
DECO_USE_GRAD=0
DECO_COLOR="$(fg 180 142 173)"

HI="$(fg 136 192 208)"
HI2="$(fg 136 192 208)"
LB="$(fg 136 192 208)"
FD="$(fg 76 86 106)"
BOFF="$(fg 59 66 82)"
C_WARN="$(fg 180 142 173)"
C_CRIT="$(fg 220 140 170)"
C_BAR="$(fg 136 192 208)"

# Compact powerline segment colors (bg R G B, fg R G B)
COMPACT_FG="$(fg 236 239 244)"  # Nord6 — bright
COMPACT_SEP="$(fg 236 239 244)"  # Nord6 — bright separator
CSEG1_BG=(136 192 208);  CSEG1_FG=(46 52 64)      # dir — Nord8 bg
CSEG2_BG=(180 142 173);  CSEG2_FG=(46 52 64)      # branch — Nord15 bg
CSEG3_BG=(76 86 106);    CSEG3_FG=(180 142 173)   # model — Nord3 bg
CSEG4_BG=(46 52 64);     CSEG4_FG=(136 192 208)   # 5H — Nord0 bg
