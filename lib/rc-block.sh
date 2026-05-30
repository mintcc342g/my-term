#!/bin/bash
# lib/rc-block.sh — managed-block helper for shell rc files (zshrc/zprofile).
#
# Each managed block is wrapped with a pair of marker lines:
#   #-- my-term:<tag>: start
#   <content...>
#   #-- my-term:<tag>: end
#
# rc_upsert_block FILE TAG CONTENT
#   - If both markers exist in FILE: replace the lines between them with CONTENT.
#   - Otherwise: append a fresh marker-wrapped block at EOF.
# CONTENT may be a multi-line string.

rc_upsert_block() {
  local file="$1" tag="$2" content="$3"
  local begin="#-- my-term:${tag}: start"
  local end="#-- my-term:${tag}: end"

  touch "$file"

  if grep -qF "$begin" "$file" 2>/dev/null && grep -qF "$end" "$file" 2>/dev/null; then
    local cf tmp
    cf=$(mktemp)
    tmp=$(mktemp)
    printf '%s\n' "$content" > "$cf"
    awk -v begin="$begin" -v end="$end" -v cf="$cf" '
      $0 == begin {
        print
        while ((getline line < cf) > 0) print line
        close(cf)
        in_block = 1
        next
      }
      $0 == end {
        in_block = 0
        print
        next
      }
      !in_block { print }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
    rm -f "$cf"
  else
    printf '\n%s\n%s\n%s\n' "$begin" "$content" "$end" >> "$file"
  fi
}

# rc_remove_block FILE TAG
#   - Remove the marker pair and everything between them (inverse of upsert).
#   - No-op if FILE missing or the start marker is absent.
# Only touches the my-term managed block; user content outside the markers is
# left as-is. The leading blank line upsert may have added is left untouched
# (cosmetic only).
rc_remove_block() {
  local file="$1" tag="$2"
  local begin="#-- my-term:${tag}: start"
  local end="#-- my-term:${tag}: end"

  [ -f "$file" ] || return 0
  grep -qF "$begin" "$file" 2>/dev/null || return 0

  local tmp
  tmp=$(mktemp)
  awk -v begin="$begin" -v end="$end" '
    $0 == begin { in_block = 1; next }
    $0 == end   { in_block = 0; next }
    !in_block   { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file" || rm -f "$tmp"
}
