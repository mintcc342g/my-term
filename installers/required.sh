#!/bin/bash
# installers/required.sh — required tools (Homebrew + jq) and system checks
# source'd by install.sh

install_required() {
  # Both required tools already present — announce and skip the whole step
  # (no prompt, no reinstall). brew being on PATH means its shellenv is already
  # set up, so there's nothing left to do here.
  if command -v brew &>/dev/null && command -v jq &>/dev/null; then
    log_done "$L_REQ_ALREADY"
    sleep 1
    return 0
  fi

  local choice=""
  UI_MENU_NOTE=" ${UI_RED_BOLD}${L_REQ_NOTE}${UI_RESET}" \
    ui_menu "$L_REQ_TITLE" choice \
      "$L_YES" \
      "$L_NO_EXIT"

  echo
  if [ "$choice" != "0" ]; then
    log_fail "Required tools not installed. Exiting."
    echo
    exit 0
  fi

  # ── Verify macOS-bundled tools ────────────────────────────────
  local missing=()
  for _tool in curl git; do
    command -v "$_tool" &>/dev/null || missing+=("$_tool")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    log_fail "Missing system tool(s): ${missing[*]}"
    log_step "These come from macOS Command Line Tools. Run:"
    echo "    xcode-select --install"
    exit 1
  fi

  # ── Homebrew ─────────────────────────────────────────────────
  log_start "install Homebrew…"
  if ! command -v brew &>/dev/null; then
    log_step "Homebrew not found. Installing…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log_step "Homebrew found."
  fi

  # A fresh install doesn't add brew to the current shell's PATH, so `brew` here
  # would be "command not found" and abort under `set -e`. Locate the binary at
  # its known prefix (Apple Silicon: /opt/homebrew, Intel: /usr/local) and eval
  # shellenv ourselves before any brew call.
  local BREW_BIN=""
  if command -v brew &>/dev/null; then
    BREW_BIN=$(command -v brew)
  elif [ -x /opt/homebrew/bin/brew ]; then
    BREW_BIN=/opt/homebrew/bin/brew
  elif [ -x /usr/local/bin/brew ]; then
    BREW_BIN=/usr/local/bin/brew
  else
    log_fail "Homebrew install failed — brew binary not found."
    exit 1
  fi

  local ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"
  rc_upsert_block "$ZPROFILE" "brew-shellenv" "eval \"\$($BREW_BIN shellenv)\""
  eval "$($BREW_BIN shellenv)"

  # ── jq ───────────────────────────────────────────────────────
  if ! command -v jq &>/dev/null; then
    log_start "install jq…"
    brew install jq
  else
    log_step "jq found."
  fi

  log_done "Required tools ready."
  sleep 1
}
