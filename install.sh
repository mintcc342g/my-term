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
source "$SCRIPT_DIR/installers/required.sh"
source "$SCRIPT_DIR/installers/convenience.sh"
source "$SCRIPT_DIR/installers/oh-my-zsh.sh"
source "$SCRIPT_DIR/installers/shell-theme.sh"
source "$SCRIPT_DIR/installers/asdf-langs.sh"
source "$SCRIPT_DIR/installers/pyenv.sh"
source "$SCRIPT_DIR/installers/ai-tools.sh"

# ── Terminal cleanup on exit/interrupt ──────────────────────────
trap 'printf "\033[?25h" 2>/dev/null; stty sane 2>/dev/null' EXIT INT TERM

# ── OS check ────────────────────────────────────────────────────
if [ "$(uname -s)" = "Linux" ]; then
    echo "${RED_BOLD}NOT SUPPORT OS${RESET}"
    exit 1
fi

# ── Component orchestrator (Yes/No per component, dependency-aware) ──
run_install_interactive() {
  log_start "Running installer…"

  # Required tools first — declines exit the script entirely.
  install_required

  ui_confirm_run "Convenience tools (CLI, macOS apps, DevOps)" install_convenience

  ui_confirm_if_command brew "Oh-my-zsh + zsh plugins" install_oh_my_zsh "Homebrew"
  ui_confirm_if_dir "$HOME/.oh-my-zsh" "Shell theme (newro)" install_shell_theme "oh-my-zsh"
  ui_confirm_if_command brew "asdf + languages" install_asdf_langs "Homebrew"
  ui_confirm_if_command brew "pyenv" install_pyenv "Homebrew"
  ui_confirm_if_command brew "AI tools (Claude, OpenCode, Codex)" install_ai_tools "Homebrew"
}

# ── Main menu ───────────────────────────────────────────────────
while true; do
  choice=""
  menu_items=()
  menu_actions=()

  menu_items+=("Install");  menu_actions+=("install")
  menu_items+=("Update");   menu_actions+=("update")

  # HUD configure menu only when modular HUD is installed.
  # Legacy users won't see this until they run Update once (which migrates).
  if [ -f "$HOME/.claude/my-hud/configure.sh" ]; then
    menu_items+=("HUD configure"); menu_actions+=("hud-config")
  fi

  menu_items+=("✗ Exit");   menu_actions+=("exit")

  ui_menu "my-term installer" choice "${menu_items[@]}"

  [ "$choice" = "255" ] && break
  action="${menu_actions[$choice]:-exit}"

  case "$action" in
    install)      last_action="install" ; run_install_interactive ; break ;;
    update)       last_action="update"  ; update_my_claude ; break ;;
    hud-config)
      last_action="hud-config"
      bash "$SCRIPT_DIR/my-claude/hud/configure.sh"
      break ;;
    exit)         break ;;
  esac
done

ui_print_completion "${last_action:-install}"
