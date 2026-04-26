#!/bin/bash
# installers/asdf-langs.sh — asdf + language plugins (arrow-key selection)
# source'd by install.sh

install_asdf_langs() {
  log_start "brew install asdf…"

  if ! command -v brew &>/dev/null; then
    log_fail "Homebrew not found. Please install convenience tools first."
    return 1
  fi
  brew install asdf

  local ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"
  rc_upsert_block "$ZPROFILE" "asdf-shims" 'if [[ ":$PATH:" != *":$HOME/.asdf/shims:"* ]]; then
  export PATH="$HOME/.asdf/shims:$PATH"
fi'

  log_done "asdf installed."

  # Language selection
  local choice=""

  while true; do
    ui_menu "asdf — select language to configure" choice \
      "Golang" \
      "Java"

    case "$choice" in
      0)
        log_step "configure Golang…"
        asdf plugin add golang https://github.com/kennyp/asdf-golang.git 2>/dev/null || true
        rc_upsert_block "$ZPROFILE" "asdf-golang" '#. ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh'
        log_done "Golang plugin added."
        echo
        echo "${YELLOW_BOLD}[WARNING]${RESET} ${RED_BOLD}After installing Golang${RESET}, please ${RED_BOLD}uncomment${RESET} the Golang environment configuration in your ${RED_BOLD}.zprofile.${RESET}"
        echo
        sleep 2
        ;;
      1)
        log_step "configure Java…"
        asdf plugin add java https://github.com/halcyon/asdf-java.git 2>/dev/null || true
        rc_upsert_block "$ZPROFILE" "asdf-java" '#. ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/java/set-java-home.zsh'
        log_done "Java plugin added."
        echo
        echo "${YELLOW_BOLD}[WARNING]${RESET} ${RED_BOLD}After installing Java${RESET}, please ${RED_BOLD}uncomment${RESET} the Java environment configuration in your ${RED_BOLD}.zprofile.${RESET}"
        echo
        sleep 2
        ;;
      255)
        break
        ;;
    esac
  done
}
