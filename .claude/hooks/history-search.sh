#!/usr/bin/env bash
# Searches the old sessions of one project, for facts that a handoff or a
# compaction dropped. Read-only. Run by the agent through Bash.
#   history-search.sh <project-folder> <regex> [hits-per-file] [max-hits]
# Prints transcript hits (newest session first), then memory and handoff hits.
# Skips the running session when CLAUDE_CODE_SESSION_ID is set.
# max-hits caps the transcript hits in total.
# The regex is case-insensitive. Keep it to ERE syntax that grep and jq share.

dir=$1 re=$2 per=${3:-5} max=${4:-40}
if [ -z "$dir" ] || [ -z "$re" ] || ! [[ $per =~ ^[0-9]+$ ]] || ! [[ $max =~ ^[0-9]+$ ]]; then
  echo 'usage: history-search.sh <project-folder> <regex> [hits-per-file] [max-hits]' >&2
  exit 1
fi
# jq errors are hidden below, so a regex that jq rejects would return nothing.
grep -qiE -- "$re" </dev/null 2>/dev/null
if (( $? > 1 )) || ! jq -n --arg re "$re" '"" | test($re; "i")' >/dev/null 2>&1; then
  echo "history-search: grep or jq rejects the regex: $re" >&2
  exit 1
fi
dir=${dir%/}

# Claude Code makes the transcript key with every non-alphanumeric as "-".
key=$(printf '%s' "$dir" | tr -c 'A-Za-z0-9' '-')
projects="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects"

# The handoff key comes from idle-handoff.sh new_path, which keeps dots.
base=$dir
common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) &&
  base=$(dirname "$common")
handoffs="${HANDOFF_ROOT:-$HOME/.local/state/claude-handoffs}/${base//\//-}"

shopt -s nullglob
# The second glob adds worktree sessions of the same project.
files=("$projects/$key"/*.jsonl "$projects/$key"--worktrees-*/*.jsonl "$projects/$key"--claude-worktrees-*/*.jsonl)
if (( ${#files[@]} )); then
  echo "== transcripts"
  n=0
  ls -t "${files[@]}" | while (( n < max )) && read -r f; do
    [ "$(basename "$f" .jsonl)" = "${CLAUDE_CODE_SESSION_ID:-}" ] && continue
    # One JSONL line is one entry, so grep first and give jq only the hits.
    out=$(grep -iE -- "$re" "$f" | jq -r --arg re "$re" --arg sid "$(basename "$f" .jsonl | cut -c1-8)" '
      def txt:
        if type == "string" then .
        elif type == "array" then
          [.[] | if type == "string" then .
                 elif .type == "text" then .text
                 elif .type == "tool_use" then (.input | tostring)
                 elif .type == "tool_result" then (.content | txt)
                 else empty end] | join(" ")
        else "" end;
      select(.type == "user" or .type == "assistant")
      | (.message.content | txt) as $t
      | ($t | [match($re; "i")] | first | .offset) as $o
      | select($o != null)
      # gsub is slow on long text, so it runs on the 400-char snippet only.
      | "\($sid) \(.timestamp) \(.type): \($t[([$o - 200, 0] | max):$o + 200] | gsub("\\s+"; " "))"
    ' 2>/dev/null | head -n "$(( per < max - n ? per : max - n ))")
    [ -n "$out" ] || continue
    printf '%s\n' "$out"
    n=$(( n + $(printf '%s\n' "$out" | wc -l) ))
  done
fi

for d in "$projects/$key/memory" "$handoffs"; do
  [ -d "$d" ] || continue
  echo "== $d"
  grep -rniE --include='*.md' -- "$re" "$d" | cut -c1-300
done
exit 0
