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

  # 진입 안내 — 키-디렉토리 매칭 동작을 키 생성 전에 알리고 진행 여부를 확인.
  # 디렉토리 컨벤션을 사후에 깨달으면 리포 재배치 + .git/config / .gitmodules
  # 의 host alias 잔재 정리까지 가야 해서 비용이 큼. ui_menu 는 리드로우마다
  # 화면을 지우므로 안내문은 UI_MENU_NOTE 로 전달 (Case B 와 동일 패턴).
  local intro; intro="$(lang_gitssh_intro)"

  local proceed=""
  UI_MENU_NOTE="$intro" ui_menu "$L_GITSSH_INTRO_TITLE" proceed "$L_YES" "$L_NO"
  if [ "$proceed" != "0" ]; then
    umask "$_old_umask"
    ui_log_skipped "Git SSH"
    return 0
  fi

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
    lang_gitssh_conflict "$external_default_key" "$managed_default_key"
    echo -ne " ${UI_DIM}${L_GITSSH_ENTER_NEXT}${UI_RESET}" > /dev/tty
    read -r _ < /dev/tty
    umask "$_old_umask"
    ui_log_skipped "Git SSH"
    return 0
  fi

  local has_default=false
  if [ "$has_managed_default" = "true" ]; then
    # Case A: my-term 이 관리하는 default 키가 이미 있음 — 추가 등록 여부만 확인.
    # 예전엔 log_step + sleep 로 잠깐 띄웠다가 다음 화면(ui_clear_screen)이
    # 덮어써 깜빡였음. Case B 처럼 ui_menu 로 머무르게 함.
    local note; note="$(lang_gitssh_caseA_note "$managed_default_key")"

    local cont=""
    UI_MENU_NOTE="$note" ui_menu "$L_GITSSH_CASEA_TITLE" cont "$L_YES" "$L_NO"
    if [ "$cont" != "0" ]; then
      umask "$_old_umask"
      ui_log_skipped "Git SSH"
      return 0
    fi
    has_default=true
  elif [ "$has_external_default" = "true" ]; then
    # Case B: 사용자 기존 default 를 존중하되, 매니지드 블록을 파일 맨 위로
    # 배치해야 이후 추가되는 Match 블록이 가려지지 않음.
    # ui_menu 는 매 리드로우마다 화면을 지우므로 안내문은 UI_MENU_NOTE 로
    # 전달해야 메뉴와 함께 표시됨 (obsidian/ai-tools 의 패턴과 동일).
    local note; note="$(lang_gitssh_caseB_note "$external_default_key")"

    local cont=""
    UI_MENU_NOTE="$note" ui_menu "$L_GITSSH_CASEB_TITLE" cont "$L_YES" "$L_NO"
    if [ "$cont" != "0" ]; then
      umask "$_old_umask"
      ui_log_skipped "Git SSH"
      return 0
    fi
    _git_ssh_ensure_block_at_top "$SSH_CONFIG"
    has_default=true
  fi

  local created=false
  while true; do
    # rc: 0 = 등록 성공(또는 재시도용 soft error), 1 = 치명적 오류,
    #     2 = 빈 닉네임으로 사용자가 키 생성을 종료 → 루프 탈출.
    # set -e 환경이라 비-0 반환이 스크립트를 죽이지 않도록 `|| rc=$?` 로 받는다.
    local rc=0
    _git_ssh_create_one "$SSH_CONFIG" "$has_default" || rc=$?
    if [ "$rc" -eq 1 ]; then
      umask "$_old_umask"
      return 1
    fi
    # 빈 닉네임으로 종료. 이번 실행에서 등록한 키가 하나도 없으면 (예: 첫
    # 화면에서 바로 비우고 나감) 완료가 아니라 skip 으로 표기한다.
    if [ "$rc" -eq 2 ]; then
      if [ "$created" = "false" ]; then
        umask "$_old_umask"
        ui_log_skipped "Git SSH"
        return 0
      fi
      break
    fi
    created=true
    # First successful registration becomes default — subsequent ones are matched.
    [ "$has_default" = "false" ] && has_default=true

    local more=""
    ui_menu "$L_GITSSH_ANOTHER_TITLE" more "$L_YES" "$L_NO_DONE"
    [ "$more" != "0" ] && break
  done

  umask "$_old_umask"
  log_done "Git SSH setup complete."
  printf "  ${UI_DIM}%s${UI_RESET}\n" "$L_GITSSH_VERIFY"
}

