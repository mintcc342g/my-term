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
> [!info] **Default schema notice (delete after the first guidance)**
>
> This schema was created as a default by the my-term installer. After guiding the user through the following, delete this entire `DEFAULT_SCHEMA_GREETING` block:
>
> 1. The core structure of the schema, one line each (folders / frontmatter / type / 3-op)
> 2. Ask whether the user wants to use this default schema as-is or modify it
> 3. After the user responds, remove this block in full (including the markers `<!-- DEFAULT_SCHEMA_GREETING:BEGIN -->` ~ `<!-- DEFAULT_SCHEMA_GREETING:END -->`) and update `updated:` in the frontmatter to today's date
<!-- DEFAULT_SCHEMA_GREETING:END -->

# Schema

The source of truth for this vault's structure, types, and operating rules. Both the LLM and the user create and maintain notes based on this document.

## Purpose

This vault is a store for **context continuity across machines and sessions**.

AI agent memory (Claude `~/.claude/`, Codex `~/.codex/`, etc.) is machine-bound, so it is lost or broken across different machines, reinstalls, and new sessions. The vault is synced via git so the user and the agent can naturally continue the same work even when the machine, session, or tool changes.

The karpathy LLM Wiki Pattern (compounding knowledge) is a byproduct layered on top, not the primary goal. **The primary goal is work continuity.**

## Memory Unification

A corollary of `## Purpose`: **the single store for persistent information is the wiki note.** Don't use AI agent memory (Claude `~/.claude/.../memory/`, etc.) — it's machine-bound, so continuity breaks.

- **No referencing**: when writing notes, don't cite or link AI agent memory. The rationale must exist as a wiki note, and you link that with `[[link]]`.
- **No storing**: don't write new entries into AI agent memory.
- **Memory-like info → `memory` tag**: when "worth remembering" info appears (user preferences · feedback · working principles), make it a wiki note and add `memory` to `tags`. `type` follows its nature (`decision`/`concept`), the folder follows the related project (cross-cutting identification via the `memory` tag). Retrieve it from the wiki too (`tag:#memory` search / Bases).

## Structure Principle: folder + frontmatter 2-tier classification

- **Folder = top-level category** (`works/`, `meta/`)
- **frontmatter `topic` = sub-topic under the folder** (e.g. `vault-structure`, `api-design`)
- System folders (separate): `raw/`, `views/`

```
{{WIKI_NAME}}/
├── schema.md, index.md, log.md   # system (root)
├── views/                        # Bases dynamic views
├── raw/                          # original conversations
├── meta/                         # the vault's own decisions/rules
├── works/                        # work projects
│   └── <project>/<file>.md
└── toy/                          # personal projects
    └── <file>.md
```

## Frontmatter Convention

### Required

```yaml
---
title: Note Title (English)
type: concept | decision | project
topic: <sub-slug>     # e.g. vault-structure, api-design
status: draft | active | stale
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []
---
```

### Optional

- `sources: ["[[raw/...]]"]` — link to the original conversation
- `project: <name>` — project membership
- `related: ["[[...]]"]` — related notes
- `confidence: high | medium | low` — confidence in the note's core claim. Used by a handoff agent to judge trust
- `last_verified: YYYY-MM-DD` — last date the content was fact-checked (`updated` is the edit date; this is the verification date)

## Type Definitions

| type | meaning | example |
|---|---|---|
| `concept` | concept · principle · pattern | Dependency Injection Pattern |
| `decision` | decision + rationale | Database Choice — Postgres vs MySQL |
| `project` | work in progress | API Server Refactor |

## Topic Slugs

A **sub-topic** under a folder. More specific than the folder. lowercase kebab.

| folder | topic examples |
|---|---|
| `meta/` | `vault-structure`, `vault-system` |
| `works/<project>/` | `api-design`, `infra-config`, `deployment` |
| `toy/` | `commit-convention`, `dev-workflow`, `editor-tooling` |

When a single folder needs grouping by `topic`, use Bases.

## Classification Tool Mapping

| dimension | implementation |
|---|---|
| top-level category | folder (`works/<project>/`, `meta/`) |
| sub-topic | `topic:` frontmatter |
| kind | `type:` frontmatter |
| status | `status:` frontmatter |
| date | `created:`, `updated:` |
| free-form | `tags:` |
| relations | `[[wikilink]]` |
| dynamic groups | `views/*.base` |

## File Names

**File name = English note title** (same as frontmatter `title`).

- English identifier, kebab-case / no date prefix
- the date is owned by frontmatter `created:`
- on title collision, make the title more specific (e.g. `Job vs Deployment (k8s)`)
- same for system files (`schema.md`, `index.md`, `log.md`, `views/*.base`)

## Raw Storage Policy (mode B)

Default mode: **LLM auto-decides + user veto**.

### Keep
- discussions dense with decision rationale
- conversations that went through fact-checking / verification
- conversations worth linking as `sources:` from another wiki page

### Don't keep
- simple command execution
- simple Q&A
- conversations fully absorbed into the wiki after refinement

### Procedure
When a conversation ends, the LLM gives a one-line report. User OK / Cancel.

### Raw file name
`raw/<Note Title>.md` (English, kebab / no date prefix). The date goes in the `date:` frontmatter.

## 3-Op (karpathy LLM Wiki Pattern)

| op | action |
|---|---|
| **Ingest** | new material → update the related wiki page + record in [[log]] |
| **Query** | question → answer using the wiki. A valuable answer becomes a new page + [[log]] |
| **Lint** | periodic check: contradictions · stale · orphan · broken references + [[log]] |

