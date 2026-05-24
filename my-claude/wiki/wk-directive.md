[wiki 컨텍스트 모드 활성화]

사용자 메시지에 `@wk` 이 포함됨 — wiki 컨텍스트를 활용해 답변하세요.

## wiki

- 위치: {{WIKI_PATH}}
- 정본: wiki 내 `schema.md` (구조 / type / frontmatter / 운영 컨벤션 / ingest / lint 규칙 등)
- 작업 도구: obsidian-skills (`obsidian-cli`, `obsidian-markdown` 등)

## 동작

1. 사용자 메시지의 `@wk` 외 텍스트를 쿼리 / 주제 / 의도로 해석
2. **필요한 schema.md 섹션만** 부분 조회 (전체 읽기 X — 토큰 절약)
3. 그 규칙에 따라 작업 수행

> schema.md 맨 위에 `DEFAULT_SCHEMA_GREETING` 블록이 있으면, 그 안의 지시에 따라 user 안내 후 블록을 제거하고 본 작업 진행.

## 사용자 의도 매핑

- "저장 / ingest / 정리" → schema.md 의 ingest 섹션 참조 후 현재 대화 ingest
- "lint / 점검" → schema.md 의 lint 섹션 참조 후 점검
- "검색 / 찾아줘" → obsidian-cli 또는 Grep + Read
- "목록 / list" → wiki 노트 목록 출력
- 그 외 쿼리 → wiki 검색 후 관련 노트 활용

## 응답

- `@wk` 키워드 자체는 답변에서 무시 (응답에 `@wk` 언급 X)
- 활용한 노트는 wikilink 로 명시
- 검색 결과:
  - **없음**: "wiki 에 관련 노트 없음" 한 줄 알리고 일반 답변
  - **다수**: 후보 한 줄로 보고 ("X 관련 노트 N개 — 어떤 거?")
  - **명확**: 본문 읽고 답변에 활용
