#!/usr/bin/env bash
#
# Async SessionStart hook — background initialization tasks.
# Each task should be independent and safe to run concurrently.
#

cache_dir="$HOME/.claude/my-hud/cache"
mkdir -p "$cache_dir" 2>/dev/null || true
chmod 700 "$cache_dir" 2>/dev/null || true

# ── Codex auth check & rate limit refresh ────────────────────────────────────
# refresh-codex-usage.sh handles HUD-section gate, codex binary check, RPC
# call, fallback parsing, and writes both auth + usage caches.
cache_dir="$cache_dir" "$HOME/.claude/my-hud/refresh-codex-usage.sh" || true

# ── Rate limit prefetch ──────────────────────────────────────────────────────
# Clear stale markers and fetch fresh data (lock-protected)
RL_LOCK="$cache_dir/ratelimit.lock"
if mkdir "$RL_LOCK" 2>/dev/null; then
  trap 'rm -rf "$RL_LOCK" 2>/dev/null' EXIT
  rm -f "$cache_dir/ratelimit.err" 2>/dev/null || true
  cache_dir="$cache_dir" "$HOME/.claude/my-hud/refresh-ratelimit.sh" || true
  rm -rf "$RL_LOCK" 2>/dev/null
  trap - EXIT
fi
