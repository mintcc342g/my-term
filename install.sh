#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
YELLOW=$'\033[93m'
YELLOW_BOLD=$'\033[33;1m'
BLUE=$'\033[94m'
BLUE_BOLD=$'\033[34;1m'
RED_BOLD=$'\033[31;1m'
PINK=$'\033[38;5;205m'
PURPLE=$'\033[35m'
GREEN=$'\033[92m'
GREEN_BOLD=$'\033[32;1m'
RESET=$'\033[0m'

log_start() { echo "${BLUE_BOLD}➜${RESET} $*"; }
log_step()  { echo "${YELLOW_BOLD}⚙${RESET} $*"; }
log_fail()  { echo "${RED_BOLD}✖${RESET} $*"; }
log_done()  { echo "${GREEN_BOLD}✔${RESET} $*"; }

# ── Source shared UI + installers ───────────────────────────────
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/installers/convenience.sh"
source "$SCRIPT_DIR/installers/oh-my-zsh.sh"
source "$SCRIPT_DIR/installers/shell-theme.sh"
source "$SCRIPT_DIR/installers/asdf-langs.sh"
source "$SCRIPT_DIR/installers/pyenv.sh"
source "$SCRIPT_DIR/installers/ai-tools.sh"

# ── OS check ────────────────────────────────────────────────────
if [ "$(uname -s)" = "Linux" ]; then
    echo "${RED_BOLD}NOT SUPPORT OS${RESET}"
    exit 0
fi

# ── Main menu ───────────────────────────────────────────────────
run_everything() {
  install_convenience
  install_oh_my_zsh
  install_shell_theme
  install_asdf_langs
  install_pyenv
  install_ai_tools
}

while true; do
  choice=""
  menu_items=()
  menu_actions=()

  menu_items+=("Convenience tools (CLI, macOS apps, DevOps)"); menu_actions+=("convenience")
  menu_items+=("oh-my-zsh + zsh plugins");                     menu_actions+=("oh-my-zsh")
  menu_items+=("Shell theme (newro)");                         menu_actions+=("shell-theme")
  menu_items+=("asdf + languages");                            menu_actions+=("asdf")
  menu_items+=("pyenv");                                       menu_actions+=("pyenv")
  menu_items+=("AI tools (Claude, OpenCode, Codex)");          menu_actions+=("ai-tools")

  # Detect HUD (new or legacy)
  if [ -f "$HOME/.claude/my-hud/configure.sh" ] || [ -f "$HOME/.claude/my-hud/powerline-statusline.sh" ]; then
    menu_items+=("HUD settings"); menu_actions+=("hud-config")
  fi

  menu_items+=("Everything"); menu_actions+=("everything")
  menu_items+=("Exit");       menu_actions+=("exit")

  ui_menu "my-term installer" choice "${menu_items[@]}"

  [ "$choice" = "255" ] && break
  action="${menu_actions[$choice]:-exit}"

  case "$action" in
    convenience)  install_convenience ;;
    oh-my-zsh)    install_oh_my_zsh ;;
    shell-theme)  install_shell_theme ;;
    asdf)         install_asdf_langs ;;
    pyenv)        install_pyenv ;;
    ai-tools)     install_ai_tools ;;
    hud-config)
      bash "$SCRIPT_DIR/my-claude/hud/configure.sh" --project-root "$SCRIPT_DIR"
      ;;
    everything)   run_everything ; break ;;
    exit)         break ;;
  esac
done

printf '\033[2J\033[H'
log_done "${GREEN_BOLD}Installation complete!${RESET} 🎉"
printf "  Please run ${YELLOW_BOLD}'source \${HOME}/.zshrc'${RESET} or ${YELLOW_BOLD}restart${RESET} your shell.\n\n"

cat << EOF
::::::::::: ::::::::::: ::: ::::::::       ::::    ::::  :::   :::  ::::::::   ::::::::  ${YELLOW}:::${BLUE} :::${PINK} :::${PURPLE} :::${GREEN} :::${RESET}
    :+:         :+:     :+ :+:    :+:      +:+:+: :+:+:+ :+:   :+: :+:    :+: :+:    :+: ${YELLOW}:+:${BLUE} :+:${PINK} :+:${PURPLE} :+:${GREEN} :+:${RESET}
    +:+         +:+        +:+             +:+ +:+:+ +:+  +:+ +:+  +:+        +:+    +:+ ${YELLOW}+:+${BLUE} +:+${PINK} +:+${PURPLE} +:+${GREEN} +:+${RESET}
    +#+         +#+        +#++:++#++      +#+  +:+  +#+   +#++:   :#:        +#+    +:+ ${YELLOW}+#+${BLUE} +#+${PINK} +#+${PURPLE} +#+${GREEN} +#+${RESET}
    +#+         +#+               +#+      +#+       +#+    +#+    +#+   +#+# +#+    +#+ ${YELLOW}+#+${BLUE} +#+${PINK} +#+${PURPLE} +#+${GREEN} +#+${RESET}
    #+#         #+#        #+#    #+#      #+#       #+#    #+#    #+#    #+# #+#    #+#
###########     ###         ########       ###       ###    ###     ########   ########  ${YELLOW}###${BLUE} ###${PINK} ###${PURPLE} ###${GREEN} ###${RESET}
EOF
echo
