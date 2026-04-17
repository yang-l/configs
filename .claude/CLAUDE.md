
<!-- CLAUDE.md Configuration -->

## Constraints
- **CRITICAL**: Never access secrets or credentials
- Scope: exactly what's asked. If a fix naturally suggests a related improvement, mention it but don't implement without approval
- Balance performance and simplicity; ask the user when the tradeoff is significant — changes algorithm complexity class, adds a dependency, or trades readability for speed

## Workflow
Clarify ambiguity → Research (read first) → Plan → Execute → Verify
- On failure: show details, diagnose root cause, propose fix. After 2 failed attempts at the same approach, step back and reconsider strategy

## Agent Teams
TeamCreate > subagents when 3+ independent workstreams
- 3-5 teammates, 5-6 tasks each
- **No shared files** between teammates — concurrent writes cause conflicts
- Plan approval for risky tasks: destructive ops, shared-state changes, or irreversible actions
- Clean up via lead when done: stale branches, temp files, orphaned worktrees

### Coordinator-Worker Pattern
**4-phase**: Research (parallel workers) → Synthesis (coordinator) → Implementation (workers) → Verification (fresh workers)
- **Synthesis is YOUR job** — absorb worker results, then spec: file paths, line numbers, exact changes, done criteria
- **Self-contained prompts**: workers can't see coordinator context. Full context, purpose, pass/fail criteria
- **Reuse context** (`SendMessage`) when correcting a failure or context overlap is high
- **Spawn fresh** for verification or when the prior approach was wrong
- **Concurrency**: read-only parallel freely; writes serialize per file set; verification parallel on different files. Foreground when results needed before next step; background for independent work
- **Isolation**: `isolation: "worktree"` for write-heavy workers. One file = one owner

## Verification
- Code changes: read back edited files; run tests or linters when available
- Large docs: cite sources per claim; use direct quotes for grounding
- Say "I don't know" when uncertain. Retract unsupported claims

## Tool Routing
**Sequential thinking MCP**: use when reasoning path is uncertain, requires hypothesis testing, or involves 3+ interdependent decision points
**Sub-agent models**: haiku=fast/simple, sonnet=default, opus=complex/critical

## Auto Routing
- `prompt*` → prompt-engineer
- `understand* code*|analyse* architecture*` → Explore
- `design* solution*|plan* implementation*` → Plan
- `*golang*|*go code*|*go lang*` → golang-developer
- `wiki*|ingest*` → wiki (eval/compile/large ingest: opus[1m]; else sonnet[1m])
- No match → handle directly without routing
- Multiple matches → prefer the more specific agent
- User can explicitly redirect regardless of pattern match

## Wiki Integration (Auto-Query + Auto-Grow)

**Auto-Query (lazy load):**
- On first knowledge question (how/why/what — not mechanical tasks), read `~/.claude/.wiki/_hub.json` if it exists. Fallback: project-local `.wiki/_index.json`. Neither exists → skip silently
- Keep hub/index in context for the session. Per-prompt, scan titles/tags against question; if relevant, read 2-4 pages before answering
- Project wiki always consulted when present; global wiki for cross-project questions; random wiki for non-work topics
- Log access to consulted wiki's `_log.md`: `## [YYYY-MM-DD HH:MM] access | query: "<question>" | tier: N | read: [paths] | gap: none|miss|partial`

**Auto-Grow:** After research/debugging/architecture tasks, evaluate whether findings pass all 4 thresholds:
1. **Factual** — how something works, not opinion
2. **Novel** — not covered by existing pages (check hub/index summaries). Skip if target wiki has <20 pages
3. **Durable** — useful beyond this session
4. **Classifiable** — project-specific / global / random

All pass → spawn wiki agent (sonnet[1m]) with: literal prefix "wiki auto-grow", knowledge_text, classification, suggested_type, target_wiki_path, consulted_pages. Borderline → ask user.
Visibility: silent for updates, brief announce for new pages, ask for borderline.
