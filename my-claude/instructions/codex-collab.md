## Multi-Agent Collaboration (@co)

When the user's prompt contains `@co`, a synchronous `UserPromptSubmit` hook injects a multi-agent collaboration directive into the conversation context.

### How It Works
1. The hook reads the agent list from `~/.claude/my-collab/co-agents.json`
2. It injects a directive telling Claude to:
   - Gather relevant context from the current conversation
   - Call each configured agent via parallel foreground `Bash` tool calls (multiple tool calls in one message)
   - Wait for ALL agent responses before composing the final answer
   - Critically compare all responses and produce a merged answer

### Behavior Rules
- When the `[멀티 에이전트 협업 모드 활성화]` directive appears, you MUST follow its instructions exactly.
- You MUST call every configured agent via parallel foreground Bash tool calls. Do NOT use `run_in_background`.
- You MUST wait for all agent responses before writing your final answer. Never respond prematurely.
- You MUST include relevant context (plans, analysis data, design decisions) when calling each agent — not just the raw prompt.
- You MUST critically analyze all agent responses: state agreements concisely, state disagreements explicitly with your reasoning, and provide a final synthesized answer.
- If an agent fails (error, timeout), you MUST explicitly mention the failure (e.g., "[Codex 실패]") before answering with remaining results.
- ALWAYS respond to the user in Korean (한국어).

### Adding Agents
Edit `~/.claude/my-collab/co-agents.json`:
```json
[
  { "name": "Codex", "command": "codex exec --skip-git-repo-check" },
  { "name": "AnotherAgent", "command": "another-cli exec" }
]
```
