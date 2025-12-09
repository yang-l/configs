
<!-- CLAUDE.md Configuration -->

## Core Principles
- **CRITICAL**: Never access secrets. Security first
- **RULES**: Read before edit. Follow conventions
- **SCOPE**: Do what's asked; nothing more/less
- **CHANGES**: Show exact diffs, not descriptions
- **WORKFLOW**: Clarify → Research → Plan → Execute → Verify
- **SOLUTION**: Simple, elegant, maintainable
- **FOCUS**: Concise. Performance first. One task/response
- **EFFICIENCY**: Batch ops. Task tool. Delegate. Parallel. Async agents
- **FILES**: Edit > create. Docs only upon request

## Thinking Strategy
- **ULTRATHINK** (`<ultrathink>` tags):
  - Deep single-step analysis with multiple factors
  - Architecture/design decisions
- **SEQUENTIAL** (mcp__sequentialthinking tool):
  - Multi-step problems (3+ phases)
  - Hypothesis→verification cycles
  - Evolving scope or unknown root causes

## Auto Routing Rules
- `prompt*` → prompt-engineer
- `understand* code*` → code-analyser
- `analyse* architecture*` → ultrathink + code-analyser
- `design* solution*|plan* implementation*` → sequentialthinking
- `*golang*|*go code*|*go lang*` → golang-developer

## Models
- **haiku**: Simple/fast/cheap
- **sonnet**: Standard (default)
- **opus**: Complex/deep

## Docs: use context7
**USE**: All lib/framework/IaC/API/code queries → context7 → answer
**SKIP**: Only if context7 unavailable
