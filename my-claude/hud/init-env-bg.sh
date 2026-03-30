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
