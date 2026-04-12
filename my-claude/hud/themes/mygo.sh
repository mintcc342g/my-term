#!/bin/bash
# Theme: mygo — Nord10 deep blue → Nord4 light gray

GRAD_START_R=94;  GRAD_START_G=129; GRAD_START_B=172
GRAD_END_R=216;   GRAD_END_G=222;   GRAD_END_B=233

TITLE_BG_R=94;  TITLE_BG_G=129; TITLE_BG_B=172
TITLE_FG_R=216; TITLE_FG_G=222; TITLE_FG_B=233
USER_BG_R=216;  USER_BG_G=222;  USER_BG_B=233
USER_FG_R=46;   USER_FG_G=52;   USER_FG_B=64

DECO_BEFORE=""
DECO_ICON=$'\xef\x84\xa4'  # location-arrow
DECO_AFTER=""
DECO_FMT="(%s)"
DECO_LEN=3
DECO_USE_GRAD=1

HI="$(fg 155 176 202)"
HI2="$(fg 155 176 202)"
LB="$(fg 155 176 202)"
FD="$(fg 76 86 106)"
BOFF="$(fg 59 66 82)"
C_WARN="$(fg 140 170 210)"
C_CRIT="$(fg 216 222 233)"
C_BAR="$(fg 94 129 172)"

# Compact powerline segment colors (bg R G B, fg R G B)
CSEG1_BG=(94 129 172);   CSEG1_FG=(216 222 233)   # dir — Nord10 bg
CSEG2_BG=(76 86 106);    CSEG2_FG=(216 222 233)   # branch — Nord3 bg
CSEG3_BG=(59 66 82);     CSEG3_FG=(155 176 202)   # model — Nord1 bg
CSEG4_BG=(46 52 64);     CSEG4_FG=(155 176 202)   # 5H — Nord0 bg
