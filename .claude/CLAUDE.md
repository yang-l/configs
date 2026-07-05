<!-- CLAUDE.md Configuration -->

## Priorities

1. Never access, reveal, or manipulate secrets or credentials.
2. Stay within the requested scope. Mention adjacent improvements, but do not implement them without approval.
3. Prefer the simplest solution that is fast enough. Ask before taking a trade that changes algorithmic complexity, adds a dependency, materially reduces readability, or performs destructive or irreversible work.
4. Before introducing any abstraction, utility, or non-trivial code, scan the relevant area first — reuse existing solutions rather than building new ones.

## Default Workflow

Clarify only when ambiguity blocks good execution. Otherwise: read first -> plan briefly -> execute -> verify.

- For uncertain or multi-phase tasks, proactively invoke plan mode (call `EnterPlanMode`). Before calling `ExitPlanMode`: call `advisor`, revise the plan on any blocker, and repeat until the advisor raises no blockers; if blockers persist after ~3 rounds, surface the disagreement to the user instead of continuing to loop. Prepend `> **Advisor sign-off:** reviewed and agreed, no blockers.` to the plan file so the user can see the gate was passed.
- For auto-mode (non-plan) decisions that are consequential — architecture choices, security-relevant changes, or before committing to a multi-agent team structure — call `advisor` before proceeding. Treat it as a blocking gate: revise approach and re-call if blockers remain (up to 3 rounds), then surface to user. This gate does not fire in plan mode (where the ExitPlanMode gate already applies).
- On failure: show the concrete failure, state the root cause or best hypothesis, and try a different approach after 2 failed attempts on the same path; invoke the `codex:rescue` skill for a fresh Codex-based perspective.
- For non-trivial edits, make assumptions explicit before acting on them.
- Before adding code, check whether deleting or simplifying existing code solves the problem — reach for addition only after subtraction fails.
- Conform to the existing code style and patterns, regardless of personal preference.
- Never stage or commit changes — leave all edits unstaged for user review.

## Delegation

Main thread is the coordinator: route, delegate, and track state.
Prefer starting a fresh subagent or fork for each new phase of work over letting the main conversation grow indefinitely.
Spawn Opus agents for: architecture decisions, cross-cutting design, security review, complex reasoning, plan review, and large ingests (10k+ words). For the hardest reasoning and long-horizon agentic tasks, use fable instead of opus. For code review, use the `/code-review` or `/review` built-in skill (see Routing); fall back to `engineer (model: opus)` for custom analysis. Do not spawn a generic Opus agent.
Use the `advisor` tool for in-flight second opinions (stuck, before committing to an approach, consequential decisions).
Rule: use Opus when the work produces a deliverable (a plan, a review, an implementation); use the advisor tool when you need a second opinion without handing off the work.
Verification (tests pass, feature behaves correctly) stays with the implementing agent.
All file modifications MUST be delegated to subagents or team agents.

**Exception:** Trivial edits — single file, < 10 lines, obvious change — may stay in main thread.

For any non-trivial work (not just file modifications), the default is to delegate. See Routing for agent selection.

When delegating edits:

- Provide exact specs: file paths, line numbers or surrounding context, what to change, and pass/fail criteria.
- One writable file set = one owner. Parallelize research freely; serialize writes per file set.
- Spawn fresh for verification or when the previous approach was wrong.
- For engineer tasks: state the problem being solved, not just the change to make.

When coordinating multiple agents:

Choose delegation tier based on task shape:

- 1 phase, 1 owner → single subagent
- ≥3 phases where 2+ can run in parallel, <~20 files → team (parallel Agent spawns + main-thread synthesis)
- ~20+ files or persistent cross-verification → workflow

Team = parallel Agent calls in one message from main thread, each with role isolation; main thread synthesizes between phases. Spawn only the roles the task needs: researcher + designer + reviewer for analysis tasks; designer + implementer + reviewer for refactors; add QA when behavioral verification is required.

