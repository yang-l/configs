# Azure and Entra ID commands

Commands for Azure and Microsoft Entra ID during an incident. They cover sign-in and audit logs, the Azure activity log, app registrations, consent grants, and containment. Microsoft Graph calls run through `az rest`. The commands in this file were checked against vendor docs only, not against a local CLI.
Labels and the approval rules are in `../SKILL.md`. Read them before you run any command from this file.

## Contents

- [Before you start](#before-you-start)
- [Setup check](#setup-check)
  - [AZ-01 Show the signed-in tenant and subscription](#az-01-show-the-signed-in-tenant-and-subscription)
- [Entra logs](#entra-logs)
  - [AZ-02 List sign-ins for one user in a time range](#az-02-list-sign-ins-for-one-user-in-a-time-range)
  - [AZ-03 List directory audit events in a time range](#az-03-list-directory-audit-events-in-a-time-range)
  - [AZ-04 List directory audit events started by one user](#az-04-list-directory-audit-events-started-by-one-user)
- [Azure activity log](#azure-activity-log)
  - [AZ-05 List activity log events for one caller](#az-05-list-activity-log-events-for-one-caller)
- [App registrations](#app-registrations)
  - [AZ-06 List app registrations](#az-06-list-app-registrations)
  - [AZ-07 List password credential metadata of an app](#az-07-list-password-credential-metadata-of-an-app)
  - [AZ-08 List certificate credential metadata of an app](#az-08-list-certificate-credential-metadata-of-an-app)
  - [AZ-09 List service principals](#az-09-list-service-principals)
- [Consent grants](#consent-grants)
  - [AZ-10 List all delegated permission grants](#az-10-list-all-delegated-permission-grants)
  - [AZ-11 List delegated permission grants for one client app](#az-11-list-delegated-permission-grants-for-one-client-app)
  - [AZ-12 List app roles granted to a service principal](#az-12-list-app-roles-granted-to-a-service-principal)
  - [AZ-13 List who holds app roles on a resource service principal](#az-13-list-who-holds-app-roles-on-a-resource-service-principal)
- [Containment](#containment)
  - [AZ-14 Revoke the sign-in sessions of a user](#az-14-revoke-the-sign-in-sessions-of-a-user)
  - [AZ-15 Disable a user account](#az-15-disable-a-user-account)
  - [AZ-16 Remove a password credential from an app](#az-16-remove-a-password-credential-from-an-app)
  - [AZ-17 Remove a certificate credential from an app](#az-17-remove-a-certificate-credential-from-an-app)

## Before you start

Placeholders used in this file:

- `<tenant-id>`: the Entra tenant ID.
- `<subscription-id>`: the Azure subscription ID.
- `<evidence-dir>`: the folder where the human wants saved output.

Rules for every command:

- A human runs `az login` for the right tenant. The agent never reads, prints, or stores tokens or credentials.
- Do not run `az account get-access-token`. It prints a token.
- A registered cloud can send `az` requests to custom endpoints. An update can also change the endpoints of an existing cloud, such as `AzureCloud` ([manage clouds](https://learn.microsoft.com/en-us/cli/azure/manage-clouds-azure-cli)). Before AZ-01, and again before each WRITE command, run the read below. It reads the local CLI configuration, unless a local setting sends it to another host (see SKILL.md safety rule 17). It is READ-ONLY, SENSITIVE, because a custom endpoint can show internal network details. Ask the human first. Save the output.

  ```bash
  az cloud list --query "[?isActive].{name:name,resourceManager:endpoints.resourceManager,activeDirectory:endpoints.activeDirectory,microsoftGraph:endpoints.microsoftGraphResourceId}" --output json
  ```

  The read lists the active cloud only. Do not use `az cloud show` for this check, because without `--name` it shows `AzureCloud`, not the active cloud ([az cloud](https://learn.microsoft.com/en-us/cli/azure/cloud)). Ask the human for the approved cloud name and its approved `resourceManager`, `activeDirectory`, and Microsoft Graph endpoints. Continue only when all four values match. Otherwise stop and tell the human. The `az ad` commands use the Microsoft Graph value. The field names come from the `cloud show` example and the `--endpoint-microsoft-graph-resource-id` option on the Doc pages.

- The `az rest` commands in this file call `https://graph.microsoft.com`. Use them only when the approved cloud is `AzureCloud`. For another cloud, such as a government or China cloud, stop and ask the human for the Graph host of that cloud.
- Run AZ-01 first. Confirm that the tenant and subscription match the incident.
- Write times in UTC. Graph commands use `YYYY-MM-DDThh:mm:ssZ`. The activity log command uses a date, a time, and a `+00:00` offset.
- Log output holds personal data. Save it only to `<evidence-dir>`.
- Graph list calls return one page. `az rest` does not follow `@odata.nextLink`. For AZ-02 to AZ-04 and AZ-10 to AZ-13, read every page:
  1. Check the result for `@odata.nextLink`.
  2. When it is there, run `az rest --method get --url '<next-link-url>'` with the exact URL from the result. Keep the single quotes, because the URL can hold `$` characters that the shell would expand.
  3. Ask the human before each page, because each page is a separate SENSITIVE command. Save each page.
  4. Repeat until a result has no `@odata.nextLink`. Only then is the list complete.
- If a Graph call returns an authorization error, stop and tell the human. Do not change app consent or roles.

Save output to a file with a UTC timestamp in the name. Replace `<command>` and `<label>`.

```bash
<command> > "<evidence-dir>/az-<label>-$(date -u +%Y%m%dT%H%M%SZ).json"
```

`az rest` also has `--output-file <path>` to save the response payload.

## Setup check

### AZ-01 Show the signed-in tenant and subscription

- Purpose: confirm which tenant, subscription, and user the CLI uses before any other command. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command reads the local CLI profile.
- Command:

  ```bash
  az account show --output json
  ```

- Output: the default subscription with its ID and tenant ID, and the signed-in user. Look for: a tenant or subscription that is not the one in the incident.
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/cli/azure/account (checked 2026-11-12)

## Entra logs

### AZ-02 List sign-ins for one user in a time range

- Purpose: list the sign-ins of one user, newest first, for a time window. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Microsoft Graph `AuditLog.Read.All`. The signed-in user also needs a role such as Reports Reader, Security Reader, Security Operator, Security Administrator, or Global Reader.
- Command:

  ```bash
  az rest --method get --url "https://graph.microsoft.com/v1.0/auditLogs/signIns" --url-parameters "\$filter=userPrincipalName eq '<user-principal-name>' and createdDateTime ge <start-time-iso8601> and createdDateTime le <end-time-iso8601>" "\$top=<page-size>"
  ```

- Output: JSON with `value` entries. Key fields are `createdDateTime`, `ipAddress`, `location`, `appDisplayName`, `clientAppUsed`, `status.errorCode`, `conditionalAccessStatus`, and `riskLevelDuringSignIn`. Look for: new countries, new IP addresses, legacy clients, failures followed by a success, and risky sign-ins. The page says that this v1.0 endpoint includes interactive sign-ins and successful federated sign-ins. It does not include non-interactive sign-ins, such as a client that uses a refresh token to get a new token. Record this gap in the incident log. Ask the human for the non-interactive sign-in logs from the Entra admin center or from a log export. The page names no licence requirement. Only sign-ins inside the Entra default retention period are available. The maximum page size is 1,000. Read every page with `@odata.nextLink` (Before you start).
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/graph/api/signin-list?view=graph-rest-1.0 (checked 2026-11-12)

### AZ-03 List directory audit events in a time range

- Purpose: list changes made in Entra ID, such as role, app, and consent changes, for a time window. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Microsoft Graph `AuditLog.Read.All`. The signed-in user also needs Reports Reader, Security Reader, or Security Administrator.
- Command:

  ```bash
  az rest --method get --url "https://graph.microsoft.com/v1.0/auditLogs/directoryAudits" --url-parameters "\$filter=activityDateTime ge <start-time-iso8601> and activityDateTime le <end-time-iso8601>" "\$top=<page-size>"
  ```

- Output: JSON with `value` entries. Key fields are `activityDisplayName`, `activityDateTime`, `initiatedBy`, `targetResources`, `result`, and `loggedByService`. Look for: added credentials on apps, consent grants, role assignments, new users, and changed authentication methods. Read every page with `@odata.nextLink` (Before you start).
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/graph/api/directoryaudit-list?view=graph-rest-1.0 (checked 2026-11-12)

### AZ-04 List directory audit events started by one user

- Purpose: list what one identity changed in Entra ID. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Microsoft Graph `AuditLog.Read.All`. The signed-in user also needs Reports Reader, Security Reader, or Security Administrator.
- Command:

  ```bash
  az rest --method get --url "https://graph.microsoft.com/v1.0/auditLogs/directoryAudits" --url-parameters "\$filter=initiatedBy/user/id eq '<user-object-id>'" "\$top=<page-size>"
  ```

- Output: JSON with `value` entries started by that user. Look for: changes outside the normal duties of the user, and a new source `ipAddress`. Read every page with `@odata.nextLink` (Before you start).
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/graph/api/directoryaudit-list?view=graph-rest-1.0 (checked 2026-11-12)

## Azure activity log

### AZ-05 List activity log events for one caller

- Purpose: list Azure resource operations by one caller in a time window. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the activity log of the subscription. The CLI page does not name the role.
- Command:

  ```bash
  az monitor activity-log list --subscription <subscription-id> --caller <caller-email-or-sp-id> --start-time <start-time-with-offset> --end-time <end-time-with-offset> --max-events <max-events> --output json
  ```

- Output: JSON events. Key fields are `eventTimestamp`, `caller`, `operationName`, `resourceId`, `status`, and `authorization`. Look for: role assignments, new resources, policy changes, and failed operations by the caller. The activity log is not an authentication or authorization log. Azure Resource Manager writes no entry for a request that it rejects before the operation starts ([activity log](https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/activity-log)). Use AZ-02 for failed sign-ins. Entries can take 3 to 20 minutes to appear. Azure keeps them for 90 days. Record a later or older window as a gap. `--caller` takes an email address or a service principal ID. `--max-events` is the maximum number of records to return. It defaults to 50. The command has no next-page option, so check the count:
  1. Count the events in the output.
  2. When the count equals the `--max-events` value, the output can be cut. Raise the value and run the command again.
  3. Ask the human before each run, because each run is a separate SENSITIVE command. Save each output.
  4. Repeat until the count is lower than the value. Only then is the list complete.

- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/cli/azure/monitor/activity-log (checked 2026-11-12). The page gives `--max-events` as "Maximum number of records to return" with default 50. It names no next-page option.

## App registrations

### AZ-06 List app registrations

- Purpose: list all app registrations in the tenant. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to applications in the tenant. The CLI page does not name the role.
- Command:

  ```bash
  az ad app list --all --query "[].{displayName:displayName,appId:appId,id:id,createdDateTime:createdDateTime,signInAudience:signInAudience}" --output json
  ```

- Output: one object per app with name, app ID, object ID, creation time, and sign-in audience. Look for: apps created near the incident time, unknown names, and `AzureADMultipleOrgs` audiences. Without `--all`, the command returns only the first 100 apps. With `--all`, a large tenant can cause a long delay.
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/cli/azure/ad/app (checked 2026-11-12)

### AZ-07 List password credential metadata of an app

- Purpose: list the client secrets of one app, without their values. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the app registration. The CLI page does not name the role.
- Command:

  ```bash
  az ad app credential list --id <app-id-or-object-id> --output json
  ```

- Output: metadata only, such as key ID, display name, start date, and end date. The secret value is not retrievable. Look for: secrets added near the incident time, long lifetimes, and unknown display names.
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/cli/azure/ad/app/credential (checked 2026-11-12)

### AZ-08 List certificate credential metadata of an app

- Purpose: list the certificates of one app, without private keys. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the app registration. The CLI page does not name the role.
- Command:

  ```bash
  az ad app credential list --id <app-id-or-object-id> --cert --output json
  ```

- Output: metadata only, such as key ID, display name, start date, and end date. Look for: certificates added near the incident time and unknown display names.
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/cli/azure/ad/app/credential (checked 2026-11-12)

### AZ-09 List service principals

- Purpose: list the enterprise apps and service principals in the tenant. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to service principals in the tenant. The CLI page does not name the role.
- Command:

  ```bash
  az ad sp list --all --query "[].{displayName:displayName,appId:appId,id:id,servicePrincipalType:servicePrincipalType}" --output json
  ```

- Output: one object per service principal with name, app ID, object ID, and type. Look for: unknown names and service principals that match apps from AZ-06 with recent changes. Without `--all`, the command returns only the first 100 service principals.
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/cli/azure/ad/sp (checked 2026-11-12)

## Consent grants

### AZ-10 List all delegated permission grants

- Purpose: list every delegated permission that an app holds for users. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Microsoft Graph `Directory.Read.All`. The signed-in user also needs a role such as Global Reader, Directory Readers, or Application Administrator.
- Command:

  ```bash
  az rest --method get --url "https://graph.microsoft.com/v1.0/oauth2PermissionGrants"
  ```

- Output: JSON `value` entries with `clientId`, `consentType`, `principalId`, `resourceId`, and `scope`. Look for: `AllPrincipals` grants with broad scopes such as `Mail.Read`, `Files.ReadWrite.All`, or `Directory.ReadWrite.All`, and grants to unknown apps. The page warns about replication delay for recent changes. A `clientId` filter (AZ-11) reduces the delay. Read every page with `@odata.nextLink` (Before you start).
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/graph/api/oauth2permissiongrant-list?view=graph-rest-1.0 (checked 2026-11-12)

### AZ-11 List delegated permission grants for one client app

- Purpose: list the delegated permissions granted to one app. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Microsoft Graph `Directory.Read.All`. The signed-in user also needs a role such as Global Reader, Directory Readers, or Application Administrator.
- Command:

  ```bash
  az rest --method get --url "https://graph.microsoft.com/v1.0/oauth2PermissionGrants" --url-parameters "\$filter=clientId eq '<service-principal-object-id>'"
  ```

- Output: JSON `value` entries for that client. `clientId` is the object ID of the service principal, not the app ID. Look for: `scope` values that the app does not need. Read every page with `@odata.nextLink` (Before you start).
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/graph/api/oauth2permissiongrant-list?view=graph-rest-1.0 (checked 2026-11-12)

### AZ-12 List app roles granted to a service principal

- Purpose: list the application permissions that one service principal holds. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Microsoft Graph `Application.Read.All`. The signed-in user also needs a role such as Directory Readers or Application Administrator.
- Command:

  ```bash
  az rest --method get --url "https://graph.microsoft.com/v1.0/servicePrincipals/<service-principal-object-id>/appRoleAssignments"
  ```

- Output: JSON `value` entries with `appRoleId`, `resourceDisplayName`, `resourceId`, and `createdDateTime`. Look for: roles on Microsoft Graph or other APIs that the app does not need, and recent `createdDateTime` values. The `appRoleId` is an ID, not a name. Match it to the app roles of the resource service principal. Read every page with `@odata.nextLink` (Before you start).
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignments?view=graph-rest-1.0 (checked 2026-11-12)

### AZ-13 List who holds app roles on a resource service principal

- Purpose: list the users, groups, and apps that have an app role on one resource. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Microsoft Graph `Application.Read.All`. The signed-in user also needs a role such as Directory Readers or Application Administrator.
- Command:

  ```bash
  az rest --method get --url "https://graph.microsoft.com/v1.0/servicePrincipals/<resource-service-principal-object-id>/appRoleAssignedTo"
  ```

- Output: JSON `value` entries with `principalDisplayName`, `principalId`, `principalType`, `appRoleId`, and `createdDateTime`. Look for: unknown service principals that hold application permissions on the resource. For the Microsoft Graph resource, this lists every service principal with an application permission to Microsoft Graph. Read every page with `@odata.nextLink` (Before you start).
- Approval: ask the human first.
- Doc: https://learn.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignedto?view=graph-rest-1.0 (checked 2026-11-12)

## Containment

Record the user, the app, the credential key ID, and the time in the incident log before you run any command in this section.

### AZ-14 Revoke the sign-in sessions of a user

- Purpose: make the Entra ID refresh tokens and browser session cookies of a user invalid, so that the user cannot get new tokens. Phase: containment.
- Label: WRITE
- Permission: Microsoft Graph `User.RevokeSessions.All`.
- Command:

  ```bash
  az rest --method post --url "https://graph.microsoft.com/v1.0/users/<user-object-id>/revokeSignInSessions" --headers "Content-Type=application/json"
  ```

- Output: a JSON result with `value` set to `true`. Look for: a `true` value.
- Side effect: all refresh tokens and browser session cookies of the user become invalid. The user must sign in again to get new tokens from Entra ID. The page says tokens can stay valid for a few minutes. The command does not revoke sessions of external users. An access token that Entra ID issued stays valid until it expires. By default, an access token lasts 1 hour. Entra ID cannot revoke a session token that an application issued. Each such application ends its own sessions. Ask the human to check or end the sessions in each application that matters to the incident.
- Rollback: None. The command resets `signInSessionsValidFromDateTime` to the current time. The user signs in again.
- Approval: human approval required.
- Doc: https://learn.microsoft.com/en-us/graph/api/user-revokesigninsessions?view=graph-rest-1.0 and https://learn.microsoft.com/en-us/entra/identity/users/users-revoke-access (checked 2026-11-12)

### AZ-15 Disable a user account

- Purpose: stop a user from signing in. Phase: containment.
- Label: WRITE
- Permission: Microsoft Graph `User.EnableDisableAccount.All` and `User.Read.All`. For administrator accounts, the page names Privileged Authentication Administrator as the least privileged role.
- Command:

  ```bash
  az rest --method patch --url "https://graph.microsoft.com/v1.0/users/<user-object-id>" --body '{"accountEnabled": false}'
  ```

- Output: a success status or an authorization error. An authorization error means the caller lacks the permission or role. Look for: new sign-ins by the user in AZ-02 after this change.
- Side effect: the user cannot sign in. The page does not say whether existing sessions end. Run AZ-14 as well.
- Note: use the object ID (`id`) of the user in the URL, not the user principal name. A guest user principal name holds `#EXT#`, and a raw `#` breaks the URL.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Before the change, record the current value with `az rest --method get --url 'https://graph.microsoft.com/v1.0/users/<user-object-id>?$select=accountEnabled'`. Run the rollback only when the value was `true`. When it was `false`, do nothing. `az rest --method patch --url "https://graph.microsoft.com/v1.0/users/<user-object-id>" --body '{"accountEnabled": true}'`
- Approval: human approval required.
- Doc: https://learn.microsoft.com/en-us/graph/api/user-update?view=graph-rest-1.0 (checked 2026-11-12)

### AZ-16 Remove a password credential from an app

- Purpose: delete a leaked or unknown client secret from an app registration. Phase: containment.
- Label: WRITE
- Permission: write access to the app registration. The CLI page does not name the role.
- Command:

  ```bash
  az ad app credential delete --id <app-id-or-object-id> --key-id <key-id>
  ```

- Output: a short result or an error. Run AZ-07 again to confirm that the key ID is gone. Look for: the key ID in the AZ-07 output after the delete.
- Side effect: new token requests with this secret fail. Tokens that the app already holds can work until they expire. For some resources, that is up to 24 hours. Record that access as open in the incident notes until the tokens expire. List the resources that the app can reach.
- Rollback: None. A new credential is needed, because the secret value cannot be read back. Record the key ID, display name, and end date from AZ-07 first. `az ad app credential reset` clears all other credentials unless `--append` is set.
- Approval: human approval required.
- Doc: https://learn.microsoft.com/en-us/cli/azure/ad/app/credential and https://learn.microsoft.com/en-us/entra/workload-id/troubleshoot-revoked-credentials (checked 2026-11-12)

### AZ-17 Remove a certificate credential from an app

- Purpose: delete a leaked or unknown certificate from an app registration. Phase: containment.
- Label: WRITE
- Permission: write access to the app registration. The CLI page does not name the role.
- Command:

  ```bash
  az ad app credential delete --id <app-id-or-object-id> --key-id <key-id> --cert
  ```

- Output: a short result or an error. Run AZ-08 again to confirm that the key ID is gone. Look for: the key ID in the AZ-08 output after the delete.
- Side effect: new token requests with this certificate fail. Tokens that the app already holds can work until they expire. For some resources, that is up to 24 hours. Record that access as open in the incident notes until the tokens expire. List the resources that the app can reach.
- Rollback: None. A new credential is needed. Record the key ID, display name, and end date from AZ-08 first. The app owner can add a public certificate again with `az ad app credential reset --id <app-id-or-object-id> --cert "@<certificate-path>" --append`.
- Approval: human approval required.
- Doc: https://learn.microsoft.com/en-us/cli/azure/ad/app/credential and https://learn.microsoft.com/en-us/entra/workload-id/troubleshoot-revoked-credentials (checked 2026-11-12)
