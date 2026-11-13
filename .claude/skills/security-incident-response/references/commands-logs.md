# Log analysis commands

This file holds local recipes for `jq`, `grep`, `awk`, and `sort` on exported log files, and recipes to build an incident timeline. They read files on the local machine and send no traffic. Every entry carries the SENSITIVE tag, because logs hold user names, addresses, and internal context.
Labels and the approval rules are in `../SKILL.md`. Read them before you run any command from this file.

Work on a copy of the export, not on the original. Hash the original first with HOST-26 or HOST-27. Save each result only to the evidence folder (safety rule 14 in `../SKILL.md`).

## Contents

- [JSON logs with jq](#json-logs-with-jq)
  - [LOG-01 Select records by field value](#log-01-select-records-by-field-value)
  - [LOG-02 Select records in a time range](#log-02-select-records-in-a-time-range)
  - [LOG-03 Count records by field value](#log-03-count-records-by-field-value)
  - [LOG-04 List the top values of a field](#log-04-list-the-top-values-of-a-field)
  - [LOG-05 Print JSON as one compact line per record](#log-05-print-json-as-one-compact-line-per-record)
  - [LOG-06 Flatten CloudTrail records](#log-06-flatten-cloudtrail-records)
  - [LOG-07 Summarise CloudTrail events in columns](#log-07-summarise-cloudtrail-events-in-columns)
- [Text logs with grep](#text-logs-with-grep)
  - [LOG-08 Find a fixed string](#log-08-find-a-fixed-string)
  - [LOG-09 Match one of several patterns](#log-09-match-one-of-several-patterns)
  - [LOG-10 Match a file of indicators](#log-10-match-a-file-of-indicators)
  - [LOG-11 Show lines around a match](#log-11-show-lines-around-a-match)
  - [LOG-12 Count matching lines](#log-12-count-matching-lines)
  - [LOG-13 Search rotated gzip logs](#log-13-search-rotated-gzip-logs)
- [Access logs with awk](#access-logs-with-awk)
  - [LOG-14 Count records by column value](#log-14-count-records-by-column-value)
  - [LOG-15 Sum bytes by column value](#log-15-sum-bytes-by-column-value)
  - [LOG-16 Filter records by status code](#log-16-filter-records-by-status-code)
- [Timeline building](#timeline-building)
  - [LOG-17 Convert JSON Lines events to timeline columns](#log-17-convert-json-lines-events-to-timeline-columns)
  - [LOG-18 Convert CloudTrail events to timeline columns](#log-18-convert-cloudtrail-events-to-timeline-columns)
  - [LOG-19 Merge, sort, and de-duplicate timeline files](#log-19-merge-sort-and-de-duplicate-timeline-files)
  - [Timeline table template](#timeline-table-template)

## JSON logs with jq

`jq` reads a stream of JSON values. A JSON Lines file holds one value per line, and `jq` handles it without a flag. The `-s` (slurp) option reads the whole input into one array. It makes grouping easy, but it holds the full file in memory. For a large file, prefer a streaming recipe such as LOG-04.

### LOG-01 Select records by field value

- Purpose: keep only the records where one field has one value. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<log-file>`.
- Command:

  ```bash
  jq -c 'select(.<field-name> == "<field-value>")' <log-file>
  jq -c --argjson v '<json-value>' 'select(.<field-name> == $v)' <log-file>
  ```

- Output: each matching record on one line. Use the first line for a string value. Use the second line for a Boolean, a number, or `null`, such as `false` for CloudTrail `readOnly`. `jq` does not convert types, so the string `"false"` does not match the Boolean `false`. Set `<json-value>` only to `true`, `false`, `null`, or a number. Look for: records for a user, address, or action that is part of the incident. For a nested field, write the path, such as `.<parent-field>.<child-field>`.
- Approval: ask the human first.
- Doc: https://jqlang.org/manual/ (checked 2026-11-12)
- Local help: checked with jq (`jq --help`). The `-c` and `--argjson` options are listed. A local test on literal sample records matched `false` and `200` with the second line.

### LOG-02 Select records in a time range

- Purpose: keep only the records between two times. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<log-file>`.
- Command:

  ```bash
  jq -c --arg start '<start-time-iso8601>' --arg end '<end-time-iso8601>' 'select((.<time-field> | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) as $t | $t >= ($start | fromdateiso8601) and $t <= ($end | fromdateiso8601))' <log-file>
  ```

- Output: each record in the range, on one line. Write each time as `YYYY-MM-DDTHH:MM:SSZ` in UTC. The `sub` call removes fractional seconds, because the manual documents only the form without them. The command does not accept a time with an offset such as `+01:00`. Look for: a gap in the range, which can mean missing logs.
- Approval: ask the human first.
- Doc: https://jqlang.org/manual/ (checked 2026-11-12)
- Local help: checked with jq (`jq --help`). The `--arg` option is listed.

### LOG-03 Count records by field value

- Purpose: count how many records hold each value of one field. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<log-file>`.
- Command:

  ```bash
  jq -s -r 'group_by(.<field-name>) | map([length, (.[0].<field-name> | if . == null then "none" else tostring end)]) | sort_by(.[0]) | reverse | .[] | @tsv' <log-file>
  ```

- Output: one line per value, with the count, a tab, and the value. The highest count comes first. A missing or `null` field counts as `none`. A `false` value counts as `false`. The `-s` option loads the whole file into memory. Look for: one user, address, or action with a very high count.
- Approval: ask the human first.
- Doc: https://jqlang.org/manual/ (checked 2026-11-12)
- Local help: checked with jq (`jq --help`). The `-s` and `-r` options are listed.

### LOG-04 List the top values of a field

- Purpose: list the most common values of one field without loading the whole file. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<log-file>`.
- Command:

  ```bash
  (set -o pipefail; jq -c '.<field-name>' <log-file> | sort | uniq -c | sort -rn | awk -v n=<top-n> 'NR <= n')
  ```

- Output: the count and the value as compact JSON, with the highest count first. A string value keeps its quotes, so the string `"false"` and the Boolean `false` count separately. A record without the field, or with `null`, counts as `null`. The `-c` option writes each value on one line, so a line break inside a value cannot split it into two counts. The command was tested on a sample file with these cases (exit 0). A non-zero exit status or any error message means the count is incomplete. The last `awk` reads all its input, so that the earlier commands do not stop early. Look for: a value that dominates, or a value that you do not know.
- Approval: ask the human first.
- Doc: https://jqlang.org/manual/ (checked 2026-11-12)
- Local help: checked with jq (`jq --help`). `man sort` and `man uniq` were read on macOS.

### LOG-05 Print JSON as one compact line per record

- Purpose: turn pretty-printed JSON into one line per record, so `grep` and `awk` can read it. Phase: evidence.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<log-file>`.
- Command:

  ```bash
  jq -c '.' <log-file>
  jq -c '.[]' <log-file>
  ```

- Output: one JSON value per line. Use the first line for a file of separate values. Use the second line for a file that holds one top-level array. Look for: a parse error. It names the position of the first bad value.
- Approval: ask the human first.
- Doc: https://jqlang.org/manual/ (checked 2026-11-12)
- Local help: checked with jq (`jq --help`). The `-c` option is listed.

### LOG-06 Flatten CloudTrail records

- Purpose: turn CloudTrail files into one event per line. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the CloudTrail files.
- Command:

  ```bash
  (set -o pipefail; gzip -dc <cloudtrail-dir>/*.json.gz | jq -c '.Records[]')
  ```

- Output: one CloudTrail event per line. A non-zero exit status or any `gzip:` message means the extraction is incomplete. The `pipefail` option makes the pipeline return the status of the failed command. Each delivered file is a gzip file that holds a JSON object with a `Records` array. For a file that is not compressed, use `jq -c '.Records[]' <cloudtrail-file>`. Look for: events with `errorCode`, events from an unknown `sourceIPAddress`, and write calls where `readOnly` is false.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-log-file-examples.html and https://www.gnu.org/software/bash/manual/bash.html and https://zsh.sourceforge.io/Doc/Release/Options.html (checked 2026-11-12)
- Local help: checked with jq (`jq --help`). The `gzip` command was not read. A local test with `set -o pipefail` in zsh and bash gave a non-zero status for a missing gzip file.

### LOG-07 Summarise CloudTrail events in columns

- Purpose: print the main fields of each CloudTrail event as one tab-separated line. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the CloudTrail files.
- Command:

  ```bash
  (set -o pipefail; gzip -dc <cloudtrail-dir>/*.json.gz | jq -r '.Records[] | [.eventTime, .eventSource, .eventName, (.userIdentity.arn // .userIdentity.type // ""), .sourceIPAddress, (.errorCode // "")] | @tsv')
  ```

- Output: event time in UTC, service, action, caller, source address, and error code. A non-zero exit status or any `gzip:` message means the extraction is incomplete. Look for: an `eventName` that changes access, such as a new user or key, a caller you do not know, or many `AccessDenied` codes from one address.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-record-contents.html and https://www.gnu.org/software/bash/manual/bash.html and https://zsh.sourceforge.io/Doc/Release/Options.html (checked 2026-11-12)
- Local help: checked with jq (`jq --help`).

## Text logs with grep

The macOS `grep` page lists `-F`, `-E`, `-f`, `-A`, `-B`, and `-c`. The GNU manual describes the same options. On macOS, `-Z` means decompress. On GNU grep it prints a NUL byte after the file name. Do not use `-Z` in a recipe that must run on both systems.

### LOG-08 Find a fixed string

- Purpose: find lines that hold one exact string, such as an address or a user name. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<log-file>`.
- Command:

  ```bash
  grep -F -n '<search-string>' <log-file>
  ```

- Output: each matching line with its line number. The `-F` option treats the string as text, so a dot in an address does not match any character. Look for: the first and last time the string appears.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/grep/manual/grep.html (checked 2026-11-12)
- Local help: checked on macOS (`man grep`). The `-F` and `-n` options are listed.

### LOG-09 Match one of several patterns

- Purpose: find lines that match any of two or more patterns. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<log-file>`.
- Command:

  ```bash
  grep -E '<pattern-one>|<pattern-two>' <log-file>
  ```

- Output: each line that matches at least one pattern. Look for: lines that match both a user and an action.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/grep/manual/grep.html (checked 2026-11-12)
- Local help: checked on macOS (`man grep`). The `-E` option is listed.

### LOG-10 Match a file of indicators

- Purpose: find every line that holds any indicator of compromise from a list. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<ioc-ip-file>`, `<ioc-text-file>`, and `<log-file>`.
- Command:

  ```bash
  grep -F -w -n -f <ioc-ip-file> <log-file>
  grep -F -n -f <ioc-text-file> <log-file>
  ```

- Output: each matching line with its line number. Each indicator file holds one indicator per line. Remove empty lines first, because an empty line matches every log line. Put IP addresses in `<ioc-ip-file>`. The `-w` option stops `192.0.2.1` from matching `192.0.2.12`. It does not work for IPv6, because `grep` treats `:` as a word boundary. So `2001:db8::1` also matches `2001:db8::1:2`. Treat each IPv6 match as a candidate only. Check the full address in the line before you record a hit. A log can also write one IPv6 address in other forms, such as with leading zeros. Ask the human for each form to search. Put all other indicators in `<ioc-text-file>`, such as paths, domains, hashes, and user agents. The second command has no `-w`, because `-w` needs a non-word character on each side of the match. With `-w`, `/.env` misses `GET example.com/.env`. Look for: indicators that match many lines. A short text indicator can also match inside longer words. Check each match.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/grep/manual/grep.html (checked 2026-11-12)
- Local help: checked on macOS (`man grep`). The `-F`, `-w`, `-n`, and `-f` options are listed. Tested locally on sample lines: `/.env` matched both lines without `-w`, and `192.0.2.1` with `-w` matched `192.0.2.1:443` but not `192.0.2.12`.

### LOG-11 Show lines around a match

- Purpose: read the lines before and after each match for context. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<log-file>`.
- Command:

  ```bash
  grep -F -n -B <lines-before> -A <lines-after> '<search-string>' <log-file>
  ```

- Output: each match with the lines around it. Context lines use `-` after the line number. Groups are separated by `--`. Look for: the action that comes just before or after the match.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/grep/manual/grep.html (checked 2026-11-12)
- Local help: checked on macOS (`man grep`). The `-A` and `-B` options are listed.

### LOG-12 Count matching lines

- Purpose: count the lines that match, per file. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<log-file>`.
- Command:

  ```bash
  grep -F -c '<search-string>' <log-file>
  ```

- Output: one count per file. The count is the number of lines, not the number of matches. Look for: a file with a high count next to files with zero.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/grep/manual/grep.html (checked 2026-11-12)
- Local help: checked on macOS (`man grep`). The `-c` option is listed.

### LOG-13 Search rotated gzip logs

- Purpose: search compressed, rotated logs without unpacking them. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the log files.
- Command:

  ```bash
  zgrep -F -H '<search-string>' <log-dir>/<log-name>*.gz
  ```

- Output: each matching line with its file name. Look for: the oldest file that holds a match. It shows how far back the activity goes.
- Approval: ask the human first.
- Doc: the local man page (`man zgrep`). On macOS, `zgrep` is part of the system `grep`. On Linux, it comes with gzip. The GNU gzip manual at https://www.gnu.org/software/gzip/manual/gzip.html does not describe `zgrep` (checked 2026-11-12).
- Local help: checked on macOS (`man zgrep` opens the grep page, which lists `zgrep`).

## Access logs with awk

These recipes assume fields that are separated by spaces. Print one sample line first. Count the columns. A quoted field that holds spaces shifts every later column. The macOS `awk` is the one-true-awk. GNU awk is described at https://www.gnu.org/software/gawk/manual/gawk.html. The part of that manual that was read does not show these exact examples.

### LOG-14 Count records by column value

- Purpose: count how often each value appears in one column, such as the client address. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<access-log>`.
- Command:

  ```bash
  (set -o pipefail; awk '{count[$<column-number>]++} END {for (key in count) print count[key], key}' <access-log> | sort -rn | awk -v n=<top-n> 'NR <= n')
  ```

- Output: the count and the value, with the highest count first. A non-zero exit status or any error message means the count is incomplete. The last `awk` reads all its input, so that the earlier commands do not stop early. Look for: one address with a very high count, or an address that you do not know.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/gawk/manual/gawk.html (checked 2026-11-12)
- Local help: checked on macOS (`man awk`). The field variables `$1`, `$2`, and the `-F` option are described.

### LOG-15 Sum bytes by column value

- Purpose: add up the bytes that each client received. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<access-log>`.
- Command:

  ```bash
  (set -o pipefail; awk '{bytes[$<client-column>] += $<bytes-column>} END {for (key in bytes) print bytes[key], key}' <access-log> | sort -rn | awk -v n=<top-n> 'NR <= n')
  ```

- Output: total bytes and the client value, with the highest total first. A dash in the bytes column counts as zero. A non-zero exit status or any error message means the result is incomplete. The last `awk` reads all its input, so that the earlier commands do not stop early. Look for: a client with a very large total, which can mean data theft or scraping.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/gawk/manual/gawk.html (checked 2026-11-12)
- Local help: checked on macOS (`man awk`).

### LOG-16 Filter records by status code

- Purpose: keep the records with one status code, or with a code at or above a limit. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<access-log>`.
- Command:

  ```bash
  awk '$<status-column> == "<status-code>"' <access-log>
  awk '$<status-column> >= <min-status-code>' <access-log>
  ```

- Output: each matching log line. Use the first line for one code. Use the second line for a range. Look for: a burst of 401 or 403 codes, then a 200 from the same client.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/gawk/manual/gawk.html (checked 2026-11-12)
- Local help: checked on macOS (`man awk`).

## Timeline building

A timeline puts events from many sources in one time order. Use these columns: `UTC time | source | actor | action | target | detail | evidence ref`. Convert each time to UTC in the `YYYY-MM-DDTHH:MM:SSZ` form first. Then a plain text sort gives time order. Keep the `evidence ref` so each row leads back to a file and a record.

### LOG-17 Convert JSON Lines events to timeline columns

- Purpose: turn one JSON Lines log into timeline rows. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `<log-file>`.
- Command:

  ```bash
  jq -r --arg source '<source-name>' --arg ref '<evidence-ref>' '[(.<time-field> | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 | todateiso8601), $source, (.<actor-field> // ""), (.<action-field> // ""), (.<target-field> // ""), (.<detail-field> // ""), ($ref + "#line" + (input_line_number | tostring))] | map(tostring) | @tsv' <log-file>
  ```

- Output: one tab-separated row per record, in the timeline column order. The time field must be UTC with a trailing `Z`. The command removes fractional seconds. The evidence ref ends with the line number of the record, so two events in the same second stay separate rows in LOG-19. This works only when each record is on one line, as JSON Lines requires. Look for: rows with an empty actor or action, which means a field name is wrong. Check one sample row first.
- Approval: ask the human first.
- Doc: https://jqlang.org/manual/ (checked 2026-11-12)
- Local help: checked with jq (`jq --help`). The `@tsv` filter escapes tabs and line breaks inside values.

### LOG-18 Convert CloudTrail events to timeline columns

- Purpose: turn CloudTrail files into timeline rows. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the CloudTrail files.
- Command:

  ```bash
  (set -o pipefail; gzip -dc <cloudtrail-dir>/*.json.gz | jq -r --arg source 'cloudtrail' --arg ref '<evidence-ref>' '.Records[] | [.eventTime, $source, (.userIdentity.arn // .userIdentity.principalId // .userIdentity.type // ""), .eventName, .eventSource, (.sourceIPAddress + " " + (.errorCode // "ok")), ($ref + "#" + .eventID)] | @tsv')
  ```

- Output: one row per event. A non-zero exit status or any `gzip:` message means the extraction is incomplete. The detail column holds the source address and `ok` or the error code. The evidence ref ends with the unique `eventID`. Look for: rows where the actor is a role or user that does not match the person at that address.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-record-contents.html and https://www.gnu.org/software/bash/manual/bash.html and https://zsh.sourceforge.io/Doc/Release/Options.html (checked 2026-11-12)
- Local help: checked with jq (`jq --help`).

### LOG-19 Merge, sort, and de-duplicate timeline files

- Purpose: combine timeline rows from several sources into one ordered list. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the timeline files.
- Command:

  ```bash
  LC_ALL=C sort -u <timeline-file-one> <timeline-file-two>
  ```

- Output: all rows in time order, with exact duplicate rows removed. Add more files to the command as needed. Rows from two sources that describe the same event have different `evidence ref` values, so they both stay. Review such pairs by hand. The `LC_ALL=C` setting gives a fixed byte order. Look for: gaps in time, and actions with no matching approval or change record.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html (checked 2026-11-12)
- Local help: checked on macOS (`man sort`). The `-u` option is listed.

### Timeline table template

Copy this table into the incident notes. Use UTC for every time. LOG-17 to LOG-19 give the first seven columns. After the LOG-19 merge, a person sets `Status` to `confirmed` or `inferred` for each row.

| UTC time | Source | Actor | Action | Target | Detail | Evidence ref | Status |
| -------- | ------ | ----- | ------ | ------ | ------ | ------------ | ------ |
|          |        |       |        |        |        |              |        |
