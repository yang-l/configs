---
name: config-optimise
description: >-
  Audits and optimises your Claude Code config files (CLAUDE.md, agent definitions, skills, output styles) — removing redundant instructions, adding missing best practices, restructuring misplaced rules, and improving vague instructions. It cuts whole-session cost only where accuracy, quality, speed, safety, reliability, and checking depth stay the same. Use when the user asks to audit, prune, refresh, improve, or health-check their Claude Code config, says it is bloated or out of date, or wants to lower Claude Code cost. Orchestrates a 6-agent team backed by deep web research and a profile of your own usage logs; no file is touched without your explicit approval.
model: opus
effort: high
---

## Scope

Operate only on files in the **project-level** `.claude/` directory (git-tracked, user-owned):

- `.claude/CLAUDE.md`
- `.claude/agents/*.md`
- `.claude/skills/*/SKILL.md`
- `.claude/output-styles/*.md`

Never touch `~/.claude/` — that directory is nix-managed and may contain web-downloaded packages. You may write `.claude/settings.json` only to land an approved `RESTRUCTURE` target, such as a hook entry or a settings key. You may also write it to land an approved cost item on a model or effort key, such as `advisorModel`.

An output style loads on every turn, so you may trim or improve it in place. Never move a rule from `CLAUDE.md` into an output style. The user rejected that move on 2026-08-19.

> **Nix propagation:** `~/.claude/` resolves through out-of-store symlinks to this repo's `.claude/` directory, so an edit or a new skill directory is live at once, with no rebuild. A package that `ai.nix` downloads at activation lands only after a nix rebuild, and the rebuild replaces any local edit to it. Verify a path with `diff ~/.claude/CLAUDE.md /Users/yangliu/personal/configs/.claude/CLAUDE.md`.

---

## Agent team

Main thread is coordinator only — it routes, delegates, and tracks state. No direct file edits in the main thread.

| Role                | Agent type        | Model  | Responsibility                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ------------------- | ----------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Researcher**      | `researcher`      | opus   | Deep web research: Anthropic official docs + community sources (GitHub discussions, developer blogs, Reddit, Hacker News, X/Twitter threads) to find current CC best practices, deprecated patterns, and capability upgrades. Produces two outputs: (1) evidence corpus `{url, quoted_text, relevance, source_credibility}` per finding; (2) a **best-practices checklist** — a structured list of patterns a well-configured CC user should have, sourced from official docs + community. |
| **Measurer**        | `general-purpose` | sonnet | Profiles whole-session usage in a window set by the setup history. Reports the top cost drivers, the cost split, the always-loaded footprint, and the measured gain of each claim. Reports main sessions and subagents separately.                                                                                                                                                                                                                                                         |
| **Analyst**         | `general-purpose` | opus   | Three passes: (1) classifies every existing instruction as `REMOVE`, `UPDATE`, `ADD`, `RESTRUCTURE`, `IMPROVE`, or `KEEP` with citation for every non-KEEP flag; (2) gap analysis — compares current config against the best-practices checklist and flags anything missing as `ADD`; (3) cost drivers: searches for a config lever for each large cost driver. Writes the annotated diff.                                                                                                 |
| **Reviewer**        | `reviewer`        | opus   | Challenges every non-KEEP flag (`REMOVE`, `UPDATE`, `ADD`, `RESTRUCTURE`, `IMPROVE`) — verifies cited evidence supports the claim, version constraints are respected, and saving estimates follow the Pass 3 methods. Moves a cost item to "Not proposed: quality risk" unless its `Quality risk` is "none" for every item in the Pass 3 list. Returns anything hallucinated or weakly supported to Analyst. At most 3 rounds.                                                             |
| **Writer**          | `engineer`        | sonnet | After user approval: applies accepted edits to project `.claude/` files. One Writer instance per file — no cross-file writes in a single agent.                                                                                                                                                                                                                                                                                                                                            |
| **Change reviewer** | `reviewer`        | opus   | Reads the final git diff. Confirms edits match exactly what was approved.                                                                                                                                                                                                                                                                                                                                                                                                                  |

The Analyst uses `general-purpose` on purpose. It needs the `advisor` tool and writes an annotated diff, and no defined agent does both.

