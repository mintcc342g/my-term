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
  menu_items=(
    "Convenience tools (CLI, macOS apps, DevOps)"
    "oh-my-zsh + zsh plugins"
    "Shell theme (newro)"
    "asdf + languages"
    "pyenv"
    "AI tools (Claude, OpenCode, Codex)"
  )

  # Show HUD config option if already installed
  hud_installed=false
  if [ -f "$HOME/.claude/my-hud/configure.sh" ]; then
    hud_installed=true
    menu_items+=("HUD settings")
  fi

  menu_items+=("Everything" "Done")

  ui_menu "my-term installer" choice "${menu_items[@]}"

  # Map selection to action
  action=""
  case "$choice" in
    0) action="convenience" ;;
    1) action="oh-my-zsh" ;;
    2) action="shell-theme" ;;
    3) action="asdf" ;;
    4) action="pyenv" ;;
    5) action="ai-tools" ;;
    *)
      if $hud_installed; then
        case "$choice" in
          6) action="hud-config" ;;
          7) action="everything" ;;
          *) action="done" ;;
        esac
      else
        case "$choice" in
          6) action="everything" ;;
          *) action="done" ;;
        esac
      fi
      ;;
  esac

  case "$action" in
    convenience)  install_convenience ;;
    oh-my-zsh)    install_oh_my_zsh ;;
    shell-theme)  install_shell_theme ;;
    asdf)         install_asdf_langs ;;
    pyenv)        install_pyenv ;;
    ai-tools)     install_ai_tools ;;
    hud-config)
      # Store project root for sync, then run configure
      echo "$SCRIPT_DIR" > "$HOME/.claude/my-hud/.project-root"
      # Sync configure.sh + ui.sh first so menu itself is up to date
      cp -f "$SCRIPT_DIR/my-claude/hud/configure.sh" "$HOME/.claude/my-hud/"
      mkdir -p "$HOME/.claude/my-hud/lib"
      cp -f "$SCRIPT_DIR/lib/ui.sh" "$HOME/.claude/my-hud/lib/"
      chmod +x "$HOME/.claude/my-hud/configure.sh"
      bash "$HOME/.claude/my-hud/configure.sh"
      ;;
    everything)   run_everything ; break ;;
    done)         break ;;
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
