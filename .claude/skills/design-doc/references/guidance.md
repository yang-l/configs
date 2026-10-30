# Design doc guidance

This guide covers technical designs, RFCs, tech specs, architecture proposals, migration designs, discovery pages, rollout plans, and runbooks. The test for every doc is the same: the reader can take the next decision or the next action without a guess. Judge each doc against its purpose and its stage. A discovery page does not need a production runbook checklist.

## Choose the mode

Pick the mode from the request:

- **Write or revise.** The user asks you to draft a doc, or to change it with decisions they give. This mode can add, move, or remove content.
- **Tighten.** The user asks you to shorten, trim, or cut a doc. This mode cuts and never adds content.
- **Review.** The user asks you to assess, review, audit, or judge readiness. This mode returns findings and never edits the source.

When the user asks for a draft and a review, write the draft first. Then review the draft, and return the doc followed by the review. When the user limits which passages you can edit, keep to that limit. Ask only when the mode changes your permission to edit an existing source and the request does not show it.

## Write or revise

1. Find the audience, the doc type, the next step, and the evidence you have. Read the notes and the linked sources. For a revision, read the latest version and keep the author's changes.
2. Lead with the problem, the proposed decision, or the action. Put the context, evidence, tradeoffs, and next steps after it.
3. Keep facts, proposals, assumptions, and open decisions apart. Keep source links that support a claim.
4. Never invent owners, approvals, test results, commands, thresholds, or system behaviour. Mark each gap as an open question, and state its effect on the next step.
5. Write a useful draft from what you know. Ask for a missing fact only when the gap stops a useful draft. Never present a rollout with gaps as ready to execute.
6. Keep the requested scope. A clarity edit does not give you permission to change the architecture or the operational behaviour. When the source has a conflict, show it and ask for the decision.
7. Keep the current decisions easy to read. When the user allows edits, move old drafting history out of the main text. Keep the rationale and the trace of each decision.
8. When the source is published or under review, use the Tighten safeguards. Rule 7 keeps comment anchors, links, headings, tables, and code blocks. Process step 2 allows only exact old→new edits with a structure check, never a freehand rewrite.
9. Before you deliver, check the draft against the doc-type checks and the language rules below. Fix each problem that the evidence supports. Keep each open gap as an open question.

Return the doc first. After it, add a short note on open decisions and on what you did not verify, when either exists. A writing request does not need the review report unless the user also asks for a review. Do not put a verdict, a language assessment, or notes about your edits inside the doc. A local draft does not give you permission to publish it.

## Tighten

Aim: cut the doc to what it must say, and keep every reason behind it. For a design, use all of this section. For a runbook, use supporting rules 1, 4, 5, 7, and 8, and the Process. Never cut a step, a prerequisite, an expected result, a stop condition, or a warning from a runbook. Report each gap that the runbook checks find. Do not fill the gap.

### Anchor principles

1. **Shorten, and keep detail in the appendix.** Prose carries the what and the why at a readable level. Exact values go in a code block, an appendix, or a linked runbook. Examples are policies, configs, encodings, and tables. Prefer a deletion or a merge to a rewrite.
2. **Keep only what serves the doc's aim.** State the aim in one sentence. Each section must serve that aim. Give adjacent or nice-to-know material a pointer, or cut it. Document this design, not domain theory that the reader already knows.

### Supporting rules

1. **Protect the rationale.** Never cut a "why" to save space, because that is the costliest mistake. Cut restatement and meta-commentary. Keep each distinct fact, control, caveat, and reason.
2. **Tell redundancy from planned repetition.** A decision table that a later section repeats is often the doc's pattern, not waste. So is a threat-model matrix, or a jump-target section with its own caveat. Cut a repeat only when one copy is the main copy and the others can become pointers.
3. **Use a pointer for detail.** State each fact once, in the section that owns it. In other sections, link to it ("see X") and do not derive it again. This stops the copies from drifting apart.
4. **A claim the reader can infer is not always safe to cut.** Keep a key claim even when a careful reader could infer it. This applies most to a security or controls doc.
5. **Remove meta text and boilerplate.** You can cut "This document describes…", "captured here so it isn't lost", hedges with no content, and examples that only repeat a rule. Keep an example that shows a real failure.
6. **Write for the engineer who builds it.** That reader has no shared context and no chance to ask a question. Use plain words. Explain only the terms this team needs.
7. **Keep the structure of a published or reviewed doc.** Never break review-comment anchors, links inside the doc, code blocks, tables, headings, or inline styles. Keep the set of anchors stable, so reviewer comments stay attached.
8. **Be honest about the limit.** If the doc is already tight, say so and stop. Do not make changes only to look busy.
9. **The runbook carries the how. The design doc carries the what and the why.** Link to the runbook, and do not copy its steps into the design.

