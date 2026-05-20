# Obsidian Vault 운영

Obsidian vault 를 karpathy "LLM Wiki Pattern" 기반 compounding knowledge system 으로 운영. vault 위치는 `$OBSIDIAN_VAULT_PATH` env var 로 지정 (my-term installer 가 zshrc 에 export).

## 정본 = vault 내 schema.md

구조 / type / frontmatter / raw / Query 흡수 / 언어 컨벤션 / 3-op 등 **모든 운영 규칙은 vault 안의 `schema.md`** 가 정본. 작업 전 schema.md 먼저 확인. 언어 / 파일명 / 태그 컨벤션 같은 user 별 세부 규칙은 schema.md 에 정의하고 본 instruction 은 메타 규칙만 다룸.

## @vl 명시 트리거

사용자 메시지에 `@vl` 포함 시 hook (`~/.claude/my-vault/vl-trigger.sh`) 이 vault 활용 directive 를 동기 주입. 회상 표현 휴리스틱 추정 X — 명시 표시만 따름.

`@vl` 은 **vault 컨텍스트 로드** 만 담당:
- 검색 / save / list 같은 동작은 obsidian-skills (`obsidian-cli`, `obsidian-markdown` 등) 자동 호출
- lint 는 휴리스틱 자동 점검 (아래 3-op 규칙)

자세한 directive 내용은 hook script 안의 inline 정의 참고.

## 3-op 자동 점검

매 응답 끝 대화 내용 휴리스틱으로 점검 → 후보 있으면 한 줄 보고. raw B 모드와 같은 자동 판단 + 거부권 패턴.

### Ingest 후보 신호

| 신호 | 추정 type |
|---|---|
| 의사결정 합의 ("그렇게 가자" / "이게 맞아") | decision |
| 사실 확인 거친 답 (검색 / 공식 문서 인용) | concept 또는 기존 페이지 갱신 |
| 여러 옵션 비교 후 선택 (trade-off) | decision |
| 재사용 가능한 일반화 (개념 / 원리) | concept |
| 진행 중 작업 / 이니셔티브 확정 | project |

### Lint 후보 신호

- 사실 정정 / "이전 결정 틀렸네"
- schema / 컨벤션 진화
- 노트 간 모순 발견
- 흡수됐어야 할 query 누락 발견

### 안 함 신호

- 단순 Q&A ("X 가 뭐야?" + 단답)
- 코드 수정 / 명령 실행
- 토론 진행 중 (결론 안 남)

### 보고 형식

응답 맨 끝에 한 줄. **대상은 항상 Obsidian vault** (`$OBSIDIAN_VAULT_PATH`). Claude memory (`~/.claude/projects/*/memory/`) 와 혼동 X — 메모리 저장은 user 가 "메모리에 저장" / "feedback 등록" 같이 명시 요청 시에만 별도 처리.

```
📥 vault ingest 후보: `<제목>` (`<type>`, `<topic>`) — 한 줄 근거. 진행할까요?
🧹 vault lint 후보: <대상> — 한 줄 근거. 진행할까요?
```

User OK / Cancel 한 마디면 충분.

## 정기 lint (시간 기반)

vault 작업 시작 시 `log/<현재연도>.md` 의 마지막 `lint` 항목 날짜 확인. **한 달 이상 경과 시**:

```
🧹 vault 정기 lint 시점 (마지막: YYYY-MM-DD). 진행할까요?
```

User OK 시 lint 사이클 (schema 대조 / orphan / stale / 모순 / 흡수 누락).

## 거부 / 우회

- User "no" / "skip" / "됐어" → 즉시 중단, 같은 세션 반복 제안 X
- User 명시 트리거 ("저장해줘" / "lint 돌려줘") → 휴리스틱 우회, 무조건 진행

## kepano/obsidian-skills plugin

설치 명령 (Claude Code 첫 실행 후):

```
/plugin marketplace add kepano/obsidian-skills
/plugin install obsidian@obsidian-skills
```

활용 skill:

| Skill | 용도 |
|---|---|
| `obsidian-markdown` | `.md` 작성 — wikilink / callout / frontmatter |
| `obsidian-bases` | `.base` 동적 뷰 (table / cards / list / map) |
| `json-canvas` | `.canvas` 시각 맵 (아키텍처 / 마인드맵) |
| `obsidian-cli` | Obsidian CLI 로 vault 조작 (Obsidian 1.12+ 내장 CLI: Settings → Command line interface → Register CLI) |
| `defuddle` | 웹 URL → clean markdown (별도 `npm i -g defuddle-cli` 필요) |

자동 호출 (description 매칭). 명시 호출 시 `/obsidian:<skill-name>`.
