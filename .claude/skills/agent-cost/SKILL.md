---
name: agent-cost
description: Measure turns, tokens and estimated cost for main conversations and each subagent type from local Claude Code transcripts. Use for "agent cost", "cost per task", "which agents burn tokens", "retries per agent type", "Claude Code spend", "compare with the usage page", "usage logs", "measure usage", "cost drivers", or "tool calls per turn".
---

# Agent Cost

## Why this exists

Claude Code already records every turn and its token usage in local transcript files.
This skill reads those files. It calls no API and writes no file.

## Run the script

Run this command for a cost table of every agent type over the last 30 days. Without
`--days`, the window is the last 7 days.

```
python3 ~/.claude/skills/agent-cost/scripts/agent_cost.py --days 30
```

Add `--project <token>` to read only the directories under `~/.claude/projects/` whose
name contains the token. The match ignores letter case, and can select more than one
directory.

Run this command to check one spawn by its id.

```
python3 ~/.claude/skills/agent-cost/scripts/agent_cost.py --agent <id>
```

The `--agent` id is the value between `agent-` and `.jsonl` in a transcript file name.
This mode ignores `--days` and reads every record in the matching file. A unique part of
the id also matches.

Add `--usd` to either mode for a list-price dollar estimate from the price table in the
script.

```
python3 ~/.claude/skills/agent-cost/scripts/agent_cost.py --days 30 --usd
```

Add `--billed <figure>` to compare the estimate with a billed figure for the same
window. `--billed` implies `--usd`.

```
python3 ~/.claude/skills/agent-cost/scripts/agent_cost.py --days 30 --billed 2500
```

## Find cost drivers

Use these flags to find where the money goes.

Add `--tools` to show tool calls per turn. It adds two columns. **calls/turn** is the
total tool calls divided by the turns that made at least one call. **1-call %** is the
share of those turns that made exactly one call. Both show `-` for a row with no
tool-using turn, and for every `[advisor]` row. A low **calls/turn** near 1.0 means the
agent rarely batches independent calls.

```
python3 ~/.claude/skills/agent-cost/scripts/agent_cost.py --days 30 --tools
```

Add `--sort cost` to order rows by descending total dollars. It implies `--usd`. Rows with
no price come last. `--sort input` orders by descending total input. The default,
`--sort spawns`, orders by descending spawn count. Add `--top <N>` to print only the
first N rows. The footer totals still cover every row.

```
python3 ~/.claude/skills/agent-cost/scripts/agent_cost.py --days 30 --sort cost --top 10
```

Add `--since YYYY-MM-DD` to start the window at local midnight of that date. Do not
combine it with `--days`. The script exits with an error if you do. With `--since`,
the footer names the start date instead of "last N days".

```
python3 ~/.claude/skills/agent-cost/scripts/agent_cost.py --since 2026-09-01 --usd
```

Add `--reprice <model>` to price every turn at another model's rates. It implies `--usd`.
The script adds one `$ at <model>` column. It prices each turn's own token split and
ignores the turn's real model. It still skips `speed: fast` and `inference_geo: us`
turns. Repeat the flag for more models. The script exits with an error on an unknown model id.

```
python3 ~/.claude/skills/agent-cost/scripts/agent_cost.py --days 30 --reprice claude-opus-5-5 --reprice claude-sonnet-5-5
```

With `--usd`, a summary follows the footer totals. It shows the cost and the share of the
grand total for `main`, for subagents, and for advisors. The advisor line sums every
`[advisor]` row, main and subagent. Those rows also stay inside the `main` and subagent
totals, so the three shares sum to more than 100% when any advisor cost exists. The summary then lists the cost
per model, largest first. With `--reprice`, it ends with the grand total at each
repriced model.

## Read the table

The table groups spawns by agent type, model, and effort. Each row reports:

- **spawns**: how many times this agent type ran on this model and effort. A `*` after
  the count means fewer than 5 spawns. Read that row's medians with caution.
- **median turns** and **p90 turns**: API calls per spawn.
- **median uncached**, **median cache write**, and **median cache read**: the three
  parts of prompt input, per spawn. They bill at different rates. A cache read
  costs a fraction of a cache write, and a cache write costs more than uncached input.
  Read all three together, not one alone.
- **median input/turn**: total prompt tokens (all three parts) divided by turn count.
  This measures context size per call, not cost.
- **median output tokens**: the tokens the model wrote, per spawn.
- **total input** and **p90 input**: the summed input tokens of all spawns in the row,
  and the 90th-percentile input of one spawn. p90 is the high
  end to plan for, not the maximum.
- **respawns**: spawns where the same session already ran a spawn with the same row
  type (see the `customAgentType` rule below) and description.
- **failed/killed**: failed-or-killed spawns over spawns with a known run status, for
  example `1/12`. The row shows `-` when no spawn in it has a known status. See "Known
  limits" for what a known status can and cannot tell you.

With `--usd`, the table also reports:

