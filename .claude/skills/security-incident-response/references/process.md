# Process: people and coordination in a security incident

This file covers who does what, and how people work together. The technical steps are in `technique.md`. Commands are in the `commands-*.md` files. This file gives no legal advice.

## Contents

1. Roles
2. Handover
3. Status updates
4. Legal and privilege
5. External forensics firms
6. Evidence and notes
7. Follow-up tracking
8. Post-incident review
9. Staff welfare
10. Agent rules for process
11. Sources

## 1. Roles

Google separates incident work into command, operations, communication, and planning. The incident commander keeps any role they have not delegated ([SRE book, managing incidents](https://sre.google/sre-book/managing-incidents/)). Google also advises that responders may delegate and escalate ([SRE workbook](https://sre.google/workbook/incident-response/)). AWS advises a RACI chart that lists who is responsible, accountable, consulted, and informed. It lists HR, executives, legal, and application owners as stakeholders ([AWS Well-Architected, SEC10-BP02](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_incident_response_develop_management_plans.html)).

One person can hold two roles in a small incident. In a serious incident, do not let one person hold command and hands-on technical work at the same time.

### 1.1 Incident commander (IC)

- Owns: the state of the incident, the severity, the plan, delegation, and the decision to contain, hand over, or close. Owns the decision to end the response.
- Does: assigns the other roles. Approves each WRITE action. Keeps the response organised. Asks for facts, not guesses.
- Does not: do deep technical work. Does not write every update. Does not make legal decisions. Does not hide bad news from leadership.

### 1.2 Communications lead

- Owns: updates to responders, leadership, and customers. Owns the update schedule. Owns the answers to questions from outside the response team.
- Does: drafts updates from facts the IC confirms. Collects questions. Keeps a list of who was told what.
- Does not: direct technical work. Does not publish unconfirmed facts. Does not speak for legal or the press unless counsel agrees.

Google calls this role the public face of the response ([SRE workbook](https://sre.google/workbook/incident-response/)).

### 1.3 Scribe

- Owns: the incident notes file and the timeline.
- Does: records each action, finding, decision, and approval with a UTC time and the person responsible. Records what was run and the result.
- Does not: investigate, decide, or filter what goes in. Does not rewrite history.

Google does not define the scribe as a formal role. A scribe appears in a case study, where the scribe keeps the record of actions, owners, and timestamps ([SRE workbook](https://sre.google/workbook/incident-response/)).

### 1.4 Operations or technical lead

- Owns: the technical work. Owns the evidence and the changes to systems.
- Does: runs or directs the containment, eradication, and recovery work. Reports facts to the IC. Proposes actions and their risk.
- Does not: set the severity, change the plan, or talk to leadership or customers without the IC.

The SRE book states that the operations team should be the only group that changes the system during an incident ([SRE book](https://sre.google/sre-book/managing-incidents/)). Everyone else asks the operations lead.

### 1.5 Optional roles

- Legal liaison. Owns the contact with counsel. Passes legal limits to the IC. Does not direct the technical work. See section 4.
- Subject matter experts (SMEs). Own deep knowledge of a system, such as an application, a database, or a cloud account. Answer questions. Do not make containment choices alone. AWS advises you to build links with SMEs and practise with them before an incident ([AWS SEC10-BP02](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_incident_response_develop_management_plans.html)).
- Planning lead. Owns longer-term work: bugs, handovers, and the list of changes to revert after the incident ([SRE book](https://sre.google/sre-book/managing-incidents/)).

### 1.6 Rules for all roles

1. Name each role holder in the incident notes at the start.
2. Say role changes out loud and write them in the notes.
3. Keep a backup channel outside normal systems. AWS advises this ([AWS SEC10-BP02](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_incident_response_develop_management_plans.html)).
4. Give each person one clear task at a time.

## 2. Handover

### 2.1 When to hand over

- Hand over at the end of a shift. Plan it before the person is tired.
- Hand over after a person works for many hours. One case study rotated the commander and on-call engineers every four hours in a long incident, to encourage rest and bring new ideas ([SRE workbook](https://sre.google/workbook/incident-response/)).
- Hand over when a more experienced person is available. Google describes one case where the commander role went to a more experienced responder ([SRE workbook](https://sre.google/workbook/incident-response/)).
- Hand over when a person has a conflict of interest, or is a possible subject of the incident.

### 2.2 Handover checklist

1. Brief the incoming person first. Use a call or video.
2. Give the handover note (section 2.3). Point to the notes file.
3. Show open actions, pending approvals, and running commands.
4. Show every access path in use and who holds each.
5. The outgoing person asks: "You are now the incident commander, okay?" The SRE book uses this wording ([SRE book](https://sre.google/sre-book/managing-incidents/)).
6. The outgoing person stays until the incoming person says yes.
7. The new holder announces the change to everyone in the response channel.
8. The scribe records the handover and the time in UTC.
9. The outgoing person stays reachable for questions for a short, agreed time.

### 2.3 Handover note template

```markdown
# Handover note

- Incident ID and title:
- Role handed over:
- From / to:
- Handover time (UTC):
- Current severity and why:

## State now

- What we know (facts, with source):
- What we assume (not confirmed):
- What we do not know:

## Done

- Containment actions taken (time UTC, who, how to reverse):
- Evidence saved (location, hash file):

## In progress

- Running tasks and their owners:
- Pending approvals:

## Next steps

1.
2.

## Risks and cautions

- Things not to do (for example, do not reboot host X before capture):
- Who must not be told:

## Contacts

- Role holders:
- Counsel or legal liaison:
- Next status update due (UTC):
- Notes file location:
```

## 3. Status updates

### 3.1 Audiences

| Audience                     | Needs                                            | Channel                                 |
| ---------------------------- | ------------------------------------------------ | --------------------------------------- |
| Responders                   | Current state, tasks, risks                      | Incident channel, notes file            |
| Leadership                   | Impact, decisions needed, risk, next update time | Short message from the IC or comms lead |
| Customers or other outsiders | Verified facts that affect them, and what to do  | Only as counsel and the IC approve      |

Google advises that silence leads people to think nothing is happening. It also advises that you prepare two or three update templates in advance ([SRE workbook](https://sre.google/workbook/incident-response/)).

### 3.2 Cadence

Atlassian advises an update every 30 minutes, or at the cadence that fits the situation ([Statuspage incident communication tips](https://support.atlassian.com/statuspage/docs/incident-communication-tips)). Use 30 minutes as the default. The IC sets the real schedule and may change it. Counsel and the IC decide when customers get updates.

Rules:

1. State the time of the next update in every update.
2. Send the update at the stated time, even if nothing changed. Write "no change".
3. Send a final update when the response ends. Google says to end the response explicitly ([SRE workbook](https://sre.google/workbook/incident-response/)).

### 3.3 What an update may contain

- Updates state facts. They do not speculate.
- Write "We know" for confirmed facts, with the source.
- Write "We do not yet know" for open questions.
- Do not name a cause until it is confirmed.
- Do not name a person as the cause.
- Do not give a time for the fix unless the IC agrees.
- Do not write secrets, full log lines, or personal data in an update.
- Mark the update "DRAFT" until a human approves it.

### 3.4 Status update template

```markdown
# Incident update

- Incident: <incident-id>, <short-title>
- Time (UTC): <time>
- Severity: <level>
- Status: <investigating | contained | recovering | monitoring | closed>

## What we know

- <confirmed fact, with source>

## What we do not know yet

- <open question>

## What we do next

- <action, owner, expected time>

## What we need

- <decision, access, or help, and from whom>

## Next update

- <time UTC>
```

## 4. Legal and privilege

This section gives general practice. It is not legal advice. Ask your own counsel.

### 4.1 Involve counsel early

1. Tell counsel at triage when the incident may involve personal data, customer data, regulated data, a contract duty, or a crime.
2. Ask counsel before you contact outsiders, law enforcement, a regulator, or a customer.
3. Ask counsel how to collect and keep evidence. Google notes that counsel sets the strategy for evidence collection ([Google Cloud incident response](https://docs.cloud.google.com/docs/security/incident-response)).
4. NIST advises that you consult management and legal counsel before you apply forensic practices ([NIST SP 800-86](https://csrc.nist.gov/pubs/sp/800/86/final)). RFC 3227 advises that you check procedures with law enforcement in your jurisdiction ([RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html), section 1).

### 4.2 Work under the direction of counsel

Some organisations run the investigation at the request of counsel. The aim is to keep the work product protected from disclosure in later legal action. Whether protection applies depends on the jurisdiction and the facts. Counsel decides. Follow the instructions counsel gives. Common practice is:

- Counsel requests the investigation in writing.
- The legal liaison is on the response channel.
- The group of people with access is small and listed.
- Findings go to counsel first.

No public source in this skill covers privilege rules. Treat the points above as practice to confirm with counsel.

### 4.3 What to write and what not to write

In chat, tickets, and notes:

- Write facts: what you saw, when, and from which source.
- Write actions: what was run, by whom, and the result.
- Write open questions as questions.
- Do not write legal conclusions, such as "this is a breach" or "we are liable".
- Do not guess about cause or fault.
- Do not name people as at fault.
- Do not write jokes or blame.
- Do not paste secrets or personal data.
- Do not forward incident details to people outside the response group.
- Mark each draft "DRAFT". When counsel asks, also mark it with a label such as "Prepared at the request of counsel". Counsel chooses the label.
- Do not delete or edit past notes. Add a correction as a new entry.

### 4.4 Notification duties

- Duties to notify regulators, customers, or partners vary by law and by contract.
- A contract may set a time limit. A law may set another.
- Counsel decides whether a duty applies and when its clock starts.
- This skill states no deadline. Ask counsel for the law and the date.
- Google shows one pattern: the commander starts the notification process, and the comms lead drafts the notice with legal input ([Google Cloud incident response](https://docs.cloud.google.com/docs/security/incident-response)).
- Record the time you became aware of the incident and the time you confirmed each fact. Counsel needs both.

### 4.5 Agents and incident data

- An agent never sends incident data to an external service.
- This includes web forms, public AI services, paste sites, online scanners, and file-sharing links.
- An agent can look up an indicator through public infrastructure: a public DNS resolver, a WHOIS registry, or a public certificate transparency search. Such a lookup does not send incident data.
- An agent asks the human before a lookup on any other outside service.
- A human decides whether data may leave the organisation, with counsel when needed.

## 5. External forensics firms

### 5.1 When to engage

- You lack the skills or the people.
- The incident is Critical, or the attacker is advanced.
- An independent report is needed for a regulator, insurer, or court.
- The incident involves possible insider action.
- The attacker may control your own systems.
- Check your cyber insurance policy. It may require a panel firm or prior notice.

AWS advises that you involve trusted partners or external experts in the response ([AWS SEC10-BP02](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_incident_response_develop_management_plans.html)). Cloud providers also offer support for active incidents. Check your provider's terms.

### 5.2 Engage through counsel

1. Ask counsel to hire the firm, or to approve the contract.
2. Counsel decides who directs the firm and who receives its reports.
3. Use a signed engagement and a confidentiality agreement before you share data.
4. Keep the engagement and its reports in a restricted folder.

This is common practice. Confirm with counsel.

### 5.3 Scope and statement of work points

- The questions the firm must answer.
- The systems, accounts, and time range in scope.
- The deliverables: written reports, timeline, indicators, advice.
- Who receives each deliverable, and who can share it.
- Draft and final report steps. Counsel decides who reviews drafts.
- Data handling: where data is stored, who can read it, how long it is kept, and how it is deleted.
- Roles and contacts on both sides.
- Time and cost limits, and how changes to scope are agreed.
- Notice when the firm finds something unexpected.
- Handling of personal data in evidence.

### 5.4 Evidence handover and chain of custody

1. List each item: name, source, UTC time of capture, size, and hash.
2. Hand over copies. Keep the originals.
3. Record each transfer: who gave, who received, when, how, and the shipping number if any. RFC 3227 lists these custody fields ([RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html), section 4.1).
4. Send data by an approved, encrypted path. Send keys by a different path.
5. The firm confirms the hashes on receipt.
6. Record the confirmation in the notes.

### 5.5 Access the firm gets

- Use least privilege. Give read-only roles first.
- Create named accounts for each person. Do not share accounts.
- Set an expiry date on each access. Time-box it to the engagement.
- Log the firm's access. Review it.
- Remove access when the engagement ends. Record the removal.
- A human approves each access grant. An agent does not create access for the firm.

## 6. Evidence and notes

1. Keep one incident notes file and one timeline for the whole incident.
2. Record all times in UTC. RFC 3227 advises that you note whether times are UTC or local ([RFC 3227](https://www.rfc-editor.org/rfc/rfc3227.html), section 2).
3. Record each entry with: time, person, action or finding, source, and result.
4. Mark each timeline entry as "confirmed" or "inferred".
5. Save command output into files. Record the file path, the UTC time, and the hash in the notes.
6. Hash each saved file. Keep the hash list as its own file.
7. Keep the notes folder access-controlled. Notes can hold personal data and internal context.
8. Do not write secrets in the notes. Write the secret's ID, not its value.
9. Add corrections as new entries. Do not edit old entries.
10. Back up the notes folder to a place the attacker cannot reach.

Use the timeline table template in `commands-logs.md`. It has a `Status` column for "confirmed" or "inferred".

## 7. Follow-up tracking

Google's postmortem guidance says an action item should have a type, a priority, one owner, and a tracking bug. It also says that a postmortem without action is no better than no postmortem ([SRE workbook, postmortem culture](https://sre.google/workbook/postmortem-culture/)).

1. Create each action item in the normal work tracker. Do not keep it only in the review document.
2. Give each item: a title, one owner, a due date, a priority, and a link to the finding that caused it.
3. State a verifiable end state for each item.
4. Use these types: prevent, detect, mitigate, repair, investigate.
5. Use the priorities P0, P1, and P2, as in the action item examples of the SRE workbook. P0 is the most urgent.
6. Review the open items at a set interval, for example weekly. Report overdue items to leadership.
7. Close an item only when the end state is shown.
8. At the next review, check that the closed items worked.

The action items table in section 8.1 is the template for tracking.

## 8. Post-incident review

Hold a review when an incident meets one of the triggers in the SRE book ([SRE book, postmortem culture](https://sre.google/sre-book/postmortem-culture/)):

- User-visible downtime or degradation beyond a set threshold.
- Data loss of any kind.
- On-call engineer intervention, such as a release rollback or rerouted traffic.
- A resolution time above a set threshold.
- A monitoring failure, which usually means manual discovery of the incident.

Also hold a review for any other incident that taught something.

Use a blameless format. Google states that a blameless postmortem focuses on what went wrong, not who caused it. Google also states that people act on the best information they had ([SRE book, postmortem culture](https://sre.google/sre-book/postmortem-culture/), [SRE workbook](https://sre.google/workbook/postmortem-culture/)). Fix systems and processes. People cannot be fixed.

Rules:

1. Write the review within a short, set time after the incident.
2. Write facts. Avoid personal judgement and emotional language.
3. Ask "what" and "how", not "who".
4. After counsel agrees, share the review widely. Do not include data that identifies a user ([SRE book, postmortem culture](https://sre.google/sre-book/postmortem-culture/)).
5. Hold a review meeting. An unreviewed postmortem has little value.
6. Track action items to closure. See section 7.

### 8.1 Review template

```markdown
# Post-incident review: <incident-id>, <title>

- Status: DRAFT
- Author and reviewers:
- Incident dates (UTC):
- Review date:
- Severity at peak:

## Summary

One paragraph: impact and cause, in plain words.

## Impact

- Who and what was affected:
- Data involved:
- Duration:
- Cost, if known:

## Detection

- How we learned of it, and how long after it began:

## Timeline (UTC)

| Time   | Event   | Source   |
| ------ | ------- | -------- |
| <time> | <event> | <source> |

## Root cause and trigger

- Cause (state "unknown" if not shown):
- Trigger:

## Contributing factors

- <technical, process, or tooling factor>

## What went well

- <item>

## What went badly

- <item>

## Where we got lucky

- <item that could have made it worse>

## Response and process

- Role changes, handovers, and gaps in tools or access:
- Legal and notification steps taken (facts only):

## Action items

| ID   | Action   | Type   | Priority | Owner    | Due    | Finding link |
| ---- | -------- | ------ | -------- | -------- | ------ | ------------ |
| <id> | <action> | <type> | <P0-P2>  | <person> | <date> | <link>       |

## Open questions

- <question>
```

## 9. Staff welfare

Incidents tire people. Tired people make mistakes. Care for the team as part of the response.

1. Set shift limits at the start. Plan handovers before people are tired. One case study rotated roles every four hours ([SRE workbook](https://sre.google/workbook/incident-response/)).
2. Do not depend on heroes. Google says incident management should not rely on the heroic effort of individuals ([SRE workbook](https://sre.google/workbook/incident-response/)).
3. Make people take breaks. A short break every few hours is a minimum.
4. Rotate roles in long incidents. The IC should rotate too.
5. Arrange food, water, and a quiet place to rest.
6. Do not ask people to work through the night without a plan for the next day.
7. Tell people to leave when their shift ends.
8. After a long or severe incident, give people time off. Leadership approves it.
9. Watch for signs of stress: short temper, errors, silence, tunnel vision, and refusal to stop. Say what you see in a kind way.
10. Offer support through the usual employee support route.
11. Keep the tone blameless in chat and in meetings. Do not blame people for the attack or for mistakes made under stress.
12. Thank people for specific work after the incident.

## 10. Agent rules for process

1. An agent may act as scribe. It records actions, findings, and times in the notes file.
2. An agent may draft status updates, handover notes, and review drafts. It marks each as "DRAFT".
3. A human sends every update. An agent does not post to a channel, an email, or a ticket on its own.
4. A human holds the incident commander role. An agent never holds it.
5. An agent does not decide severity, notification, or legal steps. It proposes them to the IC.
6. An agent never sends incident data to an external service. See section 4.5.
7. An agent does not create access for others. A human approves each access grant.
8. An agent runs only untagged READ-ONLY commands on its own. A human approves each WRITE command and each SENSITIVE command, one at a time.
9. An agent states facts and marks guesses as guesses. It does not name a person as the cause.
10. An agent tells the IC when it sees a sign of fatigue or error in the work, such as repeated mistakes.

## 11. Sources

- Google SRE book, managing incidents: https://sre.google/sre-book/managing-incidents/
- Google SRE workbook, incident response: https://sre.google/workbook/incident-response/
- Google SRE book, postmortem culture: https://sre.google/sre-book/postmortem-culture/
- Google SRE workbook, postmortem culture: https://sre.google/workbook/postmortem-culture/
- Google Cloud, data incident response process: https://docs.cloud.google.com/docs/security/incident-response
- AWS Well-Architected, SEC10-BP02 develop incident management plans: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_incident_response_develop_management_plans.html
- Atlassian Statuspage, incident communication tips: https://support.atlassian.com/statuspage/docs/incident-communication-tips
- RFC 3227: https://www.rfc-editor.org/rfc/rfc3227.html
- NIST SP 800-86: https://csrc.nist.gov/pubs/sp/800/86/final
