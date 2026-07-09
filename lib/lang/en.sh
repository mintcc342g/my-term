#!/bin/bash
# lib/lang/en.sh — English message catalog.
# ko.sh 와 동일한 키/함수 집합을 정의해야 한다 (검증: lib/lang 패리티 체크).
# 색상은 ui.sh 의 UI_* 만 사용 (source 시점에 이미 정의됨).

# ── Common ──────────────────────────────────────────────────────
L_YES="Yes"
L_NO="No"
L_NO_SKIP="No (Skip)"
L_NO_EXIT="No (Exit)"
L_NO_DONE="No (Done)"
L_DONE_ITEM="✓ Done (next step)"
L_UI_HINT="↑↓ move │ Enter select"
L_EXIT_ABORTED="Aborted — exiting installer."

# ── Main menu (install.sh) ──────────────────────────────────────
L_MENU_TITLE="my-term installer"
L_MENU_INSTALL="Install"
L_MENU_UPDATE="Update"
L_MENU_HUD_CONFIG="HUD configure"
L_MENU_DELETE="Delete (remove my-term config)"
L_MENU_EXIT="✗ Exit"

# ── Step labels (install.sh ui_confirm_run / ai-tools) ──────────
L_STEP_CONVENIENCE="Convenience tools (CLI, macOS apps, DevOps)"
L_STEP_GIT_SSH="Git SSH keys (multi-account)"
L_STEP_OMZ="Oh-my-zsh + zsh plugins"
L_STEP_THEME="Shell theme (newro)"
L_STEP_ASDF="asdf + languages"
L_STEP_PYENV="pyenv"
L_STEP_AI="AI tools (Claude, OpenCode, Codex)"
L_STEP_OBSIDIAN="Obsidian + vault tooling"

# ── Completion banner (ui.sh ui_print_completion) ───────────────
L_DONE_INSTALL="Installation complete!"
L_DONE_UPDATE="Update complete!"
L_DONE_HUDCFG="HUD configured."
L_DONE_DELETE="my-term config removed."
L_DONE_DELETE_HINT="Re-run Install to set it up again."
L_DELETE_CANCELLED="Delete cancelled."
L_DONE_RESTART_CC="Restart Claude Code sessions to apply."

# multi-color note (literal ${HOME} kept via \$).
lang_done_source_zshrc() {
  printf "  Please run ${UI_YELLOW_BOLD}'source \${HOME}/.zshrc'${UI_RESET} or ${UI_YELLOW_BOLD}restart${UI_RESET} your shell.\n\n"
}

# ── Delete (ai-tools.sh delete_my_claude) ───────────────────────
L_DELETE_CONFIRM_TITLE="Delete my-term config? This cannot be undone."

# Confirmation note: what gets removed vs. kept. Shown as the menu note.
lang_delete_plan() {
  local s="\n"
  s+="   ${UI_RED_BOLD}Will remove:${UI_RESET}\n"
  s+="     ~/.claude/my-hud, my-hooks, my-collab, my-wiki ${UI_DIM}(incl. your HUD theme / collab config)${UI_RESET}\n"
  s+="     #-- my-term: blocks in ~/.zshrc, ~/.zprofile, ~/.ssh/config\n"
  s+="     OPTIONAL instruction blocks in ~/.claude/CLAUDE.md\n"
  s+="     statusLine + my-term hooks in ~/.claude/settings.json\n"
  s+="     codex MCP entry in ~/.claude.json\n"
  s+="\n"
  s+="   ${UI_GREEN_BOLD}Will keep:${UI_RESET}\n"
  s+="     ~/.claude/memory ${UI_DIM}(your saved memory)${UI_RESET}\n"
  s+="     SSH key files ~/.ssh/id_* ${UI_DIM}(only the config block is removed)${UI_RESET}\n"
  s+="     permissions.deny security rules in settings.json\n"
  s+="     brew packages, oh-my-zsh, asdf/pyenv, CLI, IDE, Obsidian\n"
  printf '%s' "$s"
}

# ── Shared error guidance ───────────────────────────────────────
L_ERR_NO_BREW="Homebrew not found. Please install convenience tools first."
L_ERR_NO_OMZ="oh-my-zsh not found. Please install oh-my-zsh first."

