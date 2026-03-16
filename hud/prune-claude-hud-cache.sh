#!/usr/bin/env bash

set -u
umask 077

cache_dir="$HOME/.claude/my-hud/cache"
tmp_dir="$HOME/.claude/my-hud/tmp"

mkdir -p "$cache_dir" "$tmp_dir" 2>/dev/null || exit 0
chmod 700 "$cache_dir" "$tmp_dir" 2>/dev/null || true

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

# tmp 디렉토리 내 고아 파일 정리
for f in "$tmp_dir"/*; do
  [ -f "$f" ] || continue
  m=$(stat -f %m "$f" 2>/dev/null || echo 0)
  fage=$((now - m))
  [ "$fage" -gt "$orphan_tmp_seconds" ] && rm -f "$f" 2>/dev/null || true
done

tmp_stamp="$(mktemp "$tmp_dir/prune.stamp.XXXXXX")"
if printf '%s\n' "$now" > "$tmp_stamp"; then
  mv "$tmp_stamp" "$stamp"
else
  rm -f "$tmp_stamp" 2>/dev/null || true
fi
