#!/usr/bin/env bash
#
# codex-collab.sh — @co 키워드로 멀티 에이전트 협업 모드를 Claude에 주입
#
# Hook: UserPromptSubmit (동기)
# 트리거: 프롬프트에 "@co" 포함 시 (위치 무관)
# 동작: @co 제거 후 에이전트 설정을 읽어 Claude에 협업 지시문을 주입
#        (실제 에이전트 호출은 Claude가 Bash 도구로 병렬 수행)
#

set -euo pipefail

KEYWORD="@co"
AGENTS_CONFIG="$HOME/.claude/my-hud/co-agents.json"

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

# --- 에이전트 목록을 텍스트로 구성 ---
agent_list=""
while IFS=$'\t' read -r name command timeout; do
  [ -z "$timeout" ] || [ "$timeout" = "null" ] && timeout=300000
  agent_list="${agent_list}
- **${name}**: \`${command}\` (timeout: ${timeout}ms)"
done < <(jq -r '.[] | [.name, .command, (.timeout // empty)] | @tsv' "$AGENTS_CONFIG" 2>/dev/null)

# --- Claude에 협업 지시문 주입 ---
cat <<EOF
[멀티 에이전트 협업 모드 활성화]

아래 절차를 반드시 따르세요:

1. 현재 대화에서 유저의 질문과 관련된 컨텍스트를 정리하세요.
   - plan이 있으면 plan 전문 포함
   - 분석 중인 데이터, 설계 결정, 관련 파일 목록 등 포함
   - 관련 없는 대화는 제외

2. 아래 에이전트들을 Bash 도구로 호출하세요.
   - 에이전트가 여러 개일 경우: 한 메시지에서 여러 Bash 도구 호출을 동시에 보내세요 (병렬 실행).
   - run_in_background는 사용하지 마세요. 일반 foreground Bash 호출을 여러 개 병렬로 보내면 됩니다.
   - 각 에이전트에 [정리한 컨텍스트 + 유저 프롬프트]를 전달합니다.
   - **중요**: 반드시 \`</dev/null\`을 명령 끝에 붙여 stdin을 닫으세요.
   - 각 에이전트의 timeout 값을 Bash 도구의 timeout 파라미터로 전달하세요.
${agent_list}

3. 중요: 모든 에이전트의 응답이 도착할 때까지 기다리세요.
   응답이 오기 전에 최종 답변을 작성하지 마세요.

4. 모든 에이전트의 응답이 도착한 후, 당신의 자체 분석과 함께 아래 형식으로 비판적 분석 + 병합 응답을 작성하세요:
   - 각 에이전트의 핵심 의견을 요약
   - 에이전트 간 의견이 다른 부분을 명시하고, 당신의 판단을 근거와 함께 제시
   - 에이전트 간 의견이 같은 부분은 간결하게 정리
   - 최종 종합 답변 제시

5. 에이전트가 에러/타임아웃으로 실패한 경우:
   - 반드시 "[에이전트명 실패]"를 명시
   - 나머지 에이전트 결과 + 당신의 분석으로 응답

6. 모든 에이전트 호출이 완료된 후, Codex usage 캐시를 갱신하세요:
   \`cache_dir="\$HOME/.claude/my-hud/cache" bash "\$HOME/.claude/my-hud/refresh-codex-usage.sh"\`

7. 반드시 한국어(Korean)로 응답하세요.
EOF
