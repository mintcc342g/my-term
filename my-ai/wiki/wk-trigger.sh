#!/usr/bin/env bash
#
# Inject wiki context when a submitted Claude Code or Codex prompt contains @wk.

set -euo pipefail

if [[ "${1:-}" != --instructions ]]; then
  raw_input="$(cat)"
  if printf '%s' "$raw_input" | jq -e '.prompt' >/dev/null 2>&1; then
    prompt="$(printf '%s' "$raw_input" | jq -r '.prompt // ""')"
  else
    prompt="$raw_input"
  fi
  [[ "$prompt" == *"@wk"* ]] || exit 0
fi

# Read the vault path as data so shell metacharacters stay literal.
hook_dir="$(dirname "$0")"
WIKI_PATH=""
if [[ -f "$hook_dir/wiki-path" && ! -L "$hook_dir/wiki-path" ]]; then
  WIKI_PATH="$(cat "$hook_dir/wiki-path")"
fi

if [ -z "$WIKI_PATH" ] || [ ! -d "$WIKI_PATH" ]; then
  [[ "${1:-}" != --instructions ]] || exit 1
  cat <<EOF
[wiki context load failed]

\`@wk\` was detected but the wiki path is not set or does not exist.
(current value: "$WIKI_PATH")

Please guide the user to:
  - reconfigure via the "Obsidian + wiki tooling" step of my-term install.sh
EOF
  exit 0
fi

# Load the directive and substitute the configured vault path.
DIRECTIVE_FILE="$hook_dir/wk-directive.md"
if [[ -L "$DIRECTIVE_FILE" ]]; then
  printf '%s\n' "[@wk] Directive file is a symlink. Refusing."
  exit 1
fi
if [ ! -f "$DIRECTIVE_FILE" ]; then
  printf '%s\n' "[@wk] Directive file not found: $DIRECTIVE_FILE"
  exit 1
fi

directive=$(<"$DIRECTIVE_FILE")
printf '%s\n' "${directive//\{\{WIKI_PATH\}\}/"$WIKI_PATH"}"
