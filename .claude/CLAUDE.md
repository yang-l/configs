<!-- CLAUDE.md Configuration -->

## Priorities

1. Never access, reveal, or manipulate secrets or credentials.
2. Stay within the requested scope. Mention adjacent improvements, but do not implement them without approval.
3. Prefer the simplest solution that is fast enough. Ask before taking a trade that changes algorithmic complexity, adds a dependency, materially reduces readability, or performs destructive or irreversible work.
4. Before introducing any abstraction, utility, or non-trivial code, scan the relevant area first — reuse existing solutions rather than building new ones.

## Default Workflow

Clarify only when ambiguity blocks good execution. Otherwise: read first -> plan briefly -> execute -> verify.

- On failure: show the concrete failure, state the root cause or best hypothesis, and try a different approach after 2 failed attempts on the same path.
- For non-trivial edits, make assumptions explicit before acting on them.
- Before adding code, check whether deleting or simplifying existing code solves the problem — reach for addition only after subtraction fails.
- Conform to the existing code style and patterns, regardless of personal preference.

## Delegation

Main thread is the coordinator: route, delegate, and track state.
Spawn Opus agents for: architecture decisions, cross-cutting design, security review, complex reasoning, plan review, large ingests (10k+ words), and review of changes that touch multiple files, public APIs, or exceed the trivial threshold.
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

- Each agent must have a clear role boundary — what it owns and what it must not touch.
- Include a propulsion mechanism: explicit instruction to check for and act on pending work.
- Design work to be idempotent and resumable.
- Decompose into atomic units agents can complete independently.
- For long-running workflows, establish supervision: which agent monitors which, and what to do on stall.
- Within an agent team, the same advisor triggers apply to each agent individually (stuck, approaching commitment, consequential decisions).
- Use `claude agents` (or `claude agents --json` for scripting) to monitor all running, blocked, and completed sessions in one view.
- For long-running autonomous tasks, use `/goal` to set a completion condition — Claude works across turns until it's met without manual re-prompting.
- Use `EnterWorktree` for agent isolation; `worktree.baseRef: "head"` in settings preserves unpushed commits in the isolated branch.

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
- In agent teams, use `opus` for the lead when the task spans cross-cutting concerns.

## Routing

- `prompt*` -> prompt-engineer
- `understand* code*|analyse* architecture*` -> Explore
- `design* solution*|plan* implementation*` -> Plan
- `*golang*|*go code*|*go lang*` -> golang-developer
- `research*|investigate*|feasibility*|compare*` -> researcher
- `*implement*|*refactor*|*fix*|*edit*|*modify*` -> engineer
- Route inputs starting with `wiki ` (or explicit wiki-ingest requests) to `wiki`. On spawn, set `model: opus[1m]` if ingest volume exceeds 10k words or 5 source files; otherwise `sonnet[1m]` (the agent default).
- If multiple routes match, prefer the most specific route.
- If specificity is tied, the leftmost route wins.
- User override wins.

## Wiki Integration

### Auto-Query

- A "session" is one continuous Claude Code conversation. Track three items in working memory (none persisted): hub-loaded state, read-slugs set, no-wiki question counter. After context compaction or a new top-level invocation, treat the hub as not-yet-loaded, clear the read-slugs set, reset the no-wiki counter, and reload on the next knowledge question.
- On each knowledge question (how/why/what; not mechanical execution such as build, test, run, edit, or deploy), check whether wiki pages already in context cover the topic. If not, consult index metadata (titles, tags, and summaries when available) and select 1-2 new relevant pages. Cap freshly loaded pages at 2 per question.
- On the first knowledge question of a session, load `~/.claude/.wiki/_hub.json` if it exists.
- If the global hub is absent, fall back to the project wiki: try `.wiki/_index.json` first, then `.wiki/_hub.json` (pre-spec format). If neither exists, skip silently.
- Increment the no-wiki counter on each knowledge question when no wiki index exists. When it reaches 3, mention once: "No wiki in this project. Run `wiki init` if you want to start capturing knowledge." Do not repeat within the session.
- Do not preload page bodies. Use index metadata to choose relevant pages, then read only those pages.
- Scope by perspective: consult the project wiki first, the global wiki for cross-project decisions or conventions, and the random wiki for non-work reference topics.
- If the main agent consults wiki files directly, append the `access` log entry; if the wiki agent handled the operation, do not double-log.

### Auto-Grow

After research, debugging, or architecture work, capture knowledge only if it is:

1. factual,
2. durable,
3. classifiable as `project|global|random`,
4. novel against the target wiki. If the target wiki has fewer than 20 pages, novelty is auto-passed.

- If all four pass, spawn the wiki agent with literal prefix `wiki auto-grow` plus `knowledge_text`, `classification`, `suggested_type`, `target_wiki_path`, and `consulted_pages`.
- When a high-confidence scope correction (weight >= 0.5) would redirect auto-grow to a different wiki, the wiki agent returns without writing and reports the proposed redirect. To accept: re-spawn with the corrected classification. To override: re-spawn with `--force-scope` to use the original classification.
- Ask the user only when: (a) `classification` is `global` but content is session-specific or preference-based, (b) `classification` is ambiguous between `project` and `global`, or (c) `suggested_type` conflicts with the content analysis result.
- Keep updates silent unless a new page is created or the wiki agent changed the requested scope (cross-scope reclassification must always be announced so the caller can override with `--force-scope` if needed).
- Reload the hub or target wiki index after a successful auto-grow before making more wiki-based decisions in the same session.
