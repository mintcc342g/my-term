---
title: Schema
type: meta
status: active
created: {{INSTALL_DATE}}
updated: {{INSTALL_DATE}}
tags:
  - meta
  - vault-system
---

<!-- DEFAULT_SCHEMA_GREETING:BEGIN -->
> [!info] **기본 schema 안내 (첫 안내 후 삭제 대상)**
>
> 이 schema 는 my-term installer 가 기본값으로 생성한 것입니다. 사용자에게 다음을 안내한 후 이 `DEFAULT_SCHEMA_GREETING` 블록 전체를 삭제하세요:
>
> 1. schema 의 핵심 구조 한 줄씩 (폴더 / frontmatter / type / 3-op)
> 2. user 가 이 기본 schema 를 그대로 사용할지, 수정할지 묻기
> 3. user 응답 후 이 블록을 마커 (`<!-- DEFAULT_SCHEMA_GREETING:BEGIN -->` ~ `<!-- DEFAULT_SCHEMA_GREETING:END -->`) 포함 통째로 제거하고 frontmatter 의 `updated:` 를 오늘 날짜로 갱신
<!-- DEFAULT_SCHEMA_GREETING:END -->

# 스키마

이 vault 의 구조 · type · 운영 규칙 정본. LLM 과 user 모두 이 문서를 기준으로 노트를 만들고 유지한다.

## 목적

이 vault 는 **다중 머신·세션 간 컨텍스트 연속성** 저장소다.

AI agent 메모리 (Claude `~/.claude/`, Codex `~/.codex/` 등) 는 머신 종속이라 다른 머신·재설치·새 세션에서 손실·단절된다. vault 는 git 으로 동기화되어 머신·세션·도구가 바뀌어도 user 와 agent 가 같은 작업을 자연스럽게 이어갈 수 있게 한다.

karpathy LLM Wiki Pattern (compounding knowledge) 은 그 위에 얹은 부산물이지 primary 가 아니다. **primary 는 작업 연속성**.

## 구조 원칙: 폴더 + frontmatter 2-tier 분류

- **폴더 = 상위 범주** (`works/`, `meta/`)
- **frontmatter `topic` = 폴더 하위 세부 주제** (예: `vault-structure`, `api-design`)
- 시스템 폴더 (별도): `raw/`, `views/`

```
{{WIKI_NAME}}/
├── schema.md, index.md, log.md   # 시스템 (root)
├── views/                        # Bases 동적 뷰
├── raw/                          # 원본 대화
├── meta/                         # vault 자체 결정/규칙
├── works/                        # 업무 프로젝트
│   └── <project>/<file>.md
└── toy/                          # 개인 프로젝트
    └── <file>.md
```

## Frontmatter 컨벤션

### 필수

```yaml
---
title: Note Title (English)
type: concept | decision | project
topic: <세부 슬러그>     # 예: vault-structure, api-design
status: draft | active | stale
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []
---
```

### 선택

- `sources: ["[[raw/...]]"]` — 원본 대화 링크
- `project: <이름>` — 프로젝트 소속
- `related: ["[[...]]"]` — 연관 노트

## Type 정의

| type | 의미 | 예 |
|---|---|---|
| `concept` | 개념 · 원리 · 패턴 | Dependency Injection Pattern |
| `decision` | 의사결정 + 근거 | Database Choice — Postgres vs MySQL |
| `project` | 진행 중 작업 | API Server Refactor |

## Topic Slugs

폴더 하위 **세부 주제**. 폴더보다 구체적. 소문자 케밥.

| 폴더 | topic 예 |
|---|---|
| `meta/` | `vault-structure`, `vault-system` |
| `works/<project>/` | `api-design`, `infra-config`, `deployment` |
| `toy/` | `commit-convention`, `dev-workflow`, `editor-tooling` |

한 폴더 안에서 `topic` 별 group 필요해지면 Bases 로.

## 분류 도구 매핑

| 차원 | 구현 |
|---|---|
| 상위 범주 | 폴더 (`works/<project>/`, `meta/`) |
| 세부 주제 | `topic:` frontmatter |
| 종류 | `type:` frontmatter |
| 상태 | `status:` frontmatter |
| 날짜 | `created:`, `updated:` |
| 자유 | `tags:` |
| 관계 | `[[wikilink]]` |
| 동적 그룹 | `views/*.base` |