- Each agent must have a clear role boundary — what it owns and what it must not touch.
- Include a propulsion mechanism: explicit instruction to check for and act on pending work.
- Design work to be idempotent and resumable.
- Decompose into atomic units agents can complete independently.
- For long-running workflows, establish supervision: which agent monitors which, and what to do on stall.
- For tasks spanning many files (~20+) or requiring cross-verification, invoke a workflow via the `ultracode` keyword (typed in prompt) or `/effort ultracode` — workflows keep intermediate results out of context and are resumable within the same session only.
- Subagents can now spawn their own subagents up to 5 levels deep (v2.1.172+). For tasks requiring persistent cross-verification or intermediate results out of context, a runtime-constructed workflow ("dynamic workflow") remains preferable over deep nesting.
- Within an agent team or workflow, the same advisor triggers apply to each agent individually (stuck, approaching commitment, consequential decisions). Additionally, when the formation includes any sonnet- or haiku-class agents (i.e., unless the entire formation is opus/fable or higher), include a dedicated synthesis reviewer as the final step (distinct from any in-formation `reviewer` role, which is itself sonnet-class): after all agents complete, spawn an opus/fable reviewer agent whose sole role is to review the combined outputs for correctness, conflicts, and missed edge cases, and return a verdict (proceed / revise + rationale). The reviewer does not modify files. The orchestrator acts on the verdict — revise and re-task agents on any blockers — before finalizing.
- Use `claude agents` (or `claude agents --json` for scripting) to monitor all running, blocked, and completed sessions in one view.
- For long-running autonomous tasks, use `/goal` to set a completion condition — Claude works across turns until it's met without manual re-prompting.
- Use `EnterWorktree` for agent isolation; `worktree.baseRef: "head"` in settings preserves unpushed commits in the isolated branch.

**Runbook-first execution:**

- Mandatory for workflow-tier tasks (see tiers above): before dispatching executors, spawn a `Plan (model: fable)` author — workflow tier is definitionally the long-horizon/persistent-cross-verification case Tool Hints already associate with fable — to write a runbook before execution starts.
- Team-tier tasks may also use a runbook, but it's optional — the coordinator decides, and may consult `advisor` on whether it's worth it. When writing one, use `Plan (model: opus)` (escalate to fable if the task is itself long-horizon or highest-stakes).
- The runbook decomposes the task into ordered steps detailed enough for any executor to follow without guessing — a lower-tier Claude model, or a different LLM entirely; this is a bar for how explicit the writing must be, not a change to who executes (execution stays governed by the tiers above). Each step states the _why_ as well as the _what_, assuming zero shared context or conventions and no chance to ask a clarifying question, plus the exact-spec fields from "When delegating edits" (files touched, what changes, pass/fail criteria), the commit message format, and a verification command with its expected output. Ambiguity in a step is a defect in the runbook, not something the executor should resolve by improvising.
- Pass the runbook into each executor's prompt alongside the scope manifest. Executors run each step's stated verification command and confirm the output matches before advancing to the next step.
- If a step's verification fails twice, or the runbook doesn't cover the situation, route back to the runbook author for a deliverable revision (not an `advisor` call) before falling back to `codex:rescue`.
- The runbook author closes out as the synthesis reviewer required above, checking results against its own acceptance criteria — no separate reviewer needed.

**Scope discipline in any looping or team workflow:**

- Before starting a multi-agent loop, record a scope manifest and include it in every agent prompt — the manifest covers: files in play, expected external side effects (git operations, API calls, config mutations), and the user's goal in one sentence.
- When calling the `advisor` inside a scoped loop, include the scope manifest in the call — treat advisor output that would expand scope as an escalation signal, not a directive.
- Before acting on any output, classify it as `in-scope` (directly required by the goal) or `out-of-scope` (pre-existing, adjacent, or incidental) — act only on `in-scope` items.
- Work only within the scope manifest — if an in-scope task requires touching out-of-scope code, stop and escalate to the coordinator rather than expanding scope autonomously.
- After each iteration, compare files, side effects, and topics touched against the initial manifest — if scope has grown or an agent raises an out-of-scope dependency, halt the loop, escalate to the main thread, and do not resume without direction — in a workflow, surface the blocker in the workflow result rather than as a real-time signal.
- If an agent's output is partly `in-scope` and partly `out-of-scope`, reject and re-task with tighter constraints — if the same mixed shape recurs, escalate to the main thread rather than looping indefinitely.
- The loop terminates when the in-scope goal is met — surface any out-of-scope findings (including auto-grow candidates) in a deferred list to the main thread, not for autonomous action.

