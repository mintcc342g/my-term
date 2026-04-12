#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
YELLOW='\033[93m'
YELLOW_BOLD='\033[33;1m'
BLUE='\033[94m'
BLUE_BOLD='\033[34;1m'
RED_BOLD='\033[31;1m'
PINK='\033[38;5;205m'
PURPLE='\033[35m'
GREEN='\033[92m'
GREEN_BOLD='\033[32;1m'
RESET='\033[0m'

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
  ui_menu "my-term installer" choice \
    "Convenience tools (CLI, macOS apps, DevOps)" \
    "oh-my-zsh + zsh plugins" \
    "Shell theme (newro)" \
    "asdf + languages" \
    "pyenv" \
    "AI tools (Claude, OpenCode, Codex)" \
    "Everything" \
    "Done"

  case "$choice" in
    0) install_convenience ;;
    1) install_oh_my_zsh ;;
    2) install_shell_theme ;;
    3) install_asdf_langs ;;
    4) install_pyenv ;;
    5) install_ai_tools ;;
    6) run_everything ; break ;;
    7|255) break ;;
  esac
done

printf '\033[2J\033[H'
log_done "${GREEN_BOLD}Installation complete!${RESET} 🎉"
echo -e "  Please run ${YELLOW_BOLD}'source \${HOME}/.zshrc'${RESET} or ${YELLOW_BOLD}restart${RESET} your shell.\n\n"

cat << EOF
::::::::::: ::::::::::: ::: ::::::::       ::::    ::::  :::   :::  ::::::::   ::::::::  ${YELLOW}:::${BLUE} :::${PINK} :::${PURPLE} :::${GREEN} :::${RESET}
    :+:         :+:     :+ :+:    :+:      +:+:+: :+:+:+ :+:   :+: :+:    :+: :+:    :+: ${YELLOW}:+:${BLUE} :+:${PINK} :+:${PURPLE} :+:${GREEN} :+:${RESET}
    +:+         +:+        +:+             +:+ +:+:+ +:+  +:+ +:+  +:+        +:+    +:+ ${YELLOW}+:+${BLUE} +:+${PINK} +:+${PURPLE} +:+${GREEN} +:+${RESET}
    +#+         +#+        +#++:++#++      +#+  +:+  +#+   +#++:   :#:        +#+    +:+ ${YELLOW}+#+${BLUE} +#+${PINK} +#+${PURPLE} +#+${GREEN} +#+${RESET}
    +#+         +#+               +#+      +#+       +#+    +#+    +#+   +#+# +#+    +#+ ${YELLOW}+#+${BLUE} +#+${PINK} +#+${PURPLE} +#+${GREEN} +#+${RESET}
    #+#         #+#        #+#    #+#      #+#       #+#    #+#    #+#    #+# #+#    #+#
###########     ###         ########       ###       ###    ###     ########   ########  ${YELLOW}###${BLUE} ###${PINK} ###${PURPLE} ###${GREEN} ###${RESET}
EOF
echo -e "\n"
