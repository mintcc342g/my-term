#!/usr/bin/env bash
#
# Fetch Anthropic OAuth usage API and update rate limit cache.
# Called by: statusline.sh (cache miss or stale)
#
# Expects: $cache_dir to be set by caller
# Writes:  $cache_dir/ratelimit.json on success (atomic mv)
#          $cache_dir/ratelimit.err  on API error (content = backoff seconds)
#

[ -z "${cache_dir:-}" ] && exit 1

umask 077

RL_CACHE="$cache_dir/ratelimit.json"
RL_ERR_MARKER="$cache_dir/ratelimit.err"

# Defensive: never write through a symlink at our cache paths. A same-user
# attacker (or accidental link) could otherwise redirect the atomic mv.
[ -L "$RL_CACHE" ] && rm -f "$RL_CACHE"
[ -L "$RL_ERR_MARKER" ] && rm -f "$RL_ERR_MARKER"

# Exponential backoff bounds for repeated API errors.
RL_ERR_MIN=60      # base backoff window (seconds)
RL_ERR_MAX=1800    # cap (30 min)

ACCESS_TOKEN=""
# macOS Keychain first
CRED_JSON=$(/usr/bin/security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
# Fallback to credentials file
if [ -z "$CRED_JSON" ] && [ -f "$HOME/.claude/.credentials.json" ] && [ ! -L "$HOME/.claude/.credentials.json" ]; then
  cred_file="$HOME/.claude/.credentials.json"
  perm=$(stat -f '%Lp' "$cred_file" 2>/dev/null || echo "")
  if [ -n "$perm" ] && [ $((8#$perm & 077)) -ne 0 ]; then
    chmod 600 "$cred_file" 2>/dev/null || true
  fi
  CRED_JSON=$(< "$cred_file")
fi
if [ -n "$CRED_JSON" ]; then
  ACCESS_TOKEN=$(printf '%s' "$CRED_JSON" | jq -r '.claudeAiOauth.accessToken // .accessToken // empty' 2>/dev/null)
fi
unset CRED_JSON

[ -z "$ACCESS_TOKEN" ] && exit 1

# Reject tokens with dangerous characters to prevent curl config injection
case "$ACCESS_TOKEN" in *$'\n'*|*$'\r'*|*'"'*|*'\\'*) exit 1;; esac

RL_RESP=$(curl -s --max-time 5 \
  -K <(printf 'header = "Authorization: Bearer %s"\n' "$ACCESS_TOKEN") \
  -H "anthropic-beta: oauth-2025-04-20" \
  "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
unset ACCESS_TOKEN

if [ -n "$RL_RESP" ] && printf '%s' "$RL_RESP" | jq -e '.five_hour' >/dev/null 2>&1; then
  tmp_dir="${tmp_dir:-$cache_dir}"
  tmp_rl="$(mktemp "$tmp_dir/ratelimit.XXXXXX")"
  if printf '%s' "$RL_RESP" > "$tmp_rl"; then
    mv "$tmp_rl" "$RL_CACHE"
    chmod 600 "$RL_CACHE" 2>/dev/null || true
    rm -f "$RL_ERR_MARKER" 2>/dev/null || true
  else
    rm -f "$tmp_rl" 2>/dev/null || true
  fi
elif [ -n "$RL_RESP" ] && printf '%s' "$RL_RESP" | jq -e '.error' >/dev/null 2>&1; then
  # Read previous backoff window (if any), double, cap. Marker content is the
  # current window in seconds; mtime is the moment of failure. statusline
  # treats (now - mtime) <= window as "still in backoff" and skips fetch.
  prev=0
  if [ -f "$RL_ERR_MARKER" ]; then
    prev=$(tr -dc '0-9' < "$RL_ERR_MARKER" 2>/dev/null)
    [ -z "$prev" ] && prev=0
  fi
  if [ "$prev" -le 0 ]; then
    next=$RL_ERR_MIN
  else
    next=$((prev * 2))
    [ "$next" -gt "$RL_ERR_MAX" ] && next=$RL_ERR_MAX
  fi
  printf '%s\n' "$next" > "$RL_ERR_MARKER"
  chmod 600 "$RL_ERR_MARKER" 2>/dev/null || true
fi
unset RL_RESP
