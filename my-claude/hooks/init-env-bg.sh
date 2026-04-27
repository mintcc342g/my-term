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
# Stale lock guard: leftover from a crashed prior run (curl times out at 5s).
# Only treat as stale when stat actually returns an mtime — failures should not
# masquerade as "very old" and trigger spurious removal.
if [ -d "$RL_LOCK" ]; then
  _lock_mtime=$(stat -f %m "$RL_LOCK" 2>/dev/null || echo "")
  if [ -n "$_lock_mtime" ]; then
    _lock_age=$(( $(date +%s) - _lock_mtime ))
    if [ "$_lock_age" -gt 60 ]; then rm -rf "$RL_LOCK" 2>/dev/null; fi
  fi
  unset _lock_mtime _lock_age
fi
if mkdir "$RL_LOCK" 2>/dev/null; then
  trap 'rm -rf "$RL_LOCK" 2>/dev/null' EXIT
  rm -f "$cache_dir/ratelimit.err" 2>/dev/null || true
  cache_dir="$cache_dir" "$HOME/.claude/my-hud/refresh-ratelimit.sh" || true
  rm -rf "$RL_LOCK" 2>/dev/null
  trap - EXIT
fi
