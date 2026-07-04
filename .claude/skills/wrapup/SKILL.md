---
name: wrapup
description: >
  Ends the current session with two grounding questions before you close out —
  "What are you least confident about right now?" and Sam Altman's "What's
  the biggest thing I'm missing about the situation right now? What don't I
  realize?" Answers are built from this session's actual files, decisions,
  and assumptions, not generic advice — genuinely risky uncertainties are
  flagged and Claude offers to investigate them before ending. Use when
  wrapping up a work session — trigger phrases: "let's wrap up", "before we
  end this session", "wrap up this session", "before we finish here", "let's
  call it there", "end of session check". Do not trigger on standalone
  confidence remarks mid-task (e.g. "I'm not confident about X") — this is a
  deliberate end-of-session ritual, not a running commentary tool.
---

# Session Wrap-Up: Two Questions

Source: a Reddit post ("I end every AI session with two questions") describing
a two-question ritual — one the poster attributes to Sam Altman, one Claude
itself suggested — that surfaces the single biggest miss roughly one time in
four. The value is entirely in how specifically the questions get answered;
asked generically, they produce generic, useless answers. This skill exists
to prevent that.

**The two questions, verbatim:**

1. "What are you least confident about right now?"
2. "What's the biggest thing I'm missing about the situation right now? What don't I realize?" (Sam Altman's)

These are **two different vantage points, not one list asked twice**:

- Question 1 is Claude's introspection about **its own work this session** —
  what it did, and where it's shaky about that work specifically.
- Question 2 is an **outside view of the whole situation** — what a
  skeptical third party, seeing only the end state, would notice that
  neither you nor the user has said out loud yet.

If your two answers end up restating the same points from different angles,
you have not done this correctly — go back and re-derive Question 2 from the
outside-view lenses below, not from your Question 1 list.

## Step 0 — Gather before answering

Before writing anything, scan back over this session's actual transcript and
list, silently or in scratch reasoning:

- Every file you read, created, edited, or deleted.
- Every non-trivial decision you made (architecture, library, naming,
  algorithm, data format, error-handling strategy).
- Every assumption you took without explicitly confirming it with the user.
- Every piece of code, config, or content you produced.
- Any command you ran, especially anything destructive, irreversible, or
  hard to undo.

Both answers below must be built **only** from this list. Do not answer
either question in the abstract or with generic software-engineering advice
— if you cannot point to a specific file, decision, or line from this
session, it does not belong in the answer.

## Step 1 — "What are you least confident about right now?"

List 4-8 concrete items from Step 0's gather list. Each item must name an
actual file, function, decision, or assumption from _this_ session — never a
hypothetical or generic one.

**Bad answer (do not do this):**

> - I'm not totally sure the tests are comprehensive enough.
> - There might be edge cases I haven't considered.
> - The error handling could probably be more robust.

This is vague, unfalsifiable, and could be pasted into any session unchanged
— it names nothing real, so it's worthless as a self-check.

**Good answer (this is the bar):**

> - I assumed `parseConfig()` in `config.ts:42` treats a missing `timeout`
>   field as `0`, but I never actually checked — if it's `undefined` instead,
>   the retry loop in `retry.ts:18` could spin forever. **[HIGH RISK]**
> - I renamed `getUserById` to `fetchUser` across 6 call sites but only
>   grepped for the old name in `src/`, not `scripts/` or `tests/` — there
>   could be stale references outside what I searched.
> - I chose to store the new cache in-memory rather than on disk because the
>   existing `Cache` class only supported memory, but I didn't check whether
>   disk persistence was actually a requirement here.

Every item names a real file/line, a real decision, and — critically — what
could go wrong if the uncertainty resolves the bad way. That last part is
what makes an item auditable rather than a vague hedge.

**Risk-rate every item.** Mark an item **[HIGH RISK]** if it matches any of
these criteria — these are the categories the Reddit post's "one in four is
a huge deal" insight is about:

- Could cause **silent wrong behavior** — the code runs, looks fine, and
  produces incorrect results with no error.
- Rests on an **unverified architectural assumption** — a load-bearing
  belief about how an existing system works that was never actually checked
  against the code or the user.
- Is a **security-relevant gap** — auth, secrets, input validation, injection
  surface, permissions.
- Involved **unverified destructive or irreversible action** — a deletion,
  overwrite, force-push, migration, or similar, taken on an assumption that
  was never confirmed.

Items that don't match any of these are minor/cosmetic — leave them
unmarked. Do not inflate everything to HIGH RISK; the marking is only useful
if it's selective.

**If any item is HIGH RISK: do not just list it and move on.** State plainly
that this is a big enough deal to warrant checking before ending the
session, and explicitly offer to investigate it right now — read the
relevant code, trace the actual behavior, or ask the one clarifying question
that resolves it. This follow-through is the actual point of the exercise;
a list of flagged risks nobody chases down is no better than not flagging
them.

## Step 2 — "What's the biggest thing I'm missing about the situation right now? What don't I realize?" (Sam Altman's)

This is not "list more uncertainties." It's a genuine outside view: what
would a skeptical reviewer — seeing only the request and the result, not
the path taken to get there — flag that neither you nor the user has said
yet.

Work through each lens below before answering. You may find nothing under
some or all of them — that's fine and expected, but you must actually check
each one rather than skip to a conclusion.

- **Wrong framing** — is the problem being solved actually the problem that
  matters, or has the session drifted into solving an easier adjacent
  problem?
- **Unstated assumption** — is there a load-bearing belief the whole
  session rests on that was never said out loud or confirmed?
- **Scope creep or scope shrinkage** — did the session quietly do more than
  asked (introducing new surface area/risk), or less (leaving the actual
  goal only partially met while looking complete)?
- **Simpler alternative not considered** — is there an approach that would
  have gotten the same outcome with meaningfully less complexity, code, or
  risk, that was never raised?
- **A risk the user hasn't raised** — something about how this will be used,
  deployed, or maintained that seems likely to bite later, which hasn't come
  up in the conversation at all.

**Bad answer (do not do this):**

> Everything looks good, I think we covered all the bases here!

This is exactly the generic non-answer the Reddit post's approach is
designed to defeat — it required no actual outside-view thinking and could
apply to any session.

**Good answer (this is the bar):**

> Looking at the framing lens: we've spent this whole session optimizing the
> query in `reports.sql`, but the actual user complaint (from the top of the
> conversation) was that the report _page_ feels slow, and the query was only
> ~15% of that page's load time based on what I saw in `perf.log` earlier —
> the bigger win is probably the unbatched image fetches in
> `ReportView.tsx:88`, which we never looked at. That might be the real ask
> underneath the stated one.

**If, after genuinely working through the lenses, there is truly nothing
worth flagging, say so explicitly** — e.g. "I checked each of these and
didn't find a real gap: the framing matches the original ask, no
unconfirmed assumptions are load-bearing, scope matches what was asked, I
didn't spot a materially simpler alternative, and no unraised risk stood
out." Do not fabricate a weak or token concern just to appear thorough — a
genuine "nothing found, here's why" is more useful than invented filler.

## Response template

Use this shape:

```
## What I'm least confident about

- [item 1 — file/decision + what could go wrong]
- [item 2 — file/decision + what could go wrong] **[HIGH RISK]**
- ...(4-8 items total)

[If any HIGH RISK items exist:]
The [item N] above is the one I'd actually want to resolve before we call
this done — want me to dig into it now? I'd [specific next action: read X,
trace Y, ask Z].

## What you might be missing about this session (Sam Altman's question)

[Either:]
- [1-3 concrete outside-view findings, each tied to a specific lens and
  grounded in this session's actual content]

[Or, if genuinely nothing:]
I went through each lens (framing, unstated assumptions, scope, simpler
alternatives, unraised risks) and didn't find a real gap — [one line on why
for each, or a combined summary if they're all clearly fine].

---
Want me to save any of this to memory before we close out? If you'll be
picking this up in a future session, I can also run `/handoff` to write a
continuity doc (goal, progress, what worked/didn't, next steps) — just say
the word.
```

The closing memory offer and the handoff nudge are both optional and only
fire once, at the very end — they're suggestions, never automatic actions.
If the user declines or ignores either, do not raise it again in the same
session.
