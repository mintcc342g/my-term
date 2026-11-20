#!/bin/bash
# installers/convenience.sh — CLI tools, macOS apps, DevOps, and editors
# source'd by install.sh

_install_app_config() {
  local source_file="$1" destination="$2" temporary backup
  [ -f "$source_file" ] && [ ! -d "$destination" ] || return 1
  if cmp -s "$source_file" "$destination"; then
    return 0
  fi
  mkdir -p "${destination%/*}" || return 1
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    backup="$(mktemp "$destination.bak.XXXXXXXX")" || return 1
    if ! cp -P "$destination" "$backup"; then
      rm -f -- "$backup"
      return 1
    fi
    log_step "Backed up $destination to $backup"
  fi
  temporary="$(mktemp "$destination.tmp.XXXXXXXX")" || return 1
  if ! cp "$source_file" "$temporary" || ! mv -f -- "$temporary" "$destination"; then
    rm -f -- "$temporary"
    return 1
  fi
}

_backup_app_preferences() {
  local domain="$1" backup_dir backup
  backup_dir="$HOME/Library/Preferences"
  mkdir -p "$backup_dir" || return 1
  backup="$(mktemp "$backup_dir/${domain}.plist.bak.XXXXXXXX")" || return 1
  if ! /usr/bin/defaults export "$domain" "$backup"; then
    rm -f -- "$backup"
    return 1
  fi
  log_step "Backed up $domain to $backup"
}

_write_app_preferences() {
  local source_file="$1" domain="$2" keys key type value item
  local -a arguments
  keys="$(jq -er '
    select(type == "object")
    | select(all(.[]; type == "boolean" or type == "string"
      or (type == "number" and floor == .)
      or (type == "array" and all(.[]; type == "string"))))
    | keys[]
  ' "$source_file")" || return 1
  _backup_app_preferences "$domain" || return 1
  while IFS= read -r key; do
    type="$(jq -r --arg key "$key" '.[$key] | type' "$source_file")" || return 1
    case "$type" in
      boolean|number|string)
        value="$(jq -r --arg key "$key" '.[$key]' "$source_file")" || return 1
        [ "$type" != boolean ] || type=bool
        [ "$type" != number ] || type=int
        arguments=("-$type" "$value")
        ;;
      array)
        value="$(jq -r --arg key "$key" '.[$key][]' "$source_file")" || return 1
        arguments=(-array)
        if [ -n "$value" ]; then
          while IFS= read -r item; do
            arguments+=("$item")
          done <<< "$value"
        fi
        ;;
      *) log_fail "Unsupported preference type for $domain/$key: $type"; return 1 ;;
    esac
    if ! /usr/bin/defaults write "$domain" "$key" "${arguments[@]}"; then
      log_fail "Could not write preference $domain/$key"
      return 1
    fi
  done <<< "$keys"
}

_configure_convenience_app() {
  local method="$1" source_file="$2" target="$3"
  case "$method" in
    copy) _install_app_config "$source_file" "$target" ;;
    defaults) _write_app_preferences "$source_file" "$target" ;;
    *) return 1 ;;
  esac
}

install_convenience() {
  local -a UI_CHECKLIST_CATEGORIES=(
    "$L_CONVENIENCE_CLI" "$L_CONVENIENCE_APPS"
    "$L_CONVENIENCE_DEVOPS" "$L_CONVENIENCE_MANAGERS" "$L_CONVENIENCE_EDITORS"
  )
  # category index | installer type | package name or editor label
  # Optional cask fields: config method | source relative to app-configs | destination or defaults domain
  local -a tools=(
    '0|formula|ripgrep' '0|formula|fd' '0|formula|bat'
    '0|formula|television' '0|formula|tree' '0|formula|tmux' '0|formula|telnet'
    '1|cask|maccy|defaults|maccy/preferences.json|org.p0deje.Maccy'
    '1|cask|rectangle'
    '1|cask|macs-fan-control'
    '1|cask|alt-tab'
    '1|cask|postman'
    '1|cask|stats'
    '1|cask|fork'
    "1|cask|ghostty|copy|ghostty/config|${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
    '2|formula|awscli' '2|formula|helm' '2|formula|argocd'
    '2|formula|istioctl' '2|formula|k9s'
    '3|formula|oven-sh/bun/bun'
    '4|editor|Antigravity' '4|editor|LazyVim'
  )
  local -a UI_CHECKLIST_LABELS=() UI_CHECKLIST_GROUPS=() UI_CHECKLIST_SELECTED=()
  local tool group kind choice="" index package method config_path target
  for tool in "${tools[@]}"; do
    IFS='|' read -r group kind package method config_path target <<< "$tool"
    UI_CHECKLIST_GROUPS+=("$group")
    UI_CHECKLIST_LABELS+=("$package")
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

  local -a formulae=() casks=() editors=()
  local television_selected=0
  for ((index=0; index<${#tools[@]}; index++)); do
    [ "${UI_CHECKLIST_SELECTED[$index]}" -eq 1 ] || continue
    IFS='|' read -r group kind package method config_path target <<< "${tools[$index]}"
    case "$kind" in
      formula) formulae+=("$package") ;;
      cask) casks+=("$index") ;;
      editor) editors+=("$package") ;;
    esac
    [ "$package" = television ] && television_selected=1
  done
  if [ "${#formulae[@]}" -gt 0 ]; then
    log_start "brew install ${formulae[*]}…"
    brew install "${formulae[@]}"
  fi
  local app_setup_incomplete=0
  if [ "${#casks[@]}" -gt 0 ]; then
    for index in "${casks[@]}"; do
      IFS='|' read -r group kind package method config_path target <<< "${tools[$index]}"
      log_start "brew install --cask ${package}…"
      # Adopt existing manually installed apps; skip brew-managed casks.
      brew list --cask "$package" &>/dev/null || brew install --cask --adopt "$package"
      [ -n "$method" ] || continue
      config_path="$SCRIPT_DIR/app-configs/$config_path"
      if _configure_convenience_app "$method" "$config_path" "$target"; then
        log_done "$package config installed. Restart the app if it is running."
      else
        log_fail "Could not install $package config. See app-configs and the README for manual setup."
        app_setup_incomplete=1
      fi
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

  # Editor setup can require a first launch. Continue with the other selection
  # if an editor cannot complete setup in this run.
  local editor_setup_incomplete=0
  if [ "${#editors[@]}" -gt 0 ]; then
    local editor
    for editor in "${editors[@]}"; do
      case "$editor" in
        Antigravity) _install_antigravity || editor_setup_incomplete=1 ;;
        LazyVim)     _install_lazyvim || editor_setup_incomplete=1 ;;
      esac
    done
  fi

  if [ "$editor_setup_incomplete" -eq 0 ] && [ "$app_setup_incomplete" -eq 0 ]; then
    log_done "convenience tools installed."
  fi
  sleep "$UI_SKIP_PAUSE"
}
