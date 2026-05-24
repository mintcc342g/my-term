#!/usr/bin/env bash
#
# wk-trigger.sh — @wk 키워드로 wiki 컨텍스트 로드 모드를 Claude 에 주입
#
# Hook: UserPromptSubmit (동기)
# 트리거: 프롬프트에 "@wk" 포함 시 (위치 무관)
# 동작: 같은 디렉토리의 wk-directive.md 를 읽어 wiki path 치환 후 출력
#
# WIKI_PATH 는 install 시 my-term installer 가 sed 로 치환 (placeholder → 실제 경로).
# update_my_claude 호출 시 기존 deploy 된 파일에서 추출하여 재치환.
#

set -euo pipefail

KEYWORD="@wk"
WIKI_PATH="{{WIKI_PATH}}"

# --- stdin 에서 JSON 파싱 ---
raw_input="$(cat)"

if printf '%s' "$raw_input" | jq -e '.prompt' >/dev/null 2>&1; then
  prompt="$(printf '%s' "$raw_input" | jq -r '.prompt // ""')"
else
  prompt="$raw_input"
fi

# --- @wk 키워드 없으면 즉시 종료 ---
if [[ "$prompt" != *"$KEYWORD"* ]]; then
  exit 0
fi

# --- WIKI_PATH 미설정 / 경로 부재 시 안내 ---
# 참고: install 시 sed 가 안 돌면 WIKI_PATH 가 placeholder 문자열 그대로 남는데,
# 그건 디렉토리가 아니므로 아래 -d 체크에서 자연스럽게 잡힘.
if [ -z "$WIKI_PATH" ] || [ ! -d "$WIKI_PATH" ]; then
  cat <<EOF
[wiki 컨텍스트 로드 실패]

\`@wk\` 키워드가 감지됐으나 wiki 경로가 설정되지 않았거나 존재하지 않습니다.
(현재 값: "$WIKI_PATH")

사용자에게 다음을 안내하세요:
  - my-term install.sh 의 "Obsidian + wiki tooling" 단계로 재설정
EOF
  exit 0
fi

# --- directive 파일 로드 + 치환 + 주입 ---
DIRECTIVE_FILE="$(dirname "$0")/wk-directive.md"
if [[ -L "$DIRECTIVE_FILE" ]]; then
  printf '%s\n' "[@wk] 지시문 파일이 symlink입니다. 거부합니다."
  exit 1
fi
if [ ! -f "$DIRECTIVE_FILE" ]; then
  printf '%s\n' "[@wk] 지시문 파일이 없습니다: $DIRECTIVE_FILE"
  exit 1
fi

directive=$(<"$DIRECTIVE_FILE")
printf '%s\n' "${directive//\{\{WIKI_PATH\}\}/$WIKI_PATH}"
