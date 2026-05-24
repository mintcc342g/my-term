# Obsidian Vault 운영

vault 위치: `$OBSIDIAN_VAULT_PATH` (zshrc export). 모든 운영 규칙 정본은 vault 내 `schema.md`. 작업 전 먼저 확인.

## @vl 트리거

사용자 메시지에 `@vl` 포함 시 hook (`~/.claude/my-vault/vl-trigger.sh`) 이 vault directive 주입. 휴리스틱 추정 X — 명시 표시만 따름. 검색 / save / list 등 동작은 obsidian-skills (`obsidian-cli`, `obsidian-markdown` 등) 자동 호출.

## 3-op 자동 점검

매 응답 끝 대화 휴리스틱 점검 → 후보 있으면 한 줄 보고.

**Ingest 후보**: 의사결정 합의 / 사실 확인 거친 답 / 옵션 비교 후 선택 / 재사용 가능 일반화 / 진행 작업 확정
**Lint 후보**: 사실 정정 / 컨벤션 진화 / 노트 간 모순 / 흡수됐어야 할 query 누락
**안 함**: 단순 Q&A / 코드 수정 · 명령 실행 / 토론 진행 중

보고 형식 (대상은 항상 vault `$OBSIDIAN_VAULT_PATH`. Claude memory 와 혼동 X):

```
📥 vault ingest 후보: `<제목>` (`<type>`, `<topic>`) — 한 줄 근거. 진행할까요?
🧹 vault lint 후보: <대상> — 한 줄 근거. 진행할까요?
```

## 정기 lint

vault 작업 시작 시 `log/<연도>.md` 마지막 `lint` 항목 날짜 확인. **한 달 이상 경과 시** 제안:

```
🧹 vault 정기 lint 시점 (마지막: YYYY-MM-DD). 진행할까요?
```

## 거부 / 우회

- "no" / "skip" / "됐어" → 즉시 중단, 같은 세션 반복 제안 X
- 명시 트리거 ("저장해줘" / "lint 돌려줘") → 휴리스틱 우회, 무조건 진행