- **priced**: priced turns over all turns in the row, for example `142/150`. A turn is
  unpriced when its model has no listed price, or when it ran with `speed: fast` or
  `inference_geo: us`. The cost sum skips each unpriced turn, but still prices the rest
  of that spawn.
- **median $** and **total $**: the estimated list-price cost per spawn, and summed
  across the row. A spawn with no priced turn has no price, and both figures
  exclude it. Both show `?` when no spawn in the row has a price.

After the table, with `--usd`, the report shows three totals: the `main` total, the
subagent total, and their sum. The `main` and subagent totals each include their
`[advisor]` rows. With `--billed`, the report also shows the gap: the sum minus the
billed figure, in dollars and as a percent of the billed figure.

The respawn column is a proxy for retries, not an exact retry count. A team or workflow
can spawn the same agent type and description twice for unrelated reasons.

A subagent can call a tool such as `advisor` that runs on a different model. The script
reports those tokens as an extra `<agent type> [advisor]` row, on the advisor's own
model. It never adds advisor tokens to the parent row's turns or totals. The footer
spawn count excludes advisor calls, and a separate footer line counts them. An advisor
row never counts as a respawn. An advisor row always groups under effort `-`, because
the transcript does not record the advisor's own effort setting.

In an advisor row, **spawns** counts the parent spawns that called the advisor, not the
calls. So **median turns** means advisor calls per spawn, and **median $** means advisor
cost per spawn, not per call. Divide `median $` by `median turns` for a rough per-call
figure. An advisor call often has near-zero cache read, because the parent session's
cache does not cover it. The `failed/killed` column always shows `-` on an advisor row,
because the parent spawn's own row already counts that run's status once.

A named teammate stores its teammate name in `agentType` and its real type in
`customAgentType`. When a spawn has a `customAgentType`, the table uses it as the row
type. So a teammate such as "altitude-2" appears under its real type, such as "reviewer".

## The `main` rows

The script also reads main conversation transcripts and groups them under the agent
type `main`. A main conversation can change model or effort partway through, so the
script splits each session into one "part" per (model, effort) combination it used. A
`main` row's **spawns** count is the number of parts across every session, not the
number of sessions, and **median turns** is turns per part. The main thread's advisor
calls appear in `main [advisor]` rows, under effort `-`, the same as a subagent's
advisor calls. A `main` row always shows `-` for **respawns** and **failed/killed**: a
main session is not a retryable spawn, and it carries no run status.

A resumed or forked session can duplicate the same message across more than one main
transcript file. The script finds every message that appears in more than one file and
keeps one copy: the copy with the most output tokens. It counts that message once, under
the session whose copy has the earliest timestamp. The footer counts these messages.

The script filters every record, main and subagent, by its own timestamp, not by the
file's last-modified time. A long-running main session can hold records from many weeks
ago. A filter on file time alone would count those old records, even when they fall
outside `--days`. The script still skips a whole file, for speed, when its last-modified
time is older than the window.

## Known limits

- The script skips a subagent transcript with no matching `.meta.json` file, or one
  whose `.meta.json` fails to parse. The footer reports the skipped count.
- The script never counts a turn whose model is `<synthetic>`. That value marks an
  internal Claude Code record, not a billed model call.
- A run status comes from the parent session's own `<task-notification>` record. Only a
  spawn made through the top-level Agent tool gets one. A teammate inside a team or
  workflow never gets its own notification, so its status is always unknown.
- `completed` means the run finished. It does not mean the run was correct.
- The `--usd` price table is a static list, not a live lookup. It is USD list price per
  million tokens, from https://platform.claude.com/docs/en/about-claude/pricing, read on
  2026-09-30. Update `PRICE_TABLE` in the script by hand when Anthropic changes prices.
  A model id missing from the table always shows `?`, never a guess based on a similar
  model.
- A turn with no recorded `speed` prices as standard speed, not `fast`. A check on
  2026-10-01 found no `fast` value in any transcript, on any model. Only `speed: fast`
  and `inference_geo: us` still price as `?`, because the price table lists no rate for
  them.
- The total is a list-price estimate from this machine's own transcript files. It can
  differ from the claude.ai usage page, which can count other machines and a different
  date window. See "When the total differs from the usage page" below.

## When the total differs from the usage page

Run `--billed <figure>` with the figure from the claude.ai usage page for the same
window. Check these causes in order.

1. The page's date window. Check that it matches your `--days` window exactly.
2. Sessions on other machines, or in the claude.ai chat interface. This script reads
   only local transcript files.
3. A model the price table does not list. Check the table for a `?` price, or a
   **priced** cell such as `0/12`.
4. A price change since the price table was last read.
5. A pricing rule this script does not detect, for cache writes or `speed`.

Add one row per check to `~/.claude/skills/agent-cost/calibration.md`. Record the date,
the window, the billed figure, the estimate, the gap, and the cause you found. Start
your next check at the first cause that no earlier row excludes.
