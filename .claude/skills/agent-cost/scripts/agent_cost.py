#!/usr/bin/env python3
"""Measure turns and tokens per subagent type from Claude Code transcripts,
and compare that against main-conversation cost.

Stdlib only (json/pathlib/argparse/statistics/re/datetime) - no third-party
deps. Read-only: never opens a transcript for anything but reading, never
writes any file.

Each subagent spawn leaves a transcript at
    ~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl
with a sibling agent-<id>.meta.json holding `agentType` and `description`.
A main conversation leaves its own transcript at
    ~/.claude/projects/<project>/<session>.jsonl
with no sibling meta.json and no record with `"isSidechain": true`.

Claude Code writes one record per content block, so one API call produces
several assistant records that share `message.id` and repeat `usage` with a
growing `output_tokens`. This script groups assistant records by `message.id`
and keeps the record with the largest `output_tokens` in each group - that
group is one turn. For a subagent transcript, the model is taken from the
first assistant record in the file whose `message.model` is not
"<synthetic>" (a Claude Code internal marker, never a billed model). A main
conversation can change model or effort mid-session, so a main turn is
instead attributed by its own record's `message.model` and top-level
`effort` - see `collect_main_parts`.

Each turn's input splits into four parts that bill at different rates:
uncached `input_tokens`, 5-minute cache writes, 1-hour cache writes, and
`cache_read_input_tokens`. See `split_cache_creation` for how the 5m/1h
split is recovered when the top-level usage does not carry it directly.

Usage:
    agent_cost.py --days 30
    agent_cost.py --days 30 --project configs
    agent_cost.py --days 30 --usd
    agent_cost.py --days 30 --usd --billed 2500
    agent_cost.py --agent <id>
    agent_cost.py --days 30 --tools --sort cost --top 10
    agent_cost.py --since 2026-09-01 --reprice claude-opus-5-5

Exit codes:
    0  success, output on stdout
    1  no project directory matched
    2  no agent transcript matched --agent
"""
from __future__ import annotations

import argparse
import json
import re
import statistics
import sys
from datetime import datetime
from pathlib import Path

PROJECTS_ROOT = Path.home() / ".claude" / "projects"

SYNTHETIC_MODEL = "<synthetic>"

# Source: https://platform.claude.com/docs/en/about-claude/pricing, read on
# 2026-10-09. USD per million tokens. A model id absent here has no listed
# price - the script shows "?" rather than guess from a similar model.
# Haiku 5.5 has a higher rate when a turn's prompt is over 100,000 tokens. The
# threshold uses input_tokens + cache_creation + cache_read. The pricing page
# does not define it further.
PRICE_TABLE = {
    "claude-fable-5-1": {"input": 10, "write_5m": 12.50, "write_1h": 20, "read": 0.25, "output": 50},
    "claude-fable-5": {"input": 10, "write_5m": 12.50, "write_1h": 20, "read": 1, "output": 50},
    "claude-opus-5-5": {"input": 4, "write_5m": 5, "write_1h": 8, "read": 0.20, "output": 20},
    "claude-opus-5": {"input": 5, "write_5m": 6.25, "write_1h": 10, "read": 0.50, "output": 25},
    "claude-opus-4-8": {"input": 5, "write_5m": 6.25, "write_1h": 10, "read": 0.50, "output": 25},
    "claude-sonnet-5-5": {"input": 2, "write_5m": 2.50, "write_1h": 4, "read": 0.10, "output": 10},
    "claude-sonnet-5": {"input": 2, "write_5m": 2.50, "write_1h": 4, "read": 0.20, "output": 10},
    "claude-haiku-5-5": {"input": 0.10, "write_5m": 0.125, "write_1h": 0.20, "read": 0.01, "output": 0.50},
    "claude-haiku-4-5-20251001": {"input": 1, "write_5m": 1.25, "write_1h": 2, "read": 0.10, "output": 5},
}

LONG_PROMPT_PRICES = {
    "claude-haiku-5-5": (100_000, {"input": 0.50, "write_5m": 0.625, "write_1h": 1, "read": 0.05, "output": 2.50}),
}

SMALL_SAMPLE_THRESHOLD = 5


def parse_timestamp(ts: str | None) -> float | None:
    """Parse a top-level `timestamp` field (ISO 8601, UTC, e.g.
    "2026-09-10T05:59:11.075Z") into epoch seconds, or None when absent or
    unparseable. `fromisoformat` on Python < 3.11 does not accept a bare "Z"
    suffix, hence the explicit replace."""
    if not ts:
        return None
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


