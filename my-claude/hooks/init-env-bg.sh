#!/usr/bin/env bash
#
# Async SessionStart hook — background initialization tasks.
# Each task should be independent and safe to run concurrently.
#

cache_dir="$HOME/.claude/my-hud/cache"
mkdir -p "$cache_dir" 2>/dev/null || true
chmod 700 "$cache_dir" 2>/dev/null || true

# ── Codex auth check & usage refresh ─────────────────────────────────────────
# refresh-codex-usage.sh handles HUD-section gate, codex binary check, RPC
# call, fallback parsing, and writes both auth + usage caches.
#
# Anthropic rate-limit data is intentionally NOT prefetched here: statusline
# fetches it lazily on demand (cache miss / stale). Doing it here would race
# the first render under the async hook model.
cache_dir="$cache_dir" "$HOME/.claude/my-hud/refresh-codex-usage.sh" || true
