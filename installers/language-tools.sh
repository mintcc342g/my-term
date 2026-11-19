#!/bin/bash
# installers/language-tools.sh — choose asdf plugins and pyenv together

install_language_tools() {
  if ! command -v brew &>/dev/null; then
    ui_log_skipping_dep "$L_STEP_LANGUAGE_TOOLS" Homebrew
    return 0
  fi

  local choice=""
  local -a UI_CHECKLIST_CATEGORIES=("asdf" "pyenv")
  local -a UI_CHECKLIST_LABELS=("Golang" "Java" "pyenv + pyenv-virtualenv")
  local -a UI_CHECKLIST_GROUPS=(0 0 1) UI_CHECKLIST_SELECTED=()
  local -a UI_CHECKLIST_NO_ALL=([1]=1)

  ui_checklist "$L_STEP_LANGUAGE_TOOLS" choice
  echo
  if [ "$choice" != install ]; then
    ui_log_skipped "$L_STEP_LANGUAGE_TOOLS"
    return 0
  fi

  local -a asdf_languages=()
  if [ "${UI_CHECKLIST_SELECTED[0]}" -eq 1 ]; then asdf_languages+=(golang); fi
  if [ "${UI_CHECKLIST_SELECTED[1]}" -eq 1 ]; then asdf_languages+=(java); fi
  if [ "${#asdf_languages[@]}" -gt 0 ]; then
    install_asdf_langs "${asdf_languages[@]}"
  fi

  if [ "${UI_CHECKLIST_SELECTED[2]}" -eq 1 ]; then
    install_pyenv
  fi

  if [ "${#asdf_languages[@]}" -gt 0 ]; then
    lang_asdf_note
    printf '\n'
  fi
  sleep "$UI_SKIP_PAUSE"
}
