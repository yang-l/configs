# Cloudflare commands

This file covers Cloudflare incident commands. It uses `curl` against the Cloudflare API. It includes firewall events, audit logs, Access, WAF custom rules, IP lists, and origin checks.
Labels and the approval rules are in `../SKILL.md`. Read them before you run any command from this file.

## Before you start

- Ask the human for the zone ID (`<zone-id>`) and the account ID (`<account-id>`). Never guess them.
- Every command reads the API token from the environment variable `CLOUDFLARE_API_TOKEN`.
- A human sets `CLOUDFLARE_API_TOKEN`. The agent never reads, prints, or stores it. Each command passes the token header to curl as a file, with `@<(printf ...)`. `printf` runs inside the shell, so the token does not show in a process list. The curl FAQ says to keep passwords off the command line, so that they do not show in `ps` output. This form needs bash or zsh. See https://curl.se/docs/faq.html and https://curl.se/docs/manpage.html#-H (checked 2026-11-12).
- Ask the human for a token with only the permissions that the entry names. Use a read-only token for READ-ONLY entries.
- The API host `api.cloudflare.com` is a vendor endpoint. All other hosts and IPs are placeholders.
- A REST response has `success`, `errors`, and `result`. Check `success` before you trust `result`.
- A GraphQL response (CF-01 and CF-02) has `data` and `errors`. A `200` response can contain an error. Check that `errors` is `null` or empty before you trust `data`. The errors page says `errors` is `null` when no error occurred. See https://developers.cloudflare.com/analytics/graphql-api/errors/ (checked 2026-11-12).
- Do not use any Cloudflare tool other than the `curl` commands in this file.

## Contents

