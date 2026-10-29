---
name: design-doc
description: >-
  Writes, revises, tightens, and reviews engineering docs: design docs, RFCs,
  tech specs, architecture proposals, one-pagers, migration designs,
  discovery pages, rollout plans, and runbooks. Write mode drafts from notes
  and marks gaps as open questions. Tighten mode trims a doc to its
  one-sentence aim, moves exact values to an appendix, and keeps every
  rationale. Review mode gives a readiness verdict for a named next step, a
  language assessment, and evidence-backed findings, and never edits the
  source. TRIGGER when asked to draft, revise, shorten, tighten, trim, cut,
  restructure, review, assess, or audit any of these docs, or prep one for
  review. Also TRIGGER on phrasing like "is this doc still tight", "shorten but keep the
  why", "review this design for readiness", "is this design ready to
  implement", "is this runbook ready to execute", "assess this rollout plan",
  "draft a migration design from these notes", "write a discovery page".
  SKIP for code, implementation plans, security reviews, and general prose or
  marketing copy with no design content.
model: opus
effort: high
---

# Design docs

Aim: help the reader of an engineering doc take the next decision or action without a guess.

1. Pick the mode from the request: write or revise, tighten, or review. The modes are in `references/guidance.md`.
2. Read all of `references/guidance.md` before you draft, edit, or review.
3. Do the task in that mode, within the scope the user asked for.

Rules for every mode:

- A review returns findings and never edits the source.
- Keep your notes about edits, revisions, or the review process outside the doc.
- Write a local draft only. Do not publish to a wiki or another shared place unless the user asks for that destination.
