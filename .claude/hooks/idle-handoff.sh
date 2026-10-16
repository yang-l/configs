#!/usr/bin/env bash
# Idle handoff timer, driven by hooks. Subcommands:
#   mark          UserPromptSubmit, synchronous: marks the turn busy, sets the token
#   arm <minutes> UserPromptSubmit, asyncRewake: waits for idle, exits 2 to wake Claude
#   idle          Stop: marks the turn idle, saves a handoff to its final file
#   disarm        SessionEnd: links a fresh handoff for /clear, removes state
#   path <session-id> <start-folder> <slug>
#                 Run by the handoff skill through Bash: prints the final file path
# Every hook path exits 0 and prints nothing, except the arm fire (exit 2, stderr)
# and the systemMessage line after a save. A Stop hook that exits non-zero or
# prints a "decision" can block the turn end.

cmd=$1
root="${HANDOFF_ROOT:-$HOME/.local/state/claude-handoffs}"

# Worktrees share the main checkout's key. A removed worktree makes git fail,
# and then the key comes from the path itself.
new_path() { # start-folder session-id slug
  local base=$1 common
  common=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) &&
    base=$(dirname "$common")
  printf '%s/%s/%s-%s-%s.md\n' "$root" "${base//\//-}" "$(date +%Y%m%d-%H%M%S)" "$2" "$3"
}

# The Bash sandbox blocks writes outside the working folders, so path only prints.
if [ "$cmd" = path ]; then
  [[ $2 =~ ^[A-Za-z0-9-]+$ && $4 =~ ^[a-z0-9-]{1,50}$ && -n $3 ]] || exit 1
  new_path "$3" "$2" "$4"
  exit 0
fi

input=$(cat)
field() { jq -r --arg k "$1" '.[$k] // empty' <<<"$input" 2>/dev/null; }

sid=$(field session_id)
[[ $sid =~ ^[A-Za-z0-9-]+$ ]] || exit 0
[ -n "$(field agent_id)" ] && exit 0

state="${TMPDIR:-/tmp}/idle-handoff"
mkdir -p "$state" || exit 0
s="$state/$sid"
tag='[idle-handoff]'
tp=$(field transcript_path)
done_line='Handoff saved in '

lines() { [ -f "$1" ] && wc -l <"$1" | tr -d ' ' || echo 0; }

# After Esc, Stop does not run. The interrupt line counts only when it is newer
# than the line count that mark saved, so an old interrupt cannot count.
interrupted() {
  [ -f "$tp" ] || return 1
  (( $(lines "$tp") > $(cat "$s.busy" 2>/dev/null || echo 0) )) || return 1
  tail -n 1 "$tp" | grep -qF '[Request interrupted by user'
}

# The skill writes the handoff to the path from "path" when the mode allows file
# writes, and names that path in its reply. In plan mode it cannot write, so it
# puts the handoff in its final message instead.
save_handoff() {
  local reply msg want file header slug start cwd branch
  reply=$(field last_assistant_message)
  cwd=$(field cwd)
  start=${CLAUDE_PROJECT_DIR:-$cwd}
  want=$(grep -m1 "^$done_line" <<<"$reply")
  want=${want#"$done_line"}
  want=${want//\`/}
  file=''
  # Accept only a file for this session, directly inside a project folder.
  if [[ $want == "$root"/*/*-"$sid"-*.md ]] && [ "$(dirname "$(dirname "$want")")" = "$root" ]; then
    file=$want
  fi
  if [ -n "$file" ] && [ -f "$file" ]; then
    msg=$(cat "$file")
  else
    msg=$reply
  fi
  header=$(grep -m1 -E "^<!-- handoff:$sid slug:[^ ]* -->$" <<<"$msg") || return 0
  if [ -z "$file" ]; then
    slug=${header#*slug:}
    slug=${slug% -->}
    [[ $slug =~ ^[a-z0-9-]{1,50}$ ]] || slug=handoff
    file=$(new_path "$start" "$sid" "$slug")
  fi
  mkdir -p "$(dirname "$file")" || return 0
  {
    printf 'Start folder: %s\nCurrent folder: %s\n' "$start" "$cwd"
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null) && [ -n "$branch" ] &&
      printf 'Branch: %s\n' "$branch"
    printf '\n'
    awk -v h="$header" -v d="$done_line" 'f || $0 == h { f = 1 } f && index($0, d) != 1 { print }' <<<"$msg"
  } >"$file" || return 0
  printf '%s %s\n' "$(field prompt_id)" "$file" >"$s.saved"
  # systemMessage only shows a line to the user. It does not block the stop.
  jq -nc --arg m "$done_line$file" '{systemMessage: $m}'
}

case $cmd in
mark)
  prompt=$(field prompt)
  # The rewake turn holds the tag. Any other prompt is new work.
  if [ -n "$prompt" ] && [[ $prompt != *"$tag"* ]]; then
    rmdir "$s.done" 2>/dev/null
  fi
  lines "$tp" >"$s.busy"
  rm -f "$s.idle"
  field prompt_id >"$s.token"
  ;;
arm)
  wait_s=$(( ${2:-50} * 60 ))
  pid=$(field prompt_id)
  # mark and arm start in parallel. Wait for mark to write this prompt's token.
  for _ in $(seq 35); do
    [ "$(cat "$s.token" 2>/dev/null)" = "$pid" ] && break
    sleep 1
  done
  [ "$(cat "$s.token" 2>/dev/null)" = "$pid" ] || exit 0
  [ -d "$s.done" ] && exit 0
  interval=$(( wait_s / 10 ))
  (( interval > 60 )) && interval=60
  (( interval < 1 )) && interval=1
  while sleep "$interval"; do
    [ "$(cat "$s.token" 2>/dev/null)" = "$pid" ] || exit 0
    if [ -f "$s.idle" ]; then
      start=$(stat -f %m "$s.idle")
    elif [ -f "$s.busy" ] && interrupted; then
      start=$(stat -f %m "$tp")
    else
      continue
    fi
    age=$(( $(date +%s) - start ))
    (( age < wait_s )) && continue
    # The laptop slept through the wait, so the prompt cache is already cold.
    (( age * 10 > wait_s * 11 )) && exit 0
    mkdir "$s.done" 2>/dev/null || exit 0
    printf '%s You were idle for %d minutes. Call Skill("handoff") now for session %s, before the prompt cache expires. Ask nothing.\n' \
      "$tag" "$(( wait_s / 60 ))" "$sid" >&2
    exit 2
  done
  ;;
idle)
  if [ -f "$s.busy" ]; then
    : >"$s.idle"
    rm -f "$s.busy"
  fi
  save_handoff
  ;;
disarm)
  if [ "$(field reason)" = clear ] && [[ ${CLAUDE_PID:-} =~ ^[0-9]+$ ]]; then
    link="$root/.links/$CLAUDE_PID"
    rm -f "$link"
    spid='' sfile=''
    [ -f "$s.saved" ] && read -r spid sfile <"$s.saved"
    # A later prompt replaces the token, so an out-of-date handoff gets no link.
    if [ -n "$sfile" ] && [ -f "$sfile" ] && [ "$spid" = "$(cat "$s.token" 2>/dev/null)" ]; then
      mkdir -p "$root/.links" && printf '%s\n' "$sfile" >"$link"
    fi
  fi
  rm -rf "$s.token" "$s.busy" "$s.idle" "$s.saved" "$s.done"
  ;;
esac
exit 0
