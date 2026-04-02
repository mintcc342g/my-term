#!/usr/bin/env bash
#
# Async SessionStart hook — background initialization tasks.
# Each task should be independent and safe to run concurrently.
#

cache_dir="$HOME/.claude/my-hud/cache"
mkdir -p "$cache_dir" 2>/dev/null || true
chmod 700 "$cache_dir" 2>/dev/null || true

# ── Codex auth check ─────────────────────────────────────────────────────────
codex_auth_cache="$cache_dir/codex-auth"

if ! command -v codex &>/dev/null; then
  printf 'unavailable' > "$codex_auth_cache"
elif codex exec --skip-git-repo-check "echo ok" &>/dev/null; then
  printf 'ok' > "$codex_auth_cache"
else
  printf 'unavailable' > "$codex_auth_cache"
fi

chmod 600 "$codex_auth_cache" 2>/dev/null || true

# ── Rate limit prefetch ──────────────────────────────────────────────────────
# Clear stale markers and fetch fresh data (lock-protected)
RL_LOCK="$cache_dir/ratelimit.lock"
if mkdir "$RL_LOCK" 2>/dev/null; then
  trap 'rm -rf "$RL_LOCK" 2>/dev/null' EXIT
  rm -f "$cache_dir/ratelimit.err" 2>/dev/null || true
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  cache_dir="$cache_dir" "$SCRIPT_DIR/refresh-ratelimit.sh" || true
  rm -rf "$RL_LOCK" 2>/dev/null
  trap - EXIT
fi
