#!/usr/bin/env bash
#
# codex-collab.sh — @co 키워드로 멀티 에이전트 협업 모드를 Claude에 주입
#
# Hook: UserPromptSubmit (동기)
# 트리거: 프롬프트에 "@co" 포함 시 (위치 무관)
# 동작: @co 제거 후 에이전트 설정을 읽어 Claude에 협업 지시문을 주입
#        (실제 에이전트 호출은 Claude가 MCP 도구로 병렬 수행)
#

set -euo pipefail

KEYWORD="@co"
AGENTS_CONFIG="$HOME/.claude/my-collab/co-agents.json"

# --- stdin에서 JSON 파싱 ---
raw_input="$(cat)"

if printf '%s' "$raw_input" | jq -e '.prompt' >/dev/null 2>&1; then
  prompt="$(printf '%s' "$raw_input" | jq -r '.prompt // ""')"
else
  prompt="$raw_input"
fi

# --- @co 키워드 없으면 즉시 종료 ---
if [[ "$prompt" != *"$KEYWORD"* ]]; then
  exit 0
fi

# --- @co 제거 후 프롬프트 추출 ---
clean_prompt="$(printf '%s' "$prompt" | jq -Rrs 'gsub("@co\\s*"; "") | gsub("^\\s+|\\s+$"; "")')"

if [[ -z "$clean_prompt" || "$clean_prompt" == '""' ]]; then
  printf '%s\n' "[co-mux] 프롬프트가 비어 있습니다."
  exit 0
fi

# --- 에이전트 설정 로드 ---
if [[ ! -f "$AGENTS_CONFIG" ]]; then
  printf '%s\n' "[co-mux] 에이전트 설정 파일이 없습니다: $AGENTS_CONFIG"
  exit 0
fi

# --- 에이전트 설정 파일 무결성 검증 ---
if [[ -L "$AGENTS_CONFIG" ]]; then
  printf '%s\n' "[co-mux] 에이전트 설정 파일이 symlink입니다. 거부합니다."
  exit 1
fi
config_owner=$(stat -f %u "$AGENTS_CONFIG" 2>/dev/null)
if [[ "$config_owner" != "$(id -u)" ]]; then
  printf '%s\n' "[co-mux] 에이전트 설정 파일 소유자가 현재 사용자와 다릅니다."
  exit 1
fi
config_perm=$(stat -f '%Lp' "$AGENTS_CONFIG" 2>/dev/null)
if [[ -n "$config_perm" && $((8#$config_perm & 077)) -ne 0 ]]; then
  chmod 600 "$AGENTS_CONFIG" 2>/dev/null || true
fi

agent_count="$(jq 'length' "$AGENTS_CONFIG" 2>/dev/null || printf '0')"
if [[ "$agent_count" -eq 0 ]]; then
  printf '%s\n' "[co-mux] 설정된 에이전트가 없습니다."
  exit 0
fi

# --- 에이전트 목록을 텍스트로 구성 (MCP 전용) ---
agent_list=""
while IFS=$'\t' read -r name server tool timeout params_json; do
  [ -z "$timeout" ] || [ "$timeout" = "null" ] && timeout=300000
  mcp_tool="mcp__${server}__${tool}"

  # params가 있으면 호출 시 포함할 파라미터 안내 생성
  params_note=""
  if [ -n "$params_json" ] && [ "$params_json" != "null" ] && [ "$params_json" != "{}" ]; then
    params_note=" (추가 파라미터: ${params_json})"
  fi

  agent_list="${agent_list}
- **${name}**: \`${mcp_tool}\` 도구를 호출하세요.${params_note} (timeout: ${timeout}ms)"
done < <(jq -r '.[] | [
  .name,
  .server,
  .tool,
  (.timeout // empty),
  (.params // {} | tostring)
] | @tsv' "$AGENTS_CONFIG" 2>/dev/null)

# --- Claude에 협업 지시문 주입 ---
DIRECTIVE_FILE="$(dirname "$0")/co-directive.md"
if [[ -L "$DIRECTIVE_FILE" ]]; then
  printf '%s\n' "[co-mux] 지시문 파일이 symlink입니다. 거부합니다."
  exit 1
fi
if [[ ! -f "$DIRECTIVE_FILE" ]]; then
  printf '%s\n' "[co-mux] 지시문 파일이 없습니다: $DIRECTIVE_FILE"
  exit 1
fi

directive=$(<"$DIRECTIVE_FILE")
printf '%s\n' "${directive//\{\{AGENT_LIST\}\}/$agent_list}"
