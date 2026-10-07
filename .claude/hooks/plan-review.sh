#!/usr/bin/env bash
# PreToolUse hook on ExitPlanMode: open the plan in Emacs. When the user edits
# it, deny the call and send Claude the diff.
# Every early exit prints nothing, so Claude Code shows the normal approval screen.
# No `set -e`: cmp and diff return 1 when the files differ.

input=$(cat)
plan=$(jq -r '.tool_input.planFilePath // empty' <<<"$input")
log="$(jq -r '.scratchpad_dir // empty' <<<"$input")"
log="${log:-${TMPDIR:-/tmp}}/plan-review.log"

note() {
  printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$log"
}

skip() {
  note "exit: $1 tool_input keys: $(jq -c '.tool_input | keys? // []' <<<"$input")"
  exit 0
}

# hooks inside a subagent get agent_id; only the main session's plans reach the user
agent_id=$(jq -r '.agent_id // empty' <<<"$input")
[ -z "$agent_id" ] || skip "subagent $(jq -r '.agent_type // empty' <<<"$input")"

# claude-code-ide sets EMACS_SOCKET_NAME to the server of the Emacs that runs
# Claude, so open the plan there. In a tmux pane (agent-deck), no server is
# used: a fresh `emacs -nw` opens in a popup over the Claude pane.
if [ -n "$EMACS_SOCKET_NAME" ]; then
  mode=emacs
elif [ -n "$TMUX" ]; then
  mode=tmux
else
  skip "no emacs server or tmux"
fi
note "start: mode=$mode plan=$plan PATH=$PATH TMPDIR=$TMPDIR tools=$(command -v jq emacsclient tmux | tr '\n' ' ')"

[ -n "$plan" ] || skip "no planFilePath"
[ -f "$plan" ] || skip "plan file missing: $plan"
# emacsclient prints `t` on success; hook stdout must hold only JSON
if [ "$mode" = emacs ]; then
  emacsclient -s "$EMACS_SOCKET_NAME" -e t >/dev/null 2>&1 || skip "no emacs server"
else
  # agent-deck keeps a control-mode client on each session. Without -c, tmux
  # can draw the popup there, where nobody sees it, so pick the newest real one.
  session=$(tmux display -p ${TMUX_PANE:+-t "$TMUX_PANE"} '#{session_name}')
  client=$(tmux list-clients -t "$session" -F '#{client_control_mode} #{client_activity} #{client_name}' |
    awk '$1 == 0' | sort -n -k2 | tail -1 | cut -d' ' -f3-)
  note "tmux session=$session client=$client"
  [ -n "$client" ] || skip "no visible tmux client"
fi

before=$(mktemp "${TMPDIR:-/tmp}/plan-review.XXXXXX") || skip "mktemp failed"
cp "$plan" "$before" || { rm -f "$before"; skip "copy failed"; }

if [ "$mode" = emacs ]; then
  # the plan opens in another window, so remember where the cursor was and
  # return there after C-x #; fall back to any window showing a Claude buffer
  emacsclient -s "$EMACS_SOCKET_NAME" -e '(setq my-plan-review--window (selected-window))' >/dev/null 2>&1
  if ! emacsclient -q -s "$EMACS_SOCKET_NAME" "$plan" >&2; then
    rm -f "$before"
    skip "emacsclient edit failed"
  fi
  emacsclient -s "$EMACS_SOCKET_NAME" -e '(let* ((claude-p (lambda (w) (string-prefix-p "*claude-code[" (buffer-name (window-buffer w)))))
       (saved my-plan-review--window)
       (w (if (and (window-live-p saved) (funcall claude-p saved))
              saved
            (get-window-with-predicate claude-p nil t))))
  (when w
    (select-frame-set-input-focus (window-frame w))
    (select-window w)))' >/dev/null 2>&1
else
  # display-popup -E waits until the editor exits
  if ! tmux display-popup -E -c "$client" ${TMUX_PANE:+-t "$TMUX_PANE"} -w 96% -h 96% \
    "emacs -nw $(printf %q "$plan")" >&2; then
    rm -f "$before"
    skip "tmux popup failed"
  fi
fi

if cmp -s "$before" "$plan"; then
  rm -f "$before"
  note "exit: no edits"
  exit 0
fi

changes=$(diff -u -L before -L after "$before" "$plan")
rm -f "$before"
note "exit: deny with diff"

jq -n --arg diff "$changes" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("The user edited the plan file. The file now holds the user'"'"'s version.\n" +
      "1. Read the diff below. Treat added comment lines, such as COMMENT: or <!-- ... -->, as instructions.\n" +
      "2. Revise the plan file to match the intent of the edits. Remove the comment lines.\n" +
      "3. Update the Changed since last version list. Then call ExitPlanMode again.\n\n" + $diff)
  }
}'