### Process

1. Read the whole doc first. Then edit one section at a time.
2. On a published or reviewed doc, make exact old→new edits with mechanical guards. Use a find and replace that matches one place only, plus a structure check. Do not rewrite freehand. This step protects rule 7.
3. Put each possible cut in a risk tier before you apply it:

   | Tier              | What it looks like                                      | Action                               |
   | ----------------- | ------------------------------------------------------- | ------------------------------------ |
   | Clean redundancy  | Says nothing that the doc does not say elsewhere        | Apply it                             |
   | Framing only      | A change of wording or style, with no change of content | Show it to the author for a decision |
   | Touches rationale | Any "why", caveat, or reason                            | Do not apply it                      |

4. After you edit, check three things. The structure did not change. The planned cuts are in place. The meaning did not change.

## Establish the evidence

Do this before you write a review, and before you revise an existing doc.

- Read the full current doc and the decisions or procedures it links to. Find its audience, purpose, status, and next step. Infer them when they are clear. If they are not clear, state your assumption, or ask when the answer changes the verdict.
- For a set of pages, find which pages are current, which are old, and which support the others. State which pages you read in full, which you sampled, and which you could not open. Do not imply a full audit when you read only an index or extracts.
- Keep formatting that changes meaning, such as strikethrough, status labels, and superseded sections. An old option is not a current requirement. When old and current decisions are hard to tell apart, report a navigation problem, not a technical conflict.
- Read the linked material before you say that something is missing. A link to a usable source is enough, and each page does not need its own copy. Report a broken or locked link, and state how it limits the review.
- Keep these apart: confirmed requirements, adopted decisions, proposals, assumptions, and open questions. An approval label does not close the questions that came after it.
- When the doc already lists a gap as an open question, say that the doc already knows it. Then say whether it blocks the next step, and what decision or evidence closes it. Do not report it as a new gap. Do not treat normal discovery questions as defects.
- Read the code, config, tests, or primary docs when you need them to support a technical finding. Tell an unclear statement apart from a proven defect. Do not claim technical or operational proof from prose alone.

## Checks per doc type

Use only the checks that affect the next step. One doc can hold more than one type, such as a migration design with a rollout appendix. Judge those parts apart when their readiness differs. A check is not a required heading, and each gap is not a blocker.

### Technical design

- Check the problem, the users, the expected result, the scope, the recommendation, the options, and the reasons for the choice. The reader must see which decisions are made and which come next.
- For readiness to build, check the architecture and data flows, ownership boundaries, the source of truth, and integration contracts. Also check permissions and credentials, compatibility, failure and recovery, monitoring, tests, and delivery dependencies.
- Check that the examples, the options, the recommendation, and the build plan agree with each other.
- Suggest a pilot or a minimum version when the value, the adoption, or a main feasibility assumption is not proven. State what the pilot proves, its scope, the deferred work, the evidence of success, and the path to the full design. Do not suggest a pilot that skips a safeguard or does not test the central assumption.

### Team template or principles

When the team or the repo has a design template or a principles doc, read it before you write or review. Treat it as the source of truth, and do not copy it into the design. Read the current version from its source, not a summary or a copy from memory. State the version you used, outside the design. When you cannot open it, continue with the evidence you have. Say what you could not open, and do not claim that the design complies with it.

Apply the template in proportion to the design:

- Put the outcome near the top. Make it clear whether it is a proposal or an agreed decision. Make the problem, goals, scope, and build plan easy to find.
- For each decision with real alternatives, give the options, their advantages and disadvantages, the recommendation, and the reason. A table of the chosen options alone does not give that analysis.
- Leave out an options section when no real choice exists. Do not invent alternatives, and do not open a settled decision again only to fill a heading. Keep the recorded alternatives of an existing decision, in the design or through a link to its decision record.
- Keep the analysis for each decision in the main text. Move inventories, config examples, and supporting evidence to an appendix. Add an architecture diagram when it helps to explain the parts and how they connect.
- State what changes, who owns the work, the build order, and the open questions. For each open question, state who decides and what work it blocks.

In a review, check the template structure and the principles that apply. For a conflict with a principle, name the principle and quote the design text. Then state the effect and the fix or the decision that the author needs. A design does not fail only because it leaves out a heading or a diagram that it does not need.

### Migration design

- Check the current state, the target state, what moves or changes, and the affected consumers. Also check compatibility, dependencies, ownership, order, and any period when old and new run together.
- Check how the plan handles writes, data integrity, reconciliation, cutover, recovery, and retirement, where they apply.
- Find the point after which a rollback becomes hard or loses data. Check that the claimed reversibility agrees with the real order of steps and with how new writes are handled.
- Tell a design decision that is still open apart from an execution detail that the rollout plan can supply later.

