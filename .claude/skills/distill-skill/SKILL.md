---
name: distill-skill
description: >
  Turns a workflow you already carried out into a reusable Skill by mining your own past Claude Code
  session transcripts - invoke immediately, don't just answer directly, whenever the user references
  something they already did in a prior session/conversation and wants it turned into a skill, even
  without the word "skill": "turn my deploy flow into a skill", "make a skill out of how I fixed X
  last time", "I already did this once, can you turn that into a skill", "look back at that session
  where I debugged Y", "distill a skill from what I did yesterday", "mine my session history for last
  week's thing", "don't make me re-explain this, go look at what I already did". Signal: reference to
  completed past work ("last time", "yesterday", "that session"). NOT for "build me a new skill that
  does X" with no prior-session reference - route those to skill-creator, which this hands off to once
  approved (never writes a skill file itself; mines, filters, drafts, then skill-creator authors it).
---

# Distill a Skill from Session History

## Why this exists

Session transcripts under `~/.claude/projects/<project>/` already contain most of what a skill
interview would ask for: what you did, what tools you used, what broke, what you concluded. This
skill mines that history directly instead of re-interviewing you from scratch, then hands the
resulting draft to `skill-creator` for the actual authoring/validation. It deliberately does not
duplicate `skill-creator`'s job - it produces the intent `skill-creator` would otherwise have to
extract from a live conversation.

Three existing subsystems are used as-is and never modified by this flow:

- **Wiki agent** (`.claude/agents/wiki.md`) - factual knowledge only, not procedures. Out of scope.
- **Auto-memory** (`~/.claude/projects/.../memory/`) - curated `feedback` memories. Used only as a
  corroboration/conflict check against what a transcript shows, never as the primary source of steps.
- **skill-creator** (`.claude/skills/skill-creator/`) - the write-out and validation pipeline. Reused
  as-is for the final authoring step; this skill never writes into `.claude/skills/` itself.

## Before you start: this repo may be public

If the session(s) you're about to mine belong to a project other than this one, say so plainly
before you start reading transcripts: name the target project and state whether its containing repo
is public or private if you know. This is an awareness step, not a routing decision - wherever the
source session lives, **the distilled skill you produce always gets written into this configs repo**
(see step 8), and gitignored by default. Mining a work repo's history can pull in ARNs, account IDs,
internal hostnames, or other content that shouldn't end up committed to a repo you don't control the
visibility of - the redaction step in step 6 and the gitignore-by-default in step 8 are the two
independent mitigations for that, not substitutes for each other.

## Flow

### 1. Containment gate

State plainly (per "Before you start" above) that this repo is public before mining a non-configs
project. This is about awareness, not about where the output lands - the output always lands here.

### 2. Resolve the project directory

Never string-mangle a path into the encoded project-directory form (e.g. turning
`/Users/you/code/foo` into `-Users-you-code-foo` by hand) - the encoding is lossy and you will get
it wrong on repos with dots, hyphens, or unusual nesting. Instead list `~/.claude/projects/` and
match against what's actually there, the same way `scripts/mine_sessions.py --list` does internally.
If the user names a project ambiguously, show the candidates and ask.

### 3. Build a session manifest

Run:

```
scripts/mine_sessions.py --project <token> --list
```

