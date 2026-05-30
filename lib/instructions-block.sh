#!/bin/bash
# lib/instructions-block.sh — managed-block helper for AI agent instruction
# markdown files.
#
# Opt-in personal instructions live in $SCRIPT_DIR/my-claude/optional/*.md.
# When the user accepts one at install time, the installer appends a per-name
# OPTIONAL marker block to the destination:
#
#   <!-- MYTERM:OPTIONAL:<name>:BEGIN -->
#   <content of optional/<name>.md>
#   <!-- MYTERM:OPTIONAL:<name>:END -->
#
# md_refresh_optional_blocks rebuilds each existing OPTIONAL block in place
# (so repo updates to opt-in files propagate on Update). The presence of the
# block markers in the destination IS the opt-in record — no manifest needed.
# Opt-out is manual: delete the OPTIONAL block from the destination file.
#
# md_refresh_optional_blocks DST_FILE
#   - For every MYTERM:OPTIONAL:<name>:BEGIN/END pair in DST_FILE,
#     replace its inner content with optional/<name>.md (if the source file
#     still exists; otherwise leave the block untouched).
#
# Requires: $SCRIPT_DIR (set by install.sh) + log_step (from install.sh).

md_refresh_optional_blocks() {
  local dst="$1"
  local src_dir="$SCRIPT_DIR/my-claude/optional"
  [ -f "$dst" ] || return 0
  [ -d "$src_dir" ] || return 0

  # grep returns exit 1 on no-match. Without `|| true` this kills the script
  # under `set -o pipefail`. The empty-result case is handled by `[ -n ]` below.
  local names
  names=$( { grep -oE '<!-- MYTERM:OPTIONAL:[A-Za-z0-9._-]+:BEGIN -->' "$dst" || true; } \
          | sed -E 's/^<!-- MYTERM:OPTIONAL:(.+):BEGIN -->$/\1/' \
          | sort -u)
  [ -n "$names" ] || return 0

  local name src begin end tmp
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    src="$src_dir/${name}.md"
    # Source removed from repo — leave existing block untouched.
    [ -f "$src" ] || continue
    begin="<!-- MYTERM:OPTIONAL:${name}:BEGIN -->"
    end="<!-- MYTERM:OPTIONAL:${name}:END -->"

    tmp="$dst.tmp.$$"
    awk -v src="$src" -v begin="$begin" -v end="$end" '
      function emit_src(   line) {
        print begin
        while ((getline line < src) > 0) print line
        close(src)
        print end
      }
      index($0, begin) { in_block = 1; emit_src(); next }
      index($0, end)   { in_block = 0; next }
      !in_block        { print }
    ' "$dst" > "$tmp" && mv "$tmp" "$dst"
    chmod 600 "$dst"
  done <<< "$names"
}

# md_remove_optional_blocks DST_FILE
#   - Strip every MYTERM:OPTIONAL:<name>:BEGIN/END block (markers + content)
#     from DST_FILE. Inverse of the opt-in append in _prompt_optional_instructions.
#   - User content outside the markers is preserved. No-op if no blocks present.
md_remove_optional_blocks() {
  local dst="$1"
  [ -f "$dst" ] || return 0
  grep -qE '<!-- MYTERM:OPTIONAL:[A-Za-z0-9._-]+:BEGIN -->' "$dst" 2>/dev/null || return 0

  local tmp="$dst.tmp.$$"
  awk '
    /^<!-- MYTERM:OPTIONAL:[A-Za-z0-9._-]+:BEGIN -->$/ { in_block = 1; next }
    /^<!-- MYTERM:OPTIONAL:[A-Za-z0-9._-]+:END -->$/   { in_block = 0; next }
    !in_block                                          { print }
  ' "$dst" > "$tmp" && mv "$tmp" "$dst"
  chmod 600 "$dst"
}