### Discovery

- Check the question, the scope and coverage, the evidence and its sources, the findings, the assumptions, the unknowns, and the next step.
- Tell observations apart from conclusions. Show where the evidence does not support a claim.
- Open questions are normal at this stage. Check that the evidence supports the next decision, and that each main unknown has a way to find the answer.
- Do not ask for a final architecture or an operational procedure while discovery still collects evidence. When the page claims it is ready for design, find the unknowns that could change the direction.

### Rollout plan or runbook

- Check the prerequisites, target environments, roles, dependencies, ordered steps, expected results, and validation gates.
- Check monitoring, stop conditions, escalation, recovery or rollback, and completion criteria, where they apply.
- For a staged rollout, check what allows the next stage and who makes that decision.
- For a migration rollout, also check data validation, write handling, cutover, and the point of no return. Check when the team can remove the old resources.
- A rollback step must match the real failure window. "Roll back if needed" is not enough when the rollback can lose writes.
- Replace a vague gate, such as "looks healthy" or "caught quickly", with an observable condition and a time limit. The owner supplies the metric, the range, and the time. Do not invent thresholds, commands, owners, approvals, or an acceptable data loss.
- A useful planning draft can still be not ready to execute. Say which of the two it is.

## Clear language

CLAUDE.md Writing and the `asd-ste100` skill hold the base language rules. Apply them in every mode. This section adds the rules for engineering docs. In tighten mode, apply only the rules that cut or reword. Do not add an example or a term explanation in tighten mode.

- Keep precise technical terms. Explain an unknown term or acronym the first time, when the audience needs it. Do not replace a precise term with a vague everyday word.
- Flag a vague claim such as "robust" or "seamless". Replace it with the behaviour or evidence that supports it, or flag the missing detail.
- Add a concrete example when it helps to explain the change. Do not invent facts or requirements for the example.
- Flag empty openings and transitions, such as "In today's fast-paced world", "Let's delve into", and "In conclusion".
- Flag inflated verbs and phrases, such as "unlock", "empower", "foster", "leverage", and "comprehensive solution", when a concrete description says more. These words are examples, not a ban list.
- Flag summaries that repeat, generic benefits, and sentences that only repeat their heading.
- Flag canned contrasts ("this isn't X, it's Y"), question-and-answer hooks, repeated slogans, invented labels, too much emphasis, and needless hyphenated adjectives.
- Do not add personality with slang, deliberate mistakes, stories, or forced friendliness. Do not claim to detect AI authorship, and do not try to pass an AI detector.
- Keep each statement's strength. "May" stays "may", "should" stays "should", and a proposal stays a proposal.
- Keep code, commands, identifiers, paths, config values, quotes, contract wording, command order, and operational safeguards as they are. Improve the text around them.
- For a design, make the proposal, the reasons, the tradeoffs, and the open decisions easy to find. For a procedure, put the prerequisites, expected results, stop conditions, and warnings next to the steps they affect.

## Author and agent commentary

Remove text that describes how the doc was made, because it does not help the reader decide or act. Examples:

- agent planning or self-talk, such as "I need to check this before answering"
- chat replies, such as "Here is the revised version"
- notes about edits, such as "I moved this section to make it clearer"
- prompt instructions
- notes only for the author, such as "You could add a diagram here"

Judge the visible text and its use to the reader. Do not claim to identify AI authorship or hidden thoughts.

Keep the technical rationale, the alternatives, the evidence, the limits, and the open decisions that readers need. Text that explains "why" or uses "I" or "we" is not commentary by default. When a comment holds a real uncertainty, keep the uncertainty as an open question or a verification gap. Judge a TODO by the doc's stage. A TODO is fine in discovery or a working draft. An open execution detail can block a rollout.

Example: "I did not have access to the staging account, so I left the IAM section vague" becomes a finding about the missing check. If readers need it, the doc says "The staging IAM roles are not verified." Keep "We picked a canary release to limit how many users a bad build reaches", because it explains a decision.

In review mode, report each commentary passage as a finding, and leave the source unchanged. In write, revise, or tighten mode, keep the notes about your edits outside the doc.

## Review mode

### Verdict and assessment

Start with the doc type, the next step, and one verdict:

- **Ready:** no material gaps for that next step.
- **Ready with follow-ups:** the next step can start. Name the follow-ups that do not block it.
- **Not ready:** the author must close material gaps before that next step.
- **Insufficient evidence:** missing or incomplete material stops a supported verdict.

A verdict applies to one next step. "Ready for discussion" does not mean "ready to execute in production". Do not certify that a doc is safe overall.

After the verdict, write a **Language assessment**. State whether the doc is clear for its audience, and name the main readability problems. When there are none, write "No material language issues found." When the source is missing or incomplete, state what you could not assess.

