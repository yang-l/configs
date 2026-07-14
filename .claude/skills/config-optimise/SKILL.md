---
name: config-optimise
description: Audits and optimises your Claude Code config files (CLAUDE.md, agent definitions, skills) — removing redundant instructions, adding missing best practices, restructuring misplaced rules, and improving vague instructions. Use whenever you want to keep your config lean, current, and effective — trigger phrases: "prune my config", "optimise my config", "audit my CLAUDE.md", "improve my CLAUDE.md", "is my CLAUDE.md still current", "what's missing from my config", "clean up my agents", "refresh my config", "update my claude setup", "health check my claude config", "my claude config is getting bloated". Orchestrates a 7-agent team backed by deep web research; no file is touched without your explicit approval.
effort: high
---

## Scope

Operate only on files in the **project-level** `.claude/` directory (git-tracked, user-owned):

- `.claude/CLAUDE.md`
- `.claude/agents/*.md`
- `.claude/skills/*/SKILL.md`

Never touch `~/.claude/` — that directory is nix-managed and may contain web-downloaded packages. Never touch `.claude/settings*.json` — those are CC's own API format, not user prose instructions.

> **Nix propagation:** `~/.claude/CLAUDE.md` is a nix symlink pointing to the project copy. Accepted prunes take effect globally after the next nix rebuild. Remind the user of this before applying any changes.

---

## Agent team

Main thread is coordinator only — it routes, delegates, and tracks state. No direct file edits in the main thread.

| Role                | Agent type        | Model  | Responsibility                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ------------------- | ----------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Researcher**      | `researcher`      | opus   | Deep web research: Anthropic official docs + community sources (GitHub discussions, developer blogs, Reddit, Hacker News, X/Twitter threads) to find current CC best practices, deprecated patterns, and capability upgrades. Produces two outputs: (1) evidence corpus `{url, quoted_text, relevance, source_credibility}` per finding; (2) a **best-practices checklist** — a structured list of patterns a well-configured CC user should have, sourced from official docs + community. |
| **Analyst**         | `general-purpose` | opus   | Two passes: (1) classifies every existing instruction as `REMOVE`, `UPDATE`, `ADD`, `RESTRUCTURE`, `IMPROVE`, or `KEEP` with citation for every non-KEEP flag; (2) gap analysis — compares current config against the best-practices checklist and flags anything missing as `ADD`.                                                                                                                                                                                                        |
| **Planner**         | `Plan`            | sonnet | Turns analyst classifications into a structured annotated diff, one file at a time.                                                                                                                                                                                                                                                                                                                                                                                                        |
| **Reviewer**        | `engineer`        | fable  | Challenges every non-KEEP flag (`REMOVE`, `UPDATE`, `ADD`, `RESTRUCTURE`, `IMPROVE`) — verifies cited evidence supports the claim and version constraints are respected. Returns anything hallucinated or weakly supported to Analyst. Loop until sign-off.                                                                                                                                                                                                                                |
| **Writer**          | `engineer`        | sonnet | After user approval: applies accepted edits to project `.claude/` files. One Writer instance per file — no cross-file writes in a single agent.                                                                                                                                                                                                                                                                                                                                            |
| **Prompt engineer** | `prompt-engineer` | opus   | After edits are applied: rewrites the updated file to be more formal and concise — tightens wording, removes redundancy — without adding new instructions or changing meaning.                                                                                                                                                                                                                                                                                                             |
| **Change reviewer** | `engineer`        | opus   | Reads the final git diff. Confirms edits match exactly what was approved, and that the prompt-engineer pass introduced no unintended changes.                                                                                                                                                                                                                                                                                                                                              |

The Analyst may pre-load target file contents while the Researcher fetches evidence, but classification must not begin until the full evidence corpus is returned. All other stages are sequential.

Each agent should use the built-in `advisor` tool when: stuck or not converging, before committing to a consequential interpretation, or when evidence is ambiguous. The Analyst should call advisor before flagging anything as `REMOVE` if the evidence feels uncertain. The Reviewer should call advisor if it cannot decide whether to accept or reject a flag.

---

## Workflow

### Step 1 — Discover targets and detect CC version

Run `claude --version` to get the exact Claude Code version the user is currently running. Record this as `current_cc_version`. Pass it to the Researcher — it is the version ceiling for what counts as "built-in". Features that shipped in a version newer than `current_cc_version` must not be used as evidence for `REMOVE` or `RESTRUCTURE` flags.

List all files matching the scope above in the project `.claude/` directory. Check `.claude/skills/config-optimise/.last-audited.json` if it exists — load the `kept_items` list to skip items the user already decided to keep.

### Step 2 — Research (Researcher agent)

Spawn the Researcher (opus). Provide `references/sources.md` as the seed URL list.

Instruct it to conduct **two rounds of research**:

**Round 1 — Official sources:** Fetch each seed URL. Search for updated versions of those pages ("Claude Code changelog 2026", "Anthropic models overview", etc.) to avoid stale cached content. Capture: new default behaviors, new settings keys, new hook events, deprecated patterns, model ID changes. For each finding, record the CC version it was introduced in (from the changelog). Only include findings from versions ≤ `current_cc_version` in the evidence corpus — newer features are irrelevant to the user's current install.

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

### Step 3 — Audit (Analyst agent)

Spawn the Analyst. Provide: all target file contents + the evidence corpus + the best-practices checklist from Step 2.

**Pass 1 — classify existing instructions.** For every distinct instruction, rule, or bullet point in each file:

