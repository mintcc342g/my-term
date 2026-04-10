#!/usr/bin/env bash
#
# Parse latest Codex session file and update codex-usage.json cache.
# Called by: init-env-bg.sh (session start), @co post-processing
#
# Expects: $cache_dir to be set by caller
# Writes:  $cache_dir/codex-usage.json on success
#

[ -z "${cache_dir:-}" ] && exit 1

umask 077

CODEX_USAGE_CACHE="$cache_dir/codex-usage.json"

codex_usage_line=""
while IFS= read -r session_file; do
  [ -z "$session_file" ] && continue
  codex_usage_line=$(grep '"type":"token_count"' "$session_file" 2>/dev/null | tail -n 1 || true)
  [ -n "$codex_usage_line" ] && break
done < <(
  find "$HOME/.codex/sessions" "$HOME/.codex/archived_sessions" -type f -name '*.jsonl' -exec stat -f '%m %N' {} + 2>/dev/null \
    | sort -rn \
    | awk 'NR <= 5 { $1 = ""; sub(/^ /, ""); print }'
)

if [ -n "$codex_usage_line" ] && printf '%s' "$codex_usage_line" | jq -e '.payload.rate_limits.primary.used_percent' >/dev/null 2>&1; then
  tmp_codex="$(mktemp "$cache_dir/codex-usage.XXXXXX")"
  if printf '%s' "$codex_usage_line" | jq '{
      primary: {
        used_percent: (.payload.rate_limits.primary.used_percent // 0),
        left_percent: (100 - ((.payload.rate_limits.primary.used_percent // 0) | floor)),
        resets_at: (.payload.rate_limits.primary.resets_at // 0),
        window_minutes: (.payload.rate_limits.primary.window_minutes // 0)
      },
      secondary: {
        used_percent: (.payload.rate_limits.secondary.used_percent // 0),
        left_percent: (100 - ((.payload.rate_limits.secondary.used_percent // 0) | floor)),
        resets_at: (.payload.rate_limits.secondary.resets_at // 0),
        window_minutes: (.payload.rate_limits.secondary.window_minutes // 0)
      },
      plan_type: (.payload.rate_limits.plan_type // null),
      updated_at: now
    }' > "$tmp_codex"; then
    mv "$tmp_codex" "$CODEX_USAGE_CACHE"
    chmod 600 "$CODEX_USAGE_CACHE" 2>/dev/null || true
  else
    rm -f "$tmp_codex" 2>/dev/null || true
  fi
fi
