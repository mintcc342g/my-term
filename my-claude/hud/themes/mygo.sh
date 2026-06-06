#!/bin/bash
# Theme: mygo — MyGO 로고 블루(#549DC2) → Nord4 light gray

GRAD_START_R=103;  GRAD_START_G=168; GRAD_START_B=201
GRAD_END_R=216;   GRAD_END_G=222;   GRAD_END_B=233

TITLE_BG_R=103;  TITLE_BG_G=168; TITLE_BG_B=201
TITLE_FG_R=46;  TITLE_FG_G=52;  TITLE_FG_B=64
USER_BG_R=216;  USER_BG_G=222;  USER_BG_B=233
USER_FG_R=46;   USER_FG_G=52;   USER_FG_B=64

DECO_BEFORE=""
DECO_ICON=$'\xef\x84\xa4'  # location-arrow
DECO_AFTER=""
DECO_FMT="(%s)"
DECO_LEN=3
DECO_USE_GRAD=1

HI="$(fg 103 168 201)"
HI2="$(fg 103 168 201)"
LB="$(fg 103 168 201)"
FD="$(fg 76 86 106)"
BOFF="$(fg 59 66 82)"
C_WARN="$(fg 250 250 186)"
C_CRIT="$(fg 255 240 60)"
C_BAR="$(fg 103 168 201)"

# Per-icon colors — each theme owns these (currently LB except where customized)
C_ICON_DIR="$LB"
C_ICON_GIT="$LB"
C_ICON_EFFORT="$LB"
C_ICON_RESET="$LB"
C_ICON_SESS="$LB"
C_ICON_UPSTREAM="$LB"

C_SEP="$(fg 255 255 136)"

# Compact powerline segment colors (bg R G B, fg R G B)
COMPACT_FG="$(fg 236 239 244)"  # Nord6 — bright
COMPACT_SEP="$(fg 216 222 233)"  # Nord4 — light separator
CSEG1_BG=(94 129 172);   CSEG1_FG=(216 222 233)   # dir — Nord10 bg
CSEG2_BG=(76 86 106);    CSEG2_FG=(216 222 233)   # branch — Nord3 bg
CSEG3_BG=(59 66 82);     CSEG3_FG=(155 176 202)   # model — Nord1 bg
CSEG4_BG=(46 52 64);     CSEG4_FG=(155 176 202)   # 5H — Nord0 bg
