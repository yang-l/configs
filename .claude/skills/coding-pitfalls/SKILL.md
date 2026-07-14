---
name: coding-pitfalls
description: >
  Provides countermeasures for 9 documented LLM coding failure modes:
  silent assumptions and anchoring bias (model runs with wrong framing
  without surfacing it), overcomplexity and abstraction bloat, unscoped
  side-effect edits, self-referential test blindspots, N+1 and batching
  ignorance, security vulnerability amplification (2.7x higher density
  in AI code), debugging decay after repeated fix attempts, deprecated
  API hallucination, and multi-agent coordination failure (conflicting
  outputs, silent duplication, absent end-to-end verification). Also
  covers leverage patterns: tests-first, naive-then-optimize, declarative
  goals, plan-before-execute, and context quality over volume. Load when
  writing, reviewing, debugging, or refactoring code — especially when
  multiple fix attempts have failed, AI-generated code is being accepted,
  or agents are handing off work between themselves.
when_to_use: >
  Use when the user is writing new code, reviewing a PR or diff, debugging
  a failing test, refactoring, accepting AI-generated suggestions, working
  on multi-agent pipelines, or asking about code quality, vibe coding,
  agentic coding mistakes, or LLM coding anti-patterns. Also load when
  a fix attempt has been tried twice without success, or when reviewing
  security-sensitive AI output.
effort: high
---

# LLM Coding Pitfalls

