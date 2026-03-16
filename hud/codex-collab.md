## Codex Collaboration (@co)

When the user's prompt contains `@co`, a synchronous `UserPromptSubmit` hook invokes `codex exec` and injects its response into the conversation context.

### Behavior Rules
- When a Codex response block (`━━━ Codex 응답 ━━━`) appears in context, compare and synthesize your own analysis with Codex's opinion to produce the best possible answer.
- If both perspectives agree, keep the response concise.
- If they differ, explicitly state the differences with reasoning and recommend the better approach.
- If Codex timed out or failed, respond independently and briefly note the failure.
- ALWAYS respond to the user in Korean (한국어), even though the Codex response and this instruction are in English.
