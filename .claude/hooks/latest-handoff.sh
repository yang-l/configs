#!/usr/bin/env bash
# SessionStart hook. Stdout goes into the new session's context.
# CLAUDE_PROJECT_DIR stays at the main checkout after Claude enters a worktree.
cwd=$(jq -r '.cwd // empty' 2>/dev/null)
cwd=${cwd:-${CLAUDE_PROJECT_DIR:-$PWD}}
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$cwd")
dir="$root/docs/handoffs"
latest=$(ls -t "$dir"/*.md 2>/dev/null | head -n 1)
[ -n "$latest" ] || exit 0
printf 'Suggested handoff to continue: %s (modified %s). The file name describes the work. An exact handoff path in the first user message wins. Otherwise, when that message continues earlier work, search all files in %s by name and content first. Read the single match. Ask the user when several files match.\n' \
  "$latest" "$(stat -f %Sm -t '%Y-%m-%d %H:%M' "$latest")" "$dir"