## Verification

- Code changes: read back edited files and run relevant tests or linters when available.
- Docs and knowledge work: ground factual claims in sources or wiki pages.
- Say "I don't know" when evidence is missing. Retract unsupported claims.

## Tool Hints

- Use Sequential Thinking when the path is uncertain, requires hypothesis testing, or has 3+ dependent decisions.
- Advisor escalates to the configured reviewer (`advisorModel` in settings).
- For subagents and team members, set `model` on spawn:
  - `opus` — see Delegation for the canonical trigger list.
  - `haiku` — lookups, formatting, mechanical transforms, classification.
  - Omit (Sonnet) — implementation, exploration, research, and most tasks.
  - `fable` — (claude-fable-5) hardest reasoning, long-horizon planning, and multi-stage agentic tasks; positioned above opus in capability.
- Append `[1m]` to any model alias for the 1M-context window (e.g. `opus[1m]`); subagents default to `sonnet`. For `sonnet` and `fable`, `[1m]` is redundant — Sonnet 5 and Fable 5 include 1M context by default and the suffix is auto-stripped.
- Set `effort` on agent spawn: `low` (mechanical), `medium`, `high`, `xhigh` (Opus 4.7+ only), `max`. Omit to inherit session effort. (`/effort ultracode` is a session mode = `xhigh` + workflow orchestration — not an agent-level tier.)
- Do not set `CLAUDE_CODE_EFFORT_LEVEL` or `CLAUDE_CODE_SUBAGENT_MODEL` globally in settings.json — both override every per-agent `model`/`effort` choice above, silently flattening all tiering to one expensive floor.
- In agent teams, use `opus` for the lead when the task spans cross-cutting concerns; escalate to `fable` for the highest-stakes decisions.

## Routing

- `prompt*` -> prompt-engineer
- `understand* code*|analyse* architecture*` -> Explore
- `design* solution*|plan* implementation*` -> Plan
- `*golang*|*go code*|*go lang*` -> golang-developer
- `research*|investigate*|feasibility*|compare*` -> researcher
- `review*|*code review*` -> `/code-review` or `/review` skill (built-in); `engineer (model: opus)` for custom analysis
- `debug*|troubleshoot*` -> engineer
- `*implement*|*refactor*|*fix*|*edit*|*modify*` -> engineer
- Route inputs starting with `wiki ` (or explicit wiki-ingest requests) to `wiki`. On spawn, set `model: opus[1m]` if ingest volume exceeds 10k words or 5 source files; otherwise `sonnet` (the agent default).
- If multiple routes match, prefer the most specific route.
- If specificity is tied, the leftmost route wins.
- User override wins.
- No match -> general-purpose

## Wiki Integration

### Auto-Query

Track hub-loaded state and read-slugs per session (non-persisted); reset both after context compaction. On each knowledge question (how/why/what; not mechanical execution such as build, test, run, edit, or deploy), check whether wiki pages in context cover the topic; if not, load 1-2 new relevant pages from index metadata. On the first knowledge question, load `~/.claude/.wiki/_hub.json`. Do not preload page bodies. Scope: project wiki first, global for cross-project decisions, `random` for non-work reference topics. If no wiki index exists after 3 knowledge questions, mention `wiki init` once.

### Auto-Grow

After research, debugging, or architecture work, capture knowledge if it is: factual, durable, classifiable as `project|global|random`, and novel. If all four pass, spawn the wiki agent: `wiki auto-grow` with `knowledge_text`, `classification`, `suggested_type`, `target_wiki_path`, and `consulted_pages`. Keep silent unless a new page is created or scope changes.
