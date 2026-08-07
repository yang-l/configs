#!/usr/bin/env python3
"""Mine Claude Code session transcripts for distill-skill.

Stdlib only (json/pathlib/argparse) - no third-party deps, no shell-quoting
risk. This script is deliberately dumb: it resolves a project directory,
lists sessions, and emits filtered transcript text. It never decides which
session or which subagent matters - that judgment call belongs to the
researcher agent that consumes this script's output.

Never reads sessions-index.json: it is stale (confirmed zero overlap between
its indexed session IDs and the real .jsonl files present in a project dir,
and it only exists in a handful of project dirs to begin with). The manifest
is always built from the ai-title records inside the .jsonl files themselves.

Usage:
    mine_sessions.py --project <token> --list
    mine_sessions.py --project <token> --session <session-id>
    mine_sessions.py --session <session-id>   # searches all project dirs

Exit codes:
    0  success, output on stdout
    1  no project directory matched / ambiguous match
    2  no sessions found for the resolved project
    3  session id not found
    4  filtering produced empty output (nothing procedure-relevant found)
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECTS_ROOT = Path.home() / ".claude" / "projects"

# Below this size, a session transcript is almost always a stub (a mode
# ping, an aborted prompt, a one-line question) - not worth listing unless
# it already carries an ai-title or last-prompt record.
MIN_MEANINGFUL_BYTES = 10 * 1024

# Tool result / tool_use bodies longer than this are truncated in filtered
# output - full bodies (especially successful command output) are exactly
# the verbosity this script exists to strip out.
MAX_BLOCK_CHARS = 2000

ERROR_MARKERS = ("error", "Error", "ERROR", "failed", "Failed", "FAILED", "traceback", "Traceback")


def resolve_project_dir(token: str | None) -> Path:
    """Resolve a project directory by matching `token` against directory
    names under ~/.claude/projects/ - never by string-mangling the given
    token into the encoded path form (that encoding is lossy and cannot be
    reconstructed reliably)."""
    if not PROJECTS_ROOT.is_dir():
        print(f"error: no such directory: {PROJECTS_ROOT}", file=sys.stderr)
        sys.exit(1)

    candidates = sorted(p for p in PROJECTS_ROOT.iterdir() if p.is_dir())

    if token is None:
        if len(candidates) == 1:
            return candidates[0]
        print("error: --project is required when multiple project directories exist:", file=sys.stderr)
        for c in candidates:
            print(f"  {c.name}", file=sys.stderr)
        sys.exit(1)

    token_lower = token.lower()
    matches = [c for c in candidates if token_lower in c.name.lower()]

    if len(matches) == 0:
        print(f"error: no project directory matched '{token}' under {PROJECTS_ROOT}", file=sys.stderr)
        print("available directories:", file=sys.stderr)
        for c in candidates:
            print(f"  {c.name}", file=sys.stderr)
        sys.exit(1)

    if len(matches) > 1:
        print(f"error: '{token}' matched {len(matches)} project directories, ambiguous:", file=sys.stderr)
        for c in matches:
            print(f"  {c.name}", file=sys.stderr)
        print("re-run with a more specific --project token", file=sys.stderr)
        sys.exit(1)

    return matches[0]


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


def extract_title(session_path: Path) -> str | None:
    """Extract a title for a session using the fallback chain:
    ai-title -> last-prompt -> first user message -> None (skip).
    The final fallback (first user message) is only used if the file is
    at least MIN_MEANINGFUL_BYTES - below that, a session is treated as
    noise unless it already has an explicit ai-title or last-prompt."""
    ai_title = None
    last_prompt = None
    first_user_text = None

    for record in read_jsonl_records(session_path):
        rtype = record.get("type")
        if rtype == "ai-title" and ai_title is None:
            ai_title = record.get("aiTitle")
        elif rtype == "last-prompt" and last_prompt is None:
            last_prompt = record.get("lastPrompt") or record.get("prompt")
        elif rtype == "user" and first_user_text is None:
            content = record.get("message", {}).get("content")
            if isinstance(content, str):
                first_user_text = content
            elif isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "text":
                        first_user_text = block.get("text")
                        break

    if ai_title:
        return ai_title
    if last_prompt:
        return last_prompt.strip().splitlines()[0][:120]
    if session_path.stat().st_size >= MIN_MEANINGFUL_BYTES and first_user_text:
        return first_user_text.strip().splitlines()[0][:120]
    return None


def cmd_list(project_dir: Path) -> None:
    entries = []
    for path in project_dir.glob("*.jsonl"):
        title = extract_title(path)
        if title is None:
            continue
        entries.append((path.stat().st_mtime, path.stem, title))

    if not entries:
        print(f"error: no sessions found for project directory {project_dir}", file=sys.stderr)
        print("(sessions-index.json was deliberately not consulted - it is stale)", file=sys.stderr)
        sys.exit(2)

    entries.sort(key=lambda e: e[0], reverse=True)
    for mtime, session_id, title in entries:
        from datetime import datetime
        date_str = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")
        print(f"{date_str}\t{session_id}\t{title}")


def is_error_text(text: str) -> bool:
    return any(marker in text for marker in ERROR_MARKERS)


def truncate(text: str, limit: int = MAX_BLOCK_CHARS) -> str:
    text = text.strip()
    if len(text) <= limit:
        return text
    return text[:limit] + f"... [truncated, {len(text) - limit} more chars]"


def format_tool_use(block: dict) -> str:
    name = block.get("name", "?")
    inp = block.get("input", {}) or {}
    if name == "Bash":
        return f"TOOL Bash: {inp.get('command', '')}"
    if name in ("Read", "Write", "Edit", "MultiEdit"):
        return f"TOOL {name}: {inp.get('file_path', '')}"
    if name in ("Grep", "Glob"):
        return f"TOOL {name}: pattern={inp.get('pattern', '')} path={inp.get('path', '')}"
    if name == "Agent":
        return f"TOOL Agent: {inp.get('description', '')}"
    # Generic fallback: name + a short repr of the input keys/values.
    short_input = truncate(json.dumps(inp), 300)
    return f"TOOL {name}: {short_input}"


def format_tool_result(block: dict) -> str | None:
    content = block.get("content")
    text = ""
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        parts = [c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text"]
        text = "\n".join(parts)

    is_error_flag = bool(block.get("is_error"))
    if is_error_flag or is_error_text(text):
        return f"RESULT (error): {truncate(text)}"
    # Successful tool output is exactly the verbosity this script drops.
    return None


def filter_transcript(path: Path, header: str | None = None) -> str:
    lines = []
    if header:
        lines.append(f"=== {header} ===")

    for record in read_jsonl_records(path):
        rtype = record.get("type")
        if rtype not in ("user", "assistant"):
            continue

        message = record.get("message", {})
        role = message.get("role", rtype)
        content = message.get("content")

        if isinstance(content, str):
            if content.strip():
                lines.append(f"{role.upper()}: {truncate(content)}")
            continue

        if not isinstance(content, list):
            continue

        for block in content:
            if not isinstance(block, dict):
                continue
            btype = block.get("type")
            if btype == "text":
                text = block.get("text", "")
                if text.strip():
                    lines.append(f"{role.upper()}: {truncate(text)}")
            elif btype == "tool_use":
                lines.append(format_tool_use(block))
            elif btype == "tool_result":
                formatted = format_tool_result(block)
                if formatted:
                    lines.append(formatted)
            # "thinking" blocks are intentionally dropped: they are
            # internal reasoning, not the decisions/commands a rebuilt
            # procedure needs, and they are the single biggest source of
            # raw transcript bulk.

    return "\n".join(lines)


def cmd_session(project_dir: Path | None, session_id: str) -> None:
    search_dirs = [project_dir] if project_dir else sorted(
        p for p in PROJECTS_ROOT.iterdir() if p.is_dir()
    )

    session_path = None
    owning_dir = None
    for d in search_dirs:
        candidate = d / f"{session_id}.jsonl"
        if candidate.exists():
            session_path = candidate
            owning_dir = d
            break

    if session_path is None:
        print(f"error: session {session_id} not found (searched {len(search_dirs)} project dir(s))", file=sys.stderr)
        sys.exit(3)

    sections = [filter_transcript(session_path, header=f"MAIN SESSION {session_id}")]

    subagents_dir = owning_dir / session_id / "subagents"
    if subagents_dir.is_dir():
        for meta_path in sorted(subagents_dir.glob("*.meta.json")):
            agent_jsonl = meta_path.with_name(meta_path.name[: -len(".meta.json")] + ".jsonl")
            if not agent_jsonl.exists():
                continue
            try:
                meta = json.loads(meta_path.read_text())
            except json.JSONDecodeError:
                meta = {}
            header = f"SUBAGENT {meta.get('agentType', '?')}: {meta.get('description', meta_path.stem)}"
            sections.append(filter_transcript(agent_jsonl, header=header))

    output = "\n\n".join(s for s in sections if s.strip())

    if not output.strip():
        print(f"error: filtering session {session_id} produced no output - no procedure-relevant content found", file=sys.stderr)
        sys.exit(4)

    print(output)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project", default=None, help="Substring to match against a directory name under ~/.claude/projects/")
    parser.add_argument("--list", action="store_true", help="List sessions in the resolved project directory")
    parser.add_argument("--session", default=None, help="Session id to filter and print")
    args = parser.parse_args()

    if not args.list and not args.session:
        parser.error("one of --list or --session is required")

    if args.list:
        project_dir = resolve_project_dir(args.project)
        cmd_list(project_dir)
        return

    project_dir = resolve_project_dir(args.project) if args.project else None
    cmd_session(project_dir, args.session)


if __name__ == "__main__":
    main()
