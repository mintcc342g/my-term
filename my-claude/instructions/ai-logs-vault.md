# ai-logs Obsidian Vault 운영

Obsidian vault 를 karpathy "LLM Wiki Pattern" 기반 compounding knowledge system 으로 운영. vault 위치는 사용자 환경에 따라 다름 (예: `~/Documents/my/ai-logs/`).

## 정본 = vault 내 schema.md

구조 / type / frontmatter / raw / Query 흡수 / 언어 컨벤션 / 3-op 등 **모든 운영 규칙은 vault 안의 `schema.md`** 가 정본. 작업 전 schema.md 먼저 확인.

## 언어 컨벤션

식별자성 vs 본문성 분리:

- **본문 (H1 포함 아래) 한국어** — 가독성 우선
- **파일명 / frontmatter / 태그 / wikilink 식별자: 영어** — filter / graph / link 일관성
- **frontmatter `title` ≠ H1**: title 은 영어 식별자, H1 은 한국어 본문 제목
- **`.base` 내부** (`displayName`, view `name`, filter 식): 영어
- **대화 / `.claude/memory/`: 한국어 (존댓말)**

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

응답 맨 끝에 한 줄:

```
📥 ingest 후보: `<제목>` (`<type>`, `<topic>`) — 한 줄 근거. 진행할까요?
🧹 lint 후보: <대상> — 한 줄 근거. 진행할까요?
```

User OK / Cancel 한 마디면 충분.

## 정기 lint (시간 기반)

vault 작업 시작 시 `log/<현재연도>.md` 의 마지막 `lint` 항목 날짜 확인. **한 달 이상 경과 시**:

```
🧹 정기 lint 시점 (마지막: YYYY-MM-DD). 진행할까요?
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
