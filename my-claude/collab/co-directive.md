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

- Show each round's progress to the user using this format:

  ### Round N
  **Claude**: [your opinion and rationale]
  **[agent name]**: [summary of the agent's opinion]
  **Differences**: [specific points of disagreement]

- Formulate your counter-argument or follow-up question for the disagreement, then re-query the agent.
  - If the prior response included a `threadId`: use the `mcp__codex__codex-reply` tool with that `threadId` and your new `prompt`.
  - If no `threadId`: re-invoke the original tool, including prior discussion context in `prompt`.
- After receiving the agent's re-response, analyze for disagreement again.
- If consensus is reached, end the loop and move to Phase 4.
- Maximum 3 rounds. After round 3, if disagreement remains, proceed to Phase 4 with the disagreement noted explicitly.

## Phase 4: Final Synthesis

Compose the final response in this format:

### Discussion Summary
- Total number of rounds and whether consensus or disagreement was reached
- Points of agreement: summarize concisely
- Points still in disagreement: state each side's position and rationale, then give your final judgment with reasoning

### Final Answer
- The synthesized conclusion

## Failure Handling

If an agent fails (error / timeout):

- You MUST explicitly state `[<agent name> failed]` in the output.
- If the error message contains auth-related keywords (`401`, `403`, `unauthorized`, `forbidden`, `invalid api key`, `token expired`):
  → advise: "Re-authenticate with `codex login` (the API key has expired or been disabled)."
- For other errors (`500`, timeout, network, etc.):
  → advise: "Failed due to a server error or network issue. Please try again shortly."
- Continue with the remaining agent results plus your own analysis.
- The debate loop continues only with responsive agents.

## Output

- All user-facing output (round reports, discussion summary, final answer, relayed failure messages) MUST be in {{RESPONSE_LANG}}. Run the collaboration in {{RESPONSE_LANG}} end to end so no translation step is needed.
- The `@co` keyword itself should not appear in the response.