### Findings

Report findings in 2 lists, in this order:

1. **Technical and readiness findings:** missing decisions, wrong or conflicting technical details, unsafe order of steps, paths or identifiers that do not agree, missing procedures, validation gaps, and rollback gaps.
2. **Language and readability findings:** unclear sentences, unexplained jargon, repetition, vague headings, poor order, and author or agent commentary.

Rules for the lists:

- Put a finding in a list by what must change. A missing rule, owner, or decision is technical. Better wording for a fact the doc already states is language. Example: an undefined rule for which services count as "critical" is technical. A simpler sentence for a rule the doc already defines is language.
- When one passage has both kinds of problem, explain the technical problem once, in the first list. In the language list, refer to it and give only the wording change. Do not count it as a second blocker.
- Each problem that the language assessment names needs its own language finding, or a reference to the technical finding that must come first. "Repetitive", "too much jargon", or "readable but vague" alone is not a finding.
- Sort each list by priority. When a list is empty, say so in one line. Do not invent findings to fill it.

Each finding has this format:

- **Priority: short title.** The priority is one of:
  - **Blocking:** the next step needs a guess at a material decision, or accepts an undefined operational risk.
  - **Important:** likely confusion, rework, or risk that the author must fix, but the next step can start.
  - **Minor:** optional wording, navigation, or layout.
- **Location and evidence.** Name the section, with a link when you can. Quote the exact short text that supports the finding. For a conflict, quote and locate both texts. Use line numbers only when the source has stable ones, and never invent them. Tell active text apart from superseded text.
- **Missing content** has no passage to quote. Its location is "Missing from document", plus the section where the content belongs. Its evidence says what you checked, including linked docs. Quote a nearby passage only when one exists.
- **Comment.** In one or two plain sentences, state the problem and its effect on the reader. The author must be able to act on it without your working notes.
- **Suggested update.** Give one fix. Give replacement wording when the source sets the facts. Otherwise, state the decision or the information the author must supply, and label any proposed wording as conditional. Give alternatives only when they are a real choice. Never settle an uncertain technical fact only to make the rewrite complete.

Example:

> **Important: State the rollback limit directly**
>
> **Location and evidence:** Rollback: "We can switch back at any time while the old cluster still runs."
>
> **Comment:** This text implies that rollback loses no data while the old cluster runs. Readers need to know when new writes make a switch back unsafe.
>
> **Suggested update:** Replace with "After writes start on the new cluster, a switch back can lose those writes." Link the recovery procedure only if it exists and you checked it. Otherwise, report the missing procedure as a technical finding.

### Language findings in detail

- Quote the exact wording. State the reader's difficulty in plain words. Then give a concrete replacement or edit.
- When the meaning is clear, give a faithful before-and-after example. For repetition, quote the repeated text from each place and say which copy to keep. For a long sentence or jargon, show a simpler version that keeps the needed terms.
- When wording hides an open decision, name the missing information and do not write a polished answer. Example: a gate of "latency is fine" needs the metric, the limit, the time to watch, and the action when the check fails. Ask the owner for those values.
- For a repeated pattern, quote one example and name the other sections where it occurs.
- Tell a required clarification apart from optional polish. When the doc is clear, say so. Do not give a full rewrite that nobody asked for.

### Write the review in plain language

- A title names the object and the action. Write "Use one name for the queue URL setting", not "Align configuration". Write "Link the cutover steps from section 4", not "Improve discoverability". Put unrelated fixes in separate findings.
- Use familiar verbs and concrete nouns, such as "State who approves stage 2" or "Give the error-rate limit for the canary".
- Keep each comment short. State what is wrong, why it matters, and what the author must change. Do not put several requests in one long sentence.
- Before you return the review, read it once as the author. Replace each abstract title or comment with the real action. Do not tell the author to write clearly in feedback that is itself unclear.

### Shape of the review

1. The verdict, then the language assessment.
2. One or two lines on what works well.
3. The technical and readiness findings, then the language and readability findings.
4. The changes needed before the next step. Keep required decisions apart from optional polish.
5. Review coverage: what you read, your assumptions, and what you did not verify.

Do not invent findings, numeric quality scores, or a fixed number of findings. Keep the review in proportion to the doc. Do not add a full rewrite, messages to colleagues, or a checklist at the end. Keep your final self-check internal.

### Delivery estimates

Give an estimate only when the user asks, or when you must test a delivery claim in the doc. Read the implementation evidence first. Use ranges, and state your assumptions and confidence. State the work you included, such as tests, access setup, migration, review, and rollout. Keep engineering effort apart from elapsed time. Estimate a pilot apart from the full design, and only when you suggest one. Never count an option that nobody chose as build work.
