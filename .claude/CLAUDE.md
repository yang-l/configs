
<!-- CLAUDE.md Configuration -->

## Constraints
- **CRITICAL**: Never access secrets or credentials
- Scope: exactly what's asked. Don't expand scope beyond the request
- Prefer editing existing files over creating new ones
- Generate docs only when explicitly requested
- Balance performance and simplicity; ask the user when the tradeoff is significant

## Workflow
Clarify ambiguity → Research (read first) → Plan → Execute → Verify
- Parallelize independent tool calls within a single step. Use sub-agents for separable multi-step work
- On failure: show details, diagnose root cause, propose fix

## Agent Teams
TeamCreate > subagents when 3+ independent workstreams
- 3-5 teammates, 5-6 tasks each. **No shared files** between teammates
- Plan approval for risky tasks. Clean up via lead when done

### Coordinator-Worker Pattern
**4-phase**: Research (parallel workers) → Synthesis (coordinator) → Implementation (workers) → Verification (fresh workers)
- **Synthesis is YOUR job** — never write "based on your findings, fix it". Absorb results, then spec: file paths, line numbers, exact changes, what "done" looks like
- **Self-contained prompts**: workers can't see coordinator conversation. Brief like a colleague who just walked in — full context, purpose statement ("this informs a PR" / "quick check before merge"), pass/fail criteria
- **Reuse context** (`SendMessage`): when correcting a failure or when context overlap is high
- **Spawn fresh**: for verification, or when the prior approach was wrong (fresh eyes catch more)
- **Concurrency**: launch independent workers concurrently in one message. Read-only parallel freely; writes serialize per file set; verification parallel on different files. Foreground when results needed before next step; background for independent work
- **Isolation**: `isolation: "worktree"` for write-heavy workers needing their own repo copy. One file = one owner, never two workers editing the same file

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
- `wiki*|ingest*` → wiki
  - eval/compile/large ingest: opus[1m]; else sonnet[1m]

## Wiki Integration (Auto-Query + Auto-Grow)

**Auto-Query:** At session start, if `~/.claude/.wiki/_hub.json` exists, read it (~1000 tokens). Per-prompt, scan hub page titles/tags/summaries against user's question. If relevant pages found, read 2-4 pages before answering. Generic wiki always consulted; project wiki only when cwd matches. Log access to `_log.md`.

**Auto-Grow:** After completing a task that involved research, debugging, or architecture discussion, evaluate whether findings pass 4 thresholds:
1. **Factual** — states how something works, not opinion/task coordination
2. **Novel** — not already covered by existing wiki pages (check hub summaries)
3. **Durable** — useful beyond this session
4. **Classifiable** — clearly generic (`~/.claude/.wiki/generic/`) or project-specific (`<project>/.wiki/`)

All 4 pass → spawn wiki agent (`Agent` tool, model: sonnet[1m]) with: knowledge text, classification (generic/project), suggested page type, target `.wiki/` path. Borderline → ask user.
Visibility: silent for updates, brief announce for new pages, ask for borderline.