| Label         | Meaning                                                                                                                           |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `REMOVE`      | Now built-in to CC or handled natively — the instruction adds noise                                                               |
| `UPDATE`      | Stale specifics (old model ID, deprecated flag, wrong version)                                                                    |
| `ADD`         | A missing best practice not yet in the config                                                                                     |
| `RESTRUCTURE` | Should be relocated: procedural "always do X" → PostToolUse hook; file-type rule → `.claude/rules/`; behavior → settings.json key |
| `IMPROVE`     | Exists but vague or weak — rewrite for precision and consistent behaviour                                                         |
| `KEEP`        | Fine as-is                                                                                                                        |

**Hard rule:** Every label except `KEEP` requires a cited URL + exact quoted text from the evidence corpus. No fetched evidence → classify as `KEEP`. No speculating from model knowledge alone. For `REMOVE`/`RESTRUCTURE` flags citing a CC feature as "now built-in": the evidence must confirm that feature shipped in `current_cc_version` or earlier — not in a newer release. If the version is unclear from the source, classify as `KEEP`.

**Pass 2 — gap analysis.** Compare the full config against the best-practices checklist. For each checklist item not covered by any existing instruction, flag it as `ADD` with the checklist source as evidence.

### Step 4 — Plan + Review loop (Planner → Reviewer)

Spawn the Planner to draft the annotated diff in this format:

```
## .claude/CLAUDE.md

- [ ] ADD  after line 45 (new instruction):
      Suggested: "Use EnterWorktree for agent isolation when parallel changes may conflict."
      Evidence: https://code.claude.com/docs/en/settings — "worktree.baseRef: head preserves unpushed commits in the isolated branch"
      Reason: Community best practice for multi-agent work; not currently in your config.

- [ ] RESTRUCTURE  line 62: "always run prettier after editing files"
      Target: PostToolUse hook in .claude/settings.json
      Evidence: https://code.claude.com/docs/en/hooks-guide — "Hooks provide deterministic control over Claude Code's behavior, ensuring certain actions always happen rather than relying on the LLM to choose to run them."
      Reason: Procedural "always do X" belongs in hooks, not CLAUDE.md — hooks execute deterministically, prose instructions do not.

- [ ] IMPROVE  line 14: "think carefully before answering"
      Current: "think carefully before answering"
      Suggested: "Use Sequential Thinking when the path is uncertain, requires hypothesis testing, or has 3+ dependent decisions."
      Evidence: https://code.claude.com/docs/en/settings — "Sequential Thinking MCP tool available for structured reasoning"
      Reason: Vague instruction; specificity produces more consistent model behaviour.

- [ ] REMOVE  line 62: "always run npm test after editing source files"
      Evidence: https://code.claude.com/docs/en/hooks-guide — "Hooks provide deterministic control over Claude Code's behavior, ensuring certain actions always happen rather than relying on the LLM to choose to run them."
      Reason: Procedural "always do X" instructions belong in PostToolUse hooks, not CLAUDE.md. Hooks execute deterministically; prose instructions are soft context the model may skip.
      Suggested: Move to a PostToolUse hook in settings.json; remove from CLAUDE.md.

- [ ] UPDATE  line 45: "always use extended thinking for complex problems"
      Evidence: https://code.claude.com/docs/en/settings — "alwaysThinkingEnabled — Enable extended thinking by default"
      Reason: This behavior is now enforceable via settings.json key alwaysThinkingEnabled: true, making the prose instruction redundant.
      Suggested: Move to settings.json; remove from CLAUDE.md.

- [ ] KEEP    line 31: "Never access, reveal, or manipulate secrets or credentials."
      (safety invariant — unconditional, no evidence could change this)
```

Spawn the Reviewer (engineer, fable) to challenge every non-KEEP flag — if evidence doesn't clearly support a claim, send the item back to Analyst. Repeat until Reviewer signs off on the full diff.

### Step 5 — User approval gate

Present the reviewed annotated diff to the user. No files are written until explicit approval.

For each flagged item, the user approves or rejects it individually. Remind the user: accepted changes to `.claude/CLAUDE.md` take effect globally after the next nix rebuild.

Only proceed to Step 6 after receiving explicit approval.

### Step 6 — Write, Polish, and Review (Writer → Prompt engineer → Change reviewer)

1. **Writer** (engineer, sonnet): Spawn one Writer per target file. Each Writer applies only the approved edits to its assigned file, handling all label types:
   - `REMOVE`/`UPDATE`/`IMPROVE`: edit existing content in place
   - `ADD`: insert new content at the suggested location within the most semantically appropriate section — do not just append at end
   - `RESTRUCTURE`: two coordinated Writers — first removes from the source file, then (after confirmation) the second adds to the destination (e.g. a new PostToolUse hook entry in `.claude/settings.json`, or a new `.claude/rules/<topic>.md` file). Follow the existing format already in the destination file.

2. **Prompt engineer** (prompt-engineer, opus): Spawn after all Writers complete. Provide each updated file. Tighten prose, eliminate redundancy, improve consistency of tone — without adding new instructions or altering meaning. Polish pass only, not content edit. Skip any sections marked as newly added (`ADD` items) to avoid immediately re-wording content that was just deliberately worded.

3. **Change reviewer** (engineer, opus): Spawn last. Provide the original file, the approved diff, and the final file. Confirm: (a) every approved edit was applied, (b) no unapproved changes were made, (c) `RESTRUCTURE` source removals and destination additions are both present, (d) the prompt-engineer pass didn't introduce new instructions or alter intent.

Report the full outcome to the user.

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
  ]
}
```

`kept_items` accumulates across runs. On subsequent invocations, Step 1 loads this list and the Analyst skips classifying those items (they stay as implicit `KEEP`). This prevents re-raising items the user has already decided to keep.