The Analyst may pre-load target file contents while the Researcher fetches evidence, but classification must not begin until the full evidence corpus and the Step 2b measurements are returned. All other stages are sequential.

Each agent should use the built-in `advisor` tool when: stuck or not converging, before committing to a consequential interpretation, or when evidence is ambiguous. The Analyst should call advisor before flagging anything as `REMOVE` if the evidence feels uncertain. The Reviewer should call advisor if it cannot decide whether to accept or reject a flag.

---

## Workflow

### Step 1 — Discover targets and detect CC version

Run `claude --version` to get the exact Claude Code version the user is currently running. Record this as `current_cc_version`. Pass it to the Researcher — it is the version ceiling for what counts as "built-in". Features that shipped in a version newer than `current_cc_version` must not be used as evidence for `REMOVE` or `RESTRUCTURE` flags.

List all files matching the scope above in the project `.claude/` directory. Check `.claude/skills/config-optimise/.last-audited.json` if it exists — load the `kept_items` list to skip items the user already decided to keep.

### Step 2 — Research (Researcher agent)

Spawn the Researcher (opus). Provide `references/sources.md` as the seed URL list.

Instruct it to conduct **two rounds of research**:

**Round 1 — Official sources:** Fetch each seed URL. Search for updated versions of those pages ("Claude Code changelog 2026", "Anthropic models overview", etc.) to avoid stale cached content. Capture: new default behaviors, new settings keys, new hook events, deprecated patterns, model ID changes. For each Claude Code feature finding, record the CC version it was introduced in (from the changelog). Only include Claude Code feature findings from versions ≤ `current_cc_version` in the evidence corpus — newer features are irrelevant to the user's current install. API, pricing, and model prompting guidance has no CC version. For those findings, record the source date and the model the guidance applies to instead.

**Round 2 — Community and practitioner sources:** Search broadly across:

- GitHub: `anthropics/claude-code` issues, discussions, and release notes
- Developer blogs and write-ups: "Claude Code CLAUDE.md best practices", "Claude Code tips 2025 2026"
- Reddit (`r/ClaudeAI`, `r/MachineLearning`), Hacker News, and X/Twitter threads from known AI practitioners
- Any curated "awesome-claude-code" or similar community resource lists

The goal is to surface patterns the community has discovered: instructions that are now considered anti-patterns, idioms that newer CC versions handle natively, and emerging best practices that make certain CLAUDE.md entries redundant or that suggest better alternatives.

For each relevant finding, record:

```json
{
  "url": "...",
  "quoted_text": "exact sentence from the source",
  "relevance": "what CLAUDE.md instruction this might affect",
  "source_credibility": "official | community-verified | individual"
}
```

Weight `official` sources highest for `REMOVE`/`UPDATE` flags. `community-verified` findings (multiple independent sources agreeing) can support flags too. `individual` findings alone are not sufficient evidence — use them to guide further official-source verification.

Return the full evidence corpus.

### Step 2b — Usage profile and measurement (Measurer agent)

Spawn the Measurer (sonnet) after the Researcher returns the evidence corpus. This step runs on every audit. Give it every finding that claims a measurable gain, such as fewer tokens, turns, or tool calls, or lower cost. The Measurer reads the session logs in `~/.claude/projects/*/*.jsonl` and `~/.claude/projects/*/*/subagents/*.jsonl`. It does not change the logs.

The Measurer does these steps:

1. **Pick the window from the setup history.** Do not use a fixed number of days. A setup change is any change to one of these values:
   - a `model`, `advisorModel`, or `effortLevel` key at any depth in `.claude/settings.json`, such as `modelSettings.effortLevel`
   - the `CLAUDE_CODE_SUBAGENT_MODEL` or `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` key in the `env` section of `.claude/settings.json`
   - a `model:` or `effort:` line in `.claude/agents/*.md`
   - a model, effort, or advisor routing line in `.claude/CLAUDE.md` or `.claude/skills/*/SKILL.md`, such as the team table above
2. **Find setup changes from 3 sources.** The user does not commit every edit, and edits go live at once.
   - Git commits that change one of those values.
   - The `applied_changes` timestamps in `.last-audited.json`.
   - Live edits. Run `git status --porcelain` for staged, unstaged, and untracked files. Read `git diff HEAD` for model or effort lines in tracked files. Read each untracked file in scope directly, because `git diff HEAD` does not show it. Use the file modified time as the change time.
