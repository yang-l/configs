# GCP commands

Commands for Google Cloud during an incident. They cover audit logs, IAM policy, service account keys, Security Command Center findings, firewall rules, bucket exposure, and containment. The commands in this file were checked against vendor docs only, not against a local CLI.
Labels and the approval rules are in `../SKILL.md`. Read them before you run any command from this file.

## Contents

- [Before you start](#before-you-start)
- [Setup check](#setup-check)
  - [GCP-01 Show the active account and project](#gcp-01-show-the-active-account-and-project)
- [Audit logs](#audit-logs)
  - [GCP-02 Read Admin Activity audit logs for one principal](#gcp-02-read-admin-activity-audit-logs-for-one-principal)
  - [GCP-03 Read audit logs for one method name](#gcp-03-read-audit-logs-for-one-method-name)
  - [GCP-04 Read Data Access audit logs for one principal](#gcp-04-read-data-access-audit-logs-for-one-principal)
  - [GCP-05 Read audit logs at organization scope](#gcp-05-read-audit-logs-at-organization-scope)
- [IAM policy](#iam-policy)
  - [GCP-06 Get the project IAM policy](#gcp-06-get-the-project-iam-policy)
  - [GCP-07 Get the organization IAM policy](#gcp-07-get-the-organization-iam-policy)
  - [GCP-08 Get the folder IAM policy](#gcp-08-get-the-folder-iam-policy)
  - [GCP-09 List members for each role in a project](#gcp-09-list-members-for-each-role-in-a-project)
  - [GCP-10 List the roles of one member in a project](#gcp-10-list-the-roles-of-one-member-in-a-project)
- [Service accounts and keys](#service-accounts-and-keys)
  - [GCP-11 List service accounts in a project](#gcp-11-list-service-accounts-in-a-project)
  - [GCP-12 List user-managed keys of a service account](#gcp-12-list-user-managed-keys-of-a-service-account)
- [Security Command Center](#security-command-center)
  - [GCP-13 List active Security Command Center findings](#gcp-13-list-active-security-command-center-findings)
- [Firewall rules](#firewall-rules)
  - [GCP-14 List firewall rules with source ranges](#gcp-14-list-firewall-rules-with-source-ranges)
  - [GCP-15 List ingress firewall rules open to the internet](#gcp-15-list-ingress-firewall-rules-open-to-the-internet)
- [Cloud Storage exposure](#cloud-storage-exposure)
  - [GCP-16 List Cloud Storage buckets in a project](#gcp-16-list-cloud-storage-buckets-in-a-project)
  - [GCP-17 Describe bucket public access settings](#gcp-17-describe-bucket-public-access-settings)
  - [GCP-18 Get a bucket IAM policy](#gcp-18-get-a-bucket-iam-policy)
- [Containment](#containment)
  - [GCP-19 Disable a service account key](#gcp-19-disable-a-service-account-key)
  - [GCP-20 Disable a service account](#gcp-20-disable-a-service-account)
  - [GCP-21 Turn on public access prevention for one bucket](#gcp-21-turn-on-public-access-prevention-for-one-bucket)

## Before you start

Placeholders used in this file:

- `<project-id>`: the Google Cloud project ID.
- `<organization-id>`: the numeric organization ID.
- `<folder-id>`: the numeric folder ID.
- `<evidence-dir>`: the folder where the human wants saved output.

Rules for every command:

- A human signs in to `gcloud`. The agent never reads, prints, or stores credentials or tokens.
- Pass `--project=<project-id>` on each command. Do not rely on the default project in the local configuration.
- A property or an environment variable can send `gcloud` requests to another endpoint ([endpoint overrides](https://docs.cloud.google.com/sdk/gcloud/reference/topic/endpoint-override)). The `core/universe_domain` property sets the domain for API requests ([config list](https://docs.cloud.google.com/sdk/gcloud/reference/config/list)). An environment variable named `CLOUDSDK_SECTION_NAME_PROPERTY_NAME` can also set a property ([configurations](https://docs.cloud.google.com/sdk/docs/configurations)). Before the first command, and again before each WRITE command, run the four reads below. They read the local configuration and the variable names only. They are READ-ONLY, SENSITIVE, because an override can show internal network details. Ask the human first. Save the output.

  ```bash
  gcloud config list api_endpoint_overrides/
  gcloud config list core/universe_domain
  gcloud config list auth/
  env | grep -o -E '^CLOUDSDK_(API_ENDPOINT_OVERRIDES_[A-Z0-9_]*|CORE_UNIVERSE_DOMAIN|AUTH_[A-Z0-9_]*)='
  ```

  Stop and tell the human when the first read prints an override, or when the last read prints an `API_ENDPOINT_OVERRIDES` name. An access token, an access token file, a credential file override, or a service account to impersonate comes before the active account ([credential order](https://docs.cloud.google.com/sdk/docs/authenticate)). The `auth/token_host` property changes the endpoint that gives access tokens ([config list](https://docs.cloud.google.com/sdk/gcloud/reference/config/list)). So when the third read prints any property, or when the last read prints an `AUTH_` name, stop. Ask the human to confirm the identity that `gcloud` uses and the token endpoint. The last read prints names only, never a token. When the second read prints a domain, or the last read prints `CLOUDSDK_CORE_UNIVERSE_DOMAIN=`, ask the human for the approved universe domain. Continue only when the domains match.

- Write times in UTC and in the form `YYYY-MM-DDThh:mm:ssZ`.
- Log output holds personal data and internal context. Save it only to `<evidence-dir>`.

Save output to a file with a UTC timestamp in the name. Replace `<command>` and `<label>`.

```bash
<command> > "<evidence-dir>/gcp-<label>-$(date -u +%Y%m%dT%H%M%SZ).json"
```

## Setup check

### GCP-01 Show the active account and project

- Purpose: confirm which account and project `gcloud` uses before any other command. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command reads the local `gcloud` configuration only.
- Command:

  ```bash
  gcloud config get account
  gcloud config get project
  gcloud config get compute/region
  gcloud config get compute/zone
  ```

- Output: the active account email, the default project, and the default region and zone, if they are set. Do not run `gcloud config list` with no property, because it can print a value such as `proxy/password`. Look for: an account or project that is not the one in the incident.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/config/get (checked 2026-11-12)

## Audit logs

Admin Activity and System Event logs are always on. Data Access logs are off by default, except for some BigQuery services. An empty Data Access result does not prove that no access happened. GCP-02, GCP-04, and GCP-05 filter on `principalEmail`. For a third-party caller, such as a federated identity, Google fills `principalSubject` instead ([AuditLog](https://docs.cloud.google.com/logging/docs/reference/audit/auditlog/rest/Shared.Types/AuditLog)). For such a caller, run the same command with `protoPayload.authenticationInfo.principalSubject="<principal-subject>"` in place of the `principalEmail` term. A service account can act for another identity. To find the real caller, read `protoPayload.authenticationInfo.serviceAccountDelegationInfo` in the results. Compare the results with the logs of the identity provider. Record each gap in the incident log.

### GCP-02 Read Admin Activity audit logs for one principal

- Purpose: list the changes that one identity made in a project during a time window. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `logging.logEntries.list`, for example through `roles/logging.viewer`.
- Command:

  ```bash
  gcloud logging read 'logName="projects/<project-id>/logs/cloudaudit.googleapis.com%2Factivity" AND protoPayload.authenticationInfo.principalEmail="<principal-email>" AND timestamp>="<start-time-iso8601>" AND timestamp<="<end-time-iso8601>"' --project=<project-id> --order=asc --format=json
  ```

- Output: one JSON entry per call. Key fields are `protoPayload.methodName`, `protoPayload.serviceName`, `protoPayload.resourceName`, and `timestamp`. Look for: IAM changes, key creation, new service accounts, and firewall changes by an unexpected principal. Do not add `--freshness` to a filter with a timestamp. The docs say `--freshness` works only without a timestamp. The command sets no `--limit`, and the docs give the `--limit` default as unlimited. The output can be large.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/logging/read and https://docs.cloud.google.com/logging/docs/view/logging-query-language (checked 2026-11-12)

### GCP-03 Read audit logs for one method name

- Purpose: find every call to one API method in recent history. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `logging.logEntries.list`. Data Access entries also need `logging.privateLogEntries.list`, for example through `roles/logging.privateLogViewer`.
- Command:

  ```bash
  gcloud logging read 'logName:"projects/<project-id>/logs/cloudaudit.googleapis.com" AND protoPayload.methodName="<method-name>"' --project=<project-id> --freshness=<freshness-duration> --order=desc --format=json
  ```

- Output: JSON entries for the method. Key fields are `protoPayload.authenticationInfo.principalEmail`, `protoPayload.requestMetadata.callerIp`, and `timestamp`. Look for: a new caller or source IP. Method names depend on the service. Read a sample entry first to get the exact name. Use `:` instead of `=` for a partial match. The command sets no `--limit`, and the docs give the `--limit` default as unlimited. The output can be large.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/logging/read and https://docs.cloud.google.com/logging/docs/view/query-library (checked 2026-11-12)

### GCP-04 Read Data Access audit logs for one principal

- Purpose: list the reads and data calls that one identity made in a project during a time window. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `logging.privateLogEntries.list`, for example through `roles/logging.privateLogViewer`. `roles/logging.viewer` is not enough.
- Command:

  ```bash
  gcloud logging read 'logName="projects/<project-id>/logs/cloudaudit.googleapis.com%2Fdata_access" AND protoPayload.authenticationInfo.principalEmail="<principal-email>" AND timestamp>="<start-time-iso8601>" AND timestamp<="<end-time-iso8601>"' --project=<project-id> --order=asc --format=json
  ```

- Output: JSON entries for data reads and writes. Key fields are `protoPayload.methodName`, `protoPayload.resourceName`, and `timestamp`. Look for: bulk reads of storage, secrets, or BigQuery data. The command sets no `--limit`, and the docs give the `--limit` default as unlimited. The output can be large.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/logging/docs/audit (checked 2026-11-12)

### GCP-05 Read audit logs at organization scope

- Purpose: read audit logs for organization-level resources. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `logging.logEntries.list` on the organization. Data Access entries also need `logging.privateLogEntries.list`.
- Command:

  ```bash
  gcloud logging read 'logName:"organizations/<organization-id>/logs/cloudaudit.googleapis.com" AND protoPayload.authenticationInfo.principalEmail="<principal-email>" AND timestamp>="<start-time-iso8601>" AND timestamp<="<end-time-iso8601>"' --organization=<organization-id> --order=asc --format=json
  ```

- Output: JSON entries for organization-level calls, such as organization IAM changes. Look for: new role bindings and changed organization policies. For a folder, use `--folder=<folder-id>` and the log name prefix `folders/<folder-id>/logs/`. The command sets no `--limit`, and the docs give the `--limit` default as unlimited. The output can be large.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/logging/read (checked 2026-11-12)

## IAM policy

### GCP-06 Get the project IAM policy

- Purpose: read all role bindings on a project. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `resourcemanager.projects.getIamPolicy`
- Command:

  ```bash
  gcloud projects get-iam-policy <project-id> --format=json
  ```

- Output: a policy with `bindings` (role and members) and an `etag`. Look for: `allUsers`, `allAuthenticatedUsers`, unknown external members, and broad roles such as `roles/owner`.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/projects/get-iam-policy (checked 2026-11-12)

### GCP-07 Get the organization IAM policy

- Purpose: read all role bindings on the organization. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the organization IAM policy. The reference page does not name the permission.
- Command:

  ```bash
  gcloud organizations get-iam-policy <organization-id> --format=json
  ```

- Output: a policy with `bindings` and an `etag`. Look for: new members with admin roles and members from outside the organization.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/organizations/get-iam-policy (checked 2026-11-12)

### GCP-08 Get the folder IAM policy

- Purpose: read all role bindings on a folder. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the folder IAM policy. The reference page does not name the permission.
- Command:

  ```bash
  gcloud resource-manager folders get-iam-policy <folder-id> --format=json
  ```

- Output: a policy with `bindings` and an `etag`. Look for: new members with broad roles that child projects inherit.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/folders/get-iam-policy (checked 2026-11-12)

### GCP-09 List members for each role in a project

- Purpose: show one row for each role and member pair. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `resourcemanager.projects.getIamPolicy`
- Command:

  ```bash
  gcloud projects get-iam-policy <project-id> --flatten="bindings[].members" --format="table(bindings.role,bindings.members)"
  ```

- Output: a table with columns `ROLE` and `MEMBERS`. Look for: `allUsers`, `allAuthenticatedUsers`, unknown `user:` or `serviceAccount:` members, and owner or editor roles.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/projects/get-iam-policy and https://docs.cloud.google.com/sdk/gcloud/reference/topic/filters (checked 2026-11-12)

### GCP-10 List the roles of one member in a project

- Purpose: show the roles granted directly to one exact principal in a project. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `resourcemanager.projects.getIamPolicy`
- Command:

  ```bash
  f="<evidence-dir>/gcp-GCP-10-iam-policy-$(date -u +%Y%m%dT%H%M%SZ).json"
  gcloud projects get-iam-policy <project-id> --format=json > "$f" && jq -r --arg m '<member-identity>' '.bindings[] | select(any(.members[]?; . == $m)) | [.role, (.condition.title // ""), (.condition.expression // "")] | @tsv' "$f"
  ```

- Output: one row per role, with the role, the condition title, and the condition expression, separated by tabs. Set `<member-identity>` to the full member string, for example `user:` or `serviceAccount:` followed by the email. The `jq` filter matches the complete string only. The command does not use the gcloud `:` filter, because it matches a value that contains the pattern. A role with a condition applies only when its expression is `true` ([IAM conditions](https://docs.cloud.google.com/iam/docs/conditions-overview)). The gcloud CLI requests the policy version that shows conditions ([allow policies](https://docs.cloud.google.com/iam/docs/policies)). Look for: roles the identity should not hold. This shows direct grants on the project only. A role granted to `group:`, `domain:`, `allUsers`, or `allAuthenticatedUsers` does not show, even when that principal includes the identity ([allow policies](https://docs.cloud.google.com/iam/docs/allow-policies), [principal identifiers](https://docs.cloud.google.com/iam/docs/principal-identifiers)). So an empty result does not prove that the identity has no access. Check group and domain grants with GCP-09. Inherited roles need GCP-07 and GCP-08. For the effective access to one resource, a human can use Policy Troubleshooter ([troubleshoot access](https://docs.cloud.google.com/iam/docs/troubleshoot-policies)).
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/projects/get-iam-policy and https://docs.cloud.google.com/sdk/gcloud/reference/topic/filters (checked 2026-11-12)
- Local help: The `jq` filter was tested with jq on a literal sample policy. It matched only the exact member and printed the condition.

## Service accounts and keys

### GCP-11 List service accounts in a project

- Purpose: list all service accounts and see which are disabled. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: permission to list service accounts in the project. The reference page does not name it.
- Command:

  ```bash
  gcloud iam service-accounts list --project=<project-id> --format=json
  ```

- Output: one JSON object per service account, with `email`, `uniqueId`, and `disabled`. Look for: accounts that nobody recognizes and accounts created near the incident time.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/iam/service-accounts/list (checked 2026-11-12)

### GCP-12 List user-managed keys of a service account

- Purpose: list the keys that a person created for one service account. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: permission to list keys on the service account. The reference page does not name it.
- Command:

  ```bash
  gcloud iam service-accounts keys list --iam-account=<service-account-email> --managed-by=user --project=<project-id> --format=json
  ```

- Output: key metadata only. The private key is not shown. Key fields are the key name (ending with the key ID) and `validAfterTime`. Look for: keys that nobody expects and keys created near the incident time. To list only older keys, add `--created-before=<cutoff-time-iso8601>`.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/iam/service-accounts/keys/list (checked 2026-11-12)

## Security Command Center

### GCP-13 List active Security Command Center findings

- Purpose: list open findings for an organization, folder, or project. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: a Security Command Center role that lists findings at the parent scope. The pages read do not name the permission.
- Command:

  ```bash
  gcloud scc findings list <scc-parent> --location=global --filter="state=\"ACTIVE\"" --format=json
  ```

- Output: one JSON object per finding, with category, resource name, severity, and state. Look for: high-severity findings on the resources in the incident. Set `<scc-parent>` to `organizations/<organization-id>`, `folders/<folder-id>`, or `projects/<project-id>`. When data residency is on, set `--location` to `eu`, `sa`, or `us`. The docs say that without `--location`, the call goes to the older v1 API. The command sets no `--limit`, and the docs give the `--limit` default as unlimited. The output can be large.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/scc/findings/list (checked 2026-11-12)

## Firewall rules

### GCP-14 List firewall rules with source ranges

- Purpose: list all VPC firewall rules and the ranges they allow. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: permission to list firewall rules in the project. The reference page does not name it. The read of effective firewalls needs `compute.instances.getEffectiveFirewalls` on the project that holds the VM. In a Shared VPC, that is the service project, not the host project.
- Command:

  ```bash
  gcloud compute firewall-rules list --project=<project-id> --format="table(name,network,direction,priority,sourceRanges.list(),disabled)"
  ```

- Output: a table with one row per rule. Look for: ingress rules with broad source ranges, rules with high priority, and rules created near the incident time.
- Coverage: this command lists only the classic VPC firewall rules in this project. It does not show firewall policies from the organization, a folder, or the network. In a Shared VPC, the rules live in the host project. Run GCP-14 and GCP-15 with the host project ID too. For one VM, read the rules that take effect on one interface. This read is READ-ONLY, SENSITIVE. Ask the human first.

  ```bash
  gcloud compute instances network-interfaces get-effective-firewalls <instance-name> --zone=<zone> --network-interface=<network-interface> --project=<project-id> --format=json
  ```

  The default interface is `nic0`. Run it for each interface of the VM. When the read is denied, record the coverage of firewall policies as unknown. When a conclusion rests on GCP-14 and GCP-15 alone, limit it to classic rules.

- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/compute/firewall-rules/list, https://docs.cloud.google.com/firewall/docs/firewall-policies-rule-eval-order, https://docs.cloud.google.com/vpc/docs/shared-vpc, https://docs.cloud.google.com/sdk/gcloud/reference/compute/instances/network-interfaces/get-effective-firewalls, and https://docs.cloud.google.com/firewall/docs/manage-global-firewall-policies (checked 2026-11-12)

### GCP-15 List ingress firewall rules open to the internet

- Purpose: find ingress rules whose source range is open to all addresses. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: permission to list firewall rules in the project. The reference page does not name it.
- Command:

  ```bash
  gcloud compute firewall-rules list --project=<project-id> --filter="direction=INGRESS AND sourceRanges:0.0.0.0/0" --format=json
  gcloud compute firewall-rules list --project=<project-id> --filter="direction=INGRESS AND sourceRanges:::/0" --format=json
  ```

- Output: full JSON for each matching rule, with `allowed` protocols and ports and `targetTags`. Look for: SSH, RDP, database, and admin ports open to all addresses. The first line checks the IPv4 range for all addresses. The second line checks the IPv6 range. Compare the result with GCP-14, because the `:` filter operator is changing in gcloud. The coverage limits of GCP-14 apply here too.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/compute/firewall-rules/list and https://docs.cloud.google.com/sdk/gcloud/reference/topic/filters (checked 2026-11-12)

## Cloud Storage exposure

### GCP-16 List Cloud Storage buckets in a project

- Purpose: list the bucket names to check. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `storage.buckets.list`
- Command:

  ```bash
  gcloud storage buckets list --project=<project-id> --format="json(name)"
  ```

- Output: a JSON list of bucket names. Look for: buckets that nobody recognizes and names that suggest backups or exports.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/storage/buckets/list (checked 2026-11-12)

### GCP-17 Describe bucket public access settings

- Purpose: check public access prevention and uniform bucket-level access for one bucket. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `storage.buckets.get`. The third line needs `resourcemanager.projects.get`.
- Command:

  ```bash
  gcloud storage buckets describe gs://<bucket-name> --project=<project-id> --format="default(public_access_prevention,uniform_bucket_level_access)"
  gcloud storage buckets describe gs://<bucket-name> --project=<project-id> --raw --format="value(projectNumber)"
  gcloud projects describe <project-id> --format="value(projectNumber)"
  ```

- Output: `public_access_prevention` is `inherited` or `enforced`. `uniform_bucket_level_access` is `true` when it is on. Look for: `inherited` (public access is possible) and `false` (object ACLs can also grant access). The second and third lines print the project number of the bucket and of the approved project. They must match. Bucket names are global, so `--project` alone does not prove which project owns the bucket. `--raw` prints the API field names, and the API field is `projectNumber` ([bucket resource](https://docs.cloud.google.com/storage/docs/json_api/v1/buckets)). When the numbers differ, stop and tell the human. Save the output before you run GCP-21. The GCP-21 rollback needs it.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/storage/buckets/describe and https://docs.cloud.google.com/storage/docs/using-public-access-prevention (checked 2026-11-12)

### GCP-18 Get a bucket IAM policy

- Purpose: find bucket roles granted to all users or all signed-in users. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `storage.buckets.getIamPolicy`
- Command:

  ```bash
  gcloud storage buckets get-iam-policy gs://<bucket-name> --project=<project-id> --format=json
  ```

- Output: a policy with `bindings`. Look for: the members `allUsers` and `allAuthenticatedUsers`. Either one means public or near-public access. This command does not read object ACLs. If GCP-17 shows `false` for uniform access, ACLs can also expose data.
- Approval: ask the human first.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/storage/buckets/get-iam-policy (checked 2026-11-12)

## Containment

Record the key ID, the account, and the time in the incident log before you run any command in this section.

### GCP-19 Disable a service account key

- Purpose: stop a leaked or suspect key from authenticating. Phase: containment.
- Label: WRITE, SENSITIVE
- Permission: `roles/iam.serviceAccountKeyAdmin` on the project or the service account.
- Command:

  ```bash
  gcloud iam service-accounts keys disable <key-id> --iam-account=<service-account-email> --project=<project-id>
  ```

- Output: a short result or an error. The docs say `PERMISSION_DENIED` appears when the service account does not exist. Look for: the key with `disabled: true` when you run GCP-12 again.
- Side effect: any workload that uses this key fails to authenticate. Short-lived credentials already issued from the key stay valid. To block them, disable the service account (GCP-20). They stay blocked only while the account stays disabled.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Run it only when GCP-12 showed the key as enabled before the change. When the key was already disabled, do nothing. `gcloud iam service-accounts keys enable <key-id> --iam-account=<service-account-email> --project=<project-id>`
- Approval: human approval required.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/iam/service-accounts/keys/disable and https://docs.cloud.google.com/iam/docs/keys-disable-enable (checked 2026-11-12)

### GCP-20 Disable a service account

- Purpose: stop all use of a compromised service account. Phase: containment.
- Label: WRITE, SENSITIVE
- Permission: `roles/iam.serviceAccountAdmin` on the project.
- Command:

  ```bash
  gcloud iam service-accounts disable <service-account-email> --project=<project-id>
  ```

- Output: a short result or an error. The docs say `PERMISSION_DENIED` appears when the account does not exist. Look for: the account with `disabled: true` when you run GCP-11 again.
- Side effect: credential generation and API requests with this account fail. Google rejects the existing access tokens of the account. Every workload that runs as this account loses access.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Run it only when GCP-11 showed the account as enabled before the change. When the account was already disabled, do nothing. Warning: after the enable, Google accepts the existing access tokens of the account again. A stolen token that has not expired works again. Before the rollback, the human must check that such tokens expired, or accept that risk. `gcloud iam service-accounts enable <service-account-email> --project=<project-id>`
- Approval: human approval required.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/iam/service-accounts/disable, https://docs.cloud.google.com/iam/docs/service-accounts-disable-enable, and https://docs.cloud.google.com/iam/docs/reference/rest/v1/projects.serviceAccounts/disable for the token behaviour (checked 2026-11-12)

### GCP-21 Turn on public access prevention for one bucket

- Purpose: block public access through IAM and ACL grants to one Cloud Storage bucket and its objects. Phase: containment.
- Label: WRITE
- Permission: `roles/storage.admin` on the bucket. It includes `storage.buckets.update`.
- Command: run GCP-17 first. Continue only when the project numbers match.

  ```bash
  gcloud storage buckets update gs://<bucket-name> --project=<project-id> --public-access-prevention
  ```

- Output: a short result or an error. Look for: `public_access_prevention` set to `enforced` when you run GCP-17 again. Google says that enforcement can take up to 10 minutes. After 10 minutes, check the exposure again from outside the project. Do not call the bucket contained on the `enforced` value alone.
- Side effect: `allUsers` and `allAuthenticatedUsers` can no longer read the bucket. A website or an app that reads the bucket without credentials fails. No object is deleted. An organization policy that enforces the setting blocks the rollback. Some access paths stay open. Signed URLs still work, because public access prevention does not affect them. An internet cache can still serve objects for some time. Record these paths in the incident log. Ask the human how to close them, for example by key rotation for signed URLs.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Run GCP-17 again, and continue only when the project numbers still match. When GCP-17 showed `inherited`, set the value back:

  ```bash
  gcloud storage buckets update gs://<bucket-name> --project=<project-id> --no-public-access-prevention
  ```

  When GCP-17 already showed `enforced`, do not run this command. In that case, the rollback is to do nothing. The data can be public again after the rollback. Run it only when a human decides to.

- Approval: human approval required.
- Doc: https://docs.cloud.google.com/sdk/gcloud/reference/storage/buckets/update, https://docs.cloud.google.com/storage/docs/using-public-access-prevention, and https://docs.cloud.google.com/storage/docs/public-access-prevention (checked 2026-11-12). The reference page says `--no-public-access-prevention` sets the value to `inherited`.
