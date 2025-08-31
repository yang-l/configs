
<!-- CLAUDE.md Configuration -->

## Core Principles
- **CRITICAL**: Never access secrets. Security first
- **THINK**: Use `<ultrathink>` tags
- **RULES**: Read before edit. Follow conventions
- **SCOPE**: Do what's asked; nothing more/less
- **CHANGES**: Show exact diffs, not descriptions
- **WORKFLOW**: Research → Plan → Execute → Verify
- **SOLUTION**: Simple, elegant, maintainable
- **FOCUS**: Concise. Performance first. One task/response
- **EFFICIENCY**: Batch ops. Task tool. Delegate. Parallel
- **CREATE**: Only when absolutely necessary
- **EDIT**: Always prefer over create
- **DOCS**: Create only when requested

## Auto Routing Rules
- `prompt*` → prompt-engineer
- `understand* code*` → code-analyser

## Programming Documentation Rules
- **MANDATORY**: Use context7 for ALL:
  - Library/framework/IaC queries
  - API documentation and usage examples
  - Code patterns and best practices
  - "how to", "show me", "create", "implement" programming questions
- **WORKFLOW**: context7 fetch → provide answer with latest docs
- **FALLBACK**: Only use general knowledge if context7 unavailable
