#!/bin/bash
# installers/asdf-langs.sh — asdf + selected language plugins
# source'd by install.sh

install_asdf_langs() {
  log_start "brew install asdf…"

  if ! command -v brew &>/dev/null; then
    log_fail "$L_ERR_NO_BREW"
    return 1
  fi
  brew install asdf

  local ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"
  rc_upsert_block "$ZPROFILE" "asdf-shims" 'if [[ ":$PATH:" != *":$HOME/.asdf/shims:"* ]]; then
  export PATH="$HOME/.asdf/shims:$PATH"
fi'

  log_done "asdf installed."

  local language
  for language in "$@"; do
    case "$language" in
      golang)
        log_step "configure Golang…"
        asdf plugin add golang https://github.com/kennyp/asdf-golang.git 2>/dev/null || true
        rc_upsert_block "$ZPROFILE" "asdf-golang" '#. ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh'
        log_done "Golang plugin added."
        ;;
      java)
        log_step "configure Java…"
        asdf plugin add java https://github.com/halcyon/asdf-java.git 2>/dev/null || true
        rc_upsert_block "$ZPROFILE" "asdf-java" '#. ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/java/set-java-home.zsh'
        log_done "Java plugin added."
        ;;
    esac
  done
}
