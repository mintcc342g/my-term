[Multi-Agent Collaboration Mode Active]

The user's prompt contains `@co`. Follow this procedure exactly to coordinate parallel multi-agent collaboration via MCP tools.

## Phase 1: Context Organization

Organize the context relevant to the user's question from the current conversation.

- If a plan exists, include the full plan.
- Include analysis data, design decisions, related file paths, etc.
- Exclude unrelated discussion.

## Phase 2: Round 1 — Initial Opinions

Call the configured agents via MCP tools.

- For multiple agents: send all tool calls in a **single message** for parallel execution.
- Do NOT use `run_in_background`. Use multiple foreground tool calls in parallel.
- Pass `[organized context + user prompt]` as the `prompt` parameter to each agent.
- If additional parameters are specified for an agent, pass them as well.

{{AGENT_LIST}}

Wait for ALL agent responses to arrive before proceeding to the next phase. Do not write any final answer prematurely.

## Phase 3: Comparison + Debate Loop (max 3 rounds)

Compare Round 1 responses to detect disagreement.

**On consensus**: skip directly to Phase 4.

**On disagreement**: start the debate loop.

- Show each round's progress to the user using this format (Korean output):

  ### 라운드 N
  **Claude**: [당신의 의견과 근거]
  **[에이전트명]**: [에이전트의 의견 요약]
  **차이점**: [구체적 이견 사항]

- Formulate your counter-argument or follow-up question for the disagreement, then re-query the agent.
  - If the prior response included a `threadId`: use the `mcp__codex__codex-reply` tool with that `threadId` and your new `prompt`.
  - If no `threadId`: re-invoke the original tool, including prior discussion context in `prompt`.
- After receiving the agent's re-response, analyze for disagreement again.
- If consensus is reached, end the loop and move to Phase 4.
- Maximum 3 rounds. After round 3, if disagreement remains, proceed to Phase 4 with the disagreement noted explicitly.

## Phase 4: Final Synthesis

Compose the final response in this format (Korean output):

### 논의 요약
- 총 라운드 수와 합의/이견 여부
- 합의된 부분: 간결하게 정리
- 끝까지 이견인 부분: 각 측 입장과 근거를 명시하고, 당신의 최종 판단을 근거와 함께 제시

### 최종 답변
- 종합된 결론

## Failure Handling

If an agent fails (error / timeout):

- You MUST explicitly state `[에이전트명 실패]` (Korean) in the output.
- If the error message contains auth-related keywords (`401`, `403`, `unauthorized`, `forbidden`, `invalid api key`, `token expired`):
  → advise: "`codex login`으로 재인증이 필요합니다 (API 키가 만료되었거나 비활성화된 상태입니다)"
- For other errors (`500`, timeout, network, etc.):
  → advise: "서버 에러 또는 네트워크 문제로 실패했습니다. 잠시 후 다시 시도해주세요"
- Continue with the remaining agent results plus your own analysis.
- The debate loop continues only with responsive agents.

## Response Language

All user-facing output (Round N reports, Discussion Summary, Final Answer, failure messages) MUST be in Korean using polite form (존댓말 / 합니다체). The `@co` keyword itself should not appear in the response.
