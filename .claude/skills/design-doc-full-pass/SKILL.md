---
name: design-doc-full-pass
description: |
  Full section-by-section editorial pass over a large or published / heavily-reviewed design doc, RFC, spec, or architecture doc: fans out one read-only agent per section, collects verbatim old_string→new_string cuts with a rationale and risk tier each, then applies them under a mechanical whole-doc structure-and-anchor guard. The heavier multi-agent sibling of the `design-doc` skill, which owns the underlying editorial rules this one orchestrates.
  TRIGGER whenever a doc is big or important enough that editing it single-threaded would be slow or risk breaking structure/anchors, and the user wants the whole thing gone over — e.g. "do a full pass over this RFC before it ships", "review this whole design doc section by section and tighten it", "audit this published spec end to end", "go through every section of the architecture doc and cut the fat", or hands over a long multi-section doc for comprehensive tightening.
  SKIP and defer to the plain `design-doc` skill for small or routine edits — a single section, one paragraph, a quick tighten, "does this read OK" — or any doc short enough to edit in one pass. Use this skill only when the doc is large enough that parallel section agents earn their coordination cost.
effort: high
---

## When to use this

Reach for this skill when a design doc, RFC, or spec is **large or already published / heavily reviewed** and the user wants the _whole thing_ gone over, not a quick touch-up. For a single section, one paragraph, or a routine tighten, **defer to the `design-doc` skill** — spinning up section agents isn't worth the coordination cost on a small edit.

This skill owns the **orchestration**. The per-section editorial judgment — what's safe to cut, what's protected — lives in `design-doc`; every section agent applies those rules, and this skill points there rather than restating them.

---

## The pattern

Partition → fan out → assemble → guard/verify.

Sections are disjoint in the text each agent **edits**, so agents never collide on the same string. They are _not_ disjoint in what an edit can **break**: a heading one agent rewords may be a link target elsewhere; a detail one agent cuts may be mirrored in a summary or threat table in another section; a sentence one agent trims may carry a prose cross-ref ("as in §4") or a pinned review comment. A section-blind agent sees none of that. **The coordinator is the only party with the whole-doc view, so the coordinator owns cross-reference integrity** — not the section agents.

---

## Roles

Main thread coordinates: partition, dispatch, assemble, guard. Section agents are read-only and never edit the file.

| Role                    | Agent                       | Model      | Owns                                                                                                                                                                                                                                                                                         |
| ----------------------- | --------------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Coordinator**         | main thread (or lead agent) | opus/fable | Reads the whole doc; splits it into disjoint ranges on heading boundaries; builds a cross-ref/dependency map (headings, anchors, intra-doc links, table mirrors, review-comment anchors); assigns one range per agent; applies edits as exact string replacements; owns whole-doc integrity. |
| **Section editor** (×N) | `Agent`, read-only          | sonnet     | Applies `design-doc`'s rules to **one range only**; returns verbatim `old_string`→`new_string` pairs, a one-line rationale each, and a risk tier per edit. Never writes.                                                                                                                     |
| **Verifier**            | fresh `Agent`               | opus/fable | The synthesis-reviewer gate. Resolves every anchor/link/table-mirror/comment-anchor across the whole doc, confirms every intended cut landed, and that meaning + rationale survived. Must be an agent that did **not** produce cuts.                                                         |

Hand each section editor the read-only dependency map for its range ("your heading is linked from §2; this figure is mirrored in the table in §7") so it wastes fewer proposals — agents stay disjoint on writes, they just aren't blind on cross-refs.

---

## Tier: Team vs Workflow

Default to **Team tier**: parallel `Agent` calls in one message, main-thread synthesis between phases. No opt-in required — this covers a handful of sections on one file.

Reach for the **`Workflow` tool only if both hold**: the user has explicitly opted into multi-agent orchestration (says "use a workflow", uses `ultracode`, or names a saved workflow) **and** the doc is large enough to justify it (many sections, or persistent cross-verification). A doc merely benefiting from orchestration does **not** authorize a Workflow call — never trigger one unprompted. Workflow tier is runbook-mandatory: spawn the `Plan (model: fable)` runbook author first. See `references/workflow-tier.md` for the script skeleton.

---

## What each section agent returns

One proposal per edit, in this exact shape:

```
- old_string: |
    <exact bytes to replace — must match the source verbatim>
  new_string: |
    <replacement>
  rationale: one line — why this cut/change serves the doc's aim
  risk: redundancy | framing | rationale
```

The editorial judgment behind each proposal — the two anchor principles and the nine rules (rationale is never cut for space; intentional duplication isn't redundancy; "inferable" ≠ "safe to cut"; etc.) — is owned by `design-doc`. Load that skill's rules into each section agent; do not re-derive them here.

---

## Assemble + mechanical guard

Apply every proposal as an **exact string replacement, never a freehand rewrite** — that is what makes each edit mechanically checkable.

- **Unique match is whole-doc, not per-section.** Section agents are blind to the rest of the doc, so an `old_string` that's unique inside a section may recur elsewhere. The coordinator verifies each `old_string` against the **whole file**; if it isn't unique, qualify it with surrounding context or scope the replacement to the section's byte range before applying.
- **Structural invariants stay byte-identical** except for the intended change: headings, code blocks, tables, intra-doc links/anchors, and review-comment anchors. If applying an edit would alter any of these, it isn't the edit that was proposed — reject it.
- **Review anchors often live outside the file.** On a doc under external review (GitHub PR, Confluence, Google Docs), reviewer comments are pinned in the platform, not in the file text — you can't diff them from the file. Pull the review threads if the platform is reachable (Confluence/Jira, GitHub) to map which passages are pinned; otherwise conservatively **flag, never auto-cut**, any passage a reviewer may have anchored to.

---

## Risk-tiered cut policy

`risk` is the section agent's **proposal**; whether a cut auto-applies is the **coordinator's** whole-doc call. The coordinator downgrades any `redundancy` cut its dependency map shows to be a link target, a table mirror, or review-anchored — the blind agent couldn't have known it wasn't safe.

| Tier              | Action                                                                                                                                                                                                                     |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Clean redundancy  | Auto-apply — only after the coordinator confirms the text is not a link target, not mirrored in a table elsewhere, and carries no review-comment anchor. Those are intentional duplication (`design-doc`), not redundancy. |
| Framing-only      | Flag for the author's call; don't apply silently.                                                                                                                                                                          |
| Touches rationale | Discard. Rationale is the most protected content; when in doubt, keep it and drop the edit.                                                                                                                                |

---

## Verify

Final pass, run by a **fresh opus/fable agent** (the synthesis-reviewer gate):

1. **Structure** — headings, anchors, tables, code blocks intact; every intra-doc link still resolves across the whole doc, and every mapped review-comment anchor still points at live text (for external anchors, confirm the pinned passage still exists).
2. **Completeness** — every intended cut actually landed.
3. **Meaning** — nothing load-bearing silently dropped; each edit's rationale still holds.

---

## Stop if it's already tight

If the doc is already lean, say so and stop. A full pass that changes nothing is a valid outcome; manufacturing cuts to look busy violates `design-doc`'s honesty rule.