Derived from [Karpathy's observations](https://x.com/karpathy/status/2015883857489522876)
on LLM coding failure modes, extended with community-identified anti-patterns.

## Failure Modes

### 1. Silent Assumptions (most common)

> "The most common category is that the models make wrong assumptions on your
> behalf and just run along with them without checking. They don't manage their
> confusion, they don't seek clarifications, they don't surface inconsistencies,
> they don't present tradeoffs, they don't push back when they should." — Karpathy

- Picks file format, output location, field selection without asking
- Chooses one interpretation when multiple exist
- Executes contradictory instructions without questioning
- Anchoring bias — once the model receives an initial framing or hypothesis (even an offhand one), subsequent evidence rarely dislodges it. Chain-of-Thought and "ignore previous" prompts are documented to fail here (2025 anchoring bias studies)

**Fix:** State assumptions explicitly before implementing. If multiple
interpretations exist, present them. Push back when the request is ambiguous
or contradictory.

### 2. Overcomplexity

> "They really like to overcomplicate code and APIs, they bloat abstractions,
> they don't clean up dead code." — Karpathy

> "They will implement an inefficient, bloated, brittle construction over 1000
> lines of code and it's up to you to be like 'umm couldn't you just do this
> instead?' and they will be like 'of course!' and immediately cut it down to
> 100 lines." — Karpathy

- Strategy pattern for a single calculation
- Caching, validation, notification layers nobody asked for
- Dead code left behind after refactors

**Fix:** Minimum code that solves the stated problem. Clean up dead code after
every change. If you'd need to explain why an abstraction exists, it's premature.

### 3. Side-Effect Edits

> "They still sometimes change/remove comments and code they don't like or
> don't sufficiently understand as side effects, even if it is orthogonal to
> the task at hand." — Karpathy

- Changes quote style while fixing a bug
- Adds type hints, docstrings, reformats whitespace
- "Improves" adjacent validation beyond the fix

**Fix:** Every changed line must trace to the user's request. Match existing
style, even if you'd do it differently.

### 4. Self-Referential Test Blindspot

When writing tests for its own code, the LLM tests what it _thinks_ the code
does, not what it _should_ do. Edge cases and domain constraints are
systematically under-tested.

**Fix:** Write acceptance criteria and edge-case lists from the _spec_ before
generating tests. Never rely solely on AI-generated tests for AI-generated code.

### 5. N+1 and Batching Ignorance

LLMs default to sequential I/O: fetch 50 users, then make 50 individual
profile requests. AI code has 8x more excessive I/O operations than human code.
Extends to file I/O, API calls, and database queries.

**Fix:** Review generated code for `await`/`fetch`/`query` inside loops.
Batch operations; avoid N+1 patterns in performance-sensitive contexts.

### 6. Security Vulnerability Amplification

AI-generated code has 2.7x higher vulnerability density than human code.
Improper password handling, insecure object references, injection vectors.
Vulnerability density measurably increases with each iteration of AI refinement.
AI-assisted developers generate code 3-4x faster but introduce security findings
at 10x the rate of their peers (Fortune 50 empirical study, 2025). 86% of
AI-generated samples failed XSS defenses; 88% were vulnerable to log injection
(Veracode, 2025).

**Fix:** Treat AI output as untrusted input. Run security linting on all
generated code. Re-audit after each iteration, not just the first pass.

### 7. Debugging Decay

LLM effectiveness drops 60-80% after 2-3 fix attempts on the same bug.
The model guesses rather than reasons, deletes and rewrites rather than
diagnoses, and produces worse code than the original after extended iteration.

**Fix:** If the second fix attempt fails, stop. Revert to last known good state,
re-read the error with fresh context, and reason about root cause before
changing code.

### 8. Deprecated API Hallucination

LLMs hallucinate deprecated API methods, outdated model names, and removed
parameters — drawing from stale training data. Karpathy documented Claude
generating ~1000 lines of deprecated Clerk authentication code.

**Fix:** Pin to current API docs. Verify method signatures against official
documentation before using unfamiliar APIs. Treat all API calls as suspect
until validated.

### 9. Multi-Agent Coordination Failure

In multi-agent pipelines, agents lose task context across handoffs, duplicate
work silently, and produce conflicting outputs that no single agent flags.
Analysis of 1,600+ agentic traces across 7 frameworks (MAST-Data, ICLR 2025)
identified three root causes: spec ambiguity between orchestrator and subagent,
inter-agent conflict with no arbitration, and absent end-to-end verification.

**Fix:** Define explicit input/output contracts at every agent boundary. Give
each subagent a single, stated done-condition. Have the orchestrator verify
the final output against the original spec, not just the last subagent's output.

## Leverage Patterns

> "LLMs are exceptionally good at looping until they meet specific goals and
> this is where most of the 'feel the AGI' magic is to be found." — Karpathy

Agentic engineering strategies that exploit LLM strengths:

- **Tests first:** Write tests, then make them pass — gives the agent a clear
  termination condition
- **Naive-then-optimize:** Write the obviously correct algorithm first, then
  optimize while preserving correctness
- **Declarative over imperative:** Give success criteria, not step-by-step
  instructions — agents loop longer and gain more leverage
- **Plan before execute:** Use plan mode for complex tasks to surface
  assumptions before committing to an approach
- **Exploit stamina:** LLMs never tire or get demoralized. Give them
  exploratory or repetitive work humans abandon early
- **Browser MCP:** Put the agent in the loop with a browser — enables
  self-verification against live docs, APIs, and UI
- **Context quality over volume:** Most models don't benefit from maximizing
  context — the real bottleneck is which information drives the decision.
  Curate what goes into context rather than filling it. (Datadog State of AI
  Engineering, 2026)

## Quick Reference

| Failure Mode       | Signal                                                              | Fix                                                        |
| ------------------ | ------------------------------------------------------------------- | ---------------------------------------------------------- |
| Silent assumptions | No clarifying questions on ambiguous request                        | State assumptions, present alternatives, push back         |
| Overcomplexity     | Abstract base class for one use case; dead code after refactor      | One function until proven insufficient; clean up dead code |
| Side-effect edits  | Quote style / whitespace changes in a bug fix diff                  | Only change lines that trace to the request                |
| Test blindspot     | Test asserts what code does, not what spec requires                 | Write criteria from spec, not from code                    |
| N+1 patterns       | `await`/`fetch`/`query` inside `for`/`map`                          | Batch operations, review loop bodies                       |
| Security gaps      | No input validation; hardcoded secrets; no re-audit after iteration | Treat output as untrusted; lint; re-audit each pass        |
| Debugging decay    | 3rd+ fix attempt; diff keeps growing; same error recurs             | Stop, revert, re-read error, reason before editing         |
| API hallucination  | Unfamiliar method names; API call with no doc reference             | Pin to current docs; verify signatures                     |
| Multi-agent coordination | Conflicting outputs; duplicated work across agents; no end-to-end check | Explicit input/output contracts; single done-condition per agent; orchestrator verifies against original spec |
