## Wiki

- Location: {{WIKI_PATH}}
- Source of truth: `schema.md` inside the wiki (structure / type / frontmatter / operating conventions / ingest / lint rules, etc.)
- Use Obsidian tools when available. Local file search and editing also work with the Markdown vault.

## Behavior

1. Use the user's request as the query, ignoring an explicit wiki invocation marker if present.
2. Read **only the needed sections of schema.md** (do NOT read the whole file — save tokens)
3. Carry out the work according to those rules

> If a `DEFAULT_SCHEMA_GREETING` block exists at the top of schema.md, follow the instructions inside it: guide the user, then remove the block and proceed with the work.

## User Intent Mapping

- "save / ingest / organize" → consult the ingest section of schema.md, then ingest the current conversation
- "lint / check" → consult the lint section of schema.md, then check
- "search / find" → use `obsidian-cli` or search the local files and read the relevant notes
- "list" → print the list of wiki notes
- any other query → search the wiki, then use the relevant notes

## Response

- Respond in {{RESPONSE_LANG}}
- Cite the notes you used as wikilinks
- Search results:
  - **none**: state in one line "no related note in the wiki" and answer normally
  - **multiple**: report candidates in one line ("N notes related to X — which one?")
  - **clear**: read the body and use it in the answer
