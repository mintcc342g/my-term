[wiki context mode active]

The user's message contains `@wk` — use the wiki context to answer.

## wiki

- Location: {{WIKI_PATH}}
- Source of truth: `schema.md` inside the wiki (structure / type / frontmatter / operating conventions / ingest / lint rules, etc.)
- Working tools: obsidian-skills (`obsidian-cli`, `obsidian-markdown`, etc.)

## Behavior

1. Interpret the non-`@wk` text of the user's message as the query / topic / intent
2. Read **only the needed sections of schema.md** (do NOT read the whole file — save tokens)
3. Carry out the work according to those rules

> If a `DEFAULT_SCHEMA_GREETING` block exists at the top of schema.md, follow the instructions inside it: guide the user, then remove the block and proceed with the work.

## User Intent Mapping

- "save / ingest / organize" → consult the ingest section of schema.md, then ingest the current conversation
- "lint / check" → consult the lint section of schema.md, then check
- "search / find" → obsidian-cli or Grep + Read
- "list" → print the list of wiki notes
- any other query → search the wiki, then use the relevant notes

## Response

- Respond in {{RESPONSE_LANG}}
- Ignore the `@wk` keyword itself (do not mention `@wk` in the response)
- Cite the notes you used as wikilinks
- Search results:
  - **none**: state in one line "no related note in the wiki" and answer normally
  - **multiple**: report candidates in one line ("N notes related to X — which one?")
  - **clear**: read the body and use it in the answer
