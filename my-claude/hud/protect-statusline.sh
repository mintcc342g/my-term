#!/usr/bin/env bash
#
# Protect custom statusline from being overwritten by OMC setup.
# Runs as a PostToolUse hook — zero token cost.
#

set -euo pipefail
umask 077

SETTINGS="$HOME/.claude/settings.json"
EXPECTED_CMD="bash $HOME/.claude/my-hud/statusline.sh"
tmp_dir="$HOME/.claude/my-hud/tmp"

mkdir -p "$tmp_dir" 2>/dev/null || true
chmod 700 "$tmp_dir" 2>/dev/null || true

# Read hook input from stdin
input=$(cat)

# Only act if the tool touched settings.json
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.filePath // .tool_input.path // .tool_input.command // ""' 2>/dev/null)
case "$file_path" in
  *settings.json*) ;;
  *) exit 0 ;;
esac

[ ! -f "$SETTINGS" ] && exit 0

# Check if statusLine command was changed
LOCK="$tmp_dir/settings.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  # Stale lock: 소유 프로세스가 죽었으면 제거 후 재시도
  if [ -f "$LOCK/pid" ]; then
    lock_pid=$(cat "$LOCK/pid" 2>/dev/null)
    if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
      rm -rf "$LOCK" 2>/dev/null
      mkdir "$LOCK" 2>/dev/null || exit 0
    else
      exit 0
    fi
  else
    exit 0
  fi
fi
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK" 2>/dev/null' EXIT
current_cmd=$(jq -r '.statusLine.command // ""' "$SETTINGS" 2>/dev/null)
if [ "$current_cmd" != "$EXPECTED_CMD" ]; then
  tmp=$(mktemp "$tmp_dir/settings.XXXXXX")
  if jq --arg cmd "$EXPECTED_CMD" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
  else
    rm -f "$tmp" 2>/dev/null || true
  fi
fi
