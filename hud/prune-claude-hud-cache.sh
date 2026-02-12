#!/usr/bin/env bash

set -u
umask 077

cache_dir=""
if [ -n "${TMPDIR:-}" ] && [ -d "${TMPDIR%/}" ]; then
  cache_dir="${TMPDIR%/}/claude-hud"
else
  cache_dir="$HOME/Library/Caches/claude-hud"
fi

mkdir -p "$cache_dir" 2>/dev/null || exit 0
chmod 700 "$cache_dir" 2>/dev/null || true

stamp="$cache_dir/prune.stamp"
prune_every_seconds=3600
orphan_tmp_seconds=600
general_max_age_seconds=604800

now=$(date +%s)
last=$(stat -f %m "$stamp" 2>/dev/null || echo 0)
age=$((now - last))
if [ "$age" -lt "$prune_every_seconds" ]; then
  exit 0
fi

for f in "$cache_dir"/*; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  m=$(stat -f %m "$f" 2>/dev/null || echo 0)
  fage=$((now - m))

  case "$base" in
    git-branch|ratelimit.json|session-start|prune.stamp)
      [ "$fage" -gt "$general_max_age_seconds" ] && rm -f "$f" 2>/dev/null || true
      ;;
    git-branch.*|ratelimit.*|session-start.*|prune.*)
      [ "$fage" -gt "$orphan_tmp_seconds" ] && rm -f "$f" 2>/dev/null || true
      ;;
    *)
      [ "$fage" -gt "$general_max_age_seconds" ] && rm -f "$f" 2>/dev/null || true
      ;;
  esac
done

tmp_stamp="$(mktemp "$cache_dir/prune.stamp.XXXXXX" 2>/dev/null || mktemp)"
if printf '%s\n' "$now" > "$tmp_stamp"; then
  mv "$tmp_stamp" "$stamp"
else
  rm -f "$tmp_stamp" 2>/dev/null || true
fi