- [Firewall events](#firewall-events)
  - [CF-01 Query firewall events in a time range](#cf-01-query-firewall-events-in-a-time-range)
  - [CF-02 Filter firewall events by client IP, rule ID, or action](#cf-02-filter-firewall-events-by-client-ip-rule-id-or-action)
- [Audit log](#audit-log)
  - [CF-03 List account audit log entries](#cf-03-list-account-audit-log-entries)
  - [CF-04 Filter saved audit log entries by actor](#cf-04-filter-saved-audit-log-entries-by-actor)
- [Access](#access)
  - [CF-05 List Access applications](#cf-05-list-access-applications)
  - [CF-06 List the policies of one Access application](#cf-06-list-the-policies-of-one-access-application)
  - [CF-07 List reusable Access policies](#cf-07-list-reusable-access-policies)
- [WAF custom rules](#waf-custom-rules)
  - [CF-08 Get the zone custom rules ruleset](#cf-08-get-the-zone-custom-rules-ruleset)
  - [CF-09 Add a block rule to the zone custom rules ruleset](#cf-09-add-a-block-rule-to-the-zone-custom-rules-ruleset)
  - [CF-17 Create the zone custom rules ruleset with a block rule](#cf-17-create-the-zone-custom-rules-ruleset-with-a-block-rule)
  - [CF-18 List IP Access rules with the Allow action](#cf-18-list-ip-access-rules-with-the-allow-action)
  - [CF-19 Check that traffic goes through the Cloudflare proxy](#cf-19-check-that-traffic-goes-through-the-cloudflare-proxy)
- [IP lists](#ip-lists)
  - [CF-10 List account lists](#cf-10-list-account-lists)
  - [CF-11 List the items of one list](#cf-11-list-the-items-of-one-list)
  - [CF-12 Add items to a list](#cf-12-add-items-to-a-list)
  - [CF-13 Check the status of a list bulk operation](#cf-13-check-the-status-of-a-list-bulk-operation)
- [Origin checks](#origin-checks)
  - [CF-14 Request a path through the Cloudflare proxy](#cf-14-request-a-path-through-the-cloudflare-proxy)
  - [CF-15 Request the same path directly from the origin with the hostname kept](#cf-15-request-the-same-path-directly-from-the-origin-with-the-hostname-kept)
  - [CF-16 Request the same path directly from the origin with a Host header](#cf-16-request-the-same-path-directly-from-the-origin-with-a-host-header)

## Firewall events

### CF-01 Query firewall events in a time range

- Purpose: list recent WAF and firewall events for one zone, newest first. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: API token with `Account Analytics` `Read`. The GraphQL Analytics API also needs the zone in the token scope.
- Command:

  ```bash
  curl -q -sS https://api.cloudflare.com/client/v4/graphql \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN") \
    --json '{"query":"query ListFirewallEvents($zoneTag: string, $filter: FirewallEventsAdaptiveFilter_InputObject) { viewer { zones(filter: { zoneTag: $zoneTag }) { firewallEventsAdaptive(filter: $filter, limit: 100, orderBy: [datetime_DESC]) { action clientAsn clientCountryName clientIP clientRequestPath clientRequestQuery datetime source userAgent } } } }","variables":{"zoneTag":"<zone-id>","filter":{"datetime_geq":"<start-time-iso8601>","datetime_leq":"<end-time-iso8601>"}}}'
  ```

- Output: first check that `errors` is `null` or empty. Then read `data.viewer.zones[0].firewallEventsAdaptive`, an array of events. Look for: many events from one `clientIP` or `clientAsn`, `action` values that are not `block`, odd `userAgent` values, and probes in `clientRequestPath`.
- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/analytics/graphql-api/tutorials/querying-firewall-events/ , https://developers.cloudflare.com/analytics/graphql-api/features/pagination/ , https://developers.cloudflare.com/analytics/graphql-api/sampling/ and https://developers.cloudflare.com/analytics/graphql-api/errors/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`). `--json` sets the `Content-Type` and `Accept` headers.

Notes:

- The `firewallEventsAdaptive` data is adaptively sampled. The sampling page says Cloudflare almost always uses adaptive sampling and that the sample rate varies. The page also says sampling is not used when the number of records is small. The result can be incomplete.
- The GraphQL Analytics API has no cursors (pagination page). The query stops at `limit`. To check that the query did not truncate the result, do these steps:
  1. Count the events in the result.
  2. When the count equals `limit`, split the time range into smaller ranges.
  3. Run the query again for each smaller range. Each run is a separate SENSITIVE command. Ask the human before each run and save each result.
  4. Split again every range that returns `limit` events.
  5. The result is complete for the sampled data only when every range returns fewer events than `limit`.
- Sampled data cannot prove that an event did not happen. When you need complete event evidence, ask the human for raw logs. The sampling page says Enterprise customers can access raw data through Cloudflare Logs.
- `limit` is 100 here. Raise it only up to the `maxPageSize` that the zone allows.
- The API rejects a range older than the `notOlderThan` limit. The tutorial shows the error "cannot request data older than 2678400s".
- Query the `settings` node of `firewallEventsAdaptive` to read `maxDuration`, `maxPageSize`, and `notOlderThan` for the zone. The tutorial above shows how.

### CF-02 Filter firewall events by client IP, rule ID, or action

- Purpose: find the events for one client IP, one rule, or one action. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: API token with `Account Analytics` `Read`.
- Command:

  ```bash
  curl -q -sS https://api.cloudflare.com/client/v4/graphql \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN") \
    --json '{"query":"query ListFirewallEvents($zoneTag: string, $filter: FirewallEventsAdaptiveFilter_InputObject) { viewer { zones(filter: { zoneTag: $zoneTag }) { firewallEventsAdaptive(filter: $filter, limit: 100, orderBy: [datetime_DESC]) { action clientIP clientRequestPath datetime ruleId source userAgent } } } }","variables":{"zoneTag":"<zone-id>","filter":{"datetime_geq":"<start-time-iso8601>","datetime_leq":"<end-time-iso8601>","clientIP":"<client-ip>"}}}'
  ```

- Output: the same shape as CF-01, plus `ruleId`. Check `errors` first, as in CF-01. Look for: the `ruleId` and `source` that matched, `action` values of `allow`, `log`, or `skip` for hostile traffic, and the first and last `datetime` of the returned events. The data is sampled and stops at `limit`. Read the CF-01 notes before you treat these as the first and last event. Use raw logs when you need complete evidence.
- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/analytics/graphql-api/features/filtering/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

Notes:

- To filter by rule, replace `"clientIP":"<client-ip>"` with `"ruleId":"<rule-id>"`.
- To filter by action, replace it with `"action":"<action-name>"`.
- Combine fields in one `filter` object. The API joins them with AND. The filtering page shows `OR:[ ... ]` for OR.
- The tutorial page does not list `ruleId` as a field. If the API returns an unknown-field error, browse the schema with a GraphQL client. See https://developers.cloudflare.com/analytics/graphql-api/getting-started/explore-graphql-schema/.

## Audit log

### CF-03 List account audit log entries

- Purpose: list who changed Cloudflare settings in an account, in a time range. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: API token with `Account Settings Read`.
- Command:

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/accounts/<account-id>/logs/audit?since=<start-time-iso8601>&before=<end-time-iso8601>&limit=100&direction=desc" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

- Output: `result` is an array. Each entry has `action` (`type`, `result`, `time`), `actor` (`email`, `ip_address`, `context`, `token_id`, `token_name`), `resource`, `zone`, and `raw` (`method`, `uri`, `status_code`). Look for: `actor.context` of `api_token` or `api_key` that nobody expects, an `actor.ip_address` outside known ranges, and changes to DNS, WAF, Access, or tokens. One response holds at most `limit` entries. Read every page (see the notes).
- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/api/resources/accounts/subresources/logs/subresources/audit/methods/list/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

Notes:

- To read every page:
  1. Read `result_info.cursor` in the response. The reference calls it an opaque token for the next batch.
  2. Run the same command again with the cursor in the `cursor` query parameter. Use `-G --data-urlencode "cursor=<next-cursor>"`, so that curl encodes the value. The reference does not state how to encode it.

     ```bash
     curl -q -sS -G "https://api.cloudflare.com/client/v4/accounts/<account-id>/logs/audit?since=<start-time-iso8601>&before=<end-time-iso8601>&limit=100&direction=desc" \
       --data-urlencode "cursor=<next-cursor>" \
       -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
     ```

  3. Ask the human before each page, because each page is a separate SENSITIVE command. Save each page to its own file.
  4. The reference does not say how to detect the last page. Treat the list as complete when a response has no entries or no `result_info.cursor`. Tell the human that this rule is inferred.

- This is audit logs version 2. The Cloudflare audit log page (https://developers.cloudflare.com/fundamentals/account/account-security/audit-logs/) says version 2 is available. It does not call version 1 deprecated.
- Version 1 uses `GET /accounts/<account-id>/audit_logs`. Its filters are `actor.email`, `actor.ip`, `zone.name`, `action.type`, `since`, `before`, `page`, and `per_page`. Its reference is https://developers.cloudflare.com/api/resources/audit_logs/methods/list/.
- Use version 1 only for entries that version 2 does not hold. The v2 page says that logs from before its beta period remain in version 1.
- Retention is 18 months. The v2 dashboard shows only the last 90 days. The API returns the full range.
- The v2 reference lists filter objects such as `actor_email`, `action_type`, `zone_id`, and `resource_type`. It does not show how to write them in the query string. Filter locally with CF-04 instead.

### CF-04 Filter saved audit log entries by actor

- Purpose: show only the entries of one actor from a saved CF-03 result. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the saved file. No Cloudflare permission.
- Command:

  ```bash
  jq -c '.result[] | select(.actor.email == "<user-email>") | {time: .action.time, type: .action.type, result: .action.result, ip: .actor.ip_address, context: .actor.context, resource: .resource.type, uri: .raw.uri}' <audit-log-file>
  ```

- Output: one compact JSON object per matching entry. Look for: entries from an unexpected `ip`, changes just before the incident, and `context` values that differ from the user's normal use.
- Approval: ask the human first.
- Doc: https://jqlang.github.io/jq/manual/ (checked 2026-11-12)
- Local help: checked with jq (`jq --help`).

Notes:

- Save the CF-03 response to a new file first. Ask the human where to store it. Do not overwrite an existing evidence file.
- To filter by IP, use `select(.actor.ip_address == "<client-ip>")`.
- To filter by token, use `select(.actor.token_id == "<token-id>")`.

## Access

CF-05 to CF-07 return one page of results. Read every page:

1. Read `result_info.page` and `result_info.total_pages` in the result.
2. When `page` is less than `total_pages`, run the same command with `&page=<next-page>` added to the URL.
3. Ask the human before each page, because each page is a separate SENSITIVE command. Save each page.
4. The list is complete only after the last page.

### CF-05 List Access applications

- Purpose: list the Access applications of an account. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: API token with `Access: Apps and Policies Read`.
- Command:

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/accounts/<account-id>/access/apps?per_page=100" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

- Output: `result` is an array of applications with `id`, `name`, and `domain`. Self-hosted applications can include a `policies` array. Look for: policies broader than expected, and applications that you do not expect. Read every page (see the Access section intro).
- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/api/resources/zero_trust/subresources/access/subresources/applications/methods/list/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

Notes:

- The reference lists the query parameters `page`, `per_page` (maximum 1000), `name`, `domain`, `aud`, `exact`, and `search`.
- Zone-level applications use `/zones/<zone-id>/access/apps`.

### CF-06 List the policies of one Access application

- Purpose: read the policies of one application. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: API token with `Access: Apps and Policies Read`.
- Command:

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/accounts/<account-id>/access/apps/<app-id>/policies?per_page=100" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

- Output: `result` is an array of policies. The reference says it returns the application-scoped policies and the reusable policies that the application uses. Look for: a `decision` or `include` rule that is broader than expected, and policies that you do not expect. Read every page (see the Access section intro).
- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/api/resources/zero_trust/subresources/access/subresources/applications/subresources/policies/methods/list/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

### CF-07 List reusable Access policies

- Purpose: list the reusable policies of an account. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: API token with `Access: Apps and Policies Read`.
- Command:

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/accounts/<account-id>/access/policies?per_page=100" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

- Output: `result` is an array of reusable policies. Look for: a `decision` or `include` rule that is broader than expected, and policies that you do not expect. Read every page (see the Access section intro).
- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/api/resources/zero_trust/subresources/access/subresources/policies/methods/list/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

## WAF custom rules

### CF-08 Get the zone custom rules ruleset

- Purpose: read the zone WAF custom rules and find the ruleset ID. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: API token with `Zone WAF Read`.
- Command:

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/zones/<zone-id>/rulesets/phases/http_request_firewall_custom/entrypoint" \
    --write-out "\nHTTP %{http_code}\n" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

- Output: the JSON body, then a last line with the HTTP status. Read the status first. By default, curl does not treat an HTTP error status as a failure. `HTTP 200` means the body holds the ruleset. `result.id` is the ruleset ID. `result.rules` is the ordered rule list, each with `id`, `action`, `expression`, and `enabled`. Look for: rules with action `skip` or `allow`, and expressions that match broad traffic. `HTTP 404` means the zone has no custom rules ruleset yet. Use CF-17 only in that case. For any other status, stop and tell the human. An expression can hold a shared secret value, for example a header check. Follow safety rule 15 in `../SKILL.md` when one appears.
- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/ruleset-engine/rulesets-api/view/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

Notes:

- The API returns the latest version of the ruleset. Keep the response as evidence before any change.
- Rules run in list order. A `skip` rule above a block rule can bypass the block.

### CF-09 Add a block rule to the zone custom rules ruleset

- Purpose: block a client IP at the Cloudflare edge. Phase: containment.
- Label: WRITE, SENSITIVE
- Permission: API token with `Zone WAF Write`.
- Command:

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/zones/<zone-id>/rulesets/<ruleset-id>/rules" \
    --request POST \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN") \
    --json '{"action":"block","expression":"(ip.src eq <client-ip>)","description":"<rule-description>","position":{"index":1}}'
  ```

- Output: the full ruleset with the new rule. An expression can hold a shared secret value. Follow safety rule 15 in `../SKILL.md` when one appears. Look for: the rule IDs that are in this output but not in the CF-08 output that you saved. Exactly one ID must be new. Its `action`, `expression`, and `description` must match the values that you sent. Otherwise, stop and tell the human. Record that rule `id` and its `version` for the rollback. Also record `result.version` and the ordered list of rule IDs. Check that `enabled` is `true`.
- Side effect: Cloudflare blocks each matching request that reaches the custom rules. An IP Access rule with the Allow action stops the custom rules for the requests that it matches. Run CF-18 before the change. Do not report the client as blocked while an Allow rule can match it. When CF-19 and CF-14 pass, report only that Cloudflare blocks the matching requests that go through its proxy. The rule does not stop requests sent straight to the origin, because they do not go through Cloudflare ([troubleshooting](https://developers.cloudflare.com/fundamentals/reference/troubleshooting/)). A refusal in CF-15 or CF-16 covers only the tested address, port, and network. Report the other direct origin paths as open or unknown until the human confirms that the origin accepts only Cloudflare addresses ([protect your origin](https://developers.cloudflare.com/fundamentals/security/protect-your-origin-server/)). When CF-19 or CF-14 does not pass, report only that the rule exists. The API creates a new version of the ruleset. `position` `index` `1` puts the rule first. A wrong expression blocks real users.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Run CF-08 again first. Find the rule with the recorded `id`. Continue only when its `version`, `action`, and `expression` are the values that you recorded. A later change can keep the ID and raise the version. Also compare `result.version` and the ordered list of rule IDs with the recorded values. A move of a rule changes the order but not the rule version. When any value differs, another person changed the ruleset. Stop and tell the incident commander. Delete the rule by its ID.

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/zones/<zone-id>/rulesets/<ruleset-id>/rules/<rule-id>" \
    --request DELETE \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

  The delete returns HTTP 200 with the full ruleset. The deleted rule is no longer in the list.

- Approval: human approval required.
- Doc: https://developers.cloudflare.com/ruleset-engine/rulesets-api/add-rule/, https://developers.cloudflare.com/ruleset-engine/rulesets-api/delete-rule/, and https://developers.cloudflare.com/ruleset-engine/rulesets-api/json-object/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

Notes:

- Run CF-08 first. Save the ruleset as evidence and take the `<ruleset-id>` from it.
- Run CF-02 for the same IP first. It shows how much traffic the rule would block.
- To block several IPs, use an IP list (CF-12) and a rule that refers to the list. See https://developers.cloudflare.com/waf/tools/lists/custom-lists/ for the expression form.
- The `position` object is the documented way to place a rule. Use `"before"` or `"after"` with a rule ID to place it next to another rule.
- The delete reference shows an account-level URL. The same page lists the zone-level form in the command above.

### CF-17 Create the zone custom rules ruleset with a block rule

- Purpose: block a client IP at the Cloudflare edge when the zone has no custom rules ruleset. Phase: containment.
- Label: WRITE
- Permission: API token with `Zone WAF Write`.
- Command: run only when CF-08 returned HTTP 404. Otherwise use CF-09.

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/zones/<zone-id>/rulesets" \
    --request POST \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN") \
    --json '{"name":"<ruleset-name>","kind":"zone","phase":"http_request_firewall_custom","rules":[{"action":"block","expression":"(ip.src eq <client-ip>)","description":"<rule-description>"}]}'
  ```

- Output: the new ruleset. Look for: `result.id`, `result.version`, and the rule `id` and `version` in `result.rules`. Record all four for the rollback. Run CF-08 again. It must now return the new ruleset.
- Side effect: Cloudflare blocks each matching request that reaches the custom rules. An IP Access rule with the Allow action stops the custom rules for the requests that it matches. Run CF-18 before the change. Do not report the client as blocked while an Allow rule can match it. When CF-19 and CF-14 pass, report only that Cloudflare blocks the matching requests that go through its proxy. The rule does not stop requests sent straight to the origin, because they do not go through Cloudflare ([troubleshooting](https://developers.cloudflare.com/fundamentals/reference/troubleshooting/)). A refusal in CF-15 or CF-16 covers only the tested address, port, and network. Report the other direct origin paths as open or unknown until the human confirms that the origin accepts only Cloudflare addresses ([protect your origin](https://developers.cloudflare.com/fundamentals/security/protect-your-origin-server/)). When CF-19 or CF-14 does not pass, report only that the rule exists. The zone now has a custom rules ruleset. Later rule changes use CF-09 on this ruleset. A wrong expression blocks real users.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Run CF-08 first. Delete the ruleset only when all of these are true:
  - `result.id` and `result.version` are the values that you recorded.
  - The ruleset holds exactly one rule.
  - That rule has the recorded `id` and `version`.

  A delete removes all versions of the ruleset.

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/zones/<zone-id>/rulesets/<ruleset-id>" \
    --request DELETE \
    --write-out "HTTP %{http_code}\n" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

  The delete returns HTTP 204 with no body. Record the rollback as done only when the command prints `HTTP 204`. For any other status, stop and tell the human. When the ruleset holds other rules too, delete only your rule with the CF-09 rollback, with the same version check. When your rule changed, stop and tell the human.

- Approval: human approval required.
- Doc: https://developers.cloudflare.com/ruleset-engine/rulesets-api/create/ and https://developers.cloudflare.com/ruleset-engine/rulesets-api/delete/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

Notes:

- Use POST to create the ruleset. Do not use PUT on the entrypoint URL, because PUT replaces every rule in the phase.
- The delete page says you cannot delete a ruleset that other rules still refer to.

### CF-18 List IP Access rules with the Allow action

- Purpose: find IP Access rules that let a client skip the custom rules. Run it before CF-09 or CF-17. Phase: containment.
- Label: READ-ONLY, SENSITIVE
- Permission: the Doc page names `Account Firewall Access Rules Read`. It names no zone permission. Ask the human which token permission the zone form needs.
- Command: run CF-19 first. Use the account form only when CF-19 shows that the zone belongs to `<account-id>`. Run both forms. Start with `<page>` as `1`.

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/zones/<zone-id>/firewall/access_rules/rules?mode=whitelist&page=<page>" \
    --write-out "\nHTTP %{http_code}\n" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/accounts/<account-id>/firewall/access_rules/rules?mode=whitelist&page=<page>" \
    --write-out "\nHTTP %{http_code}\n" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

- Output: the JSON body, then a last line with the HTTP status. Read the status first. For a status other than `HTTP 200`, stop and tell the human. `result` lists the rules. The API calls the Allow action `whitelist`. Each rule has a `configuration` with a `target` (`ip`, `ip_range`, `asn`, or `country`) and a `value`. Read `result_info`. Run the read again with the next `page` until no rules are left. Look for: a rule whose IP, range, ASN, or country can match the client. Requests that such a rule allows do not reach the custom rules, and they do not show in Security Events ([phase interactions](https://developers.cloudflare.com/waf/troubleshooting/phase-interactions/)). Tell the human about each such rule. The human decides what to do.
- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/api/resources/firewall/subresources/access_rules/methods/list/ (checked 2026-11-13)
- Local help: checked with curl (`curl --help all`).

### CF-19 Check that traffic goes through the Cloudflare proxy

- Purpose: check that the zone belongs to `<account-id>`, and that requests to `<hostname>` reach the Cloudflare rules. Run it before CF-18, and before you report a block as containment. Phase: containment.
- Label: READ-ONLY, SENSITIVE
- Permission: `Zone Read` for the zone, `Account DNS Settings Read` for the account settings, and `DNS Read` for the zone settings and the records.
- Command: run the four reads. Run the last read once for each affected hostname.

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/zones/<zone-id>" \
    --write-out "\nHTTP %{http_code}\n" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/accounts/<account-id>/dns_settings" \
    --write-out "\nHTTP %{http_code}\n" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/zones/<zone-id>/dns_settings" \
    --write-out "\nHTTP %{http_code}\n" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

  ```bash
  curl -q -sS -G "https://api.cloudflare.com/client/v4/zones/<zone-id>/dns_records" \
    --data-urlencode 'name.exact=<hostname>' \
    --write-out "\nHTTP %{http_code}\n" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

- Output: the JSON body of each read, then a last line with the HTTP status. Read the status first. For a status other than `HTTP 200`, stop and tell the human. Look for: a value that fails one of these checks:
  - Zone read: `result.account.id` is `<account-id>`. Otherwise, the zone belongs to a different account. Stop and tell the human.
  - Zone read: `<hostname>` is `result.name`, or ends with a dot and `result.name`. Otherwise, a different zone serves the hostname. Stop and tell the human.
  - Zone read: `result.status` is `active`, and `result.paused` is `false`. A paused zone gets no security benefits ([zone details](https://developers.cloudflare.com/api/resources/zones/methods/get/)).
  - Account read: `enforce_dns_only` is `false`. When the field is missing or has another value, the result is unknown. That setting removes all Cloudflare protections, including the WAF, for every zone in the account ([Enforce DNS-only](https://developers.cloudflare.com/dns/proxy-status/enforce-dns-only/)). The Doc page shows the field only in an update example. Its place in the response is not documented.
  - Zone settings read: `result.zone_mode` is `standard`. The value `dns_only` means that the zone does not proxy HTTP traffic. For `cdn_only` or another value, ask the human.
  - Record read: each `A`, `AAAA`, and `CNAME` record of `<hostname>` has `proxied` set to `true`. Only these types can be proxied. Other types, such as `MX` or `TXT`, are always DNS-only, so ignore them here ([proxy status](https://developers.cloudflare.com/dns/proxy-status/)). When the read returns no `A`, `AAAA`, or `CNAME` record, the result is unknown. A wildcard record or another zone can serve the hostname. Ask the human.

  When a check fails or gives an unknown result, the block may not stop the traffic. Record the effect as not confirmed. Tell the human. Then run CF-14 for each hostname. It must show a Cloudflare `remote_ip`. The record read can show origin addresses. Keep them as internal context.

- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/api/resources/zones/methods/get/, https://developers.cloudflare.com/dns/proxy-status/enforce-dns-only/, https://developers.cloudflare.com/api/resources/dns/subresources/settings/subresources/zone/methods/get/, and https://developers.cloudflare.com/api/resources/dns/subresources/records/methods/list/ (checked 2026-11-13)
- Local help: checked with curl (`curl --help all`, options `-G` and `--data-urlencode`).

## IP lists

### CF-10 List account lists

- Purpose: list the custom lists of an account, and find the list ID. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: API token with `Account Filter Lists Read`.
- Command:

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/accounts/<account-id>/rules/lists" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

- Output: `result` is an array of lists. Each list has an `id` and a `name`. Look for: lists that you do not expect, and lists that rules use as an allow list.
- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/api/resources/rules/subresources/lists/methods/list/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

### CF-11 List the items of one list

- Purpose: read the entries of one list, with their item IDs. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: API token with `Account Filter Lists Read`.
- Command:

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/accounts/<account-id>/rules/lists/<list-id>/items?per_page=100" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

- Output: `result` is an array of items. Each item has an `id`, a value such as `ip`, and a `comment`. One response holds at most `per_page` items. Read every page (see the notes). Look for: IP ranges that you do not expect in an allow list.
- Approval: ask the human first.
- Doc: https://developers.cloudflare.com/api/resources/rules/subresources/lists/subresources/items/methods/list/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

Notes:

- To read every page:
  1. Read `result_info.cursors.after` in the response. The reference lists `after` and `before` under `result_info.cursors`. It does not say which one gives the next page. Use `after`. Check that the next page holds no item ID from the first page.
  2. Run the same command again with the cursor in the `cursor` query parameter. Use `-G --data-urlencode "cursor=<next-cursor>"`, so that curl encodes the value. The reference says to make no assumptions about the content of a cursor.

     ```bash
     curl -q -sS -G "https://api.cloudflare.com/client/v4/accounts/<account-id>/rules/lists/<list-id>/items?per_page=100" \
       --data-urlencode "cursor=<next-cursor>" \
       -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
     ```

  3. Ask the human before each page, because each page is a separate SENSITIVE command. Save each page to its own file.
  4. The reference does not say how to detect the last page. Treat the list as complete when a response has no items or no `result_info.cursors.after`. Tell the human that this rule is inferred.

- The `search` query parameter filters items. For an IP list, items must start with the search string.
- The `per_page` range is 1 to 500.

### CF-12 Add items to a list

- Purpose: add IPs or CIDRs to a list that a WAF rule uses. Phase: containment.
- Label: WRITE
- Permission: API token with `Account Filter Lists Edit`.
- Command: run step 1 of the rollback first. Do not run the add when that output already holds an item whose `ip` is exactly `<ip-or-cidr>`. The address is already in the list. The add replaces that item and overwrites its `comment`, and the rollback cannot restore the old comment.

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/accounts/<account-id>/rules/lists/<list-id>/items" \
    --request POST \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN") \
    --json '[{"ip":"<ip-or-cidr>","comment":"<comment>"}]'
  ```

- Output: `result.operation_id`. The API processes the change later. Check it with CF-13. Look for: status `completed`. Set `<comment>` to a value that only this change uses, such as the incident ID and the approval number.
- Side effect: any rule that uses the list now matches the new entries. If the list is an allow list, the entries gain access. If the list is a block list, the entries lose access.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Delete only the items that this add created.
  1. Before the add, run CF-11 with `&search=<ip-or-cidr>` added to the URL. Save the output.
  2. After the add, run the same CF-11 command again.
  3. Take the item IDs that are in the second output but not in the first. Keep only an item whose `ip` is exactly `<ip-or-cidr>` and whose `comment` is exactly `<comment>`. The search matches by prefix, so it can also return other addresses.
  4. When no item or more than one item matches, stop and ask the human.
  5. Delete the matching item by ID:

  ```bash
  curl -q -sS "https://api.cloudflare.com/client/v4/accounts/<account-id>/rules/lists/<list-id>/items" \
    --request DELETE \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN") \
    --json '{"items":[{"id":"<item-id>"}]}'
  ```

  The delete also returns an `operation_id`. The delete runs later, and it can fail. Record the rollback as done only after both checks pass: 6. Run CF-13 with the delete `operation_id` until `result.status` is `completed`. When it is `failed`, stop and tell the human. 7. Run the CF-11 command from step 1 again. Check that the deleted item ID is not in the output.

- Approval: human approval required.
- Doc: https://developers.cloudflare.com/api/resources/rules/subresources/lists/subresources/items/methods/create/ and https://developers.cloudflare.com/api/resources/rules/subresources/lists/subresources/items/methods/delete/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

Notes:

- Only one bulk operation can be pending for an account. The doc page says a second write while one is pending is rejected. It does not name the status code. Wait for the first to finish.
- The body is a JSON array. One object holds one `ip` and an optional `comment`. An `ip` can be an IPv4 or IPv6 address or CIDR.
- A list blocks nothing by itself. A WAF rule must refer to it.

### CF-13 Check the status of a list bulk operation

- Purpose: confirm that an item add or delete finished. Phase: verification.
- Label: READ-ONLY
- Permission: API token with `Account Filter Lists Read`.
- Command:

  ```bash
  curl -q -sS --noproxy '*' "https://api.cloudflare.com/client/v4/accounts/<account-id>/rules/lists/bulk_operations/<operation-id>" \
    -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN")
  ```

- Output: `result.status` is `pending`, `running`, `completed`, or `failed`. Look for: `failed`. The `--noproxy '*'` option makes curl connect directly to the Cloudflare API, because this command runs without approval. When the network needs a proxy, ask the human first.
- Doc: https://developers.cloudflare.com/api/resources/rules/subresources/lists/subresources/bulk_operations/methods/get/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

## Origin checks

Use these checks to learn whether an attacker can reach the origin without Cloudflare. CF-14 carries the SENSITIVE tag, so ask the human before each run. Run it only for a hostname that the human confirms the organisation owns. That confirmation meets the destination rule (safety rule 10 in `../SKILL.md`). It does not replace the approval. Run CF-15 and CF-16 only against an origin that the human confirms the organisation owns. Ask the human first.

Each `curl` command in this file starts with `-q`, so that curl does not read a `.curlrc` file. Such a file can add options, for example one that follows a redirect to another host. Each command uses `--noproxy '*'`, so that curl connects directly and ignores a proxy in the environment. A proxy would make the test show the proxy, not the origin. For an IPv6 origin, put the address in brackets, such as `[<origin-ipv6>]`. The curl manual says to give IPv6 addresses within brackets.

### CF-14 Request a path through the Cloudflare proxy

- Purpose: record the normal response for a hostname and path. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command makes a public HTTPS request.
- Command:

  ```bash
  curl -q -sS --noproxy '*' -o /dev/null -w '%{http_code} %{remote_ip}\n' 'https://<hostname>/<path>'
  ```

- Output: the HTTP status code and the IP that answered. Look for: a `remote_ip` in a Cloudflare range. That shows the hostname is proxied. A `remote_ip` that is the origin shows the DNS record is not proxied. The local resolver can give an internal answer for the same name (split-view DNS). Then `remote_ip` can be a private origin address, and the request goes over the internal network. A private or non-Cloudflare `remote_ip` is not a public baseline. Record it as internal context.
- Approval: ask the human first.
- Doc: https://curl.se/docs/manpage.html and https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-considerations.html for split-view DNS (checked 2026-11-12)
- Local help: checked with curl (`curl --help all` and `man curl`, variables `http_code` and `remote_ip`).

Notes:

- Use a path that has no side effect. Use a `GET` request only.
- Compare this result with CF-15 and CF-16.

### CF-15 Request the same path directly from the origin with the hostname kept

- Purpose: test whether the origin answers without Cloudflare in front. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command makes a direct network request to the origin.
- Command:

  ```bash
  curl -q -sS --noproxy '*' -o /dev/null -w '%{http_code} %{remote_ip}\n' --resolve '<hostname>:443:<origin-ip>' 'https://<hostname>/<path>'
  ```

- Output: the HTTP status code and the IP that answered. When that IP is not `<origin-ip>`, the request did not test the origin. Stop and tell the human. Look for: a `200` or any normal response. That means the origin answers requests from the test network. Report a public bypass of the Cloudflare WAF and rate limits only when two more facts are true:
  - `<origin-ip>` is a public address. A private address, such as `10.0.0.0/8`, `172.16.0.0/12`, or `192.168.0.0/16` ([RFC 1918](https://www.rfc-editor.org/rfc/rfc1918)), or `fc00::/7` ([RFC 4193](https://www.rfc-editor.org/rfc/rfc4193)), shows internal reachability only.
  - The same test from a network outside the organisation also gets a normal response. Ask the human to run that test or to approve it.

  An HTTP 403 means the origin answered and refused this one request. The origin is still reachable from the test network, so do not report the bypass as closed. A timeout or a connection refusal means the origin refused this connection from your network only. To show that the bypass is closed, ask the human to check the origin access controls. An example is a firewall that allows only Cloudflare IP ranges.

- Approval: ask the human first. Run this command only against an origin that the human confirms the organisation owns.
- Doc: https://curl.se/docs/manpage.html (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`, option `--resolve <[+]host:port:addr[,addr]...>`, and `man curl`, option `--noproxy`, where a single `*` matches all hosts).

Notes:

- `--resolve` makes curl connect to `<origin-ip>` and keep `<hostname>` for TLS and the `Host` header. The certificate check still works.
- The Cloudflare guide on origin protection lists the fixes: allow only Cloudflare IP ranges, use Authenticated Origin Pulls, or use Cloudflare Tunnel. See https://developers.cloudflare.com/fundamentals/security/protect-your-origin-server/.

### CF-16 Request the same path directly from the origin with a Host header

- Purpose: test the origin when `--resolve` does not work. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command makes a direct network request to the origin.
- Command:

  ```bash
  curl -q -sS --noproxy '*' -k -o /dev/null -w '%{http_code} %{remote_ip}\n' -H 'Host: <hostname>' 'https://<origin-ip>/<path>'
  ```

- Output: the HTTP status code and the IP that answered. When that IP is not `<origin-ip>`, the request did not test the origin. Stop and tell the human. Look for: a `200` or any normal response. That means the origin answers requests from the test network. Report a public WAF bypass only when the two conditions in the CF-15 output are true. Compare the status code with CF-14.
- Approval: ask the human first. Run this command only against an origin that the human confirms the organisation owns.
- Doc: https://curl.se/docs/manpage.html (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`, options `-k, --insecure` and `-H, --header`).

Notes:

- `-k` turns off the certificate check. The origin certificate is for `<hostname>`, not for the IP. Without `-k`, curl fails with a certificate error.
- This form sends the IP, not the hostname, in the TLS server name. The origin can pick a default site. Prefer CF-15 when it works.
- Do not use `-k` for any command that sends a secret.