3. **Set the window start.** Start at the most recent setup change. If the window covers fewer than 14 days, start at the setup change before it. Repeat until the window covers at least 14 days. If no earlier setup change exists, start the window 14 days before today. Limit the window to 90 days. The user can change both limits.
4. **Profile the cost.** Run `python3 ~/.claude/skills/agent-cost/scripts/agent_cost.py --since <window start> --usd --tools --sort cost --top 15 --reprice <model>`. Give one `--reprice` for each current or proposed model. The summary after the table covers every row, not only the top 15. Record the cost split for main sessions, subagents, and advisor calls, and the cost per model. Name the window and each setup change inside it.
5. **Measure the always-loaded footprint.** Measure the bytes of the global and project `CLAUDE.md`, the active output style, `MEMORY.md`, and the `UserPromptSubmit` hook text. Count each file once by its resolved path, because `~/.claude/CLAUDE.md` is a symlink to the repo file. Estimate tokens as bytes / 4.
6. **Measure each claimed gain.** Write a script in `$TMPDIR` only for patterns that `agent_cost.py` does not report. Report the gain for each model, with main sessions and subagents separate.
7. **Compare with the last baseline.** When `.last-audited.json` holds a `baseline`, compare normalized figures: cost per day, cost per session, and cost per turn, next to the session and turn counts. Label raw totals from windows of different length as not comparable.
8. **Report the method.** Give the exact command, the sample size, and the direction in which each estimate can err.

Pass the measurements to the Analyst with the evidence corpus. For a finding that claims a measurable gain, the Analyst flags `ADD` only for a scope where the measured gain is material. The Analyst treats a gain below 5% of turns or tokens in that scope as not material. The user can set another threshold.

The Analyst puts the instruction in a file that loads for every agent in that scope. An agent file reaches only its own agent type. `CLAUDE.md` reaches the main session and every subagent. If the logs cannot measure a claim, the Analyst records "not measured" and applies the normal evidence rules.

### Step 3 — Audit (Analyst agent)

Spawn the Analyst. Provide: all target file contents + the evidence corpus + the best-practices checklist from Step 2 + the measurements from Step 2b.

**Pass 1 — classify existing instructions.** For every distinct instruction, rule, or bullet point in each file:

| Label         | Meaning                                                                                                                           |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `REMOVE`      | Now built-in to CC or handled natively — the instruction adds noise                                                               |
| `UPDATE`      | Stale specifics (old model ID, deprecated flag, wrong version)                                                                    |
| `ADD`         | A missing best practice not yet in the config                                                                                     |
| `RESTRUCTURE` | Should be relocated: procedural "always do X" → PostToolUse hook; file-type rule → `.claude/rules/`; behavior → settings.json key |
| `IMPROVE`     | Exists but vague or weak — rewrite for precision and consistent behaviour                                                         |
| `KEEP`        | Fine as-is                                                                                                                        |

> A `RESTRUCTURE` into `.claude/rules/` must give the new file a `paths:` frontmatter list. Without `paths:` the rule loads every session exactly like `CLAUDE.md`, so the move saves nothing.

**Hard rule:** Every label except `KEEP` requires a cited URL + exact quoted text from the evidence corpus. No fetched evidence → classify as `KEEP`. No speculating from model knowledge alone. For `REMOVE`/`RESTRUCTURE` flags citing a CC feature as "now built-in": the evidence must confirm that feature shipped in `current_cc_version` or earlier — not in a newer release. If the version is unclear from the source, classify as `KEEP`.

**Pass 2 — gap analysis.** Compare the full config against the best-practices checklist. For each checklist item not covered by any existing instruction, flag it as `ADD` with the checklist source as evidence.

**Pass 3 — cost drivers.** Cost comes last. Propose a cost item only when it keeps each of these at its current level:

- accuracy, output quality, and speed
- safety and security: secrets rules, deny rules, and confirmation before risky actions
- reliability: no new failure mode and no new reruns
- checking depth: reviews, tests, advisor checks, and review round limits
- the user's settled decisions and workflow: approval gates, kept items, and the plan and review steps
- context kept across a session, such as facts that compaction can drop
- interruptions to the user, such as permission prompts and clarifying questions