# ── Required tools (required.sh) ────────────────────────────────
L_REQ_TITLE="Install required tools (Homebrew + jq)?"
L_REQ_NOTE="⚠ Required — declining will exit the installer immediately."
L_REQ_ALREADY="Required tools (Homebrew, jq) already installed — skipping this step."

# ── IDEs (ides.sh) ──────────────────────────────────────────────
L_IDE_MENU_TITLE="IDE — select to install"
L_IDE_CMD_HEADER="Antigravity command setup"
L_IDE_CMD_PROMPT="Enter short command name for antigravity (default: agy)"
L_IDE_INVALID_NAME="Invalid name. Using default: agy"
L_IDE_BINDIR_NOTFOUND="Antigravity bin dir not found. Launch the IDE once, then re-run this step."
L_PROMPT_NAME="name: "
L_IDE_MORE_TITLE="IDE installed — continue?"
L_IDE_ANOTHER="Install another IDE"
L_IDE_PROCEED_FMT="Continue to the next step (%s)"

# ── asdf (asdf-langs.sh) ────────────────────────────────────────
L_ASDF_MENU_TITLE="asdf — select language to configure"
# Persistent red warning shown as the language-menu note (uncomment .zprofile).
lang_asdf_note() {
  printf '%s' " ${UI_YELLOW_BOLD}[WARNING]${UI_RESET} ${UI_RED_BOLD}After installing a language${UI_RESET}, please ${UI_RED_BOLD}uncomment${UI_RESET} its environment configuration in your ${UI_RED_BOLD}.zprofile.${UI_RESET}"
}

# ── Git SSH (git-ssh.sh) ────────────────────────────────────────
L_GITSSH_INTRO_TITLE="Git SSH — multi-account setup"
L_GITSSH_CASEA_TITLE="A default key is already in use"
L_GITSSH_CASEB_TITLE="Existing default key detected — continue?"
L_GITSSH_ANOTHER_TITLE="Create another SSH key?"
L_GITSSH_ENTER_NEXT="Press Enter for the next step…"
L_GITSSH_ENTER_DONE="Press Enter when done…"
L_GITSSH_NICK_LABEL="nickname: "
L_GITSSH_INVALID_NICK="Invalid nickname (a-z, 0-9, _, - only)."
L_GITSSH_KEY_EXISTS="Key already exists at %s. Enter a different nickname."
L_GITSSH_EMAIL_LABEL="email (key comment): "
L_GITSSH_EMPTY_EMAIL="Enter an email."
L_GITSSH_PUBKEY_LABEL="Public key:"
L_GITSSH_REGISTER_GH="Register it at GitHub Settings → SSH keys:"
L_GITSSH_DIR_LABEL="directory: "
L_GITSSH_DIR_REQUIRED="Directory is required."
L_GITSSH_VERIFY="Verify: cd <registered dir> && ssh -T git@github.com"

# intro note (UI_MENU_NOTE; literal \n for echo -e).
lang_gitssh_intro() {
  local s=""
  s+=" ─────────────────────\n"
  s+=" If you'll create two or more keys, decide which key\n"
  s+=" to use in which directory before you create them.\n"
  s+="\n"
  s+="   e.g.  ~/Documents/my    →  id_my    (personal)\n"
  s+="         ~/Documents/works →  id_work  (work)\n"
  s+="\n"
  s+=" With two or more keys, ssh can't tell which key to use\n"
  s+=" when authenticating to github.com, so you assign\n"
  s+=" a key per directory.\n"
  s+="\n"
  s+=" Set up GitHub SSH keys now?"
  printf '%s' "$s"
}

# Case A note (managed default exists).
lang_gitssh_caseA_note() {
  local managed="$1"
  local s=""
  s+=" ─────────────────────\n"
  s+=" This key is already in use as your default:\n"
  s+="    ${managed}\n"
  s+="\n"
  s+=" New keys are added with per-directory matching.\n"
  s+="\n"
  s+=" Add a new key?"
  printf '%s' "$s"
}

# Case B note (external default exists).
lang_gitssh_caseB_note() {
  local ext="$1"
  local s=""
  s+=" ${UI_DIM}~/.ssh/config already has a 'Host github.com' entry.${UI_RESET}\n"
  s+=" ${UI_DIM}It will be kept as your default key:${UI_RESET}\n"
  s+="    ${ext}\n"
  s+="\n"
  s+=" ${UI_DIM}Continue if you want to register more keys.${UI_RESET}"
  printf '%s' "$s"
}

