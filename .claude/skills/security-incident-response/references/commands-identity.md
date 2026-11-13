# Identity provider commands: Okta and Google Workspace

This file covers sign-in logs, MFA changes, session revocation, and OAuth token checks for Okta and Google Workspace. Every command uses `curl` against the vendor API, with `jq` to shape the output.
Labels and the approval rules are in `../SKILL.md`. Read them before you run any command from this file.

## Contents

- [Before you start](#before-you-start)
- [Okta](#okta)
  - [IDP-01 Find an Okta user ID](#idp-01-find-an-okta-user-id)
  - [IDP-02 List Okta sign-in events for a user](#idp-02-list-okta-sign-in-events-for-a-user)
  - [IDP-03 List Okta MFA changes for a user](#idp-03-list-okta-mfa-changes-for-a-user)
  - [IDP-04 List the enrolled factors of an Okta user](#idp-04-list-the-enrolled-factors-of-an-okta-user)
  - [IDP-05 Revoke all Okta sessions for a user](#idp-05-revoke-all-okta-sessions-for-a-user)
  - [IDP-06 Suspend an Okta user](#idp-06-suspend-an-okta-user)
- [Google Workspace](#google-workspace)
  - [IDP-07 List Google sign-in events for a user](#idp-07-list-google-sign-in-events-for-a-user)
  - [IDP-08 List Google 2-Step Verification changes in login events](#idp-08-list-google-2-step-verification-changes-in-login-events)
  - [IDP-09 List Google 2-Step Verification changes in admin events](#idp-09-list-google-2-step-verification-changes-in-admin-events)
  - [IDP-10 Show the 2-Step Verification status of a Google user](#idp-10-show-the-2-step-verification-status-of-a-google-user)
  - [IDP-11 List Google users without 2-Step Verification](#idp-11-list-google-users-without-2-step-verification)
  - [IDP-12 Sign a Google user out of all sessions](#idp-12-sign-a-google-user-out-of-all-sessions)
  - [IDP-13 List the OAuth tokens of a Google user](#idp-13-list-the-oauth-tokens-of-a-google-user)
  - [IDP-14 Delete an OAuth token of a Google user](#idp-14-delete-an-oauth-token-of-a-google-user)

## Before you start

Tokens:

- `OKTA_API_TOKEN` holds the Okta credential. A human sets `OKTA_API_TOKEN`. The agent never reads, prints, or stores it.
- `GOOGLE_ACCESS_TOKEN` holds an OAuth 2.0 access token. A human sets `GOOGLE_ACCESS_TOKEN`. The agent never reads, prints, or stores it.
- Each command passes the token header to curl as a file, with `@<(printf ...)`. `printf` runs inside the shell, so the token does not show in a process list. The curl FAQ says to keep passwords off the command line, so that they do not show in `ps` output. This form needs bash or zsh. See https://curl.se/docs/faq.html and https://curl.se/docs/manpage.html#-H (checked 2026-11-12).
- Each Google entry names the OAuth scope that the access token needs. The human gets a token with that scope from an admin account.
- The Okta commands use the `SSWS` header scheme for an API token. For an OAuth 2.0 access token, replace `SSWS` with `Bearer`.
- An Okta API token has the privileges of the admin who created it. Use the least-privileged admin that the entry allows.

Placeholders:

| Placeholder                | Meaning                                                                                         |
| -------------------------- | ----------------------------------------------------------------------------------------------- |
| `<okta-domain>`            | The host name of the Okta org.                                                                  |
| `<okta-user-id>`           | The Okta user ID. Get it with IDP-01.                                                           |
| `<user-login>`             | The Okta login of the user, usually an email address.                                           |
| `<url-encoded-user-login>` | The `<user-login>` value with each special character percent-encoded, for example `@` as `%40`. |
| `<google-user-key>`        | The primary email or the unique ID of a Google user. Reports entries also accept `all`.         |
| `<user-email>`             | The primary email of a Google user.                                                             |
| `<client-id>`              | The OAuth client ID of an app. Get it with IDP-13.                                              |
| `<start-time-iso8601>`     | The start of the window, for example `2026-11-01T00:00:00.000Z`.                                |
| `<end-time-iso8601>`       | The end of the window, in the same format.                                                      |
| `<next-page-token>`        | The `nextPageToken` value from the previous Google response.                                    |
| `<next-page-url>`          | The URL in the `rel="next"` `Link` header of the previous Okta response.                        |
| `<headers-file>`           | A new file in the evidence folder for the response headers. Use a new name for each page.       |
| `<response-file>`          | A new file in the evidence folder for the response body. Use a new name for each call.          |

Notes that apply to all entries:

- The Google API host `admin.googleapis.com` is a fixed vendor endpoint. It is not a tenant host.
- Each `curl` command starts with `-q`, so that curl does not read a `.curlrc` file. Such a file can add options, such as `--location-trusted`, which sends the token to the host of a redirect.
- Each `curl` command saves the response body to `<response-file>`. The `jq` command then reads that file. Save both only to the evidence folder (safety rule 14 in `../SKILL.md`).
- Each `curl` command prints the HTTP status with `--write-out`. Run `jq` only after you read the status. An API error body can make a `jq` filter print an empty result with exit status 0.
- For Okta, continue only when the printed status is `HTTP 200`. The Google doc pages name no success code, so continue only on a `2xx` status. Otherwise stop and tell the human.
- Each extra page is a separate command. The human approves each page. Save each page to its own files.
- Local help: `curl --help all` and `man curl` list `--dump-header`, `--output`, `--write-out`, and the `http_code` variable. The curl manual at https://curl.se/docs/manpage.html describes `--dump-header` and `--fail-with-body` (checked 2026-11-12).
- Sign-in and audit data is SENSITIVE. It holds user names, IP addresses, and locations.

Okta paging steps, for IDP-02 and IDP-03. Okta says to always follow the `next` links. Do not page by changing `since` and `until`:

1. Run `grep -i '^link:.*rel="next"' <headers-file>`.
2. If the command prints no line, you have every page that Okta returns now. These requests have `since` and `until`, so the last page has no `next` link. Okta says that some events can arrive late, and it returns no data older than 90 days ([System Log query](https://developer.okta.com/docs/reference/system-log-query/)). For a recent window, run the query again later and compare. Record any part of the window older than 90 days as a gap.
3. Otherwise, read the URL between `<` and `>`. Check that its host is `<okta-domain>`.
4. Ask the human to approve the next page.
5. Run the `curl` command again with the same options. Remove `--get` and each `--data-urlencode` option. Use `'<next-page-url>'` as the URL, unchanged and in single quotes, because the URL can hold `$`. Stop and ask the human when the URL holds a single quote. Use new file names.
6. Read the status. Run the `jq` command on the new `<response-file>`. Repeat from step 1 with the new `<headers-file>`.

## Okta

### IDP-01 Find an Okta user ID

- Purpose: Get the `id` of one user. Later Okta entries need it. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: OAuth scope `okta.users.read`, or an API token from an admin who can read users.
- Command:
  1. Save the response. The command reads the user by login, not by search:

     ```bash
     curl -q --silent --show-error --fail-with-body \
       "https://<okta-domain>/api/v1/users/<url-encoded-user-login>" \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: SSWS %s\n' "$OKTA_API_TOKEN") \
       --header "Accept: application/json"
     ```

  2. Read the printed status. Continue only when it is `HTTP 200`. For any other status, stop and tell the human.
  3. Show the user:

     ```bash
     jq '{id, status, login: .profile.login, lastLogin, lastUpdated}' <response-file>
     ```

- Output: One object for the user. Look for: `status` other than `ACTIVE`, or an unexpected `lastLogin`. Do not use the `search` parameter of the list endpoint to rule out an account. Okta says that search results come from an eventually consistent data source and may not show the latest information. A login that holds a `/` can be read only by user ID. In that case, ask the human for the ID. A human sets `OKTA_API_TOKEN`. The agent never reads, prints, or stores it.
- Approval: ask the human first.
- Doc: https://developer.okta.com/docs/api/openapi/okta-management/management/tags/user/other/getuser and https://developer.okta.com/docs/api/openapi/okta-management/management/tags/user/other/listusers (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`) and jq (`jq --help`).

### IDP-02 List Okta sign-in events for a user

- Purpose: Show the `user.session.start` events of one user in a time window, with outcome, IP address, device, and place. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: OAuth scope `okta.logs.read`, or an API token from an admin who can read the System Log.
- Command:
  1. Save the response and the headers:

     ```bash
     curl -q --silent --show-error --fail-with-body --get "https://<okta-domain>/api/v1/logs" \
       --dump-header <headers-file> \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: SSWS %s\n' "$OKTA_API_TOKEN") \
       --header "Accept: application/json" \
       --data-urlencode "since=<start-time-iso8601>" \
       --data-urlencode "until=<end-time-iso8601>" \
       --data-urlencode 'filter=eventType eq "user.session.start" and actor.id eq "<okta-user-id>"' \
       --data-urlencode "sortOrder=ASCENDING" \
       --data-urlencode "limit=1000"
     ```

  2. Read the printed status. Continue only when it is `HTTP 200`.
  3. Show the events:

     ```bash
     jq '.[] | {published, outcome: .outcome.result, reason: .outcome.reason, ip: .client.ipAddress, userAgent: .client.userAgent.rawUserAgent, geo: .client.geographicalContext}' <response-file>
     ```

- Output: One object per `user.session.start` event on this page, oldest first. Okta says that this event does not record every authentication or factor check. A `SUCCESS` result does not show that the user got a session, because more authentication or a later policy denial can follow. The event also does not show app access or token grants. For those, ask the human to approve a query for related events, such as `user.authentication.sso`, `user.authentication.auth_via_mfa`, `policy.evaluate_sign_on`, and `app.oauth2.as.token.grant`. Otherwise, record the gap in the incident log. Look for: `FAILURE` runs followed by `SUCCESS`, a new `ip`, an unknown `userAgent`, or a `geo` country the user does not use. A page holds at most 1000 events. The result is incomplete until you follow the Okta paging steps in Before you start. Do not narrow the time window to get fewer events. Add `and outcome.result eq "FAILURE"` to the filter to see failures only. A human sets `OKTA_API_TOKEN`. The agent never reads, prints, or stores it.
- Approval: ask the human first.
- Doc: https://developer.okta.com/docs/api/openapi/okta-management/management/tags/systemlog/other/listlogevents, https://developer.okta.com/docs/reference/system-log-query/, and https://developer.okta.com/docs/reference/api/event-types/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`) and jq (`jq --help`).

### IDP-03 List Okta MFA changes for a user

- Purpose: Show factor enrolment, reset, and bypass events for one user. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: OAuth scope `okta.logs.read`, or an API token from an admin who can read the System Log.
- Command:
  1. Save the response and the headers:

     ```bash
     curl -q --silent --show-error --fail-with-body --get "https://<okta-domain>/api/v1/logs" \
       --dump-header <headers-file> \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: SSWS %s\n' "$OKTA_API_TOKEN") \
       --header "Accept: application/json" \
       --data-urlencode "since=<start-time-iso8601>" \
       --data-urlencode "until=<end-time-iso8601>" \
       --data-urlencode 'filter=(eventType eq "user.mfa.factor.activate" or eventType eq "user.mfa.factor.deactivate" or eventType eq "user.mfa.factor.reset_all" or eventType eq "user.mfa.factor.suspend" or eventType eq "user.mfa.factor.update" or eventType eq "user.mfa.attempt_bypass") and (actor.id eq "<okta-user-id>" or target.id eq "<okta-user-id>")' \
       --data-urlencode "sortOrder=ASCENDING" \
       --data-urlencode "limit=1000"
     ```

  2. Read the printed status. Continue only when it is `HTTP 200`.
  3. Show the events:

     ```bash
     jq '.[] | {published, eventType, message: .displayMessage, outcome: .outcome.result, actor: .actor.alternateId, ip: .client.ipAddress, targets: [.target[]? | .alternateId]}' <response-file>
     ```

- Output: One object per factor event on this page. A page holds at most 1000 events. The result is incomplete until you follow the Okta paging steps in Before you start. Look for: `user.mfa.factor.activate` from a new IP, `user.mfa.factor.reset_all` or `deactivate` that the user did not ask for, and an `actor` who is not the user. Event names come from the Okta event types catalogue. A human sets `OKTA_API_TOKEN`. The agent never reads, prints, or stores it.
- Approval: ask the human first.
- Doc: https://developer.okta.com/docs/reference/api/event-types/ and https://developer.okta.com/docs/reference/system-log-query/ (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`) and jq (`jq --help`).

### IDP-04 List the enrolled factors of an Okta user

- Purpose: Show the factors that the Okta Factors API returns for the user, and all authenticator enrollments of the user. Compare both with IDP-03. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: OAuth scope `okta.users.read`, or an API token from an admin who can read users.
- Command:
  1. Save the Factors API response:

     ```bash
     curl -q --silent --show-error --fail-with-body "https://<okta-domain>/api/v1/users/<okta-user-id>/factors" \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: SSWS %s\n' "$OKTA_API_TOKEN") \
       --header "Accept: application/json"
     ```

  2. Read the printed status. Continue only when it is `HTTP 200`.
  3. Show the factors:

     ```bash
     jq '.[] | {id, factorType, provider, vendorName, status, created, lastUpdated}' <response-file>
     ```

  4. Ask the human to approve the next call. Save the authenticator enrollments to a new `<response-file>`:

     ```bash
     curl -q --silent --show-error --fail-with-body "https://<okta-domain>/api/v1/users/<okta-user-id>/authenticator-enrollments" \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: SSWS %s\n' "$OKTA_API_TOKEN") \
       --header "Accept: application/json"
     ```

  5. Read the printed status. Continue only when it is `HTTP 200`.
  6. Show the metadata of each enrollment:

     ```bash
     jq '.[] | {id, type, key, status, created, lastUpdated}' <response-file>
     ```

- Output: Step 3 prints one object per factor. The Factors API does not return every factor. The Okta page says it returns only "enrolled factors that are REQUIRED or OPTIONAL in the highest priority authenticator enrollment policy". A factor outside that policy does not show, so an empty list does not prove that the user has no factor. Step 6 prints one object per authenticator enrollment, with metadata only. The call does not set `discloseIdentifiers`. The Okta page labels the request "Identity Engine" and does not describe paging. Look for: a `created` date inside the incident window, an `sms`, `call`, `phone`, or `email` enrollment that the user does not know, or a `status` of `PENDING_ACTIVATION`. A human sets `OKTA_API_TOKEN`. The agent never reads, prints, or stores it.
- Approval: ask the human first.
- Doc: https://developer.okta.com/docs/api/openapi/okta-management/management/tags/userfactor/other/listfactors and https://developer.okta.com/docs/api/openapi/okta-management/management/tags/userauthenticatorenrollments/other/listauthenticatorenrollments (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`) and jq (`jq --help`).

### IDP-05 Revoke all Okta sessions for a user

- Purpose: End every Okta session of one user and revoke their OAuth and OpenID Connect tokens. Phase: containment.
- Label: WRITE
- Permission: OAuth scope `okta.users.manage`, or an API token from an admin who can manage user sessions.
- Command:

  ```bash
  curl -q --silent --show-error --fail-with-body --request DELETE \
    --write-out "HTTP %{http_code}\n" \
    --header @<(printf 'Authorization: SSWS %s\n' "$OKTA_API_TOKEN") \
    "https://<okta-domain>/api/v1/users/<okta-user-id>/sessions?oauthTokens=true&forgetDevices=true"
  ```

- Output: `HTTP 204` means the call worked. Look for: `403` (the token lacks rights), `404` (wrong user ID), or `429` (rate limit). A human sets `OKTA_API_TOKEN`. The agent never reads, prints, or stores it.
- Side effect: The user must sign in again. `oauthTokens=true` also revokes issued refresh and access tokens. The default is `false`, so a call without this parameter leaves them valid. `forgetDevices=true` clears the remembered factors on all devices. The call does not clear sessions that web or native apps created. It does not change the password or the factors.
- Rollback: None. Okta cannot restore a session or a token. The user signs in again.
- Approval: human approval required.
- Doc: https://developer.okta.com/docs/api/openapi/okta-management/management/tags/usersessions/other/revokeusersessions (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

### IDP-06 Suspend an Okta user

- Purpose: Block all sign-ins of one user while the team investigates. Phase: containment.
- Label: WRITE
- Permission: OAuth scope `okta.users.manage`, or an API token from an admin who can suspend users.
- Command: run IDP-01 first. Record the `status`. Run the suspend only when the status is `ACTIVE`.

  ```bash
  curl -q --silent --show-error --fail-with-body --request POST \
    --write-out "HTTP %{http_code}\n" \
    --header @<(printf 'Authorization: SSWS %s\n' "$OKTA_API_TOKEN") \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    "https://<okta-domain>/api/v1/users/<okta-user-id>/lifecycle/suspend"
  ```

- Output: `HTTP 200` means the status is now `SUSPENDED`. Look for: `400` (the user is not `ACTIVE`, so Okta cannot suspend the user) or `403`. A human sets `OKTA_API_TOKEN`. The agent never reads, prints, or stores it.
- Side effect: The user cannot sign in. Okta keeps the group and app assignments. Only an `ACTIVE` user can be suspended. Okta says that suspension stops all active Okta sessions of the user. The unsuspend does not restore those sessions, so the user must sign in again. The page names only Okta sessions. It does not say what happens to sessions that an app created itself. Run IDP-05 as well.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Run it only when the suspend in this run printed `HTTP 200`. Otherwise do nothing, because the unsuspend changes a `SUSPENDED` user to `ACTIVE`. `curl -q --silent --show-error --fail-with-body --request POST --write-out "HTTP %{http_code}\n" --header @<(printf 'Authorization: SSWS %s\n' "$OKTA_API_TOKEN") --header "Content-Type: application/json" "https://<okta-domain>/api/v1/users/<okta-user-id>/lifecycle/unsuspend"`
- Approval: human approval required.
- Doc: https://developer.okta.com/docs/api/openapi/okta-management/management/tags/userlifecycle/other/suspenduser, https://developer.okta.com/docs/api/openapi/okta-management/management/tags/userlifecycle/other/unsuspenduser, and https://help.okta.com/en-us/Content/topics/users-groups-profiles/usgp-deactivate-user-account.htm (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

## Google Workspace

### IDP-07 List Google sign-in events for a user

- Purpose: Show login events of one user in a time window, with IP address and login parameters. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: OAuth scope `https://www.googleapis.com/auth/admin.reports.audit.readonly`
- Command:
  1. Save the response:

     ```bash
     curl -q --silent --show-error --fail-with-body --get \
       "https://admin.googleapis.com/admin/reports/v1/activity/users/<google-user-key>/applications/login" \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: Bearer %s\n' "$GOOGLE_ACCESS_TOKEN") \
       --header "Accept: application/json" \
       --data-urlencode "startTime=<start-time-iso8601>" \
       --data-urlencode "endTime=<end-time-iso8601>" \
       --data-urlencode "maxResults=1000"
     ```

  2. Read the printed status. Continue only on a `2xx` status.
  3. Show the events:

     ```bash
     jq '{nextPageToken, activities: [.items[]? | {time: .id.time, user: .actor.email, ip: .ipAddress, events: [.events[] | {name, type, parameters: (.parameters // [])}]}]}' <response-file>
     ```

- Output: One object per login event on this page. Look for: `login_failure` runs, then `login_success` with `is_suspicious` true, an unknown `ip`, or unexpected `login_type` values. If `nextPageToken` is not null, ask the human to approve one more command. Add `--data-urlencode "pageToken=<next-page-token>"` and use a new `<response-file>`. The list is complete when `nextPageToken` is null. A human sets `GOOGLE_ACCESS_TOKEN`. The agent never reads, prints, or stores it.
- Approval: ask the human first.
- Doc: https://developers.google.com/workspace/admin/reports/v1/reference/activities/list and https://developers.google.com/workspace/admin/reports/v1/appendix/activity/login (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`) and jq (`jq --help`).

### IDP-08 List Google 2-Step Verification changes in login events

- Purpose: Find 2-Step Verification, passkey, recovery, and password changes that users made themselves. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: OAuth scope `https://www.googleapis.com/auth/admin.reports.audit.readonly`
- Command:
  1. Save the response:

     ```bash
     curl -q --silent --show-error --fail-with-body --get \
       "https://admin.googleapis.com/admin/reports/v1/activity/users/<google-user-key>/applications/login" \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: Bearer %s\n' "$GOOGLE_ACCESS_TOKEN") \
       --header "Accept: application/json" \
       --data-urlencode "startTime=<start-time-iso8601>" \
       --data-urlencode "endTime=<end-time-iso8601>" \
       --data-urlencode "maxResults=1000"
     ```

  2. Read the printed status. Continue only on a `2xx` status.
  3. Show the events:

     ```bash
     jq '{nextPageToken, activities: [.items[]? | select(any(.events[]; .name | IN("2sv_disable", "2sv_enroll", "passkey_enrolled", "passkey_removed", "recovery_email_edit", "recovery_phone_edit", "password_edit"))) | {time: .id.time, user: .actor.email, ip: .ipAddress, events: [.events[] | {name, type}]}]}' <response-file>
     ```

- Output: Only events in the list, on this page. Look for: `2sv_disable`, or `2sv_enroll`, `passkey_enrolled`, and `recovery_phone_edit` close to a suspicious login. Set `<google-user-key>` to `all` to scan every user. If `nextPageToken` is not null, ask the human to approve one more command. Add `--data-urlencode "pageToken=<next-page-token>"` and use a new `<response-file>`. The list is complete when `nextPageToken` is null. A human sets `GOOGLE_ACCESS_TOKEN`. The agent never reads, prints, or stores it.
- Approval: ask the human first.
- Doc: https://developers.google.com/workspace/admin/reports/v1/appendix/activity/login (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`) and jq (`jq --help`).

### IDP-09 List Google 2-Step Verification changes in admin events

- Purpose: Find 2-Step Verification changes that an admin made for a user. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: OAuth scope `https://www.googleapis.com/auth/admin.reports.audit.readonly`
- Command:
  1. Save the response:

     ```bash
     curl -q --silent --show-error --fail-with-body --get \
       "https://admin.googleapis.com/admin/reports/v1/activity/users/all/applications/admin" \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: Bearer %s\n' "$GOOGLE_ACCESS_TOKEN") \
       --header "Accept: application/json" \
       --data-urlencode "startTime=<start-time-iso8601>" \
       --data-urlencode "endTime=<end-time-iso8601>" \
       --data-urlencode "maxResults=1000"
     ```

  2. Read the printed status. Continue only on a `2xx` status.
  3. Show the events:

     ```bash
     jq '{nextPageToken, activities: [.items[]? | select(any(.events[]; .name | IN("TURN_OFF_2_STEP_VERIFICATION", "USER_ENROLLED_IN_TWO_STEP_VERIFICATION", "USER_PUT_IN_TWO_STEP_VERIFICATION_GRACE_PERIOD", "GENERATE_2SV_SCRATCH_CODES", "DELETE_2SV_SCRATCH_CODES", "SECURITY_KEY_REGISTERED_FOR_USER", "REVOKE_SECURITY_KEY", "PASSKEY_REVOKED", "USER_CREATED_PASSKEY_REVOKE", "UNENROLL_USER_FROM_STRONG_AUTH"))) | {time: .id.time, admin: .actor.email, ip: .ipAddress, events: [.events[] | {name, affectedUser: ([.parameters[]? | select(.name == "USER_EMAIL") | .value] | first)}]}]}' <response-file>
     ```

- Output: One object per matching admin event on this page. The `admin` field is the actor. The `affectedUser` field is the user who was changed. Look for: `TURN_OFF_2_STEP_VERIFICATION`, `USER_PUT_IN_TWO_STEP_VERIFICATION_GRACE_PERIOD`, `GENERATE_2SV_SCRATCH_CODES`, or an `admin` you do not know. Filter `affectedUser` to one user with `select(.events[].affectedUser == "<user-email>")` in `jq`. If `nextPageToken` is not null, ask the human to approve one more command. Add `--data-urlencode "pageToken=<next-page-token>"` and use a new `<response-file>`. The list is complete when `nextPageToken` is null. A human sets `GOOGLE_ACCESS_TOKEN`. The agent never reads, prints, or stores it.
- Approval: ask the human first.
- Doc: https://developers.google.com/workspace/admin/reports/v1/appendix/activity/admin-user-settings (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`) and jq (`jq --help`).

### IDP-10 Show the 2-Step Verification status of a Google user

- Purpose: Show whether one user is enrolled in and forced to use 2-Step Verification. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: OAuth scope `https://www.googleapis.com/auth/admin.directory.user.readonly`
- Command:
  1. Save the response:

     ```bash
     curl -q --silent --show-error --fail-with-body \
       "https://admin.googleapis.com/admin/directory/v1/users/<google-user-key>" \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: Bearer %s\n' "$GOOGLE_ACCESS_TOKEN") \
       --header "Accept: application/json"
     ```

  2. Read the printed status. Continue only on a `2xx` status.
  3. Show the user:

     ```bash
     jq '{primaryEmail, isEnrolledIn2Sv, isEnforcedIn2Sv, lastLoginTime, suspended, isAdmin}' <response-file>
     ```

- Output: One object. Look for: `isEnrolledIn2Sv` false, `isEnforcedIn2Sv` false, or `isAdmin` true on an account that has no 2-Step Verification. A human sets `GOOGLE_ACCESS_TOKEN`. The agent never reads, prints, or stores it.
- Approval: ask the human first.
- Doc: https://developers.google.com/workspace/admin/directory/reference/rest/v1/users/get and https://developers.google.com/workspace/admin/directory/reference/rest/v1/users (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`) and jq (`jq --help`).

### IDP-11 List Google users without 2-Step Verification

- Purpose: Find every user who is not enrolled in 2-Step Verification. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: OAuth scope `https://www.googleapis.com/auth/admin.directory.user.readonly`
- Command:
  1. Save the response:

     ```bash
     curl -q --silent --show-error --fail-with-body --get "https://admin.googleapis.com/admin/directory/v1/users" \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: Bearer %s\n' "$GOOGLE_ACCESS_TOKEN") \
       --header "Accept: application/json" \
       --data-urlencode "customer=my_customer" \
       --data-urlencode "query=isEnrolledIn2Sv=false" \
       --data-urlencode "maxResults=500"
     ```

  2. Read the printed status. Continue only on a `2xx` status.
  3. Show the users:

     ```bash
     jq '{nextPageToken, users: [.users[]? | {primaryEmail, isEnrolledIn2Sv, isEnforcedIn2Sv, lastLoginTime, suspended, isAdmin}]}' <response-file>
     ```

- Output: One object per user without 2-Step Verification on this page. Look for: admins in the list, and accounts with a recent `lastLoginTime`. If `nextPageToken` is not null, ask the human to approve one more command. Add `--data-urlencode "pageToken=<next-page-token>"` and use a new `<response-file>`. When `nextPageToken` is null, you have every page. The data can still be old. Google says that a change can take up to 36 hours to show in all search results. A user who removed 2-Step Verification recently can be missing from the list. Record this lag in the incident log. For each user at risk, run IDP-10 and check the 2-Step Verification events with IDP-08 and IDP-09. A human sets `GOOGLE_ACCESS_TOKEN`. The agent never reads, prints, or stores it.
- Approval: ask the human first.
- Doc: https://developers.google.com/workspace/admin/directory/reference/rest/v1/users/list and https://developers.google.com/workspace/admin/directory/v1/guides/search-users (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`) and jq (`jq --help`).

### IDP-12 Sign a Google user out of all sessions

- Purpose: End all web and device sessions of one user. Phase: containment.
- Label: WRITE
- Permission: OAuth scope `https://www.googleapis.com/auth/admin.directory.user.security`
- Command:

  ```bash
  curl -q --silent --show-error --fail-with-body --request POST \
    --write-out "HTTP %{http_code}\n" \
    --header @<(printf 'Authorization: Bearer %s\n' "$GOOGLE_ACCESS_TOKEN") \
    --header "Content-Length: 0" \
    "https://admin.googleapis.com/admin/directory/v1/users/<google-user-key>/signOut"
  ```

- Output: a `2xx` status means the call worked. The doc page does not name the exact code or body. Look for: `403` (the token lacks the scope or the admin role) or `404` (wrong user key). A human sets `GOOGLE_ACCESS_TOKEN`. The agent never reads, prints, or stores it.
- Side effect: Google signs the user out of all web and device sessions and resets the sign-in cookies. The user must sign in again. The docs do not say that the call revokes OAuth tokens or changes the password. Use IDP-13 and IDP-14 for tokens.
- Rollback: None. Google cannot restore a session. The user signs in again.
- Approval: human approval required.
- Doc: https://developers.google.com/workspace/admin/directory/reference/rest/v1/users/signOut (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).

### IDP-13 List the OAuth tokens of a Google user

- Purpose: Show which apps hold OAuth tokens for one user. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: OAuth scope `https://www.googleapis.com/auth/admin.directory.user.security`
- Command:
  1. Save the response:

     ```bash
     curl -q --silent --show-error --fail-with-body \
       "https://admin.googleapis.com/admin/directory/v1/users/<google-user-key>/tokens" \
       --output <response-file> \
       --write-out "HTTP %{http_code}\n" \
       --header @<(printf 'Authorization: Bearer %s\n' "$GOOGLE_ACCESS_TOKEN") \
       --header "Accept: application/json"
     ```

  2. Read the printed status. Continue only on a `2xx` status.
  3. Show the apps:

     ```bash
     jq '.items[]? | {clientId, displayText, scopes, anonymous, nativeApp}' <response-file>
     ```

- Output: One object per app. The response holds metadata only. It has no token value. Look for: an app the user does not know, `anonymous` true (an app that is not registered with Google), or broad `scopes` such as Gmail or Drive. A human sets `GOOGLE_ACCESS_TOKEN`. The agent never reads, prints, or stores it.
- Approval: ask the human first.
- Doc: https://developers.google.com/workspace/admin/directory/reference/rest/v1/tokens/list and https://developers.google.com/workspace/admin/directory/reference/rest/v1/tokens (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`) and jq (`jq --help`).

### IDP-14 Delete an OAuth token of a Google user

- Purpose: Remove the access of one app to the account of one user. Phase: containment.
- Label: WRITE
- Permission: OAuth scope `https://www.googleapis.com/auth/admin.directory.user.security`
- Command:

  ```bash
  curl -q --silent --show-error --fail-with-body --request DELETE \
    --write-out "HTTP %{http_code}\n" \
    --header @<(printf 'Authorization: Bearer %s\n' "$GOOGLE_ACCESS_TOKEN") \
    "https://admin.googleapis.com/admin/directory/v1/users/<google-user-key>/tokens/<client-id>"
  ```

- Output: `HTTP 204` with an empty body means the call worked. Look for: `404` (the app holds no token for this user). Run IDP-13 again to confirm that the app is gone. A human sets `GOOGLE_ACCESS_TOKEN`. The agent never reads, prints, or stores it.
- Side effect: The app loses access to the account of the user. A working app stops until the user grants consent again.
- Rollback: None. Google cannot restore a deleted token. If the human decides that the app is legitimate, the user can grant consent to the app again.
- Approval: human approval required.
- Doc: https://developers.google.com/workspace/admin/directory/reference/rest/v1/tokens/delete (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`).
