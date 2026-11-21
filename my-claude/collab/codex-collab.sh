#!/usr/bin/env bash
#
# Inject Claude Code collaboration instructions when a prompt contains @co.
#
# Use a synchronous UserPromptSubmit hook.
# Match @co anywhere in the prompt.
# Strip @co, read the agent configuration, and inject the collaboration instructions.
# Claude Code invokes the configured agents in parallel through their MCP tools.
#

set -euo pipefail

KEYWORD="@co"
AGENTS_CONFIG="$HOME/.claude/my-collab/co-agents.json"

# Parse JSON from stdin.
raw_input="$(cat)"

if printf '%s' "$raw_input" | jq -e '.prompt' >/dev/null 2>&1; then
  prompt="$(printf '%s' "$raw_input" | jq -r '.prompt // ""')"
else
  prompt="$raw_input"
fi

# Exit early when the prompt contains no @co.
if [[ "$prompt" != *"$KEYWORD"* ]]; then
  exit 0
fi

# Extract the prompt with @co removed.
clean_prompt="$(printf '%s' "$prompt" | jq -Rrs 'gsub("@co\\s*"; "") | gsub("^\\s+|\\s+$"; "")')"

if [[ -z "$clean_prompt" || "$clean_prompt" == '""' ]]; then
  printf '%s\n' "[co-mux] Empty prompt."
  exit 0
fi

# Load the agent configuration.
if [[ ! -f "$AGENTS_CONFIG" ]]; then
  printf '%s\n' "[co-mux] Agent config file not found: $AGENTS_CONFIG"
  exit 0
fi

# Validate the agent configuration file.
if [[ -L "$AGENTS_CONFIG" ]]; then
  printf '%s\n' "[co-mux] Agent config file is a symlink. Refusing."
  exit 1
fi
config_owner=$(stat -f %u "$AGENTS_CONFIG" 2>/dev/null)
if [[ "$config_owner" != "$(id -u)" ]]; then
  printf '%s\n' "[co-mux] Agent config file owner differs from the current user."
  exit 1
fi
config_perm=$(stat -f '%Lp' "$AGENTS_CONFIG" 2>/dev/null)
if [[ -n "$config_perm" && $((8#$config_perm & 077)) -ne 0 ]]; then
  chmod 600 "$AGENTS_CONFIG" 2>/dev/null || true
fi

agent_count="$(jq 'length' "$AGENTS_CONFIG" 2>/dev/null || printf '0')"
if [[ "$agent_count" -eq 0 ]]; then
  printf '%s\n' "[co-mux] No agents configured."
  exit 0
fi

# Build a text list of the configured MCP agents.
agent_list=""
while IFS=$'\t' read -r name server tool timeout params_json; do
  [ -z "$timeout" ] || [ "$timeout" = "null" ] && timeout=300000
  mcp_tool="mcp__${server}__${tool}"

  # Include any configured parameters in the tool instructions.
  params_note=""
  if [ -n "$params_json" ] && [ "$params_json" != "null" ] && [ "$params_json" != "{}" ]; then
    params_note=" (extra params: ${params_json})"
  fi

  agent_list="${agent_list}
- **${name}**: call the \`${mcp_tool}\` tool.${params_note} (timeout: ${timeout}ms)"
done < <(jq -r '.[] | [
  .name,
  .server,
  .tool,
  (.timeout // empty),
  (.params // {} | tostring)
] | @tsv' "$AGENTS_CONFIG" 2>/dev/null)

# Print the collaboration instructions for Claude Code.
DIRECTIVE_FILE="$(dirname "$0")/co-directive.md"
if [[ -L "$DIRECTIVE_FILE" ]]; then
  printf '%s\n' "[co-mux] Directive file is a symlink. Refusing."
  exit 1
fi
if [[ ! -f "$DIRECTIVE_FILE" ]]; then
  printf '%s\n' "[co-mux] Directive file not found: $DIRECTIVE_FILE"
  exit 1
fi

directive=$(<"$DIRECTIVE_FILE")
printf '%s\n' "${directive//\{\{AGENT_LIST\}\}/$agent_list}"
