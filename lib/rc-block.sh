#!/bin/bash
# lib/rc-block.sh — managed-block helper for shell rc files (zshrc/zprofile).
#
# Each managed block is wrapped with a pair of marker lines:
#   # myterm:<tag>:begin
#   <content...>
#   # myterm:<tag>:end
#
# rc_upsert_block FILE TAG CONTENT
#   - If both markers exist in FILE: replace the lines between them with CONTENT.
#   - Otherwise: append a fresh marker-wrapped block at EOF.
# CONTENT may be a multi-line string.

rc_upsert_block() {
  local file="$1" tag="$2" content="$3"
  local begin="# myterm:${tag}:begin"
  local end="# myterm:${tag}:end"

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
