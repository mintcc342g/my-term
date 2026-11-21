#!/bin/bash
# Language catalog loader and helpers. Compatible with Bash 3.2 without associative arrays.
#
# Catalogs define L_* strings and lang_* functions for multiline messages.
# Each catalog provides the same keys. lang_load sources one catalog at a time.
# ui.sh defines UI_* colors before loading the catalog so the strings can use them immediately.
#
# ui.sh locates this file relative to itself and loads English by default.
# install.sh calls ui_select_language to load the selected language.

# Resolve this directory in both the repository and the deployed HUD.
_LANG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Supported languages are listed as code, native menu label, and English response language name.
# The order here determines the menu order. To add a language, add a row and its
# catalog. Validation, menu labels, and response language names use this list.
_LANG_TABLE=(
  "ko|한국어|Korean"
  "en|English|English"
  "ja|日本語|Japanese"
)

# lang_is_known <code> returns 0 for supported codes and 1 otherwise.
lang_is_known() {
  local rec
  for rec in "${_LANG_TABLE[@]}"; do
    if [ "${rec%%|*}" = "$1" ]; then
      return 0
    fi
  done
  return 1
}

# lang_load <code> sources the matching catalog and falls back to English for unknown codes.
# MYTERM_LANG stays local to this shell. Child scripts default to English.
lang_load() {
  local code="${1:-en}"
  lang_is_known "$code" || code="en"
  if [ -f "$_LANG_DIR/${code}.sh" ]; then
    # shellcheck disable=SC1090
    source "$_LANG_DIR/${code}.sh"
    MYTERM_LANG="$code"
    _MYTERM_LANG_LOADED=1
  fi
}

# tf <KEY> [args...] formats a one-line catalog message. Bash 3.2 supports indirect
# parameter expansion. Only trusted catalog variables supply format strings.
tf() {
  local _fmt="${!1:-}"
  shift
  printf "$_fmt" "$@"
}

# lang_response_name [code] returns the English language name for the response placeholder.
# Defaults to the current MYTERM_LANG and falls back to English for unknown codes.
lang_response_name() {
  local target="${1:-${MYTERM_LANG:-en}}" rec
  for rec in "${_LANG_TABLE[@]}"; do
    if [ "${rec%%|*}" = "$target" ]; then
      echo "${rec##*|}"
      return 0
    fi
  done
  echo "English"
}

# ui_select_language is a multilingual menu built from the language list.
# It loads the selected language and keeps the current default on cancellation (255).
ui_select_language() {
  local _sel="" rec rest
  local -a codes=() labels=()
  for rec in "${_LANG_TABLE[@]}"; do
    codes+=("${rec%%|*}")
    rest="${rec#*|}"
    labels+=("${rest%%|*}")
  done
  ui_menu "언어 선택 / Language" _sel "${labels[@]}"
  if [ "$_sel" -ge 0 ] 2>/dev/null && [ "$_sel" -lt "${#codes[@]}" ]; then
    lang_load "${codes[$_sel]}"
  fi
}
