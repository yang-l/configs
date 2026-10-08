#!/usr/bin/env python3
# PreToolUse hook on Bash: deny file reads and typed file writes that go
# through the shell, so the Read, Edit, and Write tools (and their permission
# rules and hooks) handle them instead.
# grep and find stay allowed: native Claude Code builds have no Grep or Glob
# tool and route these Bash commands to embedded ugrep and bfs instead.
# Text matching only: it catches the common forms, not every route.
import datetime
import json
import os
import re
import shlex
import sys

SEPARATORS = {"|", "|&", "||", "&&", ";", ";;", "&", "(", ")", "\n"}
REDIRECTS = {">", ">>", ">|", "&>", "&>>", "<", "<<", "<<<", ">&", "<&", "<>"}
WRAPPERS = {"env", "sudo", "command", "nohup", "time", "exec", "then", "do", "else", "elif", "{", "!"}
NUMBER = re.compile(r"^[+-]?\d+$")
HEREDOC = re.compile(r"(?<!<)<<-?(?!<)\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")
PERL_INPLACE = re.compile(r"^-[0-9alnpw]*i")
INTERP_FILE_CALLS = ("open(", "readFile", "writeFile", "File.")
READERS = {"cat", "head", "less", "more", "bat", "nl"}
AWKS = {"awk", "gawk", "mawk"}
XARGS_VALUE_FLAGS = {"-n", "-I", "-L", "-P", "-d", "-s", "-E"}

REASONS = {
    "read": "Use the Read tool. Use offset and limit for a line range.",
    "write": "Use the Edit tool or the Write tool to change files.",
    "interpreter": "Use the Read, Edit, or Write tool for file access.",
}


def strip_heredoc_bodies(cmd):
    # Heredoc bodies hold free text (quotes, pipes) that would confuse shlex.
    lines, out, end = cmd.split("\n"), [], None
    for line in lines:
        if end is not None:
            if line.strip() == end:
                end = None
            continue
        out.append(line)
        m = HEREDOC.search(line)
        if m:
            end = m.group(2)
    return "\n".join(out)


def tokenize(cmd):
    cmd = strip_heredoc_bodies(cmd).replace("\\\n", " ")
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=True)
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    return list(lex)


def segments(tokens):
    # Yields (words, redirect_targets, heredoc, pipeline_head) per simple command.
    seg, head = [], None
    for tok in tokens + [";"]:
        if tok in SEPARATORS:
            if seg:
                parsed = parse(seg)
                if head is None:
                    head = parsed[0][0] if parsed[0] else None
                yield parsed + (head,)
            seg = []
            if tok not in {"|", "|&"}:
                head = None
        else:
            seg.append(tok)


def parse(seg):
    words, targets, heredoc, i = [], [], False, 0
    while i < len(seg):
        tok = seg[i]
        if tok in REDIRECTS:
            nxt = seg[i + 1] if i + 1 < len(seg) else ""
            if tok in {"<<", "<<<"}:
                heredoc = True
            elif tok not in {"<", "<&", ">&"} or not nxt.isdigit():
                if tok.startswith(">") or tok.startswith("&"):
                    targets.append(nxt)
            i += 2
            continue
        words.append(tok)
        i += 1
    while words:
        if words[0] == "timeout":
            words = words[1:]
            while words and words[0].startswith("-"):
                words = words[1:]
            words = words[1:]  # duration, such as 5 or 10s
        elif words[0] in WRAPPERS or re.match(r"^[A-Za-z_]\w*=", words[0]):
            words = words[1:]
        else:
            break
    if words:
        words[0] = os.path.basename(words[0])
    return words, targets, heredoc


def file_args(args):
    return [a for a in args if a and not a.startswith("-") and not NUMBER.match(a)]


def allowed_target(path, scratch):
    if path.startswith(("/dev/", "/tmp/", "/private/tmp/", "$TMPDIR", "${TMPDIR")):
        return True
    if path.isdigit() or path.startswith("&") or path == "-":
        return True
    return bool(scratch) and path.startswith(scratch)


def check(words, targets, heredoc, pipe_head, scratch):
    if not words:
        return None
    name, args = words[0], words[1:]
    files = file_args(args)
    flags = [a for a in args if a.startswith("-")]

    if name in {"sh", "bash", "zsh"}:
        for i, a in enumerate(args[:-1]):
            if re.match(r"^-[a-zA-Z]*c[a-zA-Z]*$", a):
                return check_command(args[i + 1], scratch)[0]
    if name == "xargs":
        i = 0
        while i < len(args) and args[i].startswith("-"):
            i += 2 if args[i] in XARGS_VALUE_FLAGS else 1
        inner = os.path.basename(args[i]) if i < len(args) else ""
        if inner in READERS or inner in {"tail"} | AWKS:
            return "read"

    if name in READERS and files:
        return "read"
    if name in AWKS:
        # the first non-flag word is the program, unless -f names a program file
        rest, prog_file, i = [], False, 0
        while i < len(args):
            if args[i] in {"-F", "-v", "-f"}:
                prog_file = prog_file or args[i] == "-f"
                i += 2
                continue
            if not args[i].startswith("-"):
                rest.append(args[i])
            i += 1
        if rest[0 if prog_file else 1:]:
            return "read"
    if name == "tail" and files and not any(f in {"-f", "-F"} or f.startswith("--follow") for f in flags):
        return "read"
    if name in {"sed", "gsed"}:
        if any(f.startswith("-i") or f.startswith("--in-place") for f in flags):
            return "write"
        if "-n" in flags and len(files) >= 2:
            return "read"

    if name == "perl" and any(PERL_INPLACE.match(f) for f in flags):
        return "write"
    if name in {"python", "python3", "node", "ruby", "perl"}:
        for i, a in enumerate(args[:-1]):
            if a in {"-c", "-e"} and any(s in args[i + 1] for s in INTERP_FILE_CALLS):
                return "interpreter"

    if "prettier" in words:
        return None
    if name in {"echo", "printf", "cat"} and pipe_head == name:
        if any(not allowed_target(t, scratch) for t in targets):
            return "write"
    if name == "tee" and (pipe_head in {"echo", "printf", "cat"} or heredoc):
        if any(not allowed_target(f, scratch) for f in files):
            return "write"
    return None


def check_command(cmd, scratch):
    try:
        tokens = tokenize(cmd)
    except ValueError:
        return None, None
    for words, targets, heredoc, head in segments(tokens):
        rule = check(words, targets, heredoc, head, scratch)
        if rule:
            return rule, words
    return None, None


def main():
    data = json.load(sys.stdin)
    cmd = (data.get("tool_input") or {}).get("command") or ""
    scratch = data.get("scratchpad_dir") or ""
    rule, words = check_command(cmd, scratch)
    if not rule:
        return

    reason = f"Do not use Bash for this ({' '.join(words)[:80]}). {REASONS[rule]}"
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}))
    log_dir = os.path.expanduser("~/.claude/logs")
    os.makedirs(log_dir, exist_ok=True)
    with open(os.path.join(log_dir, "bash-blocks.log"), "a") as f:
        stamp = datetime.datetime.now().strftime("%F %T")
        f.write(f"{stamp}\t{rule}\t{' '.join(cmd.split())}\n")


if __name__ == "__main__":
    main()
