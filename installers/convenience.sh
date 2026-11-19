#!/bin/bash
# installers/convenience.sh — CLI tools, macOS apps, DevOps tools
# source'd by install.sh

install_convenience() {
  local -a UI_CHECKLIST_CATEGORIES=(
    "$L_CONVENIENCE_CLI" "$L_CONVENIENCE_APPS"
    "$L_CONVENIENCE_DEVOPS" "$L_CONVENIENCE_MANAGERS"
  )
  # category index | Homebrew package type | package name
  local -a tools=(
    '0|formula|ripgrep' '0|formula|fd' '0|formula|bat'
    '0|formula|television' '0|formula|tree' '0|formula|tmux' '0|formula|telnet'
    '1|cask|maccy' '1|cask|rectangle' '1|cask|macs-fan-control'
    '1|cask|alt-tab' '1|cask|postman' '1|cask|stats' '1|cask|fork'
    '2|formula|awscli' '2|formula|helm' '2|formula|argocd'
    '2|formula|istioctl' '2|formula|k9s'
    '3|formula|oven-sh/bun/bun'
  )
  local -a UI_CHECKLIST_LABELS=() UI_CHECKLIST_GROUPS=() UI_CHECKLIST_SELECTED=()
  local tool rest choice="" index package
  for tool in "${tools[@]}"; do
    UI_CHECKLIST_GROUPS+=("${tool%%|*}")
    UI_CHECKLIST_LABELS+=("${tool##*|}")
  done
  ui_checklist "$L_STEP_CONVENIENCE" choice
  echo
  if [ "$choice" != install ]; then
    ui_log_skipped "$L_STEP_CONVENIENCE"
    return 0
  fi

  # Homebrew + jq are installed by install_required (installers/required.sh).
  # Update only after the user chooses Install with a nonempty selection.
  log_start "brew update…"
  brew update

  local -a formulae=() casks=()
  local television_selected=0
  for ((index=0; index<${#tools[@]}; index++)); do
    [ "${UI_CHECKLIST_SELECTED[$index]}" -eq 1 ] || continue
    tool=${tools[$index]}; rest=${tool#*|}; package=${rest#*|}
    case "${rest%%|*}" in
      formula) formulae+=("$package") ;;
      cask) casks+=("$package") ;;
    esac
    [ "$package" = television ] && television_selected=1
  done
  if [ "${#formulae[@]}" -gt 0 ]; then
    log_start "brew install ${formulae[*]}…"
    brew install "${formulae[@]}"
  fi
  if [ "${#casks[@]}" -gt 0 ]; then
    for package in "${casks[@]}"; do
      log_start "brew install --cask ${package}…"
      # Adopt existing manually installed apps; skip brew-managed casks.
      brew list --cask "$package" &>/dev/null || brew install --cask --adopt "$package"
    done
  fi

  # TODO: 도커랑 cli 그 툴 뭐더라 그거 설치하는 옵션 추가. 메뉴 별도로 빼고 유저가 선택할 수 있도록.

  # television shell integration. `tv init zsh` calls compdef, so load the
  # completion system first — otherwise new shells print "command not found:
  # compdef" when compinit hasn't run yet (e.g. oh-my-zsh installed with
  # KEEP_ZSHRC doesn't wire it in). `-i` skips insecure dirs without prompting.
  if [ "$television_selected" -eq 1 ]; then
    local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
    rc_upsert_block "$ZSHRC" "television" 'if (( ! $+functions[compdef] )); then
  autoload -Uz compinit && compinit -i
fi
eval "$(tv init zsh)"'
    export ZSHRC_MODIFIED=true
  fi

  log_done "convenience tools installed."
  sleep "$UI_SKIP_PAUSE"
}
