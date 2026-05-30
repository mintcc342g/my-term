#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
YELLOW_BOLD=$'\033[33;1m'
BLUE_BOLD=$'\033[34;1m'
RED_BOLD=$'\033[31;1m'
GREEN_BOLD=$'\033[32;1m'
RESET=$'\033[0m'

log_start() { echo "${BLUE_BOLD}➜${RESET} $*"; }
log_step()  { echo "${YELLOW_BOLD}⚙${RESET} $*"; }
log_fail()  { echo "${RED_BOLD}✖${RESET} $*"; }
log_done()  { echo "${GREEN_BOLD}✔${RESET} $*"; }

# ── Source shared UI + installers ───────────────────────────────
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/rc-block.sh"
source "$SCRIPT_DIR/lib/instructions-block.sh"
source "$SCRIPT_DIR/installers/required.sh"
source "$SCRIPT_DIR/installers/convenience.sh"
source "$SCRIPT_DIR/installers/git-ssh.sh"
source "$SCRIPT_DIR/installers/ides.sh"
source "$SCRIPT_DIR/installers/oh-my-zsh.sh"
source "$SCRIPT_DIR/installers/shell-theme.sh"
source "$SCRIPT_DIR/installers/asdf-langs.sh"
source "$SCRIPT_DIR/installers/pyenv.sh"
source "$SCRIPT_DIR/installers/ai-tools.sh"
source "$SCRIPT_DIR/installers/obsidian.sh"

# ── Terminal cleanup on exit/interrupt ──────────────────────────
trap 'printf "\033[?25h" 2>/dev/null; stty sane 2>/dev/null' EXIT INT TERM

# ── OS check ────────────────────────────────────────────────────
if [ "$(uname -s)" = "Linux" ]; then
    echo "${RED_BOLD}NOT SUPPORT OS${RESET}"
    exit 1
fi

# ── Language selection ──────────────────────────────────────────
# ui.sh already loaded the default (en); let the user switch up front so all
# subsequent menus/prompts render in one language.
ui_select_language

# ── Component orchestrator (Yes/No per component, dependency-aware) ──
run_install_interactive() {
  log_start "Running installer…"

  # Required tools first — declines exit the script entirely.
  install_required

  ui_confirm_run "$L_STEP_CONVENIENCE" install_convenience

  ui_confirm_run "$L_STEP_GIT_SSH" install_git_ssh

  install_ides

  ui_confirm_if_command brew "$L_STEP_OMZ" install_oh_my_zsh "Homebrew"
  ui_confirm_if_dir "$HOME/.oh-my-zsh" "$L_STEP_THEME" install_shell_theme "oh-my-zsh"
  ui_confirm_if_command brew "$L_STEP_ASDF" install_asdf_langs "Homebrew"
  ui_confirm_if_command brew "$L_STEP_PYENV" install_pyenv "Homebrew"
  ui_confirm_if_command brew "$L_STEP_AI" install_ai_tools "Homebrew"
}

# ── Main menu ───────────────────────────────────────────────────
while true; do
  choice=""
  menu_items=()
  menu_actions=()

  menu_items+=("$L_MENU_INSTALL");  menu_actions+=("install")
  menu_items+=("$L_MENU_UPDATE");   menu_actions+=("update")

  # Delete menu only when a my-term footprint exists in ~/.claude. Removes
  # my-term's deployed config; preserves memory, SSH keys, and third-party tools.
  if [ -d "$HOME/.claude/my-hud" ] || [ -d "$HOME/.claude/my-hooks" ] \
     || [ -d "$HOME/.claude/my-collab" ] || [ -d "$HOME/.claude/my-wiki" ]; then
    menu_items+=("$L_MENU_DELETE"); menu_actions+=("delete")
  fi

  # HUD configure menu only when modular HUD is installed.
  # Legacy users won't see this until they run Update once (which migrates).
  if [ -f "$HOME/.claude/my-hud/configure.sh" ]; then
    menu_items+=("$L_MENU_HUD_CONFIG"); menu_actions+=("hud-config")
  fi

  menu_items+=("$L_MENU_EXIT");   menu_actions+=("exit")

  ui_menu "$L_MENU_TITLE" choice "${menu_items[@]}"

  [ "$choice" = "255" ] && break
  action="${menu_actions[$choice]:-exit}"

  case "$action" in
    install)      last_action="install" ; run_install_interactive ; break ;;
    update)       last_action="update"  ; update_my_claude ; break ;;
    delete)       delete_my_claude ; last_action="${DELETE_LAST_ACTION:-delete}" ; break ;;
    hud-config)
      last_action="hud-config"
      bash "$SCRIPT_DIR/my-claude/hud/configure.sh"
      break ;;
    exit)         break ;;
  esac
done

ui_print_completion "${last_action:-install}"
