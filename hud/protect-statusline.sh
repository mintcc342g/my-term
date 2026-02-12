#!/usr/bin/env bash
#
# Protect custom powerline statusline from being overwritten by OMC setup.
# Runs as a PostToolUse hook — zero token cost.
#

SETTINGS="$HOME/.claude/settings.json"
EXPECTED_CMD="bash $HOME/.claude/hud/powerline-statusline.sh"

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
current_cmd=$(jq -r '.statusLine.command // ""' "$SETTINGS" 2>/dev/null)
if [ "$current_cmd" != "$EXPECTED_CMD" ]; then
  tmp=$(mktemp)
  if jq --arg cmd "$EXPECTED_CMD" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
  else
    rm -f "$tmp" 2>/dev/null || true
  fi
fi
