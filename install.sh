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

# ── Source shared UI + installers ───────────────────────────────
source "$SCRIPT_DIR/lib/ui.sh"
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

# ── Install flows ──────────────────────────────────────────────
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

# ── Arrow-key menu ─────────────────────────────────────────────
choice=""
ui_menu "my-term installer" choice \
  "Everything (env + statusline + hooks + collab)" \
  "Statusline only" \
  "Hooks only" \
  "Exit"

case "$choice" in
  0) run_everything ;;
  1) run_statusline_only ;;
  2) run_hooks_only ;;
  3|255)
    printf '\033[2J\033[H'
    echo "Bye!"
    exit 0
    ;;
esac

printf '\033[2J\033[H'
log_done "${GREEN_BOLD}All installations are complete!${RESET} 🎉"
echo "  Please run ${YELLOW_BOLD}'source \${HOME}/.zshrc'${RESET} or ${YELLOW_BOLD}restart${RESET} your shell.\n\n"

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
