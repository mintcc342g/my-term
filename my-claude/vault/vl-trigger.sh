#!/usr/bin/env bash
#
# vl-trigger.sh — @vl 키워드로 Obsidian vault 컨텍스트 로드 모드를 Claude 에 주입
#
# Hook: UserPromptSubmit (동기)
# 트리거: 프롬프트에 "@vl" 포함 시 (위치 무관)
# 동작: vault 검색 / 활용 directive 주입 (subcmd 분기 없음)
#
# subcmd 가 없는 이유:
#   - 검색 / save / list 는 obsidian-skills (obsidian-cli, obsidian-markdown 등) 가 처리
#   - lint 는 휴리스틱 자동 점검 (instruction 의 3-op 규칙)
#   - @vl 은 vault 컨텍스트 명시 로드만 담당
#
# vault 위치는 OBSIDIAN_VAULT_PATH env var 로 지정 (my-term installer 가 zshrc 에 export).
#

set -euo pipefail

KEYWORD="@vl"
VAULT_PATH="${OBSIDIAN_VAULT_PATH:-}"

# --- stdin 에서 JSON 파싱 ---
raw_input="$(cat)"

if printf '%s' "$raw_input" | jq -e '.prompt' >/dev/null 2>&1; then
  prompt="$(printf '%s' "$raw_input" | jq -r '.prompt // ""')"
else
  prompt="$raw_input"
fi

# --- @vl 키워드 없으면 즉시 종료 ---
if [[ "$prompt" != *"$KEYWORD"* ]]; then
  exit 0
fi

# --- VAULT_PATH 미설정 / 경로 부재 시 안내 ---
if [ -z "$VAULT_PATH" ] || [ ! -d "$VAULT_PATH" ]; then
  cat <<EOF
[vault 컨텍스트 로드 실패]

\`@vl\` 키워드가 감지됐으나 OBSIDIAN_VAULT_PATH env var 가 설정되지 않았거나
경로가 존재하지 않습니다. (현재 값: "$VAULT_PATH")

사용자에게 다음을 안내하세요:
  - \`export OBSIDIAN_VAULT_PATH=<your-vault-path>\` (zshrc 추가 후 셸 재시작)
  - 또는 my-term install.sh 의 "Obsidian + vault tooling" 단계로 재설정
EOF
  exit 0
fi

# --- directive 주입 ---
cat <<EOF
[vault 컨텍스트 모드 활성화]

사용자 메시지에 \`@vl\` 이 포함됨 — Obsidian vault 컨텍스트를 활용해 답변하세요.

## vault

- 위치: $VAULT_PATH
- 정본: vault 내 \`schema.md\` (구조 / type / frontmatter / 운영 컨벤션 / 3-op 등)

## 동작

1. 사용자 메시지의 \`@vl\` 외 텍스트를 쿼리 / 주제로 해석
2. vault 검색 — \`obsidian-cli\` skill 또는 Grep + Read 활용
3. 관련 노트 발견 시 본문 읽고 답변에 활용 (출처 wikilink 로 표시)
4. 검색 결과 처리:
   - **없음**: "vault 에 관련 노트 없음" 한 줄 알리고 일반 답변
   - **다수**: 후보 한 줄로 보고 ("X 관련 노트 N개 — 어떤 거?")
   - **명확**: 본문 읽고 답변에 활용

## 부수 동작 (자연어 의도 시)

\`@vl\` 외에 사용자가 다음 의도 표현 시 해당 동작:
- "저장 / 정리" → 현재 대화 ingest (\`obsidian-markdown\` skill + schema 컨벤션)
- "lint" → 정기 점검 사이클 (instruction 의 3-op 규칙 기준)
- "목록 / list" → vault 노트 목록 출력

## 응답

- \`@vl\` 키워드 자체는 답변에서 무시 (응답에 \`@vl\` 언급 X)
- 활용한 노트는 wikilink 로 명시
EOF
