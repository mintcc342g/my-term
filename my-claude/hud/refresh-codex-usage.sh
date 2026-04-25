#!/usr/bin/env bash
#
# Refresh Codex auth state and rate-limit usage caches.
#
# Strategy:
#   1. HUD codex section disabled → exit early (no codex calls)
#   2. codex binary missing       → write auth=unavailable, exit
#   3. Try app-server RPC (account/rateLimits/read) — token-free
#   4. Any RPC failure            → write auth=unavailable
#
# Single-source RPC design avoids reading session .jsonl files (which contain
# full conversation history); we touch only the rate-limits response payload.
#
# Called by: init-env-bg.sh (SessionStart), PostToolUse on mcp__codex__codex
#
# Expects: $cache_dir to be set by caller
# Writes:  $cache_dir/codex-auth       ("ok" | "unavailable")
#          $cache_dir/codex-usage.json on RPC success
#

[ -z "${cache_dir:-}" ] && exit 1

umask 077

CODEX_AUTH_CACHE="$cache_dir/codex-auth"
CODEX_USAGE_CACHE="$cache_dir/codex-usage.json"
HUD_CONFIG="$HOME/.claude/my-hud/config.json"

write_auth() {
  printf '%s' "$1" > "$CODEX_AUTH_CACHE"
  chmod 600 "$CODEX_AUTH_CACHE" 2>/dev/null || true
}

# Atomically write usage cache from a JSON line + jq filter; returns 0 on success.
write_usage() {
  local line="$1" filter="$2"
  local tmp
  tmp="$(mktemp "$cache_dir/codex-usage.XXXXXX")" || return 1
  if printf '%s' "$line" | jq "$filter" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$CODEX_USAGE_CACHE"
    chmod 600 "$CODEX_USAGE_CACHE" 2>/dev/null || true
    return 0
  fi
  rm -f "$tmp" 2>/dev/null || true
  return 1
}

# ── Gate ①: HUD codex section disabled ───────────────────────────────────────
codex_enabled=$(jq -r '.sections.codex.enabled // false' "$HUD_CONFIG" 2>/dev/null)
[ "$codex_enabled" != "true" ] && exit 0

# ── Gate ②: codex binary missing ─────────────────────────────────────────────
if ! command -v codex &>/dev/null; then
  write_auth unavailable
  exit 0
fi

# ── RPC: codex app-server stdio JSONRPC ──────────────────────────────────────
RPC_FILTER='{
  primary: {
    used_percent: (.result.rateLimits.primary.usedPercent // 0),
    left_percent: ([(100 - ((.result.rateLimits.primary.usedPercent // 0) | floor)), 0] | max),
    resets_at: (.result.rateLimits.primary.resetsAt // 0),
    window_minutes: (.result.rateLimits.primary.windowDurationMins // 0)
  },
  secondary: {
    used_percent: (.result.rateLimits.secondary.usedPercent // 0),
    left_percent: ([(100 - ((.result.rateLimits.secondary.usedPercent // 0) | floor)), 0] | max),
    resets_at: (.result.rateLimits.secondary.resetsAt // 0),
    window_minutes: (.result.rateLimits.secondary.windowDurationMins // 0)
  },
  plan_type: (.result.rateLimits.planType // null),
  updated_at: now
}'

# Run codex app-server reading from a FIFO; a generator subshell holds the
# write end open with a long sleep so codex doesn't see EOF mid-conversation.
# Main shell polls the output file for both response lines, then kills the
# generator → FIFO closes → codex exits. Response-driven, no fixed sleep.
rpc_response=""
in_fifo="$(mktemp -u "$cache_dir/codex-rpc-in.XXXXXX")"
out_file="$(mktemp "$cache_dir/codex-rpc-out.XXXXXX")"
# Defensive cleanup: covers normal exit, signals (SIGINT/SIGTERM), and any
# unexpected error path. Single-quoted so $in_fifo/$out_file expand at trap
# fire time, not at trap-set time.
trap 'rm -f "$in_fifo" "$out_file" 2>/dev/null' EXIT
if mkfifo "$in_fifo" 2>/dev/null; then
  (
    printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"my-hud","version":"1"}}}'
    printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"account/rateLimits/read","params":null}'
    # exec → gen_pid IS the sleep process so `kill` propagates instantly
    exec sleep 30
  ) > "$in_fifo" &
  gen_pid=$!
  codex app-server --listen stdio:// < "$in_fifo" > "$out_file" 2>/dev/null &
  codex_pid=$!

  # Poll up to 5s (50 × 0.1s) for both response lines.
  for _ in $(seq 1 50); do
    [ "$(wc -l < "$out_file" 2>/dev/null | tr -d ' ')" -ge 2 ] && break
    sleep 0.1
  done

  # Reap helper: send signal, poll up to N×0.1s for exit, SIGKILL fallback,
  # then drain the child via `wait`. Each step bounded so a hung child can't
  # block the script (and thus the EXIT trap) indefinitely.
  reap() {
    local pid="$1" max_iter="$2"
    kill "$pid" 2>/dev/null
    local i
    for i in $(seq 1 "$max_iter"); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done
    kill -KILL "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
  }

  reap "$gen_pid"   10   # sleep should die on SIGTERM in <100ms; cap 1s
  reap "$codex_pid" 30   # codex needs to flush after EOF; cap 3s

  rpc_response="$(cat "$out_file" 2>/dev/null)"
fi

# Extract the id=2 response line (filter JSONL stream defensively)
rate_line=$(printf '%s\n' "$rpc_response" | jq -c 'select(.id == 2)' 2>/dev/null | head -1)

# Branch 1: RPC success
if [ -n "$rate_line" ] && printf '%s' "$rate_line" | jq -e '.result.rateLimits.primary.usedPercent' &>/dev/null; then
  if write_usage "$rate_line" "$RPC_FILTER"; then
    write_auth ok
    exit 0
  fi
fi

# Any RPC failure (auth error, timeout, network, schema mismatch, missing binary) → unavailable
write_auth unavailable
exit 0
