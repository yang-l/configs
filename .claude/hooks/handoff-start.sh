#!/usr/bin/env bash
# SessionStart hook. Stdout goes into the new session's context.
# Prints only the handoff that this Claude process saved before /clear, never a
# parallel session's file. idle-handoff.sh disarm writes the link at SessionEnd.
source=$(jq -r '.source // empty' 2>/dev/null)
[[ ${CLAUDE_PID:-} =~ ^[0-9]+$ ]] || exit 0
link="${HANDOFF_ROOT:-$HOME/.local/state/claude-handoffs}/.links/$CLAUDE_PID"
[ -f "$link" ] || exit 0
file=$(cat "$link")
# Any other source also removes the link, because the system can reuse a PID.
rm -f "$link"
[ "$source" = clear ] && [ -f "$file" ] || exit 0
printf 'Handoff from this session before /clear: %s. Read only this file to continue that work. An exact handoff path in the first user message wins.\n' "$file"