The `Quality risk` of each proposed cost item must be "none" for every item in this list, backed by a cited source or a measurement. List every other cost lever under "Not proposed: quality risk" with its estimated saving and its risk. Give it no `Suggested` text.

For each cost driver at or above 5% of total cost in the Step 2b profile, search for a config lever. Levers include model or effort routing, the advisor model, delegation of large reads, context size, the always-loaded footprint, and batching. Each item keeps the hard rule: cite a source for the mechanism. Each cost item also states `Baseline`, `Estimated saving`, and `Quality risk`. `Baseline` is the observed spend. For a text reduction, `Baseline` is the measured token count, turns, and sessions, because the logs do not show the spend of one piece of text. Estimate the saving with the method that matches the lever:

- **Model change:** reprice the same token mix with `--reprice` at the current model and at the proposed model. State the unchanged-token assumption.
- **Avoided work**, such as fewer respawns or failed runs: price the observed token mix of the turns that would disappear, in all 5 billing classes, with the `agent-cost` price table.
- **Batching:** the tool calls, their results, and the output stay in the surviving turns. Count only the net change: the context that each removed turn read again. Price it as that turn's cache-read tokens at the cache-read rate. When you cannot measure that split, write "saving not measured".
- **Text reduction**, such as a smaller always-loaded footprint: removed always-loaded text saves one cache read per turn and one cache write per session start. Price removed tokens × turns at the cache-read rate, plus removed tokens × sessions at the cache-write rate. State the split and its source.
- **No measured basis:** write "saving not measured". Do not invent a figure.

State the reduction assumption for every estimate.

Resolve the current model for each invocation route, not for each row type, because one agent type can run on several models. For a subagent or teammate, check `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` first, because it overrides every spawn and frontmatter model. Otherwise use Claude Code's order:

1. The model that the invoking skill or `CLAUDE.md` routing sets at spawn.
2. The agent frontmatter `model:`.
3. The `CLAUDE_CODE_SUBAGENT_MODEL` environment override.
4. The model of the active parent or team lead at spawn time, from the parent's logged turns.

For a main session, use the logged model parts, because a session can change model partway through. Use the `settings.json` default only to forecast new sessions that start without an override. Check each result against logged turns from sessions that started after the last setup change. Mark the estimate "conditional" when the route is ambiguous or the logs disagree.

### Step 4 — Review loop (Analyst → Reviewer)

The Analyst writes the annotated diff in this format. Every non-KEEP item gives the exact text that the Writer applies. A `RESTRUCTURE` item gives both the source removal and the destination patch.

```
## .claude/CLAUDE.md

- [ ] ADD  after line 45 (new instruction):
      Suggested: "Use EnterWorktree for agent isolation when parallel changes may conflict."
      Evidence: https://code.claude.com/docs/en/settings — "worktree.baseRef: head preserves unpushed commits in the isolated branch"
      Reason: Community best practice for multi-agent work; not currently in your config.

- [ ] RESTRUCTURE  line 62: "always run prettier after editing files"
      Source removal: delete line 62 from .claude/CLAUDE.md
      Destination patch (.claude/settings.json, hooks.PostToolUse):
        { "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write" }] }
      Evidence: https://code.claude.com/docs/en/hooks-guide — "Hooks provide deterministic control over Claude Code's behavior, ensuring certain actions always happen rather than relying on the LLM to choose to run them."
      Reason: Procedural "always do X" belongs in hooks, not CLAUDE.md — hooks execute deterministically, prose instructions do not.

- [ ] UPDATE  line 45: "spawn the reviewer with model claude-opus-4-1"
      Evidence: <models overview URL> — "<exact sentence from the fetched page>"
      Reason: The pinned model ID names a model that the current models table no longer lists.
      Suggested: "spawn the reviewer with model opus"

- [ ] REMOVE  .claude/output-styles/lean.md lines 70-72: text that CLAUDE.md lines 160-166 already state
      Evidence: <memory docs URL> — "<exact sentence on duplicate or conflicting instructions>"
      Baseline: about 280 tokens loaded on every turn, <N> turns, <M> sessions, window <start> to <end>
      Estimated saving: USD <amount>, text reduction: removed tokens × turns at the cache-read rate, plus removed tokens × sessions at the cache-write rate
      Quality risk: none. CLAUDE.md keeps the same rule word for word.
      Takes effect: after a session restart

- [ ] KEEP    line 31: "Never access, reveal, or manipulate secrets or credentials."
      (safety invariant — unconditional, no evidence could change this)

## Not proposed: quality risk

- advisorModel fable -> opus: saves up to USD <amount>. Risk: the advisor is no longer a stronger model, and Fable sessions lose their advisor.
```

