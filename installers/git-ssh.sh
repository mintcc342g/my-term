#!/bin/bash
# installers/git-ssh.sh — Git SSH multi-account key setup.
# 디렉토리 기반 키 분기 (~/.ssh/config Match exec). 첫 키는 default (fallback),
# 이후 키들은 사용자가 입력한 디렉토리에 매칭되어 동작.
# source'd by install.sh

install_git_ssh() {
  log_start "Git SSH keys setup…"

  if ! command -v ssh-keygen &>/dev/null; then
    log_fail "ssh-keygen not found. Skipping."
    return 1
  fi

  local SSH_DIR="$HOME/.ssh"
  local SSH_CONFIG="$SSH_DIR/config"
  local _old_umask
  _old_umask=$(umask)
  umask 077
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  # default 키 감지 — 두 갈래:
  #   managed  : 매니지드 블록 안의 Host github.com (이전 installer 실행 결과)
  #   external : 매니지드 블록 밖의 Host github.com (사용자가 직접 작성)
  # external 이 있으면 그 키를 default 로 존중하고 첫 등록 루프를 건너뜀.
  # 둘 다 있으면 ssh first-match 로 external 이 이기고 managed 가 죽는 충돌 상태.
  local has_managed_default=false has_external_default=false
  local managed_default_key="" external_default_key=""
  if [ -f "$SSH_CONFIG" ]; then
    if _git_ssh_block_has_default "$SSH_CONFIG"; then
      has_managed_default=true
      managed_default_key=$(_git_ssh_get_default_key "$SSH_CONFIG")
    fi
    external_default_key=$(_git_ssh_find_external_default_key "$SSH_CONFIG")
    [ -n "$external_default_key" ] && has_external_default=true
  fi

  # Case D: 매니지드 안팎에 default 가 둘 다 — 사용자가 정리해야 함.
  if [ "$has_managed_default" = "true" ] && [ "$has_external_default" = "true" ]; then
    ui_clear_screen
    echo -e "${UI_BLUE_BOLD} 'Host github.com' 설정이 둘 다 있습니다${UI_RESET}" > /dev/tty
    echo -e " ─────────────────────" > /dev/tty
    echo -e " ${UI_DIM}~/.ssh/config 에 'Host github.com' 이 매니지드 블록 안팎에 모두${UI_RESET}" > /dev/tty
    echo -e " ${UI_DIM}존재합니다. ssh 는 둘 중 위쪽 값만 사용하므로 한 쪽이 가려진${UI_RESET}" > /dev/tty
    echo -e " ${UI_DIM}상태예요.${UI_RESET}" > /dev/tty
    echo > /dev/tty
    echo -e " ${UI_DIM}  매니지드 외부 (직접 작성): ${external_default_key}${UI_RESET}" > /dev/tty
    echo -e " ${UI_DIM}  매니지드 내부 (installer): ${managed_default_key}${UI_RESET}" > /dev/tty
    echo > /dev/tty
    echo -e " ${UI_DIM}~/.ssh/config 를 직접 정리하신 뒤 다시 실행해주세요.${UI_RESET}\n" > /dev/tty
    echo -ne " ${UI_DIM}Enter 로 다음 단계로…${UI_RESET}" > /dev/tty
    read -r _ < /dev/tty
    umask "$_old_umask"
    ui_log_skipped "Git SSH"
    return 0
  fi

  local has_default=false
  if [ "$has_managed_default" = "true" ]; then
    has_default=true
    log_step "Existing default key detected (${managed_default_key:-unknown}) — new keys will be registered per directory."
    sleep 1
  elif [ "$has_external_default" = "true" ]; then
    # Case B: 사용자 기존 default 를 존중하되, 매니지드 블록을 파일 맨 위로
    # 배치해야 이후 추가되는 Match 블록이 가려지지 않음.
    # ui_menu 는 매 리드로우마다 화면을 지우므로 안내문은 UI_MENU_NOTE 로
    # 전달해야 메뉴와 함께 표시됨 (obsidian/ai-tools 의 패턴과 동일).
    local note=""
    note+=" ${UI_DIM}~/.ssh/config 에 이미 'Host github.com' 설정이 있어요.${UI_RESET}\n"
    note+=" ${UI_DIM}이 키를 그대로 default 로 사용합니다:${UI_RESET}\n"
    note+="    ${external_default_key}\n"
    note+="\n"
    note+=" ${UI_DIM}추가로 키를 등록하실 거라면 진행해주세요.${UI_RESET}"

    local cont=""
    UI_MENU_NOTE="$note" ui_menu "기존 default 키가 감지됐습니다 — 진행할까요?" cont "Yes" "No"
    if [ "$cont" != "0" ]; then
      umask "$_old_umask"
      ui_log_skipped "Git SSH"
      return 0
    fi
    _git_ssh_ensure_block_at_top "$SSH_CONFIG"
    has_default=true
  fi

  while true; do
    if ! _git_ssh_create_one "$SSH_CONFIG" "$has_default"; then
      umask "$_old_umask"
      return 1
    fi
    # First successful registration becomes default — subsequent ones are matched.
    [ "$has_default" = "false" ] && has_default=true

    local more=""
    ui_menu "Create another SSH key?" more "Yes" "No (Done)"
    [ "$more" != "0" ] && break
  done

  umask "$_old_umask"
  log_done "Git SSH setup complete."
  printf "  ${UI_DIM}검증: cd <등록한 디렉토리> && ssh -T git@github.com${UI_RESET}\n"
}

