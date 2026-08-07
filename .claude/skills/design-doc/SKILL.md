---
name: design-doc
description: >-
  Tightens design docs, RFCs, tech specs, and architecture proposals: trims
  each doc to its one-sentence aim, pushes exact values/configs/tables into
  an appendix or linked runbook, and protects every distinct rationale while
  cutting restatement and meta-fluff. TRIGGER whenever asked to shorten,
  tighten, trim, cut, restructure, or prep a design doc / RFC / tech spec /
  architecture doc / one-pager / design proposal for review; when checking a
  doc for scope creep, bloat, or redundant sections; when editing a doc that
  already has review comments, intra-doc links, or anchors that must survive
  the edit; or on phrasing like "is this doc still tight", "cut this
  section", "shorten but keep the why", "prep this doc for review". Trigger
  on: design doc, design document, RFC, tech spec, technical spec,
  architecture doc, proposal doc, one-pager, doc bloat, scope creep,
  redundant section, review-comment anchors, verbatim edit, doc trim. SKIP
  for runbooks and how-to/step-by-step guides (procedure, not design
  rationale) and for general prose or marketing copy with no design content.
model: opus[1m]
effort: high
---

# Design Doc Editing

Aim: tighten a design doc, RFC, tech spec, or architecture proposal to exactly what it needs to say, without losing any reasoning behind it. Not for runbooks (rule 9), code, or general prose.

## Anchor principles

1. **Shorten; keep detail in the appendix.** Prose carries the what and why at a readable level. Exact values — policies, configs, encodings, tables — belong in a code block, appendix, or linked runbook ("details in the template"), not in the paragraph. Prefer deleting or merging over rewriting.
2. **Only what the doc is aimed for.** State the doc's aim in one sentence; every remaining section must serve it. Adjacent or nice-to-know material gets a pointer, or gets cut. Document _this_ design, not domain theory the reader already knows.

## Supporting rules

1. **Rationale is protected.** Never cut a "why" to save space — that's the costliest mistake. Cut restatement and meta-commentary; keep every distinct fact, control, caveat, and justification.
2. **Redundancy vs. intentional duplication.** A decision table a later section restates, a threat-model matrix, or a jump-target section with its own caveat — these repeats are the doc's pattern, not fat. Only cut a repeat once one copy is canonical and the rest can become pointers.
3. **Pointer + detail.** State each fact once, in its owning section. Elsewhere, link ("see X") instead of re-deriving it. Keeps copies from drifting apart.
4. **Inferable is not the same as safe to cut.** Keep a load-bearing claim even if a careful reader could infer it — especially in a security or controls doc.
5. **Kill meta and boilerplate.** "This document describes…", "captured here so it isn't lost", hedging, and worked examples that just restate a rule already shown — all cuttable. An example that concretizes a real failure stays.
6. **Write for the implementing engineer.** Zero shared context, no chance to ask a question. Plain words; expand only what this team needs.
7. **Preserve structure on published or reviewed docs.** Never break review-comment anchors, intra-doc links, code blocks, tables, headings, or inline styles. Keep the anchor set stable so reviewer comments don't detach.
8. **Be honest about the ceiling.** If the doc is already tight, say so and stop. Don't invent churn to look productive.
9. **Runbooks carry the how; the design doc carries the what/why.** Link out to the runbook instead of inlining steps.

## Process

1. Read the whole doc fresh, then edit section by section.
2. On published/reviewed docs, make exact verbatim old→new edits with mechanical guards — unique-match find/replace plus an invariant/structure check — instead of freehand rewriting. This is what protects rule 7.
3. Tier every candidate cut by risk before applying it:

   | Tier              | What it looks like                        | Action                     |
   | ----------------- | ----------------------------------------- | -------------------------- |
   | Clean redundancy  | Says nothing new anywhere else in the doc | Apply automatically        |
   | Framing-only      | Wording/style change, no content change   | Flag for the author's call |
   | Touches rationale | Any "why", caveat, or justification       | Discard — do not apply     |

4. After editing, verify: structure is unchanged, the intended cuts landed, and meaning is preserved.
