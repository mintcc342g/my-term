#!/bin/bash
# lib/lang/lang.sh — i18n 카탈로그 로더 + 헬퍼 (bash 3.2 안전 · 연관 배열 미사용)
#
# 카탈로그는 스칼라 L_* 변수 + 멀티라인용 lang_*() 함수로 구성된다. en.sh / ko.sh
# 가 동일한 키 집합을 정의하며, lang_load 가 한 번에 하나만 source 한다. 색상(UI_*)
# 은 ui.sh 에서 먼저 정의된 뒤 카탈로그를 source 하므로 즉시 확장된다.
#
# ui.sh 가 자기 위치 기준으로 이 파일을 source 하고 기본 언어(en)를 로드한다.
# install.sh 는 시작 시 ui_select_language 로 사용자 선택값을 다시 로드한다.

# 이 파일이 있는 디렉토리 (repo 와 배포본 ~/.claude/my-hud/lib/lang 양쪽에서 동작).
_LANG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# lang_load <code> — en.sh 또는 ko.sh 를 source. 알 수 없는 값은 en 으로 폴백.
# MYTERM_LANG 은 export 하지 않는다 — 자식 프로세스(configure.sh 등)는 기본 en.
lang_load() {
  local code="${1:-en}"
  case "$code" in
    en|ko) ;;
    *) code="en" ;;
  esac
  if [ -f "$_LANG_DIR/${code}.sh" ]; then
    # shellcheck disable=SC1090
    source "$_LANG_DIR/${code}.sh"
    MYTERM_LANG="$code"
    _MYTERM_LANG_LOADED=1
  fi
}

# tf <KEY> [args...] — 파라미터 있는 단일행 문구를 printf. 간접확장(${!1})은
# bash 3.2 에서 동작. 포맷은 카탈로그(신뢰 입력)에서만 온다.
tf() {
  local _fmt="${!1:-}"
  shift
  printf "$_fmt" "$@"
}

# ui_select_language — 의도적으로 이중언어인 단 하나의 화면. 선택값으로 카탈로그를
# 로드한다. 취소(q/esc)면 현재 기본값(en) 유지.
ui_select_language() {
  local _sel=""
  ui_menu "Language / 언어 선택" _sel "English" "한국어"
  case "$_sel" in
    0) lang_load en ;;
    1) lang_load ko ;;
    *) : ;;
  esac
}