# One iteration: prompt nickname/email, generate key, register, pbcopy, pause.
# Returns non-zero only on fatal errors; soft errors (empty input, duplicate
# nickname) return 0 so the outer loop can re-prompt.
_git_ssh_create_one() {
  local SSH_CONFIG="$1" has_default="$2"

  # ── nickname ─────────────────────────────────────────────────
  ui_clear_screen
  lang_gitssh_nick_help "$has_default"
  echo -ne " ${UI_YELLOW_BOLD}${L_GITSSH_NICK_LABEL}${UI_RESET}" > /dev/tty
  local nickname
  read -r nickname < /dev/tty

  # 빈 닉네임은 "그만하고 다음 단계로" 신호 — 안내 문구로 미리 고지했으므로
  # 별도 에러 없이 abort code(2) 만 반환한다.
  if [ -z "$nickname" ]; then
    return 2
  fi
  # 파일명에 안전한 문자만 허용.
  if [[ ! "$nickname" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log_fail "$L_GITSSH_INVALID_NICK"
    sleep 1
    return 0
  fi
  local key_path="$HOME/.ssh/id_$nickname"
  if [ -e "$key_path" ] || [ -e "${key_path}.pub" ]; then
    log_fail "$(tf L_GITSSH_KEY_EXISTS "$key_path")"
    sleep 1
    return 0
  fi

  # ── email ────────────────────────────────────────────────────
  echo > /dev/tty
  echo -ne " ${UI_YELLOW_BOLD}${L_GITSSH_EMAIL_LABEL}${UI_RESET}" > /dev/tty
  local email
  read -r email < /dev/tty
  if [ -z "$email" ]; then
    log_fail "$L_GITSSH_EMPTY_EMAIL"
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
    dir_path=$(_git_ssh_prompt_directory "$nickname") || { log_fail "Directory prompt failed."; sleep 1; return 0; }
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
  echo -e " ${UI_BOLD}${L_GITSSH_PUBKEY_LABEL}${UI_RESET}" > /dev/tty
  cat "$pub_key" > /dev/tty
  echo > /dev/tty
  echo -e " ${UI_YELLOW_BOLD}→${UI_RESET} ${L_GITSSH_REGISTER_GH}" > /dev/tty
  echo -e "    https://github.com/settings/ssh/new" > /dev/tty
  echo > /dev/tty
  echo -ne " ${UI_DIM}${L_GITSSH_ENTER_DONE}${UI_RESET}" > /dev/tty
  read -r _ < /dev/tty
  return 0
}

# Tab-completing directory prompt (obsidian.sh wiki path 와 동일 패턴).
# 결과는 stdout 으로 반환 — 호출부는 command substitution 으로 받음.
# 빈 입력은 거절 (디렉토리는 필수).
_git_ssh_prompt_directory() {
  local nickname="${1:-}"
  ui_clear_screen
  lang_gitssh_dir_help "$nickname"

  set -o emacs 2>/dev/null || true
  bind '"\t": menu-complete' 2>/dev/null || true
  bind '"\e[Z": menu-complete-backward' 2>/dev/null || true
  bind 'set completion-ignore-case on' 2>/dev/null || true
  bind 'set match-hidden-files off' 2>/dev/null || true
  # Dim example precedes the yellow label; \001..\002 wrap the color escapes so
  # readline counts prompt width correctly. bash 3.2 has no `read -i` prefill, so
  # this is a hint, not an editable default.
  local prompt=$'\001\033[2m\002'" (~/Documents/works)"$'\001\033[0m\002'$'\001\033[33;1m\002'" ${L_GITSSH_DIR_LABEL}"$'\001\033[0m\002'

  local dir_path
  while true; do
    read -e -r -p "$prompt" dir_path < /dev/tty
    dir_path="${dir_path/#\~/$HOME}"
    dir_path="${dir_path%/}"
    [ -n "$dir_path" ] && break
    echo -e " ${UI_RED_BOLD}${L_GITSSH_DIR_REQUIRED}${UI_RESET}" > /dev/tty
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
