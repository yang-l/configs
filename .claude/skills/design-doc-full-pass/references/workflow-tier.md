# Workflow-tier full-pass skeleton

Use **only** when the user has opted into multi-agent orchestration (explicit
"use a workflow", `ultracode`, or a named/saved workflow) **and** the doc is
large enough to justify it (many sections, or persistent cross-verification).
A task merely benefiting from orchestration does not authorize this path.

Per CLAUDE.md, workflow tier is runbook-mandatory: spawn a `Plan (model: fable)`
runbook author before any executor runs. The pattern below is identical to the
Team-tier default — this just expresses it as a resumable Workflow script that
keeps per-section proposals out of the coordinator's context.

```js
// 1. Partition: read whole doc, split on heading boundaries into disjoint ranges.
const doc = readFile(path);
const sections = partitionOnHeadings(doc); // [{ id, range, heading }]
const depMap = buildCrossRefMap(doc); // anchors, links, table-mirrors, review anchors

// 2. Fan out: one read-only section editor per range, in parallel.
const proposals = await parallel(
  sections.map(
    (s) => () => agent(sectionEditorPrompt(s, depMap), { model: "sonnet" }),
  ),
);
// each returns [{ old_string, new_string, rationale, risk }]

// 3. Assemble + guard: coordinator owns whole-doc integrity.
const edits = [];
for (const e of proposals.flat()) {
  if (!uniqueInWholeDoc(doc, e.old_string))
    e.old_string = qualifyWithContext(e); // section-blind -> whole-doc match
  if (breaksCrossRef(e, depMap)) {
    defer(e);
    continue;
  } // link target / mirrored / review-anchored -> never auto-apply
  if (e.risk === "rationale") {
    discard(e);
    continue;
  }
  if (e.risk === "framing") {
    flagForAuthor(e);
    continue;
  }
  edits.push(e); // clean redundancy only
}
const updated = applyExact(doc, edits); // exact string replacement, not freehand

// 4. Verify (synthesis-reviewer gate): fresh opus/fable agent, not one that produced cuts.
await agent(verifyPrompt(doc, updated, edits, depMap), { model: "fable" });
// confirms: structure byte-identical except intended cuts; all cross-refs resolve
// whole-doc; every intended cut landed; meaning + rationale preserved.
```
