# Codex instructions

`~/.claude/CLAUDE.md` is the source of truth. Read it at the start of every session. Follow it as if Codex were the reader. This file only translates Claude terms to Codex terms. If this file and `CLAUDE.md` disagree, this file wins for Codex.

## Session type

Decide the session type before you read `CLAUDE.md`.

- Reviewer session: the prompt asks for a `VERDICT:` line, names you as a reviewer, or asks only for a review. Treat every unclear case as a reviewer session.
- Subagent session: a parent Codex session started you.
- Main session: the user started you for any other work. A request to review and change files, such as "review and fix", is a main session.
- Exception: a direct user request to ask Claude for a review is a main session, even if it mentions `VERDICT:`. The exception does not apply when the prompt names you as a reviewer or a subagent.

In a reviewer session or a subagent session:

- Do the task that the prompt asks for. Return the result to the caller.
- Do not start Claude, Codex, or any other review.
- Reviewer session only: do not edit files.
- Skip the plan, advisor, and review-round rules in `CLAUDE.md`.

## Term map

| `CLAUDE.md` term                                                                | Codex action                                                                                                                                                                                 |
| ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CLAUDE.md`                                                                     | Also means this file, `AGENTS.md`.                                                                                                                                                           |
| `EnterPlanMode`, `ExitPlanMode`, plan file                                      | Use your plan mode. If you have none, write the plan in the reply. Then wait for approval.                                                                                                   |
| `AskUserQuestion`                                                               | Ask the question in the reply. Wait for the answer.                                                                                                                                          |
| `advisor`                                                                       | Skip. Codex has no advisor.                                                                                                                                                                  |
| Codex review                                                                    | Main session only: ask Claude for a review when the user asks for one. See "Claude as second reviewer".                                                                                      |
| `codex:rescue`                                                                  | Main session only: after 2 failed fix attempts, ask Claude for a diagnosis. Do not wait for a user request. See "Claude as second reviewer".                                                 |
| `Agent`, named agents (`researcher`, `engineer`, `reviewer`, `Plan`, `Explore`) | Start a Codex subagent with the same role. Put the role in the subagent prompt.                                                                                                              |
| Model tiers (`haiku`, `sonnet`, `opus`, `fable`)                                | See "Model tiers".                                                                                                                                                                           |
| `Skill`, skill names                                                            | Use the Codex skill with that name. For `asd-ste100`, read `~/.claude/skills/asd-ste100/references/writing-rules.md` if no skill exists.                                                     |
| `handoff` skill, `/clear`                                                       | Skip the `handoff` rule in `CLAUDE.md` Default Workflow. Start the new task normally.                                                                                                        |
| `Workflow`, `ultracode`, agent teams, hooks, output style, memory               | Skip. These are Claude Code features.                                                                                                                                                        |
| Sign-off line `advisor:` slot                                                   | Write `advisor: skipped, Codex session`. Write `Claude: <verdict>` in place of `Codex: <verdict>`. Put the line at the end of the reply. Omit the Claude clause when you did not ask Claude. |

## Model tiers

Pick the subagent model by role, as `CLAUDE.md` Delegation does. Name the model and the reasoning effort in each spawn request.

| Claude tier | Codex model   | Reasoning effort |
| ----------- | ------------- | ---------------- |
| `fable`     | `gpt-6-astra` | `high`           |
| `opus`      | `gpt-6-sol`   | `high`           |
| `sonnet`    | `gpt-6-sol`   | `medium`         |
| `haiku`     | `gpt-6-luna`  | `low`            |

An effort level in `CLAUDE.md` overrides the effort in this table.

When you set a model or reasoning effort, set `fork_turns` to `"none"` or a positive integer string. A full-history fork ignores the model and effort. Put these items in the child prompt:

- First line: "Read ~/.codex/AGENTS.md and ~/.claude/CLAUDE.md before task work. Follow both, with AGENTS.md controlling Codex-specific translations. If either file is unreadable, stop and tell the parent."
- The role and the task context.
- The rule: "Do not start Claude, Codex, or any review."
- For a review task, the rule: "Do not edit files."

## Claude as second reviewer

Use these rules only in a main session. Ask Claude for a review only when the user asks for one. Ask Claude for a diagnosis after 2 failed fix attempts, as the `CLAUDE.md` "On failure" rule does with `codex:rescue`. These rules replace the `CLAUDE.md` Default Workflow rules from "Codex request" through the "Sign-off line" bullets. Every other rule there stays the same, with "Claude" in place of "Codex".

For a diagnosis, put the failure output and the fixes you tried in place of the plan text in step 5.

1. Write the review prompt to a temporary file. Use a tool that writes text verbatim.
2. If you use a shell heredoc, quote its delimiter. First confirm that no line of the prompt equals the delimiter.
3. Do not use `echo`, `printf`, or an unquoted heredoc. Plan text can hold backticks and `$(...)`.
4. Put this line first in the prompt: "You are a second reviewer started by Codex. Do not start Codex or any other review. Do not edit files."
5. Include the full current plan text. List every user-settled decision. Tell Claude to treat each decision as fixed.
6. Tell Claude to raise a settled decision only for a strong, evidence-backed objection. Claude labels that finding `settled-decision challenge`.
7. Add the full scope rules and the Critical and High output rules from the `CLAUDE.md` "Codex prompt" and "Codex scope and output" rules.
8. Tell Claude to end with `VERDICT: approve` or `VERDICT: needs-attention`.
9. Run `claude -p --permission-mode plan < <prompt-file>` with sandbox escalation. The command needs network access and writes to `~/.claude`.
10. Set a timeout of 15 minutes on the command.
11. If the user denies the escalation, the command fails, or the timeout stops it, write `Claude: unavailable, <reason>` in the sign-off line. Never claim a verdict.
12. Read the verdict. Apply the `CLAUDE.md` "Codex round limit", "Codex findings you do not fix", and "Codex findings" rules.
13. End the reply with the sign-off line.