Every 3-op execution is recorded in the [[log]] **year file** (`log/<YYYY>.md`) in the prefix format (`## [YYYY-MM-DD] ingest|query|lint | title`). [[log]] itself is the index. File-level changes are owned by git.

### Query Absorption Policy

karpathy: "Good answers can be filed back into the wiki as new pages."

Criteria for whether an answer is absorbed into the wiki:

| condition | handling |
|---|---|
| reusable + general (concept/principle) | **new page** (`concept` type) |
| fits naturally into an existing wiki page | **update the existing page** |
| one-off, procedural, short | **not absorbed** (only the query entry in log) |

Three signals:
- **reusability** — likelihood of being referenced again when answering other queries
- **generality** — valid regardless of a specific time/context
- **density** — the answer has more than a paragraph of substance

A non-absorbed query may still be logged. At lint time, check for "missed absorption".

### Lint Check — Broken References (dangling link)

A `[[target]]` that matches no actual note (`.md`) / view (`.base`) is a broken reference. After a rename/delete, leftover links break the graph, so scan at `Lint` time (from the vault root):

```bash
python3 - <<'PY'
import os, re
files=[os.path.relpath(os.path.join(r,f),'.')
       for r,d,fs in os.walk('.') if '/.git' not in r and '/.obsidian' not in r
       for f in fs if f.endswith(('.md','.base'))]
stems={f.rsplit('.',1)[0] for f in files}
names=stems|{os.path.basename(s) for s in stems}
ok=lambda t: t in names or any(s.endswith('/'+t) for s in stems)
for f in files:
    for i,l in enumerate(open(f,encoding='utf-8'),1):
        for m in re.finditer(r'\[\[([^\]|#^]+)', l):
            t=m.group(1).strip()
            if t and not ok(t) and '(unwritten)' not in l:
                print(f'{f}:{i}  -> {t}')
PY
```

When found: stale rename/delete → **update to the current name**. For historical context (past log entries, etc.), use the `[[current name|name-at-the-time]]` alias — keep the link alive while preserving the original display.

#### Excluded from the check (intended mismatches)

- **Planned forward-ref**: `[[Note Name]] (unwritten)` — the `(unwritten)` marker is required. Reserves a note to write later (link liberally).
- **AI agent memory mention**: per `## Memory Unification`, new references are forbidden; existing historical mentions use `code` notation, so they aren't links and are irrelevant to dangling checks.
- **Syntax examples**: explanatory examples in `schema.md` / `meta/` docs (`[[Note Name]]`, `[[...]]`, `[[image.png]]`, etc.).

## Evolution Principles

- observe patterns over the first 5–10 conversations
- reflect new types / fields in the schema
- record 3-op executions in [[log]]

## Language Convention

Distinguish identifier text from prose:

- **System documents: English** — `schema.md`, `index.md`, `log.md` (+ `log/<YYYY>.md`), `views/*.base`. The user doesn't read these; the agent does, and English saves tokens. Content notes (`works/`, `meta/`, etc.) and captured `raw/` conversations follow the body language below.
- **Content-note body (H1 and below): {{RESPONSE_LANG}}** — readability first
- **File name / frontmatter / tags / wikilink identifiers: English, kebab-case** — filter / graph / link consistency
- **frontmatter `title` may differ from H1**: `title` is the English identifier, H1 is the readable heading in {{RESPONSE_LANG}}
- **Inside `.base`** (`displayName`, view `name`, filter expressions): English identifiers

## Content Discipline — No Filler

Note structure is free per type · content. But regardless of kind, the following don't go in the body (strip them at ingest):

- **Persuasion / reassurance tone**: "don't waver", "this is the right answer" — psychology, not fact
- **Decorative analogies**: analogies not strictly needed for understanding
- **Counter-argument drama**: narrative kept alive to sustain a persuasive flow. If there was a discussion, keep only the *points and conclusion* as facts

Criterion: "Does the person · agent picking up the work need this to grasp the fact / decision / reason?" → if not, cut it. "Readability first" (Language Convention) means easy for a human to read, not an invitation to add persuasion or decoration.

## Belief Revision Tracking

Only when an existing claim is **overturned / corrected**, preserve the old belief in a collapsed callout (additions / refinements don't count). Not applied retroactively.

- The current fact stays in the body; the old belief goes one-per-line into a `> [!quote]-` collapsed callout
- Format: `- ~YYYY-MM-DD: old claim — source [[...]]`
- Per-claim, inline. frontmatter `updated` is a file-level timestamp, so it's separate
- [[log]] tracks op · file changes (what happened); this callout tracks belief revision (which belief changed) — complementary
- At lint time: if an ingest overturned an existing claim but no revision callout was added, flag it

Example:

```markdown
The withdrawal-prep DB is Y.

> [!quote]- previous belief
> - ~2026-05-29: thought it was X — source [[original note]]
> - 2026-05-30: corrected to Y — source [[original note]]
```

## Obsidian Syntax (commonly used)

- Links: `[[Note Name]]`, `[[Note Name|display]]`, `[[Note Name#Heading]]`
- Embeds: `![[Note Name]]`, `![[image.png|300]]`
- Inline tags: `#tag`, `#nested/tag`
- Callout: `> [!info] Title` (`note`/`tip`/`warning`/`info`/`example`/`quote`/`bug`/`danger`/`success`/`failure`/`question`/`abstract`/`todo`)
- Highlight: `==text==`
- Hidden: `%%hidden%%`
- Block ID: `text ^block-id`
