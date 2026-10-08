# Config-Optimise Seed Sources

These are known stable entry points for Anthropic documentation. The Researcher agent uses these as a starting list — it should also WebSearch for current versions of each page since URLs and content evolve.

## Claude Code Changelog

**URL:** `https://code.claude.com/docs/en/changelog`

Per-version release notes for Claude Code. Look for: default behavior changes (a behavior becoming on-by-default means CLAUDE.md instructions to enable it are now redundant), new settings keys, new hook events, new built-in automations.

Also check the raw GitHub changelog for full history: `https://raw.githubusercontent.com/anthropics/claude-code/refs/heads/main/CHANGELOG.md`

## Models Overview

**URL:** `https://platform.claude.com/docs/en/about-claude/models/overview`

Authoritative table of all current model IDs (API, Bedrock, Vertex), deprecation status, and capabilities (extended thinking, adaptive thinking, effort levels). Use to detect stale model IDs in CLAUDE.md or agent definitions.

Note: model IDs with a date suffix (e.g. `20250514`) are pinned snapshots. Dateless IDs in the 4.6+ generation are also pinned snapshots — not evergreen pointers.

## Settings Reference

**URL:** `https://code.claude.com/docs/en/settings`

Full reference for all settings keys. When a CLAUDE.md instruction corresponds to a settings key (e.g. "always use extended thinking" → `alwaysThinkingEnabled: true`), the settings key is a stronger enforcement mechanism — the prose instruction is then redundant or weaker.

## Hooks Guide

**URL:** `https://code.claude.com/docs/en/hooks-guide`

Covers all hook lifecycle events. CLAUDE.md instructions of the form "always run X after editing" or "always validate Y before committing" should be in hooks, not CLAUDE.md. Hooks execute deterministically; CLAUDE.md instructions are soft context. Flag these as `RESTRUCTURE` with a suggestion to move to hooks.

## Memory and Rules Reference

**URL:** `https://code.claude.com/docs/en/memory`

Covers auto memory (MEMORY.md), project-level CLAUDE.md, and path-scoped rules (`.claude/rules/`). Instructions in CLAUDE.md that belong in auto memory (learned facts about the project) or in path-scoped rule files (rules only relevant to specific file types) should be flagged for relocation.

## GitHub Releases

**URL:** `https://github.com/anthropics/claude-code/releases`

Timestamped release entries often contain implementation detail omitted from the docs changelog. Useful for confirming whether a behavior change is a default flip versus opt-in.

## Prompting Best Practices

**URL:** `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices`

General prompting guidance for current Claude models. It warns that forceful prompt language can make newer models overtrigger. Use it to judge whether a strong instruction in the config needs softer wording. Record the page date, because this page has no Claude Code version.

## Model Prompting Pages

**URLs:**

- `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5`
- `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5`
- `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-haiku-5-5`

Model-specific guidance. Use them to check model or effort routing choices, and instructions written for older models. Record the page date and the model each finding applies to.

## Parallel Tool Use

**URL:** `https://platform.claude.com/docs/en/agents-and-tools/tool-use/parallel-tool-use`

Official guidance and prompt wording for batching tool calls, and the known failure modes of batching. Use it as the mechanism source for a batching cost item.

## Pricing

**URL:** `https://platform.claude.com/docs/en/about-claude/pricing`

Per-model rates for uncached input, cache writes, cache reads, and output. Use it as the mechanism source for a model-change cost item. The `agent-cost` script holds a copy of these rates in `PRICE_TABLE`. Check that the copy matches the page.
