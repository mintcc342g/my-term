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

log_start() {
  echo "${BLUE_BOLD}➜${RESET} $*"
}

log_step() {
  echo "${YELLOW_BOLD}⚙${RESET} $*"
}

log_fail() {
  echo "${RED_BOLD}✖${RESET} $*"
}

log_done() {
  echo "${GREEN_BOLD}✔${RESET} $*"
}

# ── Source installers ───────────────────────────────────────────
source "$SCRIPT_DIR/installers/env-setup.sh"
source "$SCRIPT_DIR/installers/asdf-langs.sh"
source "$SCRIPT_DIR/installers/statusline.sh"
source "$SCRIPT_DIR/installers/hooks.sh"
source "$SCRIPT_DIR/installers/collab.sh"
source "$SCRIPT_DIR/installers/claude-settings.sh"

# ── OS check ────────────────────────────────────────────────────
cd "$HOME"

if [ "$(uname -s)" = "Linux" ]; then
    echo "${RED_BOLD}NOT SUPPORT OS${RESET}…\n"
    exit 0
fi

# ── Banner ──────────────────────────────────────────────────────
print_banner() {
  cat << EOF
::::::::::: ::::::::::: ::: ::::::::       ::::    ::::  :::   :::  ::::::::   ::::::::  $(printf ${YELLOW}):::$(printf ${BLUE}) :::$(printf ${PINK}) :::$(printf ${PURPLE}) :::$(printf ${GREEN}) :::$(printf ${RESET})
    :+:         :+:     :+ :+:    :+:      +:+:+: :+:+:+ :+:   :+: :+:    :+: :+:    :+: $(printf ${YELLOW}):+:$(printf ${BLUE}) :+:$(printf ${PINK}) :+:$(printf ${PURPLE}) :+:$(printf ${GREEN}) :+:$(printf ${RESET})
    +:+         +:+        +:+             +:+ +:+:+ +:+  +:+ +:+  +:+        +:+    +:+ $(printf ${YELLOW})+:+$(printf ${BLUE}) +:+$(printf ${PINK}) +:+$(printf ${PURPLE}) +:+$(printf ${GREEN}) +:+$(printf ${RESET})
    +#+         +#+        +#++:++#++      +#+  +:+  +#+   +#++:   :#:        +#+    +:+ $(printf ${YELLOW})+#+$(printf ${BLUE}) +#+$(printf ${PINK}) +#+$(printf ${PURPLE}) +#+$(printf ${GREEN}) +#+$(printf ${RESET})
    +#+         +#+               +#+      +#+       +#+    +#+    +#+   +#+# +#+    +#+ $(printf ${YELLOW})+#+$(printf ${BLUE}) +#+$(printf ${PINK}) +#+$(printf ${PURPLE}) +#+$(printf ${GREEN}) +#+$(printf ${RESET})
    #+#         #+#        #+#    #+#      #+#       #+#    #+#    #+#    #+# #+#    #+#
###########     ###         ########       ###       ###    ###     ########   ########  $(printf ${YELLOW})###$(printf ${BLUE}) ###$(printf ${PINK}) ###$(printf ${PURPLE}) ###$(printf ${GREEN}) ###$(printf ${RESET})
EOF
  echo "\n"
}

# ── Interactive menu ────────────────────────────────────────────
run_everything() {
  install_env_setup
  install_asdf_langs
  install_statusline
  install_hooks
  install_collab
  install_claude_settings
}

run_statusline_only() {
  install_statusline
  install_claude_settings
}

run_hooks_only() {
  install_hooks
  install_claude_settings
}

print_banner
echo "${BLUE_BOLD}my-term installer${RESET}"
echo "─────────────────\n"

PS3=$'\n'"${YELLOW_BOLD}Select an option: ${RESET}"
options=(
  "Everything (env + statusline + hooks + collab)"
  "Statusline only"
  "Hooks only"
  "Exit"
)

select opt in "${options[@]}"; do
  case "$REPLY" in
    1)
      echo
      run_everything
      break
      ;;
    2)
      echo
      run_statusline_only
      break
      ;;
    3)
      echo
      run_hooks_only
      break
      ;;
    4)
      echo "Bye!"
      exit 0
      ;;
    *)
      echo "Invalid option. Try again."
      ;;
  esac
done

log_done "${GREEN_BOLD}All installations are complete!${RESET} 🎉"
echo "  Please run ${YELLOW_BOLD}'source \${HOME}/.zshrc'${RESET} or ${YELLOW_BOLD}restart${RESET} your shell.\n\n"