This reads `ai-title` / `last-prompt` records straight out of the `.jsonl` files - **never**
`sessions-index.json`. That index has been found stale in every project checked (zero overlap
between its indexed session IDs and the real `.jsonl` transcripts actually present), and it only
exists in a minority of project directories anyway. Present the dated, titled list to the user and
let them pick, or keyword-match against the flow they named ("that poetry build fix", "the deploy
thing from last week").

### 4. Enumerate subagent transcripts

The real procedure often lives in subagent transcripts, not the main session file. This repo's own
CLAUDE.md mandates delegating file modifications to subagents, so a main transcript frequently shows
only `TOOL Agent: <description>` while the actual commands run inside
`<sessionId>/subagents/agent-*.jsonl`, each with a sibling `.meta.json` giving `agentType` and
`description`. Look at those `.meta.json` files for the shortlisted session(s) and select the ones
whose `description` relates to the flow being distilled - `scripts/mine_sessions.py --session <id>`
already pulls every subagent transcript for a session in automatically, so this step is about which
sessions to run it on, not a separate manual read.

### 5. Filter

Run:

```
scripts/mine_sessions.py --project <token> --session <session-id>
```

for each shortlisted session. This is the one helper script this skill bundles - see "Helper script"
below for its exact behavior. It only filters and prints; it does not judge relevance across
sessions or subagents. That judgment is yours, in the next step.

### 6. Delegate extraction to a researcher agent

Hand the filtered output to a `researcher` agent (`model: opus[1m]`) - not `Explore`
(there is nothing left to _locate_ after step 5, only to _interpret_), and not a generic
general-purpose agent (that would need `model: opus`, which this repo's CLAUDE.md reserves for
specific trigger cases and forbids for generic agents). Tell the researcher explicitly that it is
read-only for this task despite having Bash access - it must not run any of the commands it finds,
only read and report on them.

Required output, one step at a time: `what` (plain description) / `command` (exact command) /
`verify` (a command plus its expected output) / `why` (why this step matters). All four fields are
load-bearing - do not let the researcher collapse them into prose.

Required behaviors, none of them optional:

- **Never invent a `verify` command.** If a step's transcript doesn't show a command being _executed_
  (a tool call with a corresponding tool result), emit `UNVERIFIED - needs user input` for that step
  instead of guessing one. This includes the case where a command appears only as _proposed text_ -
  e.g. inside a written plan, a suggested next step, or a "you could check this by running X" aside -
  with no tool_use/tool_result pair showing it actually ran. Proposed-but-never-executed is not
  observed; tag it `UNVERIFIED` (or, if you want to preserve the suggestion, "PROPOSED, not observed
  executing in this session") rather than presenting it as a confirmed check.
- **Tag each `verify` command** `read-only-safe` vs `requires-credentials/side-effecting` - the person
  running the distilled skill later needs to know which checks are safe to run blind.
- **Keep false starts out of the numbered step list**, but preserve them in a `## Known dead ends`
  section - what was tried and abandoned is useful context, not clutter to hide.
- **Flag ambiguity in `## Open questions`** instead of silently picking a path when the transcript
  shows more than one plausible way to do something.
- **Name provenance**: which session(s)/subagent(s) fed each part of the draft, and flag if older
  relevant sessions were pruned or unavailable (e.g. rotated out, or a project directory that no
  longer exists).
- **Redact account IDs, ARNs, tokens, and internal hostnames to placeholders.** This is the direct
  mitigation for the public-repo risk described above, independent of the gitignore-by-default in
  step 8 - do both, neither one alone is sufficient.
- **Feedback memory wins on conflict.** If a transcript shows one approach but a `feedback`-type
  memory (`~/.claude/projects/.../memory/*.md`) states a constraint that contradicts it, the memory
  wins - but don't resolve it silently. Surface the conflict in `## Open questions` so the human
  reviewing the draft sees both sides.
- **Stop and report, don't fabricate**, if no session shows a clear procedure for what the user
  asked about. A partial or absent procedure is a valid, useful answer - a confident-looking
  invented one is not.

### 7. Human review in-conversation

Nothing is written to `.claude/skills/` before the user approves the draft. Present the draft
(steps, dead ends, open questions, provenance) in the conversation and wait for explicit go-ahead.

### 8. Hand off to skill-creator

Once approved, write the file using `skill-creator`'s own authoring conventions (see its `SKILL.md`
for the anatomy of a skill directory), then:

- **Append the new skill's directory to `.gitignore`** (e.g. `.claude/skills/<distilled-name>/`) as
  part of the same write - tracking is opt-in for skills this tool produces, not opt-out. This is a
  per-skill append at write time, not a single pre-declared output path - every distilled skill is a
  first write to a name that doesn't exist yet, so there is nothing to pre-declare in `.gitignore`
  ahead of time.
- **Run the mandatory validation gate**: `python .claude/skills/skill-creator/scripts/quick_validate.py
<path-to-new-SKILL.md>`. Don't consider the write done until this passes.

Note: this gitignore-on-write default applies only to skills this tool _produces_. `distill-skill`
itself is first-party tooling like `skill-creator` or `coding-pitfalls` - it is meant to be committed,
not gitignored.

## Helper script: `scripts/mine_sessions.py`

Stdlib only (`json` / `pathlib` / `argparse`, no `yaml`, no third-party deps) so it runs under
whatever `python3` is already on the machine - no `jq`, no shell-quoting risk. Runs on Python 3.9+.

```
scripts/mine_sessions.py --project <token> --list
scripts/mine_sessions.py --project <token> --session <session-id>
scripts/mine_sessions.py --session <session-id>          # searches all project dirs if omitted
```

- `--project <token>` resolves a directory under `~/.claude/projects/` by substring match against
  the real directory names - never by re-encoding a path. Zero matches or multiple matches both exit
  non-zero with the candidate list printed, rather than silently guessing.
- `--list` builds the manifest from `ai-title` -> `last-prompt` -> first user message (skipped if the
  transcript is under ~10KB and none of the earlier fallbacks produced anything) - never from
  `sessions-index.json`.
- `--session <id>` prints the main transcript filtered down to user intent, assistant text/decisions,
  tool name + command/path, and error-only tool results (successful tool output bodies are dropped -
  that's most of the bulk), followed by every subagent transcript under
  `<session-id>/subagents/*.jsonl`, each headed by its `agentType`/`description` from the sibling
  `.meta.json`.
- Exits non-zero with an explicit message on empty output in every failure mode (no project match,
  no sessions found, session id not found, filtering produced nothing) - a silent empty result would
  otherwise be indistinguishable from "no procedure found," and only the researcher agent (step 6)
  should ever conclude that.
- Scope fence: this script emits a manifest or filtered text and nothing else. Deciding _which_
  sessions or subagents actually matter stays with the researcher agent in step 6, not with the
  script - it does not rank, score, or select on your behalf.

`skill-creator`'s own `scripts/quick_validate.py` and `scripts/run_loop.py` cover validation and
trigger-description optimization; nothing else new is needed here.

## Risks

| Risk                                       | Handling                                                                                    |
| ------------------------------------------ | ------------------------------------------------------------------------------------------- |
| Public repo + tracked-by-default skills    | Auto-`.gitignore` on write (step 8) + redaction in extraction (step 6)                      |
| Trigger collision with skill-creator       | This description was tuned against near-miss prompts for both skills before being finalized |
| No matching session found                  | Stop and report; never fabricate a procedure                                                |
| Flow spans multiple sessions               | Order by mtime; reconcile conflicts into `## Open questions`                                |
| Unsafe verify commands (prod/credentialed) | Tagged `read-only-safe` vs `requires-credentials`                                           |
| Old sessions pruned/missing                | Provenance + incompleteness flag on the output                                              |

## Out of scope for v1

Scheduled/background mining, cross-tool portability, embeddings/vector search, any write path that
skips the human-review gate in step 7, and any change to the wiki agent.
