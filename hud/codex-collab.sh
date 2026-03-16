#!/usr/bin/env bash
#
# codex-collab.sh — @co 키워드로 Codex 협업 응답을 Claude 컨텍스트에 주입
#
# Hook: UserPromptSubmit (동기)
# 트리거: 프롬프트에 "@co" 포함 시 (위치 무관)
# 동작: @co 제거 후 codex exec --json으로 전달, 토큰 누적 저장, stdout으로 결과 출력
#

set -euo pipefail

TIMEOUT="${CODEX_COLLAB_TIMEOUT:-60}"
KEYWORD="@co"

# --- 캐시 디렉토리 ---
cache_dir=""
if [ -n "${TMPDIR:-}" ] && [ -d "${TMPDIR%/}" ]; then
  cache_dir="${TMPDIR%/}/claude-hud"
else
  cache_dir="$HOME/Library/Caches/claude-hud"
fi
mkdir -p "$cache_dir" 2>/dev/null || true

CODEX_TOKEN_CACHE="$cache_dir/codex-tokens.json"

# --- stdin에서 프롬프트 읽기 ---
prompt="$(cat)"

# --- @co 키워드 없으면 즉시 종료 (출력 없음 → Claude에 영향 없음) ---
if [[ "$prompt" != *"$KEYWORD"* ]]; then
  exit 0
fi

# --- @co 제거 후 프롬프트 추출 ---
clean_prompt="${prompt//$KEYWORD /}"
clean_prompt="${clean_prompt//$KEYWORD/}"
clean_prompt="$(echo "$clean_prompt" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

if [[ -z "$clean_prompt" ]]; then
  echo "[codex-collab] 프롬프트가 비어 있습니다."
  exit 0
fi

# --- Codex exec 실행 (--json으로 토큰 정보 포함, stderr도 캡처) ---
raw_output=""
raw_stderr=""
raw_stderr="$(mktemp)"
trap 'rm -f "$raw_stderr"' EXIT

if raw_output="$(timeout "$TIMEOUT" codex exec --json --skip-git-repo-check "$clean_prompt" 2>"$raw_stderr")"; then
  # rate limit 감지 (stdout JSONL 또는 stderr에서)
  if printf '%s' "$raw_output" | grep -qi 'rate.limit\|quota.*exceeded\|too.many.requests\|429'; then
    echo "[codex-collab] Codex rate limit에 도달했습니다. Codex 응답 없이 Claude 단독으로 응답합니다."
    rm -f "$raw_stderr" 2>/dev/null; exit 0
  fi

  # JSONL에서 텍스트 응답 추출
  codex_result="$(printf '%s' "$raw_output" | grep '"type":"item.completed"' | jq -r '.item.text // empty' 2>/dev/null)"

  # JSONL에서 토큰 사용량 추출 및 누적
  turn_input="$(printf '%s' "$raw_output" | grep '"type":"turn.completed"' | jq -r '.usage.input_tokens // 0' 2>/dev/null)"
  turn_output="$(printf '%s' "$raw_output" | grep '"type":"turn.completed"' | jq -r '.usage.output_tokens // 0' 2>/dev/null)"
  turn_input="${turn_input:-0}"
  turn_output="${turn_output:-0}"

  # 현재 5h 윈도우의 resets_at 가져오기 (rate limit 리셋 시 토큰도 리셋)
  RL_CACHE="$cache_dir/ratelimit.json"
  current_resets_at=""
  if [ -f "$RL_CACHE" ]; then
    current_resets_at="$(jq -r '.five_hour.resets_at // ""' < "$RL_CACHE" 2>/dev/null)"
  fi

  # 기존 누적값 읽기 (윈도우가 바뀌었으면 리셋)
  prev_input=0
  prev_output=0
  if [ -f "$CODEX_TOKEN_CACHE" ]; then
    cached_resets_at="$(jq -r '.resets_at // ""' < "$CODEX_TOKEN_CACHE" 2>/dev/null)"
    if [ -n "$current_resets_at" ] && [ "$cached_resets_at" != "$current_resets_at" ]; then
      # 5h 윈도우가 변경됨 → 누적값 리셋
      prev_input=0
      prev_output=0
    else
      prev_input="$(jq -r '.total_input // 0' < "$CODEX_TOKEN_CACHE" 2>/dev/null)"
      prev_output="$(jq -r '.total_output // 0' < "$CODEX_TOKEN_CACHE" 2>/dev/null)"
    fi
  fi

  # 누적 저장 (resets_at 포함)
  new_input=$((prev_input + turn_input))
  new_output=$((prev_output + turn_output))
  resets_at_field=""
  [ -n "$current_resets_at" ] && resets_at_field="\"resets_at\":\"$current_resets_at\","
  printf '{%s"total_input":%d,"total_output":%d,"last_input":%d,"last_output":%d}\n' \
    "$resets_at_field" "$new_input" "$new_output" "$turn_input" "$turn_output" > "$CODEX_TOKEN_CACHE"

  if [ -n "$codex_result" ]; then
    cat <<EOF
━━━ Codex 응답 ━━━
$codex_result
━━━━━━━━━━━━━━━━━━
위 Codex 응답과 당신의 분석을 비교·합성하여 최선의 답변을 제공하세요. 의견이 다른 부분은 명시하세요.
EOF
  else
    echo "[codex-collab] Codex가 빈 응답을 반환했습니다. Claude 단독으로 응답합니다."
  fi
else
  exit_code=$?
  stderr_content="$(cat "$raw_stderr" 2>/dev/null)"

  # stderr에서 rate limit 감지
  if printf '%s' "$stderr_content" | grep -qi 'rate.limit\|quota.*exceeded\|too.many.requests\|429'; then
    echo "[codex-collab] Codex rate limit에 도달했습니다. Codex 응답 없이 Claude 단독으로 응답합니다."
  elif [[ $exit_code -eq 124 ]]; then
    echo "[codex-collab] Codex 응답 시간 초과 (${TIMEOUT}초). Claude 단독으로 응답합니다."
  else
    echo "[codex-collab] Codex 실행 실패 (exit: $exit_code). Claude 단독으로 응답합니다."
  fi
fi
