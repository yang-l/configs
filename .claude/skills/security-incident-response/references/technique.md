# Technique: phases of a security incident

This file covers what to do in each phase. The process around the work (roles, updates, legal, review) is in `process.md`. Commands are in the `commands-*.md` files.

## Contents

1. How to use this file
2. Severity guide
3. Phase 1: Detection
4. Phase 2: Triage
5. Phase 3: Scoping
6. Phase 4: Evidence preservation
7. Phase 5: Containment
8. Phase 6: Eradication
9. Phase 7: Recovery
10. Phase 8: Verification
11. Common incident types and first moves
12. Mapping to NIST SP 800-61r3 and CSF 2.0
13. Sources

## 1. How to use this file

- The phases are a guide, not a strict sequence. Analysis often resumes after containment and eradication.
- A human decides every step that changes state. An agent runs only untagged READ-ONLY commands on its own. A human approves each WRITE command and each SENSITIVE command, one at a time.
- Write each action and each finding into the incident notes file with a UTC time. See `process.md`, section 6.
- Do not skip a phase because the incident looks small. Shorten the phase instead.

## 2. Severity guide

A human responder assigns a severity at triage. The incident commander assesses it again when new facts arrive. An agent only proposes a severity. Google assesses harm, the nature of the incident, the type of data, the impact on users, and whether the incident is contained or continuing ([Google Cloud incident response](https://docs.cloud.google.com/docs/security/incident-response)). The table below uses the same factors. PagerDuty also ranks incidents by impact, with examples for each level ([PagerDuty severity levels](https://docs.pagerduty.com/ops-guides/incident-response-guide/severity-levels)). The four levels and the examples in the table belong to this skill, not to either source. The table is a starting point. Adapt it to your organisation.

| Level    | Criteria (any one is enough)                                                                                                             | Typical example                                                       |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Critical | Confirmed active attacker with privileged access. Confirmed loss of sensitive or regulated data. Core service down because of an attack. | Attacker holds admin credentials. Customer data downloaded.           |
| High     | Confirmed compromise of one account, host, or secret with a path to more access. Likely data exposure, not yet confirmed.                | Leaked cloud key with proven use by a third party.                    |
| Medium   | Suspected compromise with no proof of misuse yet. Exposure of non-sensitive data. Contained attack on a low-value system.                | Public bucket with no sensitive data. Phished user with MFA intact.   |
| Low      | Failed attack. Policy breach with no sign of misuse. Single alert with a likely benign cause.                                            | Blocked scan. Secret in a private repository, rotated before any use. |

Rules for the table:

1. Choose the higher level when two levels fit. PagerDuty advises the same: assume the highest level and review it in the postmortem.
2. Raise the level when the attacker is still active, the data is unknown, or the blast radius is unknown.
3. Lower the level only on evidence. Record the evidence in the notes.
4. Declare an incident early. Google advises declaring when a second team is needed. It also advises declaring when users see the impact, or when the issue is unsolved after an hour of focused work ([SRE book](https://sre.google/sre-book/managing-incidents/)).

## 3. Phase 1: Detection

**Goal.** Learn that something may be wrong and record the first facts without changing them.

**Steps**

1. Record the alert source, the alert text, and the UTC time you saw it. Save the alert as received.
2. Record who reported it and how to reach them.
3. Note what the alert does not say. Do not assume the first alert shows the whole attack.
4. Check that logging is on for the affected account, host, or service. Note any gap now. A gap limits what you can prove later.
5. Open the incident notes file and start the timeline.
6. Pass the alert to triage.

**Decisions**

- Is the signal real or a known false positive? Check recent changes and known tests before you dismiss it.
- Who else needs to know now? Alert the on-call security contact when the signal names a credential, customer data, or admin access.

**Pitfalls**

- Closing an alert as a false positive without a recorded reason.
- Telling the suspected user or the wider team in a public channel. The attacker may read it.
- Editing or deleting the alert. Save a copy first.
- Assuming logs exist. Retention may be short, so note the oldest log you can reach.

**Command files.** `commands-logs.md`, `commands-aws.md`, `commands-gcp.md`, `commands-azure.md`, `commands-cloudflare.md`, `commands-identity.md`, `commands-github.md`.

## 4. Phase 2: Triage

**Goal.** Decide in minutes whether this is an incident, how severe it is, and who leads.

**Steps**

1. State the claim in one sentence. Example: "Cloud key X was used from an unknown address at time T."
2. List what you know, what you assume, and what you do not know. Keep the three lists apart.
3. Confirm or refute the claim with one independent source. Use a second log or a second system.
4. Propose a severity from section 2. A human responder sets the first level. The incident commander owns later changes.
5. Name an incident commander. Say it out loud or in writing: "You are now the incident commander."
6. Open the incident channel and the incident ticket. Use the access list the commander sets.
7. Decide with the commander whether to involve counsel now. See `process.md`, section 4.

**Decisions**

- Is the attacker active now? If yes, plan to contain soon. If that is unknown, keep scoping read-only.
- Does the event involve personal data, regulated data, or customer data? If yes, involve counsel early.
- Do we need a second responder? Add one when the work will take more than an hour.

**Pitfalls**

- Spending an hour on triage before anyone is in charge.
- Mixing facts and guesses in one list.
- Relying on one log source that the attacker may control.
- Starting containment during triage without a decision by the commander. Containment before scoping can lose the attacker's trail. When the harm continues, the commander can approve containment at once. In the approval request, name the evidence that the change can destroy.

**Command files.** `commands-logs.md`, plus the file for the affected platform.

## 5. Phase 3: Scoping

**Goal.** Learn which identities, systems, data, and time window the attacker touched.

**Steps**

1. Find the earliest known bad event. Search the period before it. The first alert is rarely the first action.
2. List every identity, key, token, host, and service the attacker used. Record each with its first and last use.
3. Pivot from each indicator: the source address, the user agent, the key ID, the session ID.
4. Search for the same indicators across all accounts, zones, clusters, and repositories you own.
5. List the data the attacker could reach. Then list the data the logs show the attacker read or wrote.
6. Check for persistence: new users, new keys, new roles, new forwarding rules, new OAuth grants, new scheduled jobs, new webhooks.
7. Build the timeline in UTC. Mark each entry as confirmed or inferred.
8. Give the scoping results to the commander. Propose a new severity when the facts change.

**Decisions**

- Contain now, or watch to learn the full scope? Watching teaches you more but lets the attacker act. Microsoft notes that collecting attacker details is sometimes more important than an immediate response. Microsoft also warns to weigh the business effect of disabling accounts ([Microsoft token theft playbook](https://learn.microsoft.com/en-us/security/zero-trust/security-operations-playbook-token-theft)). Decide with the commander. Record the reason.
- Does log retention limit the scope? If yes, say so in the notes. Do not claim "no other activity" when logs do not cover the period.

**Pitfalls**

- Scoping only the first compromised identity. Attackers move to others.
- Stopping at the first persistence item. Search for more.
- Treating "no log entry" as "no activity".
- Running broad queries that return personal data into a shared channel. Keep output in the notes folder.
- Warning the attacker. Your visibility can end when you change the compromised account, delete files, or post in a shared tool that the attacker can read.

**Command files.** `commands-logs.md`, `commands-aws.md`, `commands-gcp.md`, `commands-azure.md`, `commands-identity.md`, `commands-github.md`, `commands-cloudflare.md`, `commands-kubernetes.md`, `commands-network.md`.

## 6. Phase 4: Evidence preservation

**Goal.** Keep a trustworthy copy of the evidence before any change destroys it.

RFC 3227 states the core rules: collect first and analyse later, work from a copy, and collect from the most volatile source to the least volatile ([RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html), sections 2 and 2.1). NIST SP 800-86 gives the wider forensic process ([NIST SP 800-86](https://csrc.nist.gov/pubs/sp/800/86/final)).

**Steps**

1. Decide what to preserve and in what order. Use this order of volatility: memory and process state, network state, temporary files, disk, remote logs, configuration, archives ([RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html), section 2.1).
2. Save cloud logs before retention removes them. Copy them to a store the attacker cannot write to.
3. Save the state of the affected resource before you change it: policy documents, configuration, access lists, key metadata, session lists.
4. For a host, capture memory first, then disk. Use trusted tools from protected media ([RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html), section 2.2).
5. Hash each saved file. Record the hash, the UTC time, the source, and the person who saved it.
6. Store originals read-only. Work on copies.
7. Start a chain of custody record. Record who held each item and when, where it is stored, and each transfer ([RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html), section 4.1).
8. Record the exact command, with the placeholders filled, in the notes for each capture.

**Decisions**

- Is the evidence volatile? If yes, capture it before containment. The exception is continuing harm. Then the commander can approve containment first, with the evidence that the change can destroy named.
- Is the evidence likely to be needed for legal action or for a regulator? If yes, ask counsel before you collect. Google notes that counsel sets the strategy for evidence collection ([Google Cloud incident response](https://docs.cloud.google.com/docs/security/incident-response)).
- Does collection itself change the system? Memory and disk capture tools are WRITE commands. A human approves each one.
- Does the evidence hold personal data? Limit access and collect only what the incident needs ([RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html), section 2.3).

**Pitfalls**

- Rebooting or shutting down a host before memory capture. RFC 3227 says not to shut down before evidence collection ends.
- Cutting the network of a host without thought. Some malware wipes evidence when it loses its network ([RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html), section 2.2).
- Running tools from the compromised host. Its programs may be altered.
- Using tools that change file access times across the disk.
- Rotating or deleting a key before you record its last use and its metadata.
- Deleting a compromised instance, pod, or bucket before you copy logs and state.
- Saving evidence on the same system the attacker controls.
- Skipping hashes. Without hashes you cannot show the evidence did not change.

**Command files.** `commands-hosts.md` (capture, hashing, chain of custody), `commands-logs.md`, `commands-aws.md`, `commands-gcp.md`, `commands-azure.md`, `commands-kubernetes.md`, `commands-cloudflare.md`, `commands-github.md`, `commands-identity.md`.

## 7. Phase 5: Containment

**Goal.** Stop the attacker from doing more harm while you keep the evidence and limit damage to the business.

AWS describes short-term containment as stopping the active threat, such as isolating a network or revoking credentials. Long-term containment addresses the root cause ([AWS contain guide](https://docs.aws.amazon.com/security-ir/latest/userguide/contain.html)).

**Steps**

1. Confirm that the evidence for this target is preserved. See phase 4. When it is not, name the evidence that the change can destroy. The commander decides whether to contain first.
2. Choose the least destructive action that stops the harm. Prefer reversible actions: isolate, deny, suspend, disable. Avoid delete.
3. Get the commander's approval. A human approves each WRITE command.
4. Contain every known foothold at nearly the same time, so the attacker cannot use one to regain the others.
5. Record the exact change and the time. Record how to reverse it.
6. Check that the action worked. See what the attacker can still do.
7. Watch the logs for the attacker's next move.

**Decisions**

AWS lists criteria for a containment strategy ([AWS contain guide](https://docs.aws.amazon.com/security-ir/latest/userguide/contain.html)). Ask these questions:

- What damage can the attacker still do?
- Does this action destroy evidence or meet a legal duty to keep it?
- Which service loses availability?
- How long will it take to complete?
- Does it contain fully or only in part?
- Can we reverse it?
- Is it an emergency workaround or a permanent fix?
- Do we contain now, or watch to learn more? Contain now when the attacker can reach sensitive data, destroy data, or move to more systems.

**Pitfalls**

- Changing a security group does not end open connections. AWS notes that existing tracked connections stay open and only new traffic is blocked ([AWS contain guide](https://docs.aws.amazon.com/security-ir/latest/userguide/contain.html)). End sessions in addition.
- Blocking only the attacker's IP address. Attackers use VPNs and change addresses ([Microsoft token theft playbook](https://learn.microsoft.com/en-us/security/zero-trust/security-operations-playbook-token-theft)).
- Resetting a password and leaving active sessions, refresh tokens, or API keys in place.
- Disabling one foothold and leaving the persistence the attacker added.
- Containing in steps over many hours. The attacker may notice and speed up or destroy data.
- Using the compromised channel to coordinate. Move to a clean channel first.
- Removing a secret from a repository and treating it as contained. The secret still works until it is revoked ([GitHub remediation guide](https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection/remediating-a-leaked-secret)).
- Forgetting the reverse plan. Record it before you act.

**Command files.** `commands-aws.md`, `commands-gcp.md`, `commands-azure.md`, `commands-cloudflare.md`, `commands-kubernetes.md`, `commands-identity.md`, `commands-github.md`, `commands-network.md`, `commands-hosts.md`.

## 8. Phase 6: Eradication

**Goal.** Remove the attacker's access and the cause, so the attacker cannot return.

**Steps**

1. List every item the attacker created or changed. Use the scoping list.
2. Revoke or rotate every credential the attacker could read. Revoke with the provider. GitHub says revoking the secret with its provider is the most important step ([GitHub remediation guide](https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection/remediating-a-leaked-secret)).
3. When a service depends on a secret, create the new secret first. Switch the service. Then revoke the old secret.
4. Delete attacker-created users, keys, roles, grants, devices, rules, jobs, and webhooks. Record each item before you delete it.
5. Remove or rebuild affected hosts and workloads from a known-good source. Do not clean in place when you cannot prove the host is clean.
6. Fix the root cause. Examples: patch, close the exposure, remove the permission, fix the pipeline.
7. Search for secrets the attacker may have read. Include data that held more credentials. Rotate those too.
8. Record each change in the notes.

**Decisions**

- Rebuild or clean? Rebuild when you cannot prove the attacker's full reach.
- Rotate everything or only known secrets? Rotate every secret that the compromised identity or host could read.
- Rewrite repository history? GitHub warns this is destructive and disruptive. Decide with the repository's owners ([GitHub remediation guide](https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection/remediating-a-leaked-secret)).

**Pitfalls**

- Rotating only the leaked key, not the keys it could read.
- Rotating before you record the old key's last use.
- Rotating a secret and forgetting a copy in another system: CI variables, container images, backups, config files.
- Missing persistence in places people forget: mailbox rules, OAuth app grants, scheduled jobs, startup scripts, cluster admission webhooks.
- Restoring a host from a backup made after the compromise began.
- Starting eradication before you know the full scope. The attacker returns through the foothold you missed.

**Command files.** `commands-aws.md`, `commands-gcp.md`, `commands-azure.md`, `commands-cloudflare.md`, `commands-kubernetes.md`, `commands-identity.md`, `commands-github.md`, `commands-hosts.md`.

## 9. Phase 7: Recovery

**Goal.** Return services and access to normal safely, in a known-good state.

**Steps**

1. Restore from a known-good source. Check the date of the backup against the scoping timeline.
2. Restore services in stages. Start with the least critical.
3. Reverse the temporary containment actions, one at a time. Use the reverse plan from phase 5.
4. Re-enable accounts only after you delete the attacker's added devices, credentials, and rules. Microsoft gives this order ([Microsoft token theft playbook](https://learn.microsoft.com/en-us/security/zero-trust/security-operations-playbook-token-theft)).
5. Restore data the attacker changed or deleted. Check it against a trusted copy.
6. Keep enhanced logging and alerts on the recovered systems.
7. Tell users what they must do. Examples: sign in again, re-enrol MFA, change a password.

**Decisions**

- Is the system safe to return? Use the verification checks in phase 8.
- Do we return all services at once? Return in stages so a missed foothold appears early.
- When do we declare the incident over? See phase 8.

**Pitfalls**

- Reversing containment too early.
- Returning a service with the original weakness still present.
- Restoring a backup that already holds the attacker's change.
- Disabling enhanced monitoring as soon as service is back.
- Forgetting the user-side work, such as session reset and MFA re-enrolment.

**Command files.** `commands-aws.md`, `commands-gcp.md`, `commands-azure.md`, `commands-cloudflare.md`, `commands-kubernetes.md`, `commands-identity.md`, `commands-hosts.md`, `commands-logs.md`.

## 10. Phase 8: Verification

**Goal.** Show with evidence that the attacker is gone and the fix works.

**Steps**

1. Re-run the scoping searches for every indicator. Expect no new activity after containment.
2. Check that each revoked credential now fails. Test with a human-approved check.
3. Check that each exposure is closed from the outside. Test as an outside user would.
4. Compare the current state of changed resources with the saved state from phase 4.
5. Watch the logs for a set period. Choose the period with the commander. Use a longer period for a serious incident.
6. Search for the attacker's indicators in the new period and in other systems.
7. Record what you checked, the result, and the time.
8. End the response out loud and in writing. Google advises ending the response explicitly, or people assume it is still running ([SRE workbook](https://sre.google/workbook/incident-response/)).
9. Start the post-incident review. See `process.md`, section 8.

**Decisions**

- Is the monitoring period long enough? A longer period suits an attacker who was active for a long time.
- Is the root cause known? If it is not known, write it as an open question. Do not claim a cause you have not shown.
- Do we need an independent check? Use a second person or an external firm for a serious incident.

**Pitfalls**

- Declaring the incident closed because the alerts stopped.
- Checking only the systems you contained.
- Testing a revoked credential in a way that creates new access or new data.
- Closing the incident without an owner for each open action item.

**Command files.** `commands-logs.md`, `commands-network.md`, plus the file for the affected platform.

## 11. Common incident types and first moves

Each type lists first moves in order. All types use the same phases. Do phase 4 before any change that destroys state. The exception is continuing harm. Then the commander can approve the change first, after reading which evidence it can destroy.

### 11.1 Leaked cloud key

1. Record the key ID, where it leaked, and when. Do not copy the secret into notes.
2. Record the key's creation date, last use, and the identity it belongs to.
3. Read the provider's audit log for the recorded uses of the key. Look for use from unknown addresses and for new identities, keys, or roles. Record the event types, Regions, and accounts that the log does not cover. For example, CloudTrail logs no data events by default.
4. Save the audit log and the key metadata.
5. After the commander approves, deactivate the key. Prefer deactivate over delete, so you keep the record.
6. Rotate the key and update the services that need it.
7. Check what the key could reach. Rotate any secret it could read.
8. Remove the secret from the source where it leaked. Removal alone does not stop abuse ([GitHub remediation guide](https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection/remediating-a-leaked-secret)).

Files: `commands-aws.md`, `commands-gcp.md`, `commands-azure.md`, `commands-github.md`, `commands-logs.md`.

### 11.2 Compromised identity account or session token

1. Treat the account as compromised when you cannot confirm that the activity is legitimate. Microsoft gives the same rule for token theft ([Microsoft token theft playbook](https://learn.microsoft.com/en-us/security/zero-trust/security-operations-playbook-token-theft)).
2. Save the sign-in and audit logs for the user.
3. List new MFA methods, devices, OAuth grants, mailbox rules, and API tokens added after the first bad sign-in.
4. Check whether other users share the attacker's address or user agent.
5. Contain: reset the password, end all sessions, revoke refresh tokens, and block the user as needed. A stolen token can pass MFA, so ending sessions matters.
6. Remove the attacker's added methods, devices, grants, and rules before you re-enable the user.
7. Check what the account could reach and what it accessed.

Files: `commands-identity.md`, `commands-azure.md`, `commands-logs.md`, `commands-github.md`.

### 11.3 Exposed origin or WAF bypass

1. Confirm that the origin answers requests that do not pass through the proxy or WAF.
2. Find how the origin address leaked. Cloudflare lists historical DNS records, DNS-only records such as SPF, and mail servers on the same host ([Cloudflare protect your origin](https://developers.cloudflare.com/fundamentals/security/protect-your-origin-server/)).
3. Read origin and edge logs for direct requests. Compare them with the edge logs to find traffic that skipped the WAF.
4. Save the logs.
5. Contain: restrict the origin to the proxy network. Cloudflare rates IP allowlisting as moderate because of spoofing, and rates Authenticated Origin Pulls and Tunnel as very secure.
6. If the address leaked, rotate the origin address. Cloudflare advises this after onboarding ([Cloudflare protect your origin](https://developers.cloudflare.com/fundamentals/security/protect-your-origin-server/)).
7. Check whether the attacker used the bypass to reach data or to attack the application.

Files: `commands-cloudflare.md`, `commands-network.md`, `commands-logs.md`, `commands-hosts.md`.

### 11.4 Public bucket or data exposure

1. Confirm the exposure from outside the account with a read-only check.
2. Save the bucket policy, ACLs, public-access settings, and object list before any change.
3. Enable or find access logs. Check whether they cover the exposure period.
4. Read the access logs for reads by unknown parties. Absence of logs does not prove absence of access.
5. After approval, block public access (AWS-61, GCP-21). Do not delete objects.
6. List which data was exposed. Involve counsel when it includes personal data or regulated data.
7. Check whether the bucket held secrets. Rotate them.

Files: `commands-aws.md`, `commands-gcp.md`, `commands-azure.md`, `commands-logs.md`, `commands-network.md`.

### 11.5 Compromised CI or source repository

1. Record the affected repositories, workflows, runners, and tokens.
2. Save the audit log, workflow run logs, and the commit and pull request history.
3. List the secrets that the workflows could read. Treat all of them as exposed.
4. Check for malicious changes: workflow files, dependencies, release artifacts, webhooks, deploy keys, and installed apps.
5. After approval, disable the affected workflows (GH-12). Revoke the tokens and deploy keys (GH-11).
6. Rotate all exposed secrets. Revoke at the provider.
7. Check released artifacts built in the exposure window. Rebuild them from a clean source if needed.

Files: `commands-github.md`, `commands-logs.md`, `commands-aws.md`, `commands-gcp.md`, `commands-azure.md`.

### 11.6 Malware on a host

1. Do not shut down or reboot the host.
2. Record the host, the user, the alert, and the time.
3. Capture memory with an approved tool. Then capture the disk or a snapshot. See `commands-hosts.md`.
4. Hash and store the captures. Start the chain of custody.
5. Isolate the host from the network in a reversible way. Note that cutting the network can make some malware wipe evidence ([RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html), section 2.2). Capture memory first. The exception is continuing harm. Then the commander can approve isolation first, with the evidence that it can destroy named.
6. Search other hosts for the same indicators.
7. Check which credentials the host held. Rotate them.
8. Rebuild the host from a known-good source.

Files: `commands-hosts.md`, `commands-network.md`, `commands-logs.md`.

### 11.7 Compromised Kubernetes workload

1. Record the namespace, pod, node, image, and service account.
2. Save the pod specification and the logs. Do not read secret values.
3. Check the service account's permissions. A pod with create rights can reach the nodes. Kubernetes warns about this ([Kubernetes security checklist](https://kubernetes.io/docs/concepts/security/security-checklist/)).
4. Check for access to the cloud metadata service. Kubernetes advises blocking it when it is not needed.
5. Capture evidence from the pod and node before you delete the pod.
6. Contain: apply a network policy that denies ingress and egress to the pod (K8S-19). Another policy that allows traffic to the pod still allows it, so check the existing policies first. Network policies need a network plugin that supports them ([Kubernetes security checklist](https://kubernetes.io/docs/concepts/security/security-checklist/)).
7. If node compromise is possible, cordon the node only after evidence capture. The exception is continuing harm. Then the commander can approve the cordon first, with the evidence that it can destroy named.
8. Rotate the service account tokens and any secret that the pod could read.
9. Check the cluster audit log for the same service account.

Files: `commands-kubernetes.md`, `commands-hosts.md`, `commands-logs.md`, `commands-aws.md`, `commands-gcp.md`, `commands-azure.md`.

## 12. Mapping to NIST SP 800-61r3 and CSF 2.0

NIST SP 800-61r3 (April 2025) supersedes Rev. 2 ([NIST publication page](https://csrc.nist.gov/pubs/sp/800/61/r3/final)). It is a CSF 2.0 Community Profile. It does not use the Rev. 2 four-phase lifecycle as its main structure. It organises incident response around the six CSF 2.0 functions: Govern, Identify, Protect, Detect, Respond, Recover.

The NIST incident response project page describes the model in three levels ([NIST incident response project](https://csrc.nist.gov/projects/incident-response)):

- Govern, Identify, and Protect are preparation. NIST says they "are not part of the incident response itself".
- Detect, Respond, and Recover are incident response.
- Improvement sits in the Identify function. Lessons from all functions feed into it.

NIST SP 800-61r3 Table 1 links the old Rev. 2 phases to the CSF 2.0 functions ([NIST SP 800-61r3 PDF](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r3.pdf), page 6):

| Rev. 2 phase                        | CSF 2.0 functions                                 |
| ----------------------------------- | ------------------------------------------------- |
| Preparation                         | Govern, Identify (all Categories), Protect        |
| Detection & Analysis                | Detect, Identify (Improvement Category)           |
| Containment, Eradication & Recovery | Respond, Recover, Identify (Improvement Category) |
| Post-Incident Activity              | Identify (Improvement Category)                   |

This skill maps its phases as follows. The mapping is ours, not NIST's. The category names come from CSF 2.0 ([NIST CSWP 29](https://nvlpubs.nist.gov/nistpubs/CSWP/NIST.CSWP.29.pdf)).

| Skill phase                         | CSF 2.0 function                              | CSF 2.0 categories                                                            |
| ----------------------------------- | --------------------------------------------- | ----------------------------------------------------------------------------- |
| 1. Detection                        | Detect                                        | DE.CM Continuous Monitoring, DE.AE Adverse Event Analysis                     |
| 2. Triage                           | Detect, then Respond                          | DE.AE Adverse Event Analysis, RS.MA Incident Management                       |
| 3. Scoping                          | Respond                                       | RS.AN Incident Analysis                                                       |
| 4. Evidence preservation            | Respond                                       | RS.AN Incident Analysis                                                       |
| 5. Containment                      | Respond                                       | RS.MI Incident Mitigation                                                     |
| 6. Eradication                      | Respond                                       | RS.MI Incident Mitigation                                                     |
| 7. Recovery                         | Recover                                       | RC.RP Incident Recovery Plan Execution, RC.CO Incident Recovery Communication |
| 8. Verification                     | Recover, with return to Detect for monitoring | RC.RP Incident Recovery Plan Execution, DE.CM Continuous Monitoring           |
| Status updates (`process.md`)       | Respond, Recover                              | RS.CO Incident Response Reporting and Communication, RC.CO                    |
| Post-incident review (`process.md`) | Improvement, in Identify                      | ID.IM Improvement                                                             |

Preparation (Govern, Identify, Protect) is out of scope for this file. Preparation covers plans, logging, access, tooling, and practice. It limits how fast you can run phases 1 to 8.

## 13. Sources

- NIST SP 800-61r3: https://csrc.nist.gov/pubs/sp/800/61/r3/final
- NIST SP 800-61r3 PDF (Table 1): https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r3.pdf
- NIST CSF 2.0 (CSWP 29): https://nvlpubs.nist.gov/nistpubs/CSWP/NIST.CSWP.29.pdf
- NIST incident response project: https://csrc.nist.gov/projects/incident-response
- NIST SP 800-86: https://csrc.nist.gov/pubs/sp/800/86/final
- RFC 3227: https://www.rfc-editor.org/rfc/rfc3227.html
- Google SRE book, managing incidents: https://sre.google/sre-book/managing-incidents/
- Google SRE workbook, incident response: https://sre.google/workbook/incident-response/
- Google Cloud, data incident response process: https://docs.cloud.google.com/docs/security/incident-response
- PagerDuty, severity levels: https://docs.pagerduty.com/ops-guides/incident-response-guide/severity-levels
- AWS Security Incident Response User Guide, contain: https://docs.aws.amazon.com/security-ir/latest/userguide/contain.html
- Microsoft token theft playbook: https://learn.microsoft.com/en-us/security/zero-trust/security-operations-playbook-token-theft
- GitHub, remediating a leaked secret: https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection/remediating-a-leaked-secret
- Cloudflare, protect your origin server: https://developers.cloudflare.com/fundamentals/security/protect-your-origin-server/
- Kubernetes security checklist: https://kubernetes.io/docs/concepts/security/security-checklist/
