---
name: adversarial-review
description: Runs a single-critic attack on an implementation plan before execution. Checks the plan across six fixed failure lenses and returns a STOP, REVISE, or SHIP verdict. Trigger with /adversarial-review, "red team this plan", "poke holes", "break this plan", or "find holes".
---

# Adversarial Review

## 1. Purpose and scope

This skill attacks one implementation plan before you run it. Assume the plan is wrong. Find the flaw that would sink it.

Use the right tool for the stakes:

- Use the `advisor` tool for a quick, unstructured second opinion.
- Use this skill for one structured, cheap attack on a single plan.
- Use the `council-review` skill for a heavy, multi-member debate on a high-stakes open decision.

This skill reviews plans only. It does not review code. For code review, use the `/code-review` skill or the `reviewer` agent.

## 2. Step 1: get the plan

Find the plan with this order of checks.

1. The user gives a plan file path. Read the whole file.
2. The user pastes plan text. Use that text.
3. The user gives no argument. Use the plan file named in the current plan-mode instructions. If none exists, use the newest file under `~/.claude/plans/*.md`.
4. No plan exists anywhere above. Stop and report "no plan to review".

## 3. Step 2: attack the plan through six lenses

Run each lens once against the plan. A lens either names a finding, or states that the plan is clear on that lens and names the evidence you checked. Never invent a finding a lens did not surface.

1. **Assumption**: name the assumption the plan depends on that, if false, sinks the plan.
2. **Failure mode**: assume the plan ran and failed, then name the most likely cause.
3. **Sequencing**: find a step in the wrong order, a missing dependency, or a blocked start condition.
4. **Scope**: find scope creep past the stated goal, or a gap that leaves the goal unmet.
5. **Verification**: find a success claim the plan cannot prove, or a missing test or check.
6. **Reversibility**: find a destructive or irreversible step that has no rollback path.

## 4. Step 3: rate findings and decide the verdict

Rate every finding with one of these severity tiers.

- **BLOCKER**: the plan fails, or causes harm, as written.
- **RISK**: the plan likely causes rework or leaves a gap.
- **NOTE**: a minor improvement, not required for the plan to work.

Give every BLOCKER a disproof check: the cheapest concrete command, file read, or measurement that settles whether the blocker is real.

Set the verdict with these rules, in order.

1. Any BLOCKER exists. Verdict is STOP.
2. No BLOCKER exists and at least one RISK exists. Verdict is REVISE.
3. No BLOCKER and no RISK exist. Verdict is SHIP.

A review where every lens comes back clear is a SHIP.

## 5. Output format

Write the result in this order, with the verdict first.

1. The verdict on the first line: STOP, REVISE, or SHIP.
2. Findings grouped by severity (BLOCKER, then RISK, then NOTE). Name the lens for each finding.
3. The disproof check under each BLOCKER.
4. A two-sentence summary. Name the single most important fix. If the verdict is SHIP, state that no fix is required.

Give the result with no preamble and no self-grading.

## 6. Honesty rule

When a lens finds no flaw, say so in plain words and name the weakest point on that lens instead. Never manufacture a flaw to look useful.
