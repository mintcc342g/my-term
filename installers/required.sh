#!/bin/bash
# installers/required.sh — required tools (Homebrew + jq) and system checks
# source'd by install.sh

install_required() {
  local choice=""
  ui_menu "Install required tools (Homebrew + jq)? This installer needs them." choice \
    "Yes" \
    "No"

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

  local BREW_PREFIX
  BREW_PREFIX=$(brew --prefix)
  local ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"
  rc_upsert_block "$ZPROFILE" "brew-shellenv" "eval \"\$($BREW_PREFIX/bin/brew shellenv)\""
  eval "$($BREW_PREFIX/bin/brew shellenv)"

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
