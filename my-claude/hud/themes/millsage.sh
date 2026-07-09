#!/bin/bash
# Theme: millsage — gray(#969FB0) → light gray gradient

GRAD_START_R=199; GRAD_START_G=205; GRAD_START_B=215
GRAD_END_R=246;   GRAD_END_G=248;   GRAD_END_B=251

TITLE_BG_R=199;  TITLE_BG_G=205;  TITLE_BG_B=215
TITLE_FG_R=46;   TITLE_FG_G=52;   TITLE_FG_B=64
USER_BG_R=246;   USER_BG_G=248;   USER_BG_B=251
USER_FG_R=46;    USER_FG_G=52;    USER_FG_B=64

DECO_BEFORE=""
DECO_ICON="❉"  # 불꽃(hanabi)
DECO_AFTER=""
DECO_FMT=" %s "
DECO_LEN=3
DECO_USE_GRAD=1

HI="$(fg 199 205 215)"
HI2="$(fg 199 205 215)"
LB="$(fg 199 205 215)"
FD="$(fg 76 86 106)"
BOFF="$(fg 59 66 82)"
C_WARN="$(fg 190 168 230)"   # gauge warn — 연한 보라 (pale lavender)
C_CRIT="$(fg 150 112 208)"   # gauge crit — 라벤더(살짝 진하게)
C_BAR="$(fg 199 205 215)"

# Per-icon colors — 전부 일반색(LB 회색)
C_ICON_DIR="$LB"
C_ICON_GIT="$LB"
C_ICON_EFFORT="$LB"
C_ICON_RESET="$LB"
C_ICON_RESET_5H="$LB"
C_ICON_RESET_WK="$LB"
C_ICON_SESS="$LB"
C_ICON_UPSTREAM="$LB"

C_SEP="$LB"                          # 기본 구분선 — 회색 (codex 등)
C_SEP_WS="$(fg 255 244 151)"         # workspace dir│branch — 로고에 숨어있던 6번째 색(노랑)

# claude 섹션 구분자 — 멤버색 (위→아래: 호타루·호카·나츠메·마호로·나기)
C_SEP_CL_EFFORT="$(fg 191 97 106)"   # MDL│effort — 빨강 (나츠메)
C_SEP_CL_CACHE="$(fg 163 190 140)"   # effort│CACHE — 초록 (호타루)
C_SEP_CL_5H="$(fg 180 142 173)"      # 5H │↻ — 보라 (호카)
C_SEP_CL_WK="$(fg 136 192 208)"      # WK │↻ — 시안 (마호로)
C_SEP_CL_CTX="$(fg 94 129 172)"      # CTX │시계 — 파랑 (나기)

# Compact powerline segment colors (bg R G B, fg R G B)
COMPACT_FG="$(fg 46 52 64)"      # compact 글자색 = 제목/유저 기존 색(Nord0)
COMPACT_SEP="$(fg 128 138 155)"  # 진한 회색 separator
CSEG1_BG=(216 222 233);  CSEG1_FG=(46 52 64)      # dir — Nord4 bg
CSEG2_BG=(76 86 106);    CSEG2_FG=(216 222 233)   # branch — Nord3 bg
CSEG3_BG=(59 66 82);     CSEG3_FG=(216 222 233)   # model — Nord1 bg
CSEG4_BG=(46 52 64);     CSEG4_FG=(216 222 233)   # 5H — Nord0 bg