def read_jsonl_records(path: Path):
    """Yield parsed JSON records from a .jsonl file, skipping malformed lines."""
    with path.open("r", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def resolve_project_dirs(token: str | None) -> list[Path]:
    """Resolve project directories by matching `token` against directory names
    under ~/.claude/projects/ - never by string-mangling the token into the
    encoded path form. Returns every directory when token is None."""
    if not PROJECTS_ROOT.is_dir():
        print(f"error: no such directory: {PROJECTS_ROOT}", file=sys.stderr)
        sys.exit(1)

    candidates = sorted(p for p in PROJECTS_ROOT.iterdir() if p.is_dir())

    if token is None:
        return candidates

    token_lower = token.lower()
    matches = [c for c in candidates if token_lower in c.name.lower()]
    if not matches:
        print(f"error: no project directory matched '{token}' under {PROJECTS_ROOT}", file=sys.stderr)
        sys.exit(1)
    return matches


def split_cache_creation(total: int, top_split: tuple[int, int], iteration_splits: list[tuple[int, int]]) -> tuple[int, int, bool]:
    """Return (write_5m, write_1h, used_fallback) for one turn's cache writes.

    `top_split` is the turn's own (ephemeral_5m, ephemeral_1h) pair from its
    top-level `usage.cache_creation`. `iteration_splits` are the same pair
    from each of the turn's own "message"-type `usage.iterations` entries,
    when there are any. The top-level split does not always add up to
    `total` (`cache_creation_input_tokens`) - the missing tokens can sit in
    the iterations instead. When neither reconciles, the whole gap is
    counted as a 1h write and `used_fallback` is True, so the caller can
    track how often this happened."""
    top_5m, top_1h = top_split
    if top_5m + top_1h == total:
        return top_5m, top_1h, False
    if iteration_splits:
        iter_5m = sum(s[0] for s in iteration_splits)
        iter_1h = sum(s[1] for s in iteration_splits)
        if iter_5m + iter_1h == total:
            return iter_5m, iter_1h, False
    return 0, total, True


def turn_and_advisors_from_usage(usage: dict, record_model: str | None) -> tuple[tuple, list[tuple], int]:
    """Build one turn tuple, its advisor_turns, and a fallback count from one
    retained assistant record's `usage` dict and its `message.model`. Shared
    by `turns_from_transcript` (one subagent transcript, deduped per file)
    and `parse_main_records` (one main transcript, deduped per file, but one
    model/effort per message instead of one per file).

    A single message can carry an `iterations` list inside `usage`. Most
    iterations have type "message" and belong to the parent model - their
    tokens already sum into the top-level usage fields used for the turn,
    and their own cache_creation splits are used to recover a top-level
    split that does not reconcile. An iteration such as an advisor call
    (type "advisor_message") runs on a different model and is not part of
    that sum, so it becomes its own advisor_turns entry, priced separately
    so its cost is not lost and not double-counted. Advisor iterations carry
    no `speed` or `inference_geo` of their own - they share the same
    physical API response as the parent turn, so they inherit that turn's
    values."""
    fallback_count = 0
    speed = usage.get("speed")
    geo = usage.get("inference_geo")
    top_creation = usage.get("cache_creation") or {}
    top_split = (
        top_creation.get("ephemeral_5m_input_tokens", 0),
        top_creation.get("ephemeral_1h_input_tokens", 0),
    )

    advisor_turns = []
    message_iteration_splits: list[tuple[int, int]] = []
    for iteration in usage.get("iterations") or []:
        if not isinstance(iteration, dict):
            continue
        iteration_model = iteration.get("model")
        same_model_message = iteration.get("type") == "message" and (
            iteration_model is None or iteration_model == record_model
        )
        if same_model_message:
            it_creation = iteration.get("cache_creation") or {}
            message_iteration_splits.append((
                it_creation.get("ephemeral_5m_input_tokens", 0),
                it_creation.get("ephemeral_1h_input_tokens", 0),
            ))
            continue

        adv_creation = iteration.get("cache_creation") or {}
        adv_5m, adv_1h, adv_fallback = split_cache_creation(
            iteration.get("cache_creation_input_tokens", 0),
            (
                adv_creation.get("ephemeral_5m_input_tokens", 0),
                adv_creation.get("ephemeral_1h_input_tokens", 0),
            ),
            [],
        )
        if adv_fallback:
            fallback_count += 1
        advisor_turns.append((
            iteration.get("input_tokens", 0),
            adv_5m,
            adv_1h,
            iteration.get("cache_read_input_tokens", 0),
            iteration.get("output_tokens", 0),
            iteration_model or record_model or "unknown",
            speed,
            geo,
        ))

    write_5m, write_1h, used_fallback = split_cache_creation(
        usage.get("cache_creation_input_tokens", 0), top_split, message_iteration_splits
    )
    if used_fallback:
        fallback_count += 1
    turn = (
        usage.get("input_tokens", 0),
        write_5m,
        write_1h,
        usage.get("cache_read_input_tokens", 0),
        usage.get("output_tokens", 0),
        record_model,
        speed,
        geo,
    )
    return turn, advisor_turns, fallback_count


def add_tool_use_ids(message: dict, message_id: str, tool_ids: dict[str, set]) -> None:
    """Record the id of each `tool_use` content block of one assistant record
    under its `message.id`. One message streams across several records, one
    content block each, and only one record per id is retained for usage, so
    tool calls need their own accumulator. Keying on the block id keeps a
    block that repeats across records from counting twice."""
    content = message.get("content")
    if not isinstance(content, list):
        return
    for block in content:
        if isinstance(block, dict) and block.get("type") == "tool_use" and block.get("id"):
            tool_ids.setdefault(message_id, set()).add(block["id"])


def turns_from_transcript(jsonl_path: Path, cutoff: float | None = None):
    """Return (model, effort, turns, advisor_turns, fallback_count,
    tool_counts) for one subagent transcript. `tool_counts` is one tool-call
    count per entry of `turns`, in the same order.

    `turns` and `advisor_turns` are lists of
    (uncached, write_5m, write_1h, read, output, model, speed, geo) tuples,
    one per unique message.id for `turns`, and one per cross-model
    `usage.iterations` entry (such as an advisor call) for `advisor_turns`.
    `model` is the first non-synthetic message.model seen, or None if every
    assistant record is synthetic or missing. `effort` is the top-level
    `effort` field on the first assistant record, or None when absent.
    `fallback_count` is how many turns (own or advisor) needed the
    `split_cache_creation` fallback.

    `cutoff` is an epoch-seconds boundary. A record whose own top-level
    `timestamp` is older than `cutoff` is skipped entirely, before it can
    affect `model`, `effort`, or any turn - this is what lets a long-lived
    transcript report only its in-window activity. `cutoff=None` (the
    `--agent` default) disables this filter and reads every record, exactly
    as before this filter existed. A record whose `message.model` is
    "<synthetic>" is also skipped entirely: it is a zero-token Claude Code
    internal marker, never a billed turn."""
    best_by_id: dict[str, tuple[dict, str | None]] = {}
    model = None
    effort = None
    first_assistant_seen = False
    order: list[str] = []
    tool_ids: dict[str, set] = {}

    for record in read_jsonl_records(jsonl_path):
        if record.get("type") != "assistant":
            continue
        if cutoff is not None:
            ts = parse_timestamp(record.get("timestamp"))
            if ts is None or ts < cutoff:
                continue
        if not first_assistant_seen:
            effort = record.get("effort")
            first_assistant_seen = True
        message = record.get("message", {})
        record_model = message.get("model")
        if record_model == SYNTHETIC_MODEL:
            continue
        if model is None and record_model:
            model = record_model

        message_id = message.get("id")
        if message_id is None:
            continue
        add_tool_use_ids(message, message_id, tool_ids)
        usage = message.get("usage") or {}
        output_tokens = usage.get("output_tokens", 0)

        current_best = best_by_id.get(message_id)
        if current_best is None:
            order.append(message_id)
            best_by_id[message_id] = (usage, record_model)
        elif output_tokens > current_best[0].get("output_tokens", 0):
            best_by_id[message_id] = (usage, record_model)

    turns = []
    advisor_turns = []
    fallback_count = 0
    for message_id in order:
        usage, record_model = best_by_id[message_id]
        turn, turn_advisors, turn_fallback = turn_and_advisors_from_usage(usage, record_model)
        fallback_count += turn_fallback
        turns.append(turn)
        advisor_turns.extend(turn_advisors)
    tool_counts = [len(tool_ids.get(message_id, ())) for message_id in order]

    return model, effort, turns, advisor_turns, fallback_count, tool_counts


def turn_total_input(turn: tuple) -> int:
    uncached, write_5m, write_1h, read = turn[0], turn[1], turn[2], turn[3]
    return uncached + write_5m + write_1h + read


def tier_prices(model: str, turn: tuple) -> dict:
    """Return `model`'s rates for this turn. A turn whose prompt is over the model's LONG_PROMPT_PRICES threshold uses the higher rates for every token in the turn, output included."""
    long_tier = LONG_PROMPT_PRICES.get(model)
    if long_tier and turn_total_input(turn) > long_tier[0]:
        return long_tier[1]
    return PRICE_TABLE[model]


def price_turn(turn: tuple) -> float | None:
    """Return the list-price USD cost of one turn, or None when unpriceable:
    an unknown model, `speed` "fast" (an unlisted fast-mode multiplier), or
    `inference_geo` "us" (also an unlisted multiplier). An absent `speed`
    counts as standard price on every model - no transcript in a 2026-10-01
    check ever carried a "fast" value, so treating an absent `speed` as
    unpriceable was leaving out real turns, mostly on Opus models, without
    actually catching any fast-mode turn."""
    uncached, write_5m, write_1h, read, output, model, speed, geo = turn
    if model not in PRICE_TABLE:
        return None
    if speed == "fast" or geo == "us":
        return None
    prices = tier_prices(model, turn)
    cost = (
        uncached * prices["input"]
        + write_5m * prices["write_5m"]
        + write_1h * prices["write_1h"]
        + read * prices["read"]
        + output * prices["output"]
    )
    return cost / 1_000_000


def reprice_turn(turn: tuple, model: str) -> float | None:
    """Price one turn's own token split at `model`'s rates, ignoring the
    turn's own model. Same skip rule as `price_turn` for `speed` "fast" and
    `inference_geo` "us"."""
    uncached, write_5m, write_1h, read, output, _, speed, geo = turn
    if speed == "fast" or geo == "us":
        return None
    prices = tier_prices(model, turn)
    cost = (
        uncached * prices["input"]
        + write_5m * prices["write_5m"]
        + write_1h * prices["write_1h"]
        + read * prices["read"]
        + output * prices["output"]
    )
    return cost / 1_000_000


def spawn_price_turns(turns: list[tuple]) -> tuple[float, int]:
    """Return (summed USD cost of the priceable turns, count of priceable
    turns) for one spawn. An unpriceable turn is left out of the sum rather
    than voiding the whole spawn's price - the caller treats a spawn with
    zero priceable turns as having no price at all (see each call site)."""
    total = 0.0
    priced = 0
    for turn in turns:
        cost = price_turn(turn)
        if cost is not None:
            total += cost
            priced += 1
    return total, priced


def load_meta(meta_path: Path) -> dict | None:
    if not meta_path.exists():
        return None
    try:
        return json.loads(meta_path.read_text())
    except json.JSONDecodeError:
        return None


def load_task_statuses(session_file: Path) -> dict[str, str]:
    """Return {agent_id: status} from every <task-notification> block in one
    parent session file that names a <task-id>. A resumed agent fires more
    than one notification for the same id - the last one wins. The block has
    no closing tag, so it is bounded by splitting on the opening tag instead
    of matching to a close. The Task tool's own description text also
    contains the string "<task-notification>" with no <task-id> after it -
    a chunk with no <task-id> is skipped."""
    if not session_file.exists():
        return {}
    text = session_file.read_text(errors="replace")
    statuses: dict[str, str] = {}
    for chunk in text.split("<task-notification>")[1:]:
        id_match = re.search(r"<task-id>([^<]+)</task-id>", chunk)
        if not id_match:
            continue
        status_match = re.search(r"<status>([a-z_]+)</status>", chunk)
        if not status_match:
            continue
        statuses[id_match.group(1)] = status_match.group(1)
    return statuses


def collect_spawns(project_dirs: list[Path], cutoff: float | None):
    """Walk every subagents/ directory under project_dirs and return
    (spawns, skipped_count). A spawn is one processed transcript. Respawns
    are computed per subagents/ directory (one session), in file-mtime
    order, so the flag reflects real spawn order rather than filename sort -
    this scan always covers every file, regardless of `cutoff`, so a spawn
    outside the window still counts toward respawn order for spawns inside
    it. `cutoff` only skips the (possibly large) per-record parse of a file
    whose own mtime is already older than the window - a file's mtime is
    never older than any record inside it, so this cannot drop an in-window
    turn. The per-record `timestamp` filter inside `turns_from_transcript`
    is what actually decides which turns count."""
    spawns = []
    skipped = 0

    subagents_dirs = sorted(
        {p.parent for pd in project_dirs for p in pd.glob("*/subagents/agent-*.jsonl")}
    )

    for subagents_dir in subagents_dirs:
        session_file = subagents_dir.parent.parent / f"{subagents_dir.parent.name}.jsonl"
        statuses = load_task_statuses(session_file)

        jsonl_paths = sorted(subagents_dir.glob("agent-*.jsonl"), key=lambda p: p.stat().st_mtime)
        seen_keys: set[tuple[str, str]] = set()

        for jsonl_path in jsonl_paths:
            meta_path = jsonl_path.with_name(jsonl_path.stem + ".meta.json")
            meta = load_meta(meta_path)
            if meta is None:
                skipped += 1
                continue

            agent_type = meta.get("agentType", "?")
            # A named teammate writes its teammate name into agentType (e.g.
            # "altitude-2") and its real type into customAgentType (e.g.
            # "reviewer"). Group and display by customAgentType when it is
            # set, since agentType is a per-spawn label in that case, not a
            # task category. A spawn with no customAgentType keeps its own
            # agentType - never guess one.
            row_type = meta.get("customAgentType") or agent_type
            description = meta.get("description", "")
            # Keyed on row_type, not the raw agentType: a named teammate's
            # agentType is unique per spawn (e.g. "reuse", "reuse-2"), so
            # keying on it would hide real respawns of the same row_type +
            # description pair (e.g. three "reviewer" teammates all doing
            # "Reuse review"). The subagents_dir loop already scopes this
            # per session.
            key = (row_type, description)
            is_respawn = key in seen_keys
            seen_keys.add(key)

            mtime = jsonl_path.stat().st_mtime
            if cutoff is not None and mtime < cutoff:
                model, effort, turns, advisor_turns, fallback_count, tool_counts = None, None, [], [], 0, []
            else:
                model, effort, turns, advisor_turns, fallback_count, tool_counts = turns_from_transcript(jsonl_path, cutoff)
            # The task-id a task-notification names is the agent id in the
            # transcript file name - the same id cmd_agent matches against.
            # A teammate never gets its own notification (only the top-level
            # Agent-tool call does), so its status is unknown, not "-":
            # "-" is a display choice made when a whole row lacks a status.
            agent_id = jsonl_path.stem[len("agent-"):]
            status = statuses.get(agent_id)
            spawns.append({
                "path": jsonl_path,
                "agent_type": row_type,
                "description": description,
                "model": model or "unknown",
                "effort": effort or "-",
                "status": status,
                "turns": turns,
                "tool_calls": tool_counts,
                "is_respawn": is_respawn,
                "is_advisor": False,
                "is_main": False,
                "mtime": mtime,
                "fallback_count": fallback_count,
            })

            # Advisor (or other cross-model) iterations get their own pseudo
            # rows, grouped separately per model, so their cost is visible
            # without inflating the real spawn's turn/token totals or count.
            # is_advisor keeps them out of the real spawn count and the
            # respawn count in the footer and table. Status is always
            # unknown here, not inherited from the parent spawn: the parent
            # spawn's own row already counts that run's status once, and
            # inheriting it here would count the same run twice.
            by_advisor_model: dict[str, list[tuple]] = {}
            for adv_turn in advisor_turns:
                by_advisor_model.setdefault(adv_turn[5], []).append(adv_turn)
            for adv_model, adv_turns in by_advisor_model.items():
                spawns.append({
                    "path": jsonl_path,
                    "agent_type": f"{row_type} [advisor]",
                    "description": description,
                    "model": adv_model,
                    # The transcript does not record the advisor's own
                    # effort setting, so advisor rows always group under "-".
                    "effort": "-",
                    "status": None,
                    "turns": adv_turns,
                    "tool_calls": [],
                    "is_respawn": False,
                    "is_advisor": True,
                    "is_main": False,
                    "mtime": mtime,
                    "fallback_count": 0,
                })

    return spawns, skipped


def parse_main_records(jsonl_path: Path, cutoff: float | None):
    """Return (records, fallback_count) for one main conversation file.

    `records` is a list of dicts, one per unique in-window `message.id` in
    this file: {"message_id", "timestamp" (epoch), "model", "effort",
    "turn", "advisor_turns"}. This dedupes the same per-call content-block
    streaming `turns_from_transcript` dedupes for a subagent transcript, but
    keeps each message's own `model` and top-level `effort` rather than one
    pair for the whole file, because a main session can change model or
    effort mid-session. `collect_main_parts` does a further dedupe across
    every main file, for sessions resumed or forked into more than one
    file."""
    best_by_id: dict[str, tuple[int, dict, str | None, str | None, float | None]] = {}
    order: list[str] = []
    tool_ids: dict[str, set] = {}

    for record in read_jsonl_records(jsonl_path):
        if record.get("type") != "assistant":
            continue
        ts = parse_timestamp(record.get("timestamp"))
        if cutoff is not None and (ts is None or ts < cutoff):
            continue
        message = record.get("message", {}) or {}
        record_model = message.get("model")
        if record_model == SYNTHETIC_MODEL:
            continue
        message_id = message.get("id")
        if message_id is None:
            continue
        add_tool_use_ids(message, message_id, tool_ids)
        effort = record.get("effort")
        usage = message.get("usage") or {}
        output_tokens = usage.get("output_tokens", 0)

        current = best_by_id.get(message_id)
        if current is None:
            order.append(message_id)
            best_by_id[message_id] = (output_tokens, usage, record_model, effort, ts)
        elif output_tokens > current[0]:
            best_by_id[message_id] = (output_tokens, usage, record_model, effort, ts)

    records = []
    fallback_count = 0
    for message_id in order:
        output_tokens, usage, record_model, effort, ts = best_by_id[message_id]
        turn, advisor_turns, turn_fallback = turn_and_advisors_from_usage(usage, record_model)
        fallback_count += turn_fallback
        records.append({
            "message_id": message_id,
            "timestamp": ts,
            "model": record_model or "unknown",
            "effort": effort,
            "turn": turn,
            "advisor_turns": advisor_turns,
            "tool_calls": len(tool_ids.get(message_id, ())),
        })
    return records, fallback_count


def collect_main_parts(project_dirs: list[Path], cutoff: float | None):
    """Build main-conversation pseudo-spawns and return
    (main_entries, session_count, duplicate_id_count, fallback_count).

    Each main file is `<project>/<session>.jsonl`, a direct child of a
    project directory (never under a subagents/ directory, and never a file
    with an `isSidechain: true` record). A main session can be resumed or
    forked into more than one file, duplicating the same `message.id`
    across files - this is deduped here, across every main file read, not
    per file: for each `message.id` seen in more than one file, the turn
    data comes from the copy with the largest `output_tokens`, and that
    turn is credited to the file whose copy has the earliest `timestamp`
    (its session owns the turn for grouping purposes). `duplicate_id_count`
    is how many distinct message ids this applied to.

    The unit of a `main` row is one (session, model, effort) "part" - one
    main_entries dict per part, with that part's turns, so the existing
    spawn-grouping code in `cmd_table` can aggregate `main` rows exactly as
    it aggregates subagent rows: `spawns` counts parts, and `median turns`
    is turns per part. The main thread's own advisor calls become their own
    `main [advisor]` parts, grouped by (session, advisor model), effort
    "-"."""
    main_files = sorted({p for pd in project_dirs for p in pd.glob("*.jsonl")})

    by_message_id: dict[str, list[tuple[Path, dict]]] = {}
    fallback_count = 0
    for jsonl_path in main_files:
        if cutoff is not None and jsonl_path.stat().st_mtime < cutoff:
            continue
        records, file_fallback = parse_main_records(jsonl_path, cutoff)
        fallback_count += file_fallback
        for rec in records:
            by_message_id.setdefault(rec["message_id"], []).append((jsonl_path, rec))

    parts: dict[tuple[str, str, str], list[tuple]] = {}
    part_tool_calls: dict[tuple[str, str, str], list[int]] = {}
    advisor_parts: dict[tuple[str, str], list[tuple]] = {}
    session_ids: set[str] = set()
    duplicate_id_count = 0

    for copies in by_message_id.values():
        if len(copies) > 1:
            duplicate_id_count += 1
        _, retained_rec = max(copies, key=lambda c: c[1]["turn"][4])
        credited_path, _ = min(copies, key=lambda c: (c[1]["timestamp"] is None, c[1]["timestamp"]))
        session_id = credited_path.stem
        session_ids.add(session_id)

        effort = retained_rec["effort"] or "-"
        model = retained_rec["model"]
        parts.setdefault((session_id, model, effort), []).append(retained_rec["turn"])
        part_tool_calls.setdefault((session_id, model, effort), []).append(retained_rec["tool_calls"])

        for adv_turn in retained_rec["advisor_turns"]:
            advisor_parts.setdefault((session_id, adv_turn[5]), []).append(adv_turn)

    main_entries = []
    for (session_id, model, effort), turns in parts.items():
        main_entries.append({
            "agent_type": "main",
            "model": model,
            "effort": effort,
            "status": None,
            "turns": turns,
            "tool_calls": part_tool_calls[(session_id, model, effort)],
            "is_respawn": False,
            "is_advisor": False,
            "is_main": True,
            "fallback_count": 0,
        })
    for (session_id, adv_model), turns in advisor_parts.items():
        main_entries.append({
            "agent_type": "main [advisor]",
            "model": adv_model,
            "effort": "-",
            "status": None,
            "turns": turns,
            "tool_calls": [],
            "is_respawn": False,
            "is_advisor": True,
            "is_main": True,
            "fallback_count": 0,
        })

    return main_entries, len(session_ids), duplicate_id_count, fallback_count


def percentile(values: list[float], pct: float) -> float:
    """Linear-interpolation percentile, no third-party deps."""
    if not values:
        return 0.0
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    rank = (len(ordered) - 1) * (pct / 100)
    lower = int(rank)
    upper = min(lower + 1, len(ordered) - 1)
    if lower == upper:
        return ordered[lower]
    return ordered[lower] * (upper - rank) + ordered[upper] * (rank - lower)


def cmd_table(project_dirs: list[Path], days: int, usd: bool, billed: float | None = None,
              tools: bool = False, sort: str = "spawns", top: int | None = None,
              reprice: list[str] | None = None, since: datetime | None = None) -> None:
    reprice = reprice or []
    cutoff = None
    if since is not None:
        cutoff = since.timestamp()
    elif days is not None:
        import time
        cutoff = time.time() - days * 86400

    spawns, skipped = collect_spawns(project_dirs, cutoff)
    sub_in_range = [s for s in spawns if cutoff is None or s["mtime"] >= cutoff]

    main_entries, main_session_count, duplicate_id_count, main_fallback_count = (
        collect_main_parts(project_dirs, cutoff)
    )

    in_range = sub_in_range + main_entries

    groups: dict[tuple[str, str, str], list[dict]] = {}
    for spawn in in_range:
        groups.setdefault((spawn["agent_type"], spawn["model"], spawn["effort"]), []).append(spawn)

    rows = []
    for (agent_type, model, effort), group_spawns in groups.items():
        is_main = group_spawns[0]["is_main"]
        turn_counts = [len(s["turns"]) for s in group_spawns]
        uncached_totals = [sum(t[0] for t in s["turns"]) for s in group_spawns]
        write_totals = [sum(t[1] + t[2] for t in s["turns"]) for s in group_spawns]
        read_totals = [sum(t[3] for t in s["turns"]) for s in group_spawns]
        output_totals = [sum(t[4] for t in s["turns"]) for s in group_spawns]
        input_totals = [
            u + w + r for u, w, r in zip(uncached_totals, write_totals, read_totals)
        ]
        input_per_turn = [
            (total / count) if count else 0
            for total, count in zip(input_totals, turn_counts)
        ]
        respawns = sum(1 for s in group_spawns if s["is_respawn"])

        known_statuses = [s["status"] for s in group_spawns if s["status"] is not None]
        failed_killed = sum(1 for st in known_statuses if st in ("failed", "killed"))

        # Turn-level pricing: an unpriceable turn is left out of its spawn's
        # sum, not the whole spawn - a spawn only has no price at all when
        # none of its turns priced.
        price_results = [spawn_price_turns(s["turns"]) for s in group_spawns]
        spawn_prices = [total if priced_n else None for total, priced_n in price_results]
        priced_prices = [p for p in spawn_prices if p is not None]
        priced_turns = sum(p[1] for p in price_results)

        tool_calls = [n for s in group_spawns for n in s["tool_calls"]]
        tool_using = [n for n in tool_calls if n >= 1]
        reprice_totals = {}
        for target in reprice:
            repriced = [c for c in (reprice_turn(t, target) for s in group_spawns for t in s["turns"])
                        if c is not None]
            reprice_totals[target] = sum(repriced) if repriced else None

        rows.append({
            "agent_type": agent_type,
            "model": model,
            "effort": effort,
            "is_main": is_main,
            "is_advisor": group_spawns[0]["is_advisor"],
            "tool_using_turns": len(tool_using),
            "tool_calls_total": sum(tool_using),
            "one_call_turns": sum(1 for n in tool_using if n == 1),
            "reprice_totals": reprice_totals,
            "spawns": len(group_spawns),
            "median_turns": statistics.median(turn_counts),
            "p90_turns": percentile(turn_counts, 90),
            "median_uncached": statistics.median(uncached_totals),
            "median_write": statistics.median(write_totals),
            "median_read": statistics.median(read_totals),
            "median_input_per_turn": statistics.median(input_per_turn),
            "median_output": statistics.median(output_totals),
            "total_input": sum(input_totals),
            "p90_input": percentile(input_totals, 90),
            "respawns": respawns,
            "known_statuses": len(known_statuses),
            "failed_killed": failed_killed,
            "total_turns": sum(turn_counts),
            "priced_turns": priced_turns,
            "median_price": statistics.median(priced_prices) if priced_prices else None,
            "total_price": sum(priced_prices) if priced_prices else None,
        })

    tie_key = lambda r: (r["agent_type"], r["model"], r["effort"])
    if sort == "cost":
        rows.sort(key=lambda r: (r["total_price"] is None, -(r["total_price"] or 0)) + tie_key(r))
    elif sort == "input":
        rows.sort(key=lambda r: (-r["total_input"],) + tie_key(r))
    else:
        rows.sort(key=lambda r: (-r["spawns"],) + tie_key(r))
    all_rows = rows
    rows = rows[:top] if top is not None else rows

    header = ["agentType", "model", "effort", "spawns", "median turns", "p90 turns",
              "median uncached", "median cache write", "median cache read",
              "median input/turn", "median output tokens", "total input", "p90 input",
              "respawns", "failed/killed"]
    if tools:
        header += ["calls/turn", "1-call %"]
    if usd:
        header += ["priced", "median $", "total $"]
        header += [f"$ at {m}" for m in reprice]
    print("| " + " | ".join(header) + " |")
    print("|" + "|".join(["---"] * len(header)) + "|")
    for row in rows:
        spawns_cell = f"{row['spawns']}*" if row["spawns"] < SMALL_SAMPLE_THRESHOLD else str(row["spawns"])
        failed_killed_cell = (
            f"{row['failed_killed']}/{row['known_statuses']}" if row["known_statuses"] else "-"
        )
        respawns_cell = "-" if row["is_main"] else row["respawns"]
        values = [
            row["agent_type"], row["model"], row["effort"], spawns_cell,
            round(row["median_turns"], 1), round(row["p90_turns"], 1),
            round(row["median_uncached"]), round(row["median_write"]), round(row["median_read"]),
            round(row["median_input_per_turn"]), round(row["median_output"]),
            row["total_input"], round(row["p90_input"]),
            respawns_cell, failed_killed_cell,
        ]
        if tools:
            if row["tool_using_turns"]:
                values += [round(row["tool_calls_total"] / row["tool_using_turns"], 1),
                           f"{round(row['one_call_turns'] / row['tool_using_turns'] * 100)}%"]
            else:
                values += ["-", "-"]
        if usd:
            priced_cell = f"{row['priced_turns']}/{row['total_turns']}"
            median_price_cell = round(row["median_price"], 4) if row["median_price"] is not None else "?"
            total_price_cell = round(row["total_price"], 4) if row["total_price"] is not None else "?"
            values += [priced_cell, median_price_cell, total_price_cell]
            for target in reprice:
                cell = row["reprice_totals"][target]
                values.append(round(cell, 4) if cell is not None else "?")
        print("| " + " | ".join(str(v) for v in values) + " |")

    if usd:
        main_total = sum(r["total_price"] for r in all_rows if r["is_main"] and r["total_price"] is not None)
        subagent_total = sum(r["total_price"] for r in all_rows if not r["is_main"] and r["total_price"] is not None)
        grand_total = main_total + subagent_total
        print(f"\nmain total: ${round(main_total, 2)}")
        print(f"subagent total: ${round(subagent_total, 2)}")
        print(f"grand total: ${round(grand_total, 2)}")
        if billed is not None:
            gap = grand_total - billed
            gap_pct = (gap / billed * 100) if billed else float("nan")
            print(f"billed (user-supplied): ${round(billed, 2)}")
            print(f"gap: ${round(gap, 2)} ({round(gap_pct, 1)}% over billed)")
        advisor_total = sum(r["total_price"] for r in all_rows if r["is_advisor"] and r["total_price"] is not None)
        by_model: dict[str, float] = {}
        for r in all_rows:
            if r["total_price"] is not None:
                by_model[r["model"]] = by_model.get(r["model"], 0.0) + r["total_price"]
        share = lambda amount: round(amount / grand_total * 100, 1) if grand_total else 0.0
        print("\ncost split, share of grand total:")
        print(f"  main: ${round(main_total, 2)} ({share(main_total)}%)")
        print(f"  subagent: ${round(subagent_total, 2)} ({share(subagent_total)}%)")
        print(f"  advisor (main and subagent [advisor] rows, also included in main and subagent above): "
              f"${round(advisor_total, 2)} ({share(advisor_total)}%)")
        print("cost by model:")
        for m, amount in sorted(by_model.items(), key=lambda kv: -kv[1]):
            print(f"  {m}: ${round(amount, 2)} ({share(amount)}%)")
        for target in reprice:
            repriced_total = sum(r["reprice_totals"][target] for r in all_rows
                                 if r["reprice_totals"][target] is not None)
            print(f"grand total at {target}: ${round(repriced_total, 2)}")
    else:
        print()

    real_count = sum(1 for s in in_range if not s["is_advisor"] and not s["is_main"])
    # An [advisor] entry is one spawn's calls to one advisor model, not one
    # call - sum len(turns) to count the calls inside it, not the entries.
    advisor_count = sum(len(s["turns"]) for s in in_range if s["is_advisor"])
    fallback_count = sum(s["fallback_count"] for s in sub_in_range) + main_fallback_count

    if since is not None:
        window = f"since {since.strftime('%Y-%m-%d')}"
    else:
        window = f"last {days} days" if days is not None else "all time"
    print(f"{real_count} spawns, {window}, {skipped} files skipped (no meta.json or bad JSON).")
    print(f"{main_session_count} main sessions, {window}, counted separately from the spawn count above.")
    print(f"{duplicate_id_count} message ids appeared in more than one main file "
          "(resumed or forked sessions) - the earliest-timestamp file was credited, the rest dropped.")
    print(f"{advisor_count} advisor calls, in their own [advisor] rows, not counted as spawns.")
    print("Respawns count is a proxy for retries, not an exact retry count. main rows show '-': "
          "a main session is not a retryable spawn.")
    print("A spawns count marked * means fewer than 5 spawns (or parts, for a main row) - "
          "read that row's medians with caution.")
    print("failed/killed shows failed-or-killed over spawns with a known run status. "
          "A teammate never gets its own status, so its rows show '-'. main rows always show '-': "
          "a main session carries no run status. "
          "'completed' means the run finished - it does not mean the run was correct.")
    if fallback_count:
        print(f"{fallback_count} turns could not reconcile a cache-write split against "
              "cache_creation_input_tokens, so the whole gap was counted as a 1h write.")
    if usd:
        total_turns_all = sum(len(s["turns"]) for s in in_range)
        total_priced_turns_all = sum(spawn_price_turns(s["turns"])[1] for s in in_range)
        unpriced_turns = total_turns_all - total_priced_turns_all
        fully_unpriced_spawns = sum(
            1 for s in in_range if s["turns"] and spawn_price_turns(s["turns"])[1] == 0
        )
        absent_speed_priced = sum(
            1 for s in in_range for t in s["turns"]
            if t[6] is None and t[7] != "us" and t[5] in PRICE_TABLE
        )
        print("priced counts turns, not spawns: a spawn's unpriceable turns are left out of its "
              "sum, the rest of the spawn still prices.")
        print(f"{unpriced_turns} turns are unpriceable (unlisted model, fast mode or us-geo pricing) "
              "and are left out of every total.")
        if fully_unpriced_spawns:
            print(f"{fully_unpriced_spawns} spawns have no priceable turn at all "
                  "and are left out of every median $ and total $ figure.")
        print(f"{absent_speed_priced} turns had no recorded speed and were priced as standard.")
        print("$ figures are a list-price estimate, not a billed amount.")


def cmd_agent(project_dirs: list[Path], agent_token: str, usd: bool) -> None:
    all_paths = sorted(
        p for pd in project_dirs for p in pd.glob("*/subagents/agent-*.jsonl")
    )
    exact = [p for p in all_paths if p.stem[len("agent-"):] == agent_token]
    matches = exact or [p for p in all_paths if agent_token.lower() in p.stem[len("agent-"):].lower()]

    if not matches:
        print(f"error: no agent transcript matched '{agent_token}'", file=sys.stderr)
        sys.exit(2)
    if len(matches) > 1:
        print(f"error: '{agent_token}' matched {len(matches)} transcripts, ambiguous:", file=sys.stderr)
        for m in matches:
            print(f"  {m}", file=sys.stderr)
        sys.exit(2)

    jsonl_path = matches[0]
    meta_path = jsonl_path.with_name(jsonl_path.stem + ".meta.json")
    meta = load_meta(meta_path) or {}
    model, effort, turns, advisor_turns, fallback_count, _tool_counts = turns_from_transcript(jsonl_path)

    uncached_total = sum(t[0] for t in turns)
    write_5m_total = sum(t[1] for t in turns)
    write_1h_total = sum(t[2] for t in turns)
    read_total = sum(t[3] for t in turns)
    output_total = sum(t[4] for t in turns)
    input_total = uncached_total + write_5m_total + write_1h_total + read_total

    session_file = jsonl_path.parent.parent.parent / f"{jsonl_path.parent.parent.name}.jsonl"
    status = load_task_statuses(session_file).get(jsonl_path.stem[len("agent-"):])

    print(f"agent-id: {agent_token}")
    print(f"path: {jsonl_path}")
    print(f"agentType: {meta.get('agentType', '?')}")
    custom_agent_type = meta.get("customAgentType")
    if custom_agent_type:
        print(f"customAgentType: {custom_agent_type}")
    print(f"description: {meta.get('description', '')}")
    print(f"model: {model or 'unknown'}")
    print(f"effort: {effort or '-'}")
    print(f"status: {status or '-'}")
    print(f"turns: {len(turns)}")
    print(f"input tokens: {input_total} "
          f"(uncached {uncached_total}, 5m write {write_5m_total}, "
          f"1h write {write_1h_total}, cache read {read_total})")
    print(f"output tokens: {output_total}")
    if fallback_count:
        print(f"{fallback_count} turns used the 1h-write fallback (see split_cache_creation).")
    if usd:
        price_total, priced_n = spawn_price_turns(turns)
        if priced_n == 0:
            print("estimated cost: ? (no priceable turn in this spawn)" if turns else "estimated cost: ? (no turns)")
        elif priced_n == len(turns):
            print(f"estimated cost: ${round(price_total, 4)}")
        else:
            print(f"estimated cost: ${round(price_total, 4)} ({priced_n}/{len(turns)} turns priced, "
                  "the rest were unpriceable and left out)")

    if advisor_turns:
        by_model: dict[str, list[tuple]] = {}
        for adv_turn in advisor_turns:
            by_model.setdefault(adv_turn[5], []).append(adv_turn)
        print("advisor calls (separate model, not in the turns above):")
        for adv_model, calls in by_model.items():
            adv_input_total = sum(turn_total_input(c) for c in calls)
            adv_output_total = sum(c[4] for c in calls)
            line = (f"  model: {adv_model}, calls: {len(calls)}, "
                    f"input tokens: {adv_input_total}, output tokens: {adv_output_total}")
            if usd:
                adv_price_total, adv_priced_n = spawn_price_turns(calls)
                if adv_priced_n == 0:
                    line += ", estimated cost: ?"
                elif adv_priced_n == len(calls):
                    line += f", estimated cost: ${round(adv_price_total, 4)}"
                else:
                    line += f", estimated cost: ${round(adv_price_total, 4)} ({adv_priced_n}/{len(calls)} calls priced)"
            print(line)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--days", type=int, default=None, help="Only include spawns from the last N days (default 7). Ignored with --agent.")
    parser.add_argument("--project", default=None, help="Substring to match against a directory name under ~/.claude/projects/")
    parser.add_argument("--agent", default=None, help="Print turns and tokens for one spawn id, ignoring --days")
    parser.add_argument("--usd", action="store_true", help="Add a list-price USD estimate, per the price table in this script")
    parser.add_argument("--billed", type=float, default=None,
                         help="Compare the USD estimate against this billed figure, e.g. from the "
                              "claude.ai usage page for the same window. Implies --usd.")
    parser.add_argument("--tools", action="store_true",
                         help="Add calls/turn and 1-call % columns (tool calls per tool-using turn).")
    parser.add_argument("--sort", choices=["spawns", "cost", "input"], default="spawns",
                         help="Row order: spawns (default), cost (descending total $, implies --usd), or input (descending total input).")
    parser.add_argument("--top", type=int, default=None, help="Print only the first N rows after sorting. Totals still cover every row.")
    parser.add_argument("--reprice", action="append", default=[], metavar="MODEL",
                         help="Add a '$ at MODEL' column pricing every turn at MODEL's rates. Implies --usd. May repeat.")
    parser.add_argument("--since", default=None, metavar="YYYY-MM-DD",
                         help="Start the window at local midnight of this date. Cannot be combined with --days.")
    args = parser.parse_args()
    if args.since is not None:
        if args.days is not None:
            parser.error("--since cannot be combined with --days")
        try:
            args.since = datetime.strptime(args.since, "%Y-%m-%d")
        except ValueError:
            parser.error(f"--since expects YYYY-MM-DD, got '{args.since}'")
    if args.days is None:
        args.days = 7
    for model in args.reprice:
        if model not in PRICE_TABLE:
            parser.error(f"--reprice: unknown model '{model}'. Known: {', '.join(PRICE_TABLE)}")
    if args.billed is not None or args.sort == "cost" or args.reprice:
        args.usd = True

    project_dirs = resolve_project_dirs(args.project)

    if args.agent:
        cmd_agent(project_dirs, args.agent, args.usd)
        return

    cmd_table(project_dirs, args.days, args.usd, args.billed,
              args.tools, args.sort, args.top, args.reprice, args.since)


if __name__ == "__main__":
    main()
