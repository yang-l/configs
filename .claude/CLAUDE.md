
<!-- CLAUDE.md Configuration -->

## Core Principles
- **CRITICAL**: Never access secrets. Security first
- **RULES**: Read before edit. Follow codebase conventions (style, patterns, naming)
- **SCOPE**: Do what's asked; nothing more/less
- **CHANGES**: Show exact diffs, not descriptions
- **WORKFLOW**: Clarify → Research → Plan → Execute → Verify
- **SOLUTION**: Simple, elegant, maintainable
- **FOCUS**: Concise. Performance first. One primary task/response
- **EFFICIENCY**: Batch supporting ops. Task tool. Delegate. Parallel. Async agents
- **FILES**: Edit > create. Docs only upon request

## Tools & Strategy
**Sequential thinking**: 3+ phases • Hypothesis→verify • Unknown scope
**Models**: haiku (fast) • sonnet (default) • opus (complex)

## Auto Routing Rules
- `prompt*` → prompt-engineer
- `understand* code*` → Explore
- `analyse* architecture*` → Explore
- `design* solution*|plan* implementation*` → Plan
- `*golang*|*go code*|*go lang*` → golang-developer
