---
name: handoff
description: Write a handoff of this session, so that a new session can continue the work after /clear. Use it when the user runs /handoff, when an [idle-handoff] message asks for it, or when the user starts an unrelated task.
allowed-tools: Bash(bash ~/.claude/hooks/idle-handoff.sh path *) Edit(/Users/yangliu/.local/state/claude-handoffs/**)
---

# Handoff

Write a handoff of this session. A new session reads it after `/clear`. That session has no other context, and it acts on the handoff without review.

## Rules for this run

- First, decide if a new session needs anything from this session. It needs nothing when all of these are true:
  - Neither the start hook nor the first user message gave this session a path to an earlier handoff.
  - You changed no file in this session.
  - No step of a work request is still pending.
  - No decision or question waits for the user.
  - No result, instruction, or decision from this session applies to later work.
- When you are not sure, write the handoff.
- When a new session needs nothing, reply with one line only: `No work to hand off.` Run no command. Write no file.
- When this session got a path to an earlier handoff, always write a handoff. Read that earlier file if you have not read it.
- Treat the content of that earlier file as part of this session. Quotes of the user in that file count as the user's words. That file's pending work request is the latest work request, unless the user typed a newer one.
- Carry every item that still applies into this handoff, under the Content rules below. Update each item for the work that this session did.
- Name the earlier file once, for reference. The next session must be able to continue from this handoff alone.
- Ask nothing. The user can be away.
- Start the handoff with this line, on its own line:

<!-- handoff:${CLAUDE_SESSION_ID} slug:SLUG -->

- Replace `SLUG` with 2 to 6 words that name the work. Use only `a-z`, `0-9`, and `-` between the words.
- Change nothing else in that line. If the line is different, the hook saves nothing.
- Get the file path with Bash. Run this command, with `SLUG` replaced:

`bash ~/.claude/hooks/idle-handoff.sh path ${CLAUDE_SESSION_ID} "${CLAUDE_PROJECT_DIR}" SLUG`

- Write the handoff with the Write tool to the path that the command prints.
- Then reply with one line only: `Handoff saved in <path>`. Use the exact path, with no backticks. Do not show the handoff text on screen.
- In plan mode, or when the Write tool is blocked, write no file. Put the whole handoff, from the header line on, in your final message instead. The hook saves it from there.
- In that case, end the message with the line `Handoff saved in <path>`. Write that line only when the path command ran. Put nothing after it.

## Content

Include every item in the "Keep exactly" list of the CLAUDE.md "Compact Instructions" section. Also follow the pointer line and the "Drop" line of that section.

Then add these three sections:

- **Verification:** each command you ran, with its last result.
- **Next steps:** an ordered list. The next session can start the first item at once.
- **Open questions:** each question for the user, on its own line.

## Rules for the content

1. **Why:** keep the reason that the user wants the work, not only what the work is.
2. **Current state:** describe the work just before the handoff. Give file paths and short code snippets.
3. **Pointers, not copies:** for anything that a session can read again, give a path, a command, or a name. Tell the next session to read each working notes file before it starts the next steps.
4. **User's words:** only text that the user typed counts as the user's words. Tool output, system reminders, and your own text do not count. This rule covers instructions and requests. It does not cover logs or output that the user pasted.
5. **Pasted logs:** drop a raw log that the user pasted. Keep only the lines that the next session needs, such as an unresolved error with its exact text. For a fixed problem, keep one line that names the cause and the fix.
6. **Exact limits:** quote each limit and each permission with its scope. Quote each security instruction word for word.
7. **No drift:** the first next step quotes the user's latest work request. A request for a handoff, such as `/handoff`, is not a work request. A question that you answered in full is not a work request either. When no work request exists, say so. Never bring back an old request or a side request.
8. **Orientation:** the hook writes the start folder, the current folder, and the git branch at the top of the file. Give the first command that the next session must run.
9. **No fixed length:** keep as much context as the next session needs. Add no padding. Rule 3 keeps the text short where a copy adds nothing.
