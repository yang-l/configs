
<!-- CLAUDE.md Configuration -->

## Constraints
- **CRITICAL**: Never access secrets or credentials
- Scope: exactly what's asked. One task per response
- Prefer editing existing files over creating new ones
- Generate docs only when explicitly requested
- Balance performance and simplicity; ask when tradeoff is significant

## Workflow
Clarify ambiguity → Research (read first) → Plan → Execute → Verify
- Parallelize independent tool calls. Use sub-agents for separable work
- On failure: show details, diagnose root cause, propose fix

## Agent Teams
TeamCreate > subagents when 3+ independent workstreams
- 3-5 teammates, 5-6 tasks each. **No shared files** between teammates
- Plan approval for risky tasks. Clean up via lead when done

### Coordinator-Worker Pattern
**4-phase**: Research (parallel workers) → Synthesis (coordinator) → Implementation (workers) → Verification (fresh workers)
- **Synthesis is YOUR job** — never write "based on your findings, fix it". Absorb results, then spec: file paths, line numbers, exact changes, what "done" looks like
- **Self-contained prompts**: workers can't see coordinator conversation. Brief like a colleague who just walked in — full context, purpose statement ("this informs a PR" / "quick check before merge"), pass/fail criteria
- **Continue vs. spawn fresh**: high context overlap or correcting failure → `SendMessage` to reuse context; low overlap, wrong approach, or verification → spawn fresh (fresh eyes catch more)
- **Concurrency**: launch independent workers concurrently in one message. Read-only parallel freely; writes serialize per file set; verification parallel on different files. Foreground when results needed before next step; background for independent work
- **Isolation**: `isolation: "worktree"` for write-heavy workers needing their own repo copy. One file = one owner, never two workers editing the same file

## Verification
- Large docs: cite sources per claim; use direct quotes for grounding
- Say "I don't know" when uncertain. Retract unsupported claims

## Tool Routing
**Sequential thinking MCP**: use for 3+ phase problems, hypothesis testing, unknown scope
**Sub-agent models**: haiku=fast/simple, sonnet=default, opus=complex/critical

## Auto Routing
- `prompt*` → prompt-engineer
- `understand* code*|analyse* architecture*` → Explore
- `design* solution*|plan* implementation*` → Plan
- `*golang*|*go code*|*go lang*` → golang-developer