## 파일명

**파일명 = 영어 노트 제목** (frontmatter `title` 과 동일).

- 영어 식별자, 케밥 케이스 / 날짜 prefix 금지
- 날짜는 frontmatter `created:` 가 책임짐
- 같은 제목 충돌 시 제목을 더 구체화 (예: `Job vs Deployment (k8s)`)
- 시스템 파일 (`schema.md`, `index.md`, `log.md`, `views/*.base`) 동일

## Raw 저장 정책 (B 모드)

기본 모드: **LLM 자동 판단 + user 거부권**.

### 남김
- 의사결정 근거가 빽빽한 토론
- 사실 확인 / 검증 거친 대화
- 다른 wiki 페이지의 `sources:` 로 link 될 만한 대화

### 안 남김
- 단순 명령 실행
- 단순 질의응답
- 정제 끝나 wiki 에 100% 흡수된 대화

### 절차
대화 끝나면 LLM 한 줄 보고. user OK / Cancel.

### Raw 파일명
`raw/<Note Title>.md` (영어, 케밥 / 날짜 prefix 금지). 날짜는 `date:` frontmatter.

## 3-Op (karpathy LLM Wiki Pattern)

| op | 동작 |
|---|---|
| **Ingest** | 새 자료 → 관련 wiki 페이지 갱신 + [[log]] 기록 |
| **Query** | 질문 → wiki 활용해서 답. 가치 있는 답은 새 페이지로 + [[log]] |
| **Lint** | 주기적 점검: 모순 · stale · orphan · 끊긴 참조 + [[log]] |

3-op 의 모든 실행은 [[log]] **연도 파일** (`log/<YYYY>.md`) 에 prefix 형식 (`## [YYYY-MM-DD] ingest|query|lint | 제목`) 으로 기록. [[log]] 자체는 인덱스. file 수준 변경은 git 이 책임.

### Query 흡수 정책

karpathy: "Good answers can be filed back into the wiki as new pages."

답이 wiki 에 흡수될지 판단 기준:

| 조건 | 처리 |
|---|---|
| 재사용 가능 + 일반성 (개념/원리) | **새 페이지** (`concept` type) |
| 기존 wiki 페이지에 자연스럽게 끼움 | **기존 페이지 갱신** |
| 일회성, 절차적, 짧음 | **흡수 안 함** (log 의 query 항목만) |

3가지 신호:
- **재사용성** — 다른 query 답할 때 다시 참조될 가능성
- **일반성** — 특정 시점/맥락 무관하게 valid
- **밀도** — 답이 단락 이상의 부피

흡수 안 한 query 도 log 에 기록 가능. lint 시 "흡수 누락" 점검.

## 진화 원칙

- 처음 5–10 개 대화에서 패턴 관찰
- 새 type / 필드는 schema 에 반영
- 3-op 실행은 [[log]] 에 기록

## 언어 컨벤션

식별자성 텍스트와 본문성 텍스트를 구분:

- **본문 (H1 포함 아래) 한국어** — 가독성 우선
- **파일명 / frontmatter / 태그 / wikilink 식별자: 영어** — filter / graph / link 일관성
- **frontmatter `title` ≠ H1**: title 은 영어 식별자, H1 은 한국어 본문 제목
- **`.base` 내부** (`displayName`, view `name`, filter 식): 영어
- **대화 / `.claude/memory/`: 한국어 (존댓말)**

## Obsidian 문법 (자주 쓰는 것)

- 링크: `[[Note Name]]`, `[[Note Name|표시]]`, `[[Note Name#Heading]]`
- 임베드: `![[Note Name]]`, `![[image.png|300]]`
- 인라인 태그: `#tag`, `#nested/tag`
- Callout: `> [!info] 제목` (`note`/`tip`/`warning`/`info`/`example`/`quote`/`bug`/`danger`/`success`/`failure`/`question`/`abstract`/`todo`)
- 하이라이트: `==텍스트==`
- 숨김: `%%hidden%%`
- 블록 ID: `텍스트 ^block-id`