# One iteration: prompt nickname/email, generate key, register, pbcopy, pause.
# Returns non-zero only on fatal errors; soft errors (empty input, duplicate
# nickname) return 0 so the outer loop can re-prompt.
_git_ssh_create_one() {
  local SSH_CONFIG="$1" has_default="$2"

  # ── nickname ─────────────────────────────────────────────────
  ui_clear_screen
  echo -e "${UI_BLUE_BOLD} SSH key — nickname${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}이 닉네임이 키 파일명에 사용됩니다 (~/.ssh/id_<nickname>).${UI_RESET}" > /dev/tty
  if [ "$has_default" = "false" ]; then
    echo -e " ${UI_DIM}최초 입력 키는 default 키로 등록됩니다 (디렉토리 매칭 X, fallback 으로 동작).${UI_RESET}\n" > /dev/tty
  else
    echo -e " ${UI_DIM}이후 키는 디렉토리 매칭 방식으로 등록됩니다.${UI_RESET}\n" > /dev/tty
  fi
  echo -ne " ${UI_YELLOW_BOLD}nickname: ${UI_RESET}" > /dev/tty
  local nickname
  read -r nickname < /dev/tty

  if [ -z "$nickname" ]; then
    log_fail "Empty nickname."
    sleep 1
    return 0
  fi
  # 파일명에 안전한 문자만 허용.
  if [[ ! "$nickname" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log_fail "Invalid nickname (a-z, 0-9, _, - only)."
    sleep 1
    return 0
  fi
  local key_path="$HOME/.ssh/id_$nickname"
  if [ -e "$key_path" ] || [ -e "${key_path}.pub" ]; then
    log_fail "Key already exists at $key_path. 다른 nickname 을 입력하세요."
    sleep 1
    return 0
  fi

  # ── email ────────────────────────────────────────────────────
  echo > /dev/tty
  echo -ne " ${UI_YELLOW_BOLD}email (key comment): ${UI_RESET}" > /dev/tty
  local email
  read -r email < /dev/tty
  if [ -z "$email" ]; then
    log_fail "Empty email."
    sleep 1
    return 0
  fi

  # ── ssh-keygen (passphrase 는 ssh-keygen 이 직접 prompt) ──────
  echo > /dev/tty
  log_step "Generating ed25519 key at ${key_path}…"
  if ! ssh-keygen -t ed25519 -f "$key_path" -C "$email" < /dev/tty; then
    log_fail "ssh-keygen failed."
    sleep 1
    return 0
  fi

  # ── register in ~/.ssh/config ────────────────────────────────
  if [ "$has_default" = "false" ]; then
    _git_ssh_register_default "$SSH_CONFIG" "$key_path"
    log_done "Registered as default key in $SSH_CONFIG"
  else
    local dir_path
    dir_path=$(_git_ssh_prompt_directory) || { log_fail "Directory prompt failed."; sleep 1; return 0; }
    if [ ! -d "$dir_path" ]; then
      if ! mkdir -p "$dir_path"; then
        log_fail "Failed to create $dir_path"
        sleep 1
        return 0
      fi
      log_done "Created directory: $dir_path"
    else
      log_step "Using existing directory: $dir_path"
    fi
    _git_ssh_register_match "$SSH_CONFIG" "$key_path" "$dir_path"
    log_done "Registered $key_path for $dir_path"
  fi
  chmod 600 "$SSH_CONFIG"

  # ── pbcopy + GitHub 등록 안내 ─────────────────────────────────
  local pub_key="${key_path}.pub"
  if command -v pbcopy &>/dev/null; then
    pbcopy < "$pub_key"
    log_done "Public key copied to clipboard."
  fi
  echo > /dev/tty
  echo -e " ${UI_BOLD}Public key:${UI_RESET}" > /dev/tty
  cat "$pub_key" > /dev/tty
  echo > /dev/tty
  echo -e " ${UI_YELLOW_BOLD}→${UI_RESET} GitHub Settings → SSH keys 에 등록하세요:" > /dev/tty
  echo -e "    https://github.com/settings/ssh/new" > /dev/tty
  echo > /dev/tty
  echo -ne " ${UI_DIM}등록 완료 후 Enter…${UI_RESET}" > /dev/tty
  read -r _ < /dev/tty
  return 0
}

# Tab-completing directory prompt (obsidian.sh wiki path 와 동일 패턴).
# 결과는 stdout 으로 반환 — 호출부는 command substitution 으로 받음.
# 빈 입력은 거절 (디렉토리는 필수).
_git_ssh_prompt_directory() {
  ui_clear_screen
  echo -e "${UI_BLUE_BOLD} SSH key — directory${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}이 키를 사용할 디렉토리 경로 (Tab 자동완성).${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}해당 경로(및 하위)에서 git 작업 시 이 키가 자동 선택됩니다.${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}경로가 없으면 자동으로 생성됩니다.${UI_RESET}\n" > /dev/tty

  set -o emacs 2>/dev/null || true
  bind '"\t": menu-complete' 2>/dev/null || true
  bind '"\e[Z": menu-complete-backward' 2>/dev/null || true
  bind 'set completion-ignore-case on' 2>/dev/null || true
  bind 'set match-hidden-files off' 2>/dev/null || true
  local prompt=$'\001\033[33;1m\002 directory: \001\033[0m\002'

  local dir_path
  while true; do
    read -e -r -p "$prompt" dir_path < /dev/tty
    dir_path="${dir_path/#\~/$HOME}"
    dir_path="${dir_path%/}"
    [ -n "$dir_path" ] && break
    echo -e " ${UI_RED_BOLD}디렉토리는 필수입니다.${UI_RESET}" > /dev/tty
  done
  printf '%s' "$dir_path"
}

# Returns 0 if managed block contains a default 'Host github.com' line.
_git_ssh_block_has_default() {
  local file="$1"
  awk '
    /^#-- my-term:git-ssh: start$/ { in_block=1; next }
    /^#-- my-term:git-ssh: end$/   { in_block=0; next }
    in_block && /^Host github\.com$/ { found=1; exit }
    END { exit found ? 0 : 1 }
  ' "$file" 2>/dev/null
}

# Print the IdentityFile path of the existing default key (Host github.com block).
_git_ssh_get_default_key() {
  local file="$1"
  awk '
    /^#-- my-term:git-ssh: start$/ { in_block=1; next }
    /^#-- my-term:git-ssh: end$/   { in_block=0; next }
    in_block && /^Host github\.com$/ { in_default=1; next }
    in_block && in_default && /^[[:space:]]+IdentityFile / {
      print $2; exit
    }
  ' "$file" 2>/dev/null
}

# Find the IdentityFile of the first 'Host github.com' block OUTSIDE the
# managed block (i.e. user-written). Empty output if none.
_git_ssh_find_external_default_key() {
  local file="$1"
  awk '
    /^#-- my-term:git-ssh: start$/ { in_managed=1; next }
    /^#-- my-term:git-ssh: end$/   { in_managed=0; next }
    in_managed { next }
    /^Host github\.com[[:space:]]*$/ { in_host=1; next }
    /^Host /  { in_host=0; next }
    /^Match / { in_host=0; next }
    in_host && /^[[:space:]]+IdentityFile / { print $2; exit }
  ' "$file" 2>/dev/null
}

# Ensure my-term managed block sits at the TOP of the file. Idempotent.
# - If markers don't exist: prepend empty marker pair at top.
# - If markers exist but not at top: extract block content, remove old
#   markers, re-insert (with content) at top.
# Required for Case B (external default exists) so that subsequently added
# Match entries evaluate before user's existing Host github.com block.
_git_ssh_ensure_block_at_top() {
  local file="$1"
  local begin="#-- my-term:git-ssh: start"
  local end="#-- my-term:git-ssh: end"

  touch "$file"

  if ! grep -qF "$begin" "$file" 2>/dev/null; then
    local tmp
    tmp=$(mktemp)
    printf '%s\n%s\n\n' "$begin" "$end" > "$tmp"
    cat "$file" >> "$tmp"
    mv "$tmp" "$file"
    return 0
  fi

  # Markers exist — check if already at top (first non-blank line is begin).
  local first_content
  first_content=$(awk 'NF { print; exit }' "$file")
  if [ "$first_content" = "$begin" ]; then
    return 0
  fi

  # Extract current block content, strip block from file, prepend block at top.
  local block_content
  block_content=$(_git_ssh_get_block "$file")
  local tmp tmp2
  tmp=$(mktemp)
  tmp2=$(mktemp)
  awk -v begin="$begin" -v end="$end" '
    $0 == begin { in_block=1; next }
    $0 == end   { in_block=0; next }
    !in_block { print }
  ' "$file" > "$tmp"
  {
    printf '%s\n' "$begin"
    [ -n "$block_content" ] && printf '%s\n' "$block_content"
    printf '%s\n\n' "$end"
    cat "$tmp"
  } > "$tmp2"
  mv "$tmp2" "$file"
  rm -f "$tmp"
}

# Extract current managed block content (without markers).
_git_ssh_get_block() {
  local file="$1"
  [ -f "$file" ] || return 0
  awk '
    /^#-- my-term:git-ssh: start$/ { in_block=1; next }
    /^#-- my-term:git-ssh: end$/   { in_block=0; next }
    in_block { print }
  ' "$file"
}

# Append default Host github.com block to existing content (or create new).
_git_ssh_register_default() {
  local file="$1" key="$2"
  local existing block
  existing=$(_git_ssh_get_block "$file")
  if [ -n "$existing" ]; then
    block="${existing}"$'\n\n'
  else
    block=""
  fi
  block+="Host github.com"$'\n'
  block+="  HostName github.com"$'\n'
  block+="  IdentityFile ${key}"$'\n'
  block+="  IdentitiesOnly yes"
  rc_upsert_block "$file" "git-ssh" "$block"
}

# Prepend new Match block at the TOP of existing content. ssh_config 는 매칭
# 키워드의 첫 일치 값을 사용하므로 (ssh_config(5)), 최신 등록이 우선되도록.
# 같은 디렉토리를 두 번 등록해도 가장 최근 키가 winning entry 가 됨.
_git_ssh_register_match() {
  local file="$1" key="$2" dir="$3"
  local pattern
  pattern=$(_git_ssh_escape_regex "$dir")
  local match_block
  match_block="Match host github.com exec \"echo \$PWD | grep -qE '${pattern}(/|\$)'\""$'\n'
  match_block+="  HostName github.com"$'\n'
  match_block+="  IdentityFile ${key}"$'\n'
  match_block+="  IdentitiesOnly yes"

  local existing
  existing=$(_git_ssh_get_block "$file")

  local new_block
  if [ -n "$existing" ]; then
    new_block="${match_block}"$'\n\n'"${existing}"
  else
    new_block="$match_block"
  fi
  rc_upsert_block "$file" "git-ssh" "$new_block"
}

# Escape ERE special chars in user-provided path for use inside grep -qE pattern.
_git_ssh_escape_regex() {
  printf '%s' "$1" | sed 's/[][\\.*^$+?(){}|]/\\&/g'
}
