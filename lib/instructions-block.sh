#!/bin/bash
# lib/instructions-block.sh — managed-block helper for AI agent instruction
# markdown files.
#
# Each AI agent (Claude / Codex / OpenCode / …) reads a global instruction
# file in markdown. We sync $SCRIPT_DIR/my-claude/instructions/*.md
# (concatenated alphabetically) into a managed block wrapped with:
#
#   <!-- MYTERM:BEGIN -->
#   <combined source>
#   <!-- MYTERM:END -->
#
# Content outside the markers is preserved (user's personal additions).
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
# md_upsert_myterm_block DST_FILE
#   - DST_FILE missing            → create parent dir, write combined source
#   - markers present in DST_FILE → replace block in place
#   - no markers in DST_FILE      → backup, then overwrite (legacy migration)
#
# md_refresh_optional_blocks DST_FILE
#   - For every MYTERM:OPTIONAL:<name>:BEGIN/END pair in DST_FILE,
#     replace its inner content with optional/<name>.md (if the source file
#     still exists; otherwise leave the block untouched).
#
# Requires: $SCRIPT_DIR (set by install.sh) + log_step (from install.sh).

md_upsert_myterm_block() {
  local dst="$1"
  local src_dir="$SCRIPT_DIR/my-claude/instructions"
  local begin='<!-- MYTERM:BEGIN -->'
  local end='<!-- MYTERM:END -->'

  # Build the block body: BEGIN marker + concat(instructions/*.md) + END marker.
  # Markers are owned by this helper, not by source files, so adding a new
  # instruction file (with no markers of its own) cannot land outside the block.
  local block
  block=$(mktemp)
  printf '%s\n' "$begin" > "$block"
  local found=0
  for f in "$src_dir"/*.md; do
    [ -f "$f" ] || continue
    cat "$f" >> "$block"
    printf '\n\n' >> "$block"
    found=1
  done
  printf '%s\n' "$end" >> "$block"

  if [ "$found" = "0" ]; then
    rm -f "$block"
    return 0
  fi

  # Ensure parent directory exists for fresh-install targets
  # (~/.codex/, ~/.config/opencode/ may not exist yet).
  mkdir -p "$(dirname "$dst")"

  if [ ! -f "$dst" ]; then
    cp -f "$block" "$dst"
    chmod 600 "$dst"
    rm -f "$block"
    return 0
  fi

  if ! grep -qF "$begin" "$dst" || ! grep -qF "$end" "$dst"; then
    local backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
    cp -f "$dst" "$backup"
    chmod 600 "$backup"
    cp -f "$block" "$dst"
    chmod 600 "$dst"
    log_step "legacy $dst backed up to $backup"
    rm -f "$block"
    return 0
  fi

  local tmp="$dst.tmp.$$"
  awk -v block="$block" -v begin="$begin" -v end="$end" '
    function emit_block(   line) {
      while ((getline line < block) > 0) print line
      close(block)
    }
    index($0, begin) { in_block = 1; emit_block(); next }
    index($0, end)   { in_block = 0; next }
    !in_block        { print }
  ' "$dst" > "$tmp" && mv "$tmp" "$dst"
  chmod 600 "$dst"
  rm -f "$block"
}

md_refresh_optional_blocks() {
  local dst="$1"
  local src_dir="$SCRIPT_DIR/my-claude/optional"
  [ -f "$dst" ] || return 0
  [ -d "$src_dir" ] || return 0

  # Collect names of OPTIONAL blocks present in destination.
  local names
  names=$(grep -oE '<!-- MYTERM:OPTIONAL:[A-Za-z0-9._-]+:BEGIN -->' "$dst" \
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