# Case D conflict screen (prints to /dev/tty).
lang_gitssh_conflict() {
  local ext="$1" managed="$2"
  echo -e "${UI_BLUE_BOLD} Two 'Host github.com' entries found${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}~/.ssh/config has 'Host github.com' both inside and outside${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}the managed block. ssh uses only the first match, so one${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}of them is shadowed.${UI_RESET}" > /dev/tty
  echo > /dev/tty
  echo -e " ${UI_DIM}  outside managed (hand-written): ${ext}${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}  inside managed (installer): ${managed}${UI_RESET}" > /dev/tty
  echo > /dev/tty
  echo -e " ${UI_DIM}Clean up ~/.ssh/config yourself, then run again.${UI_RESET}\n" > /dev/tty
}

# nickname help screen.
lang_gitssh_nick_help() {
  local has_default="$1"
  echo -e "${UI_BLUE_BOLD} SSH key — nickname${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}This nickname is used in the key filename (~/.ssh/id_<nickname>).${UI_RESET}" > /dev/tty
  if [ "$has_default" = "false" ]; then
    echo -e " ${UI_DIM}The first key is registered as the default, so no directory is set for it.${UI_RESET}" > /dev/tty
  else
    echo -e " ${UI_DIM}A default key already exists, so this key is made just for a specific directory.${UI_RESET}" > /dev/tty
    echo -e " ${UI_DIM}You create the key in this step, then choose its directory in the next one.${UI_RESET}" > /dev/tty
  fi
  echo -e " ${UI_DIM}${UI_ITALIC}Press Enter without a nickname to stop here and move to the next step.${UI_RESET}\n" > /dev/tty
}

# directory help screen.
lang_gitssh_dir_help() {
  local nickname="${1:-}"
  echo -e "${UI_BLUE_BOLD} SSH key — directory${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}Directory where the '${nickname}' key applies (Tab to autocomplete).${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}   e.g. ~/Documents/works${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}git in this path (and below) picks the '${nickname}' key automatically.${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}The path is created if it doesn't exist.${UI_RESET}\n" > /dev/tty
}

# ── Obsidian (obsidian.sh) ──────────────────────────────────────
L_OBS_STORAGE_TITLE="Wiki storage type"
L_OBS_STORAGE_LOCAL="Local"
L_OBS_CANCELLED="Obsidian wiki setup cancelled."
L_OBS_WIKIPATH_LABEL="wiki path: "
L_OBS_EMPTY_PATH="Empty wiki path. Skipping wiki setup."
L_OBS_PLUGIN_HINT="After first Claude Code launch, manually install the obsidian-skills plugin:"

# wiki path help screen (storage: 0=local 1=icloud 2=git).
lang_obs_wikipath_help() {
  local storage="$1"
  echo -e "${UI_BLUE_BOLD} Wiki path${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}Enter the local directory path for the wiki (Tab to autocomplete).${UI_RESET}" > /dev/tty
  case "$storage" in
    0)
      echo -e " ${UI_DIM}  Local — any directory works.${UI_RESET}\n" > /dev/tty
      ;;
    1)
      echo -e " ${UI_DIM}  iCloud Drive — Obsidian's standard iCloud vault path:${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}    ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/<vault-name>${UI_RESET}\n" > /dev/tty
      ;;
    2)
      echo -e " ${UI_DIM}  Git — point to the local git repository directory to use.${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}  No repo yet? Give a path and the directory is created for you.${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}     e.g. ~/Documents/my-notes${UI_RESET}\n" > /dev/tty
      ;;
  esac
}

# ── AI tools (ai-tools.sh) ──────────────────────────────────────
L_AI_MENU_TITLE="AI tools — select to install"
L_AI_METHOD_TITLE="Claude Code install method"
L_AI_METHOD_STABLE="Stable (stable version)"
L_AI_METHOD_LATEST="Latest (newest version, not the stabilized one)"
L_AI_ALIAS_HEADER="Claude alias setup"
L_AI_ALIAS_PROMPT="Enter alias for claude command (default: c)"
L_AI_ALIAS_LABEL="alias: "
L_AI_INVALID_ALIAS="Invalid alias name. Using default: c"
L_AI_HUD_TITLE="Install HUD statusline?"
L_AI_GOFMT_TITLE="Go detected — add gofmt hook to Claude?"
