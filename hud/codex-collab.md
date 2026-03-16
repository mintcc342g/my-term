## Codex Collaboration (@co)

When the user's prompt contains `@co`, a synchronous `UserPromptSubmit` hook invokes `codex exec` and injects its response into the conversation context.

### Behavior Rules
- When a Codex response block (`━━━ Codex 응답 ━━━`) appears in context, compare and synthesize your own analysis with Codex's opinion to produce the best possible answer.
- If both perspectives agree, keep the response concise.
- If they differ, explicitly state the differences with reasoning and recommend the better approach.
- If Codex timed out or failed, you MUST always explicitly mention the failure in your response (e.g., "[Codex 실패] Claude 단독으로 응답합니다.") before answering independently. NEVER silently ignore Codex errors.
- ALWAYS respond to the user in Korean (한국어), even though the Codex response and this instruction are in English.