After each Analyst draft or revision, the main thread runs the `asd-ste100` skill in strict mode on each new or changed `Suggested` string. The Reviewer then reviews that final text, so its sign-off covers the exact words the user sees.

Spawn the Reviewer (reviewer, opus) to challenge every non-KEEP flag — if evidence doesn't clearly support a claim, send the item back to Analyst. Run at most 3 Analyst and Reviewer rounds. An item still disputed after round 3 goes to Step 5 under "Disputed, not actionable".

### Step 5 — User approval gate

Present the reviewed annotated diff to the user. No files are written until explicit approval.

For each flagged item, the user approves or rejects it individually. Show the "Not proposed: quality risk" list after the items, for information only. List disputed items in a separate "Disputed, not actionable" section. The user cannot approve these items in this run, and no Writer receives them.

Remind the user: accepted edits go live at once, because `~/.claude/` symlinks to this repo. Two exceptions apply. An edit to a model or effort key in `settings.json` applies to new sessions only. An output style edit needs a session restart. No nix rebuild is needed for an edit or for a new skill directory. A package that `ai.nix` downloads at activation needs a rebuild, and the rebuild replaces any local edit to it.

Only proceed to Step 6 after receiving explicit approval.

### Step 6 — Write and Review (Writer → Change reviewer)

1. **Writer** (engineer, sonnet): Spawn one Writer per target file. Each Writer applies only the approved edits to its assigned file, verbatim, handling all label types:
   - `REMOVE`/`UPDATE`/`IMPROVE`: edit existing content in place
   - `ADD`: insert new content at the suggested location within the most semantically appropriate section — do not just append at end
   - `RESTRUCTURE`: two coordinated Writers — first removes from the source file, then (after confirmation) the second adds to the destination (e.g. a new PostToolUse hook entry in `.claude/settings.json`, or a new `.claude/rules/<topic>.md` file). Follow the existing format already in the destination file.

2. **Change reviewer** (reviewer, opus): Spawn last. Provide the original file, the approved diff, and the final file. Confirm: (a) every approved edit was applied, (b) no unapproved changes were made, (c) `RESTRUCTURE` source removals and destination additions are both present.

Report the full outcome to the user. Repeat the timing exceptions from Step 5 for each applied item they cover.

### Step 7 — Persist audit state

Write (or update) `.claude/skills/config-optimise/.last-audited.json`:

```json
{
  "last_run": "<ISO date>",
  "kept_items": [
    {
      "file": ".claude/CLAUDE.md",
      "fingerprint": "first ~60 chars of the instruction text"
    }
  ],
  "applied_changes": [
    {
      "file": ".claude/settings.json",
      "change": "advisorModel fable -> opus",
      "applied_at": "<ISO timestamp>"
    }
  ],
  "baseline": {
    "date": "<ISO date>",
    "window_start": "<ISO date>",
    "window_days": 59,
    "setup_changes": ["<ISO date>: <what changed>"],
    "sessions": 0,
    "turns": 0,
    "total_cost": 0,
    "cost_per_day": 0,
    "share": { "main": 0, "subagent": 0, "advisor": 0 },
    "calls_per_turn": { "<model>": 0 },
    "footprint_bytes": 0
  }
}
```

`kept_items` accumulates across runs. On subsequent invocations, Step 1 loads this list and the Analyst skips classifying those items (they stay as implicit `KEEP`). This prevents re-raising items the user has already decided to keep.

`applied_changes` accumulates across runs. Step 2b uses its timestamps to find setup changes that the user never committed. `baseline` holds the figures from the latest run, for the next run's comparison.

### Step 8 — Ask the user to run `/doctor prompt-audit`

Run this step last, after Step 7. Tell the user to run `/doctor prompt-audit` (Claude Code v2.1.283 or later). The command checks the config for instructions written for older models. Only the user can run it. Do not act on its report without user approval.
