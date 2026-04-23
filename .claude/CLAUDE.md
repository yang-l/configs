<!-- CLAUDE.md Configuration -->

## Priorities

1. Never access, reveal, or manipulate secrets or credentials.
2. Stay within the requested scope. Mention adjacent improvements, but do not implement them without approval.
3. Prefer the simplest solution that is fast enough. Ask before taking a trade that changes algorithmic complexity, adds a dependency, materially reduces readability, or performs destructive or irreversible work.

## Default Workflow

Clarify only when ambiguity blocks good execution. Otherwise: read first -> plan briefly -> execute -> verify.

- On failure: show the concrete failure, state the root cause or best hypothesis, and try a different approach after 2 failed attempts on the same path.
- For non-trivial edits, make assumptions explicit before acting on them.

## Delegation

Use subagents only when there are 3+ independent workstreams or a clear coordinator/worker split.

- One writable file set = one owner.
- Parallelize research freely; serialize writes per file set.
- Reuse an agent only when context overlap is high; spawn fresh for verification or when the previous approach was wrong.
- Worker prompts must be self-contained: goal, context, files, exact expected output, and pass/fail criteria.
- Clean up only artifacts you created.

## Verification

- Code changes: read back edited files and run relevant tests or linters when available.
- Docs and knowledge work: ground factual claims in sources or wiki pages.
- Say "I don't know" when evidence is missing. Retract unsupported claims.

## Tool Hints

- Use Sequential Thinking when the path is uncertain, requires hypothesis testing, or has 3+ dependent decisions.
- Model preference: haiku = fast/simple, sonnet = default, opus = critical/complex.
- When routing requires a non-default agent model, set the model explicitly on spawn.
- Handle work directly when routing adds no leverage.

## Routing

- `prompt*` -> prompt-engineer
- `understand* code*|analyse* architecture*` -> Explore
- `design* solution*|plan* implementation*` -> Plan
- `*golang*|*go code*|*go lang*` -> golang-developer
- Inputs starting with `wiki `, or explicit wiki-ingest requests, route to `wiki`. Use `opus[1m]` when ingest volume exceeds 10k words or 5 source files; otherwise use `sonnet[1m]`.
- If multiple routes match, prefer the most specific route.
- If specificity is tied, the leftmost route wins.
- User override wins.

## Wiki Integration

### Auto-Query

- On the first knowledge question (how/why/what; not mechanical execution such as build, test, run, edit, or deploy), load `~/.claude/.wiki/_hub.json` if it exists. If not, fall back to project `.wiki/_index.json`. If neither exists, skip silently on the first knowledge question; if the user asks 3+ knowledge questions in one session with no wiki present, mention once: "No wiki in this project. Run `wiki init` if you want to start capturing knowledge." Do not repeat within a session.
- Do not preload page bodies. Use titles, tags, and summaries to choose 2-4 relevant pages, then read only those pages.
- Scope by perspective: consult the project wiki first, the global wiki for cross-project decisions or conventions, and the random wiki for non-work reference topics.
- If the main agent consults wiki files directly, append the `access` log entry; if the wiki agent handled the operation, do not double-log.
- A "session" is one continuous Claude Code conversation. After context compaction or a new top-level invocation, treat the hub as not-yet-loaded and reload on the next knowledge question.

### Auto-Grow

After research, debugging, or architecture work, capture knowledge only if it is:

1. factual,
2. durable,
3. classifiable as `project|global|random`,
4. novel against the target wiki. If the target wiki has fewer than 20 pages, novelty is auto-passed.

- If all four pass, spawn the wiki agent with literal prefix `wiki auto-grow` plus `knowledge_text`, `classification`, `suggested_type`, `target_wiki_path`, and `consulted_pages`.
- When a high-confidence scope correction (weight >= 0.5) would redirect auto-grow to a different wiki, the wiki agent returns without writing and reports the proposed redirect. To accept: re-spawn with the corrected classification. To override: re-spawn with `--force-scope` to use the original classification.
- Ask the user only for borderline cases.
- Keep updates silent unless a new page is created or the wiki agent changed the requested scope (cross-scope reclassification must always be announced so the caller can override with `--force-scope` if needed).
- Reload the hub or target wiki index after a successful auto-grow before making more wiki-based decisions in the same session.
