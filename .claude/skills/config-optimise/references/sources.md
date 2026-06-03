# Config-Prune Seed Sources

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

Covers all hook lifecycle events. CLAUDE.md instructions of the form "always run X after editing" or "always validate Y before committing" should be in hooks, not CLAUDE.md. Hooks execute deterministically; CLAUDE.md instructions are soft context. Flag these as `UPDATE` with a suggestion to move to hooks.

## Memory and Rules Reference

**URL:** `https://code.claude.com/docs/en/memory`

Covers auto memory (MEMORY.md), project-level CLAUDE.md, and path-scoped rules (`.claude/rules/`). Instructions in CLAUDE.md that belong in auto memory (learned facts about the project) or in path-scoped rule files (rules only relevant to specific file types) should be flagged for relocation.

## GitHub Releases

**URL:** `https://github.com/anthropics/claude-code/releases`

Timestamped release entries often contain implementation detail omitted from the docs changelog. Useful for confirming whether a behavior change is a default flip versus opt-in.
