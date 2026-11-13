# Kubernetes commands

This file covers Kubernetes incident commands for `kubectl` and for audit log files. It includes RBAC, service accounts, Secret metadata, Ingresses, events, audit logs, and containment.
Labels and the approval rules are in `../SKILL.md`. Read them before you run any command from this file.

## Before you start

- Ask the human which cluster to use. Get the name of the kubeconfig context. Use it as `<context>`.
- A context name does not prove which cluster it reaches. Run K8S-01 before the first command and before each WRITE command. Compare its cluster, server, user, proxy, TLS setting, and helper program with the values that the human approved. When one differs, stop and tell the human.
- Every `kubectl` command in this file has `--context '<context>'`. Do not rely on the current context.
- Ask the human for any namespace (`<namespace>`), node (`<node-name>`), or user (`<username>`) that a command needs. Never guess them.
- Never run a command that prints Secret values. Do not use `-o yaml`, `-o json`, or `-o jsonpath` on a Secret. Do not use `describe secret`. See the warning in the Secrets section.
- The local `kubectl` client and the cluster can run different versions. Check `kubectl version` only when the human asks.

## Contents

- [Context](#context)
  - [K8S-01 Show the current kubeconfig context](#k8s-01-show-the-current-kubeconfig-context)
- [RBAC bindings](#rbac-bindings)
  - [K8S-02 List cluster role bindings with their subjects](#k8s-02-list-cluster-role-bindings-with-their-subjects)
  - [K8S-03 List role bindings in all namespaces with their subjects](#k8s-03-list-role-bindings-in-all-namespaces-with-their-subjects)
  - [K8S-04 Describe one cluster role binding](#k8s-04-describe-one-cluster-role-binding)
  - [K8S-05 Describe one role binding](#k8s-05-describe-one-role-binding)
  - [K8S-06 List what a user or service account can do](#k8s-06-list-what-a-user-or-service-account-can-do)
- [Service accounts](#service-accounts)
  - [K8S-07 List service accounts in all namespaces](#k8s-07-list-service-accounts-in-all-namespaces)
  - [K8S-08 List service account token Secrets (metadata only)](#k8s-08-list-service-account-token-secrets-metadata-only)
- [Secrets](#secrets)
  - [K8S-09 List Secret metadata in all namespaces](#k8s-09-list-secret-metadata-in-all-namespaces)
- [Ingresses](#ingresses)
  - [K8S-10 List Ingresses with hosts and backends](#k8s-10-list-ingresses-with-hosts-and-backends)
- [Events](#events)
  - [K8S-11 List events in all namespaces by time](#k8s-11-list-events-in-all-namespaces-by-time)
  - [K8S-12 List events with the events command](#k8s-12-list-events-with-the-events-command)
- [Audit logs](#audit-logs)
  - [K8S-13 Filter an audit log file by user](#k8s-13-filter-an-audit-log-file-by-user)
  - [K8S-14 Filter an audit log file for Secret access](#k8s-14-filter-an-audit-log-file-for-secret-access)
  - [K8S-15 Filter an audit log file for impersonation and exec](#k8s-15-filter-an-audit-log-file-for-impersonation-and-exec)
- [Containment](#containment)
  - [K8S-16 Save the manifest of a Deployment](#k8s-16-save-the-manifest-of-a-deployment)
  - [K8S-17 Cordon a node](#k8s-17-cordon-a-node)
  - [K8S-18 Scale a Deployment to zero](#k8s-18-scale-a-deployment-to-zero)
  - [K8S-19 Isolate pods with a deny-all network policy](#k8s-19-isolate-pods-with-a-deny-all-network-policy)

## Context

### K8S-01 Show the current kubeconfig context

- Purpose: show which cluster, API server, and user the named context uses. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the kubeconfig that the human set. No cluster permission.
- Command:

  ```bash
  kubectl config current-context
  kubectl config view --minify --context '<context>' -o jsonpath='{.contexts[0].name} {.contexts[0].context.cluster} {.clusters[0].cluster.server} {.contexts[0].context.user}{"\n"}'
  kubectl config view --minify --context '<context>' -o jsonpath='proxy-url={.clusters[0].cluster.proxy-url} insecure-skip-tls-verify={.clusters[0].cluster.insecure-skip-tls-verify} exec-command={.users[0].user.exec.command} exec-env-names={.users[0].user.exec.env[*].name}{"\n"}'
  env | grep -o -i -E '^(https?|all|no)_proxy='
  ```

- Output: the first line is the default context. The second line gives the context name, cluster name, API server URL, and user name of `<context>`. The third line shows the proxy, the TLS check setting, the authentication helper program, and the names of its extra environment variables for `<context>`. The last line prints the names of proxy variables in the environment, not their values. With no `proxy-url`, the client uses the `http_proxy` and `https_proxy` variables ([kubeconfig](https://kubernetes.io/docs/reference/config-api/kubeconfig.v1/)). The jsonpath reads no credential field. An error `cannot locate context` means that the name is wrong. Look for: a value that differs from the values that the human approved. Stop and tell the human in these cases:
  - `proxy-url` has a value, or the last line prints a proxy name. Ask the human to approve the route.
  - `insecure-skip-tls-verify` is `true`. The client then does not check the server certificate.
  - `exec-command` has a value. Each later `kubectl` call runs that program with the `args` and `env` of the same `exec` block. Kubernetes warns that a crafted kubeconfig can run malicious code. The agent does not print `args` or the `env` values, because they can hold a secret. Ask the human to read the whole `exec` block in their own terminal. Continue only after the human confirms that the program, its arguments, and its environment are trusted.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/kubectl/quick-reference/ and https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl config current-context --help`, `kubectl config view --help`, `kubectl options`, flag `--context`). Tested on a sample kubeconfig with two contexts: the second command printed the values of the named context, and a wrong name gave exit 1. The third command printed the proxy, `true`, the helper path, and the env names for a context that had them. It printed empty values for a context without them.

## RBAC bindings

### K8S-02 List cluster role bindings with their subjects

- Purpose: show who has cluster-wide roles. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `list` on `clusterrolebindings` in the `rbac.authorization.k8s.io` API group.
- Command:

  ```bash
  kubectl --context '<context>' get clusterrolebindings -o custom-columns='NAME:.metadata.name,ROLE:.roleRef.name,SUBJECT_KINDS:.subjects[*].kind,SUBJECTS:.subjects[*].name,SUBJECT_NAMESPACES:.subjects[*].namespace,CREATED:.metadata.creationTimestamp'
  ```

- Output: one row for each binding. Look for: `ROLE` of `cluster-admin`, subjects that you do not know, `Group` subjects such as `system:masters`, and recent `CREATED` values.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl get --help`, output format `custom-columns`).

Notes:

- The `-o wide` form of `kubectl get clusterrolebindings,rolebindings -A` also shows subjects. The docs do not list its columns. Use the `custom-columns` form above.

### K8S-03 List role bindings in all namespaces with their subjects

- Purpose: show who has roles inside namespaces. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `list` on `rolebindings` in all namespaces, in the `rbac.authorization.k8s.io` API group.
- Command:

  ```bash
  kubectl --context '<context>' get rolebindings -A -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,ROLE_KIND:.roleRef.kind,ROLE:.roleRef.name,SUBJECT_KINDS:.subjects[*].kind,SUBJECTS:.subjects[*].name,CREATED:.metadata.creationTimestamp'
  ```

- Output: one row for each binding. Look for: a `ClusterRole` such as `cluster-admin` bound inside a namespace, subjects that you do not know, and recent `CREATED` values.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl get --help`, flag `-A, --all-namespaces`).

### K8S-04 Describe one cluster role binding

- Purpose: read the role and the subjects of one cluster role binding. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `get` on `clusterrolebindings` in the `rbac.authorization.k8s.io` API group.
- Command:

  ```bash
  kubectl --context '<context>' describe clusterrolebinding <binding-name>
  ```

- Output: the role reference and a table of subjects with their kind, name, and namespace. Look for: a subject that you do not know, and a role with wide rights.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_describe/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl describe --help`).

### K8S-05 Describe one role binding

- Purpose: read the role and the subjects of one role binding. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `get` on `rolebindings` in the namespace, in the `rbac.authorization.k8s.io` API group.
- Command:

  ```bash
  kubectl --context '<context>' describe rolebinding <binding-name> -n <namespace>
  ```

- Output: the role reference and a table of subjects. Look for: a subject that you do not know, and a role with wide rights.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_describe/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl describe --help`).

### K8S-06 List what a user or service account can do

- Purpose: list the actions that an identity can do in one namespace. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: the human's identity needs the `impersonate` verb on `users`, `groups`, or `serviceaccounts` in the core API group. The `--as` flag sends the request as the other identity.
- Command:

  ```bash
  kubectl --context '<context>' auth can-i --list --as=<username> --as-group=<group-name> --namespace=<namespace>
  ```

- Output: a table of resources, verbs, and non-resource URLs that the identity can use. Repeat `--as-group` once for each group of the identity. `--as` alone sends no groups, so rights from a group are missing from the result. Kubernetes says the list "may be incomplete depending on the server's authorization mode, and any errors experienced during the evaluation." Record unknown groups as a gap. Check each critical right with `kubectl auth can-i <verb> <resource>` and the same flags. Look for: `*` in `Resources` or `Verbs`, `get` or `list` on `secrets`, `create` on `pods/exec`, `create` on `rolebindings`, and `impersonate`.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/access-authn-authz/user-impersonation/, https://kubernetes.io/docs/reference/kubernetes-api/definitions/self-subject-rules-review-v1-authorization/, and https://kubernetes.io/docs/reference/access-authn-authz/authentication/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl auth can-i --help`, `kubectl options`, flags `--as` and `--as-group`). The help says `--as-group` can be repeated.

Notes:

- For a service account, write the name as `--as=system:serviceaccount:<namespace>:<service-account-name>`. Add `--as-group=system:serviceaccounts --as-group=system:serviceaccounts:<namespace>`. The authentication page gives this user name form and these two groups.
- If the human lacks the `impersonate` verb, the API returns a `forbidden` error. Do not try to grant it. Ask the human.
- The API server audit log records the impersonation. The event has an `impersonatedUser` field.
- Run the command once for each namespace that matters. Without `--namespace`, kubectl uses the namespace of the context.

## Service accounts

### K8S-07 List service accounts in all namespaces

- Purpose: list all service accounts and the Secrets that they name. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `list` on `serviceaccounts` in all namespaces.
- Command:

  ```bash
  kubectl --context '<context>' get serviceaccounts -A -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,SECRETS:.secrets[*].name,CREATED:.metadata.creationTimestamp'
  ```

- Output: one row for each service account. Look for: names that you do not know, recent `CREATED` values, and a value in `SECRETS`. A value in `SECRETS` points to a long-lived token Secret. Check it with K8S-08.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl get --help`).

### K8S-08 List service account token Secrets (metadata only)

- Purpose: find long-lived service account tokens and their owners. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `list` on `secrets` in all namespaces. This right also allows a user to read Secret values. Ask the human to confirm that you may use it.
- Command:

  ```bash
  kubectl --context '<context>' get secrets -A --field-selector type=kubernetes.io/service-account-token -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,SERVICE_ACCOUNT:.metadata.annotations.kubernetes\.io/service-account\.name,CREATED:.metadata.creationTimestamp'
  ```

- Output: one row for each token Secret. Look for: tokens that are old, tokens for powerful service accounts (see K8S-02 and K8S-03), and tokens that nobody needs.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/concepts/configuration/secret/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl get --help`, flag `--field-selector`).

Notes:

- The command selects only the columns above. It never selects `.data`.
- The Kubernetes docs say that a `kubernetes.io/service-account-token` Secret is a legacy long-lived credential. Anyone who reads it can act as the service account.
- The field selector for the Secret field `type` is in the docs. The page does not show it with this value.
- The backslashes in the annotation key are the documented way to escape dots in a JSONPath key. The docs show them for `-o jsonpath`, not for `custom-columns`.

## Secrets

Warning: these forms print Secret values. Never run them.

- `kubectl get secret <name> -o yaml` and `-o json` print the `data` field. The values are base64 text, not encrypted.
- `kubectl get secret <name> -o jsonpath='{.data}'` prints the values.
- `kubectl describe secret <name>` shows the size in bytes for each key, for example `ca.crt: 1338 bytes`. The Kubernetes docs example omits the `token` value. Some kubectl versions can print the token of a service account token Secret. Do not run `describe secret`.
- Any identity that can `get` or `list` Secrets can read the values.
- Do not paste a Secret value into a report. If a value is exposed, tell the human. The human decides on key rotation.

### K8S-09 List Secret metadata in all namespaces

- Purpose: list all Secrets with their type and age, without values. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `list` on `secrets` in all namespaces. This right also allows a user to read Secret values. Ask the human to confirm that you may use it.
- Command:

  ```bash
  kubectl --context '<context>' get secrets -A -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.type,CREATED:.metadata.creationTimestamp'
  ```

- Output: one row for each Secret. Look for: Secrets created during the incident window, names that suggest credentials such as keys or tokens, and unexpected `TYPE` values such as `kubernetes.io/service-account-token` or `kubernetes.io/dockerconfigjson`.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/concepts/configuration/secret/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl get --help`, output format `custom-columns`).

Notes:

- The command selects only four metadata columns. It never selects `.data` or `.stringData`.
- Plain `kubectl get secrets -A` also hides the values. It shows `NAME`, `TYPE`, `DATA` (the number of keys), and `AGE`.
- Check who read Secrets with K8S-14.

## Ingresses

### K8S-10 List Ingresses with hosts and backends

- Purpose: list the hostnames and backend services that the cluster exposes. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `list` on `ingresses` in all namespaces, in the `networking.k8s.io` API group.
- Command:

  ```bash
  kubectl --context '<context>' get ingress -A -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,CLASS:.spec.ingressClassName,HOSTS:.spec.rules[*].host,PATHS:.spec.rules[*].http.paths[*].path,BACKENDS:.spec.rules[*].http.paths[*].backend.service.name,RESOURCE_BACKENDS:.spec.rules[*].http.paths[*].backend.resource.name,DEFAULT:.spec.defaultBackend.service.name,DEFAULT_RESOURCE:.spec.defaultBackend.resource.name,CREATED:.metadata.creationTimestamp'
  ```

- Output: one row for each Ingress. Look for: hosts that you do not know, a missing `HOSTS` value (the rule then matches all traffic), backends that you do not expect, and recent `CREATED` values. An Ingress with no rules sends all traffic to its default backend, in `DEFAULT` or `DEFAULT_RESOURCE`. A resource backend points to an object that is not a Service, such as a storage bucket. Tell the human about each resource backend.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl get --help`).

Notes:

- The `host` field is optional. A rule without a host applies to all inbound HTTP traffic on the Ingress address.
- Some clusters use other kinds for routing, such as Gateway API routes. This command shows only `Ingress` objects.

## Events

### K8S-11 List events in all namespaces by time

- Purpose: show recent cluster events in time order. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: `list` on `events` in all namespaces.
- Command:

  ```bash
  kubectl --context '<context>' get events -A --sort-by=.metadata.creationTimestamp
  ```

- Output: events with the oldest first and the newest last. Look for: `Warning` events, failed pulls of unknown images, pods that start in odd namespaces, `Killing` events, and failed mounts or Secret lookups.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/kubectl/quick-reference/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl get --help`, flags `-A` and `--sort-by`).

Notes:

- The Kubernetes quick reference uses `.metadata.creationTimestamp` for this sort. It does not show `.lastTimestamp`.
- Events are short-lived. Use the audit log (K8S-13 to K8S-15) for older history.

### K8S-12 List events with the events command

- Purpose: list events with a command that is made for events. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: `list` on `events` in all namespaces.
- Command:

  ```bash
  kubectl --context '<context>' events --all-namespaces --types=Warning
  ```

- Output: a table of `Warning` events. Look for: the same signs as in K8S-11.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_events/ (checked 2026-11-12)
- Local help: on kubectl clients before v1.26, `kubectl events --help` returns `unknown command "events"`. Those clients have the experimental form, `kubectl alpha events`.

Notes:

- A kubectl client before v1.26 has no `kubectl events`. Use `kubectl alpha events --all-namespaces` on that client, or use K8S-11.
- The current Kubernetes reference shows `kubectl events` with the options `--all-namespaces`, `--types`, `--for`, and `--watch`. The reference page does not give the first version that has it.
- Use `--for <kind>/<name>` to show the events of one object.

## Audit logs

Audit logs are not a `kubectl` command. The API server writes them.

- The audit policy file sets what the API server records. The flag `--audit-policy-file` names the file. If the flag is missing, the API server records no events.
- The flag `--audit-log-path` sets the audit log file. If the flag is missing, the log backend is off. A value of `-` writes to standard output.
- The log backend writes JSON lines. Each line is one event.
- The policy sets a level for each rule. `Metadata` records the user, time, resource, and verb, but no body. `Request` and `RequestResponse` also record bodies.
- An event has the fields `auditID`, `stage`, `requestURI`, `verb`, `user`, `impersonatedUser`, `sourceIPs`, `userAgent`, `objectRef`, `responseStatus`, `requestReceivedTimestamp`, and `stageTimestamp`.
- Audit log lines can hold Secret values if the policy records `Request` or `RequestResponse` for Secrets. The example policy in the docs uses `Metadata` for Secrets.
- Audit log lines hold user names, source IPs, and object names. Tag all audit log work SENSITIVE.
- Doc for the policy and the log file: https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/ (checked 2026-11-12)
- Doc for the event fields: https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/ (checked 2026-11-12)

On managed clusters, you usually cannot read the log file. Use the cloud service instead.

- Amazon EKS: enable the `audit` log type. EKS sends it to CloudWatch Logs. The log group is `/aws/eks/<cluster-name>/cluster`. The stream names start with `kube-apiserver-audit-`. Doc: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html (checked 2026-11-12)
- Google GKE: Cloud Audit Logs record Kubernetes audit events with the resource type `k8s_cluster`. Admin Activity logs are always on. Data Access logs are off by default. Read them in Logs Explorer. Doc: https://docs.cloud.google.com/kubernetes-engine/docs/how-to/audit-logging (checked 2026-11-12)
- Azure AKS: control plane logs are resource logs. Create a diagnostic setting to send the `kube-audit` or `kube-audit-admin` category to a Log Analytics workspace. The `kube-audit-admin` category omits `get` and `list` events. Doc: https://learn.microsoft.com/en-us/azure/aks/monitor-aks (checked 2026-11-12)

For the jq filters below, export the log lines to a file first. Ask the human where to save the file. Do not overwrite an existing evidence file.

### K8S-13 Filter an audit log file by user

- Purpose: show what one user or service account did. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the audit log file. No cluster permission.
- Command:

  ```bash
  jq -c 'select(.user.username == "<username>") | {time: .requestReceivedTimestamp, stage: .stage, verb: .verb, uri: .requestURI, source_ips: .sourceIPs, user_agent: .userAgent, resource: .objectRef.resource, namespace: .objectRef.namespace, name: .objectRef.name, code: .responseStatus.code}' <audit-log-file>
  ```

- Output: one compact JSON object for each event of that user. Look for: sign-ins from unexpected `source_ips`, an odd `user_agent`, `create` or `delete` verbs on `pods`, `secrets`, `rolebindings`, or `clusterrolebindings`, and many `403` codes (probing).
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/ (checked 2026-11-12)
- Local help: checked with jq (`jq --help`).

Notes:

- For a service account, the user name has the form `system:serviceaccount:<namespace>:<service-account-name>`.
- The command shows selected fields only. It does not print `requestObject` or `responseObject`.
- The same request can appear in more than one stage. If you see duplicates, add `select(.stage == "ResponseComplete")`.

### K8S-14 Filter an audit log file for Secret access

- Purpose: find who read or listed Secrets. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the audit log file. No cluster permission.
- Command:

  ```bash
  jq -c 'select(.objectRef.resource == "secrets" and (.verb == "get" or .verb == "list" or .verb == "watch")) | {time: .requestReceivedTimestamp, user: .user.username, verb: .verb, uri: .requestURI, source_ips: .sourceIPs, namespace: .objectRef.namespace, name: .objectRef.name, code: .responseStatus.code}' <audit-log-file>
  ```

- Output: one compact JSON object for each read of a Secret. Look for: users or service accounts that do not normally read Secrets, a `list` over all namespaces, reads from unexpected `source_ips`, and reads in the incident window.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/ (checked 2026-11-12)
- Local help: checked with jq (`jq --help`).

Notes:

- The command never prints `requestObject` or `responseObject`. Keep it that way. At the `RequestResponse` level, the response can hold Secret values.
- The audit policy sets what the log holds. If the policy does not record `secrets`, this filter finds nothing. Tell the human that the log is incomplete.

### K8S-15 Filter an audit log file for impersonation and exec

- Purpose: find requests that used impersonation, and requests that opened a shell in a pod. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the audit log file. No cluster permission.
- Command:

  ```bash
  jq -c 'select(.impersonatedUser != null or (.requestURI | contains("/exec"))) | {time: .requestReceivedTimestamp, user: .user.username, impersonated: .impersonatedUser.username, verb: .verb, uri: .requestURI, source_ips: .sourceIPs, code: .responseStatus.code}' <audit-log-file>
  ```

- Output: one compact JSON object for each matching event. Look for: `impersonated` values such as `system:masters` users, `exec` requests to pods by users who do not run workloads, and requests from unexpected `source_ips`.
- Approval: ask the human first.
- Doc: https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/ (checked 2026-11-12)
- Local help: checked with jq (`jq --help`).

Notes:

- The `contains("/exec")` test matches the `exec` subresource in the request URI. It can also match other URIs that hold that text.
- The `objectRef` field has a `subresource` key. The cited pages do not confirm this key. The URI test avoids it.

## Containment

Save evidence before you change anything. The exception is continuing harm. Then the incident commander can approve containment first, with the evidence that the change can destroy named (workflow in `../SKILL.md`). Still run the reads that the rollback needs, such as the node read in K8S-17. Ask the human to approve each command in this section.

### K8S-16 Save the manifest of a Deployment

- Purpose: keep the Deployment definition and the replica count before containment. Phase: evidence.
- Label: READ-ONLY, SENSITIVE
- Permission: `get` on `deployments` in the `apps` API group.
- Command:

  ```bash
  kubectl --context '<context>' get deployment <deployment-name> -n <namespace> -o yaml > <manifest-file>
  kubectl --context '<context>' get deployment <deployment-name> -n <namespace> -o json | jq '{name: .metadata.name, namespace: .metadata.namespace, uid: .metadata.uid, generation: .metadata.generation, replicas: .spec.replicas, selector: .spec.selector, podLabels: .spec.template.metadata.labels, serviceAccountName: .spec.template.spec.serviceAccountName, containers: [(.spec.template.spec.containers[], .spec.template.spec.initContainers[]?) | {name, image, plainEnvNames: [.env[]? | select(has("value")) | .name], refEnvNames: [.env[]? | select(has("valueFrom")) | .name], envFrom}]}'
  ```

- Output: the first command writes the full Deployment to the file and prints nothing. The file holds `spec.replicas`, the images, and the environment values. Do not read the file, because environment values can hold secrets. The second command prints only a short summary: name, namespace, `replicas`, the pod `selector`, pod labels, and service account. For each container, it prints the name, image, environment variable names, and `envFrom` references. It prints no values, annotations, commands, or arguments, because those fields can hold credentials. A human reviews those fields in the saved file. Look for: unknown images, an unexpected service account, and names in `plainEnvNames` such as `TOKEN` or `PASSWORD`. Such a variable holds a plain value instead of a `valueFrom` reference. Report the variable name only (safety rule 15 in `../SKILL.md`).
- Approval: ask the human first. Store the file where the human says.
- Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_get/ and https://jqlang.org/manual/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl get --help`). The `jq` filter was tested with jq on a sample Deployment.

Notes:

- This writes a new local file only. Choose a path that does not exist. Do not overwrite an existing evidence file.
- The file can hold credentials that are in plain environment values. Treat the file as sensitive.
- Take the replica count from `replicas` in the second output before you run K8S-18.
- Build `<selector>` for K8S-18 and K8S-19 from `selector.matchLabels` in the second output. Join every pair with commas, such as `app=web,tier=api`. Do not use one pair alone, because labels are not unique. When `selector` holds `matchExpressions`, stop and ask the human.

### K8S-17 Cordon a node

- Purpose: stop the scheduler from placing new ordinary pods on a node. Phase: containment.
- Label: WRITE
- Permission: `get` and `patch` on `nodes`. The checks read the node, and `kubectl cordon` reads the node before the patch. The pod check in the notes needs `list` on `pods` in all namespaces, which takes a ClusterRole ([RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)).
- Command:

  ```bash
  kubectl --context '<context>' cordon <node-name>
  ```

- Output: `node/<node-name> cordoned`. Look for: an error such as `forbidden`, or a node name that does not exist.
- Side effect: the scheduler places no new ordinary pods on the node. Three kinds of pod can still start there:
  - DaemonSet pods. They tolerate the `node.kubernetes.io/unschedulable` taint ([DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)).
  - Any other pod that tolerates that taint. Kubernetes says such pods "might be scheduled to the node" ([safely drain a node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)).
  - Pods with `spec.nodeName` set. The scheduler ignores them, and the kubelet on the named node starts them ([nodeName](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)).

  Pods that already run on the node keep running. This does not stop an attacker who already runs code on the node. Report the node as cordoned, not as contained. When the incident needs the node isolated, tell the incident commander that a cordon alone does not isolate the node. A stronger control, such as K8S-19 or a network block at the cloud provider, needs its own approval.

- Rollback: follow safety rule 16 in `../SKILL.md` first. Before the cordon, record the node with `kubectl --context '<context>' get node <node-name> -o jsonpath='{.metadata.uid} {.spec.unschedulable}'`. Run the same read after the cordon and before the rollback. A node that someone replaced with the same name has a new UID. Run the rollback only when all three conditions are true:
  - The read before the cordon showed no `unschedulable` value, so the node was schedulable.
  - The read after the cordon showed `true`.
  - The read before the rollback shows the same UID and `true`.

  Otherwise, do nothing and tell the incident commander. The rollback is `kubectl --context '<context>' uncordon <node-name>`.

- Approval: human approval required.
- Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_cordon/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl cordon --help`, `kubectl uncordon --help`).

Notes:

- The `--dry-run=server` option shows the request without a change. The local help lists it.
- Do not drain the node. A drain evicts pods and destroys evidence.
- List the pods on the node before the cordon. List them again after the cordon. The read is READ-ONLY, SENSITIVE, because it shows pod names and addresses in all namespaces. Ask the human before each run. Save the output. When the first read is denied, stop and tell the human before the cordon. A new pod in the second list means the cordon did not stop it. Tell the incident commander. Each list shows one moment only, so a pod can start later. The read uses a supported Pod field selector ([field selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/)). Local help: `kubectl get --help` lists `--field-selector` and `--all-namespaces`.

  ```bash
  kubectl --context '<context>' get pods --all-namespaces --field-selector spec.nodeName=<node-name> -o wide
  ```

### K8S-18 Scale a Deployment to zero

- Purpose: stop all pods of a compromised Deployment. Phase: containment.
- Label: WRITE
- Permission: in the `apps` API group, `get` on `deployments`, and `get` and `update` on `deployments/scale`. With `--current-replicas`, `kubectl scale` reads the scale and then sends an update. The target pod list needs `list` on `replicasets` and `pods`.
- Command: make the target pod list first (see the notes). Then read the Deployment. This read is READ-ONLY, SENSITIVE. Ask the human first.

  ```bash
  kubectl --context '<context>' get deployment/<deployment-name> -n <namespace> -o jsonpath='{.metadata.uid} {.metadata.generation} {.metadata.resourceVersion}'
  ```

  Continue only when three values match. The UID is `<deployment-uid>` from the target pod list. It is also the `uid` in the K8S-16 output. The generation is the one in the K8S-16 output. A Deployment that someone deleted and created again with the same name has a new UID. Otherwise, the Deployment changed after the check. Stop and tell the human. Use the `resourceVersion` from this read as `<resource-version>`. The scale fails when the Deployment changed after this read.

  ```bash
  kubectl --context '<context>' scale deployment/<deployment-name> -n <namespace> --replicas=0 --current-replicas=<replica-count> --resource-version='<resource-version>'
  ```

- Output: `deployment.apps/<deployment-name> scaled`. Look for: an error that the current replica count or the resource version does not match. The `--current-replicas` and `--resource-version` flags make the scale fail when the value differs. The `scaled` message does not show that the pods stopped, because the default `--timeout=0s` does not wait. After the scale, ask the human to approve each check:
  1. Read the replica count. Run the read again until it prints nothing or `0`.

     ```bash
     kubectl --context '<context>' get deployment/<deployment-name> -n <namespace> -o jsonpath='{.status.replicas}'
     ```

  2. Run steps 2 and 3 of the target pod list again. A Deployment can create a new ReplicaSet, so find the ReplicaSets again each time. Run the steps until no target pod UID is in the list. Also, no pod can have an owner UID from the old or the new ReplicaSets. A pod that is terminating stays in the list until it ends, and it can still run. Containment is incomplete while such a pod is listed, or when one starts again.

- Side effect: Kubernetes deletes all pods of the Deployment. A Service sends traffic to any pod that matches its selector ([Service](https://kubernetes.io/docs/concepts/services-networking/service/)). So other pods can still serve the same Service. Before you say that the traffic of a Service stopped, read the Service and then list its EndpointSlices. These reads are READ-ONLY, SENSITIVE. Ask the human first for each read. They need `get` on `services`, and `list` on `endpointslices` in the `discovery.k8s.io` API group.

  ```bash
  kubectl --context '<context>' get service <service-name> -n <namespace> -o jsonpath='{.spec.type} {.spec.selector} {.spec.externalName}{"\n"}'
  ```

  The read prints the type, the selector, and the external name. When the type is `ExternalName`, Kubernetes sends the traffic to that DNS name. It does not use EndpointSlices. When the Service has no selector, the control plane does not manage its EndpointSlices. In both cases, the next read does not show where traffic goes. Tell the human.

  ```bash
  kubectl --context '<context>' get endpointslices -n <namespace> -l kubernetes.io/service-name=<service-name> -o wide
  ```

  The service read was tested offline with `kubectl create service ... --dry-run=client` and the same jsonpath. It printed the type, the selector, and the external name. The label `kubernetes.io/service-name` links each EndpointSlice to its Service ([EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/)). Look for: endpoints that remain. An endpoint with the condition `serving` still gets traffic. Data in memory and in pod-local disk is lost. A controller such as a horizontal pod autoscaler or a GitOps tool can scale the Deployment up again.

- Rollback: follow safety rule 16 in `../SKILL.md` first. Run it only when the scale in this run printed `scaled`. When the scale failed, it changed nothing, and the rollback could start pods that another person stopped. Right after the scale, run the Deployment read from the Command field again. Record the generation. The rollback starts new pods from `.spec.template`. A change of the template after the scale raises the generation. Before the rollback, run the read again.

  Run the rollback only when the UID is still `<deployment-uid>` and the generation is the value that you recorded after the scale. Otherwise, another person changed the Deployment. Stop and tell the incident commander. Use the `resourceVersion` from this read as `<resource-version>`. The scale then fails when the Deployment changed after the read.

  ```bash
  kubectl --context '<context>' scale deployment/<deployment-name> -n <namespace> --replicas=<replica-count> --current-replicas=0 --resource-version='<resource-version>'
  ```

- Approval: human approval required.
- Doc: https://kubernetes.io/docs/reference/kubectl/quick-reference/, https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/, and https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl scale --help`, flags `--replicas`, `--current-replicas`, and `--resource-version`). The help says that the preconditions are checked when the scale is sent to the server.

Notes:

- Run K8S-16 first. Take `<replica-count>` from `replicas` in its second output.
- Make the target pod list before the scale. Each step is READ-ONLY, SENSITIVE. Ask the human before each step. Save each output.
  1. Read the Deployment UID. This is `<deployment-uid>`.

     ```bash
     kubectl --context '<context>' get deployment/<deployment-name> -n <namespace> -o jsonpath='{.metadata.uid}'
     ```

  2. List the ReplicaSets with their UID, name, and owner UID. Keep the ReplicaSets whose owner UID is `<deployment-uid>`. Do not match by name, because Kubernetes can shorten the Deployment name in a ReplicaSet name.

     ```bash
     kubectl --context '<context>' get replicasets -n <namespace> -o jsonpath='{range .items[*]}{.metadata.uid}{" "}{.metadata.name}{" "}{.metadata.ownerReferences[*].uid}{"\n"}{end}'
     ```

  3. List every pod in the namespace with its UID, name, and owner UID. A target pod has an owner UID from step 2. Record the UID of each target pod.

     ```bash
     kubectl --context '<context>' get pods -n <namespace> -o jsonpath='{range .items[*]}{.metadata.uid}{" "}{.metadata.name}{" "}{.metadata.ownerReferences[*].uid}{"\n"}{end}'
     ```

- Capture pod evidence before you scale. The human decides how to do that.
- Ask the human to stop any autoscaler or GitOps sync for the Deployment, so that it stays at zero.

### K8S-19 Isolate pods with a deny-all network policy

- Purpose: block network traffic to and from the pods of a compromised workload, and keep the pods for evidence. Phase: containment.
- Label: WRITE
- Permission: `create`, `delete`, `get`, and `list` on `networkpolicies` in the `networking.k8s.io` API group. The pod checks need `list` on `pods` and `replicasets`. When a check fails or is denied, stop and tell the human.
- Command: write this policy to `<policy-file>`. Put every pair from `selector.matchLabels` in the second K8S-16 output under `matchLabels`, one line for each pair. Put each value in double quotes, so that YAML reads a value such as `true` as a string. The file holds this one document only. Add no `ingress` or `egress` rules.

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: <policy-name>
    namespace: <namespace>
  spec:
    podSelector:
      matchLabels:
        <label-key>: "<label-value>"
    policyTypes:
      - Ingress
      - Egress
  ```

  Then create it:

  ```bash
  kubectl --context '<context>' create -f <policy-file>
  ```

- Output: one line, `networkpolicy.networking.k8s.io/<policy-name> created`. More than one line means the file held more than one object. Stop and tell the human. Look for: an `AlreadyExists` error. It means a policy with that name exists, and `create` changed nothing. Pick a new name. Then ask again.
- Side effect: the selected pods lose all network traffic that no other policy allows. The pods keep running. DNS lookups to the cluster DNS pods fail, so the application can fail. A DNS cache on the node, such as NodeLocal DNSCache, can still answer, because traffic from a pod to its own node is allowed.
- Limits:
  - The cluster must use a network plugin that enforces NetworkPolicy. Without one, the policy has no effect.
  - Policies are additive. Another policy that allows traffic to the same pods still allows it. See the notes for the check.
  - Traffic between a pod and its own node is always allowed.
  - The behaviour for `hostNetwork` pods is undefined.
  - Whether the policy closes connections that already exist depends on the plugin.
  - The Kubernetes API cannot show when the plugin applies the policy.
  - A deny-all policy is only guaranteed to deny TCP, UDP, and SCTP. For other protocols, such as ICMP, the behaviour is undefined. When such traffic matters, ask the human for another containment, such as K8S-17 and K8S-18.
- Containment check: do not report the pods as contained after the create alone. A connection needs egress permission at the source and ingress permission at the destination. Ask the human for each step:
  1. Confirm that the network plugin of the cluster enforces NetworkPolicy.
  2. Before the create, test a connection from a test pod to a target pod port. The connection must work. Put the test pod in a namespace where no policy selects it.
  3. After the create, test the same connection again. It must fail. Then ingress to the target pod is blocked.
  4. An egress test needs a command inside a target pod, which changes the evidence. The human decides. Until then, report egress as unverified.
  5. Report traffic to the own node, and DNS through a node cache, as open until the human checks it.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Run it only when the create printed `created` in this run. First read the policy again with the UID check in the notes. Run the delete only when the UID and the `resourceVersion` are the values that you recorded after the create. Otherwise, another person changed or replaced the policy. Stop and tell the human. `kubectl --context '<context>' delete networkpolicy <policy-name> -n <namespace>`. The `kubectl delete` command does no version check, so a change between the read and the delete is still possible.
- Approval: human approval required.
- Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/, https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/, https://kubernetes.io/docs/reference/kubernetes-api/networking/network-policy-v1/, and https://kubernetes.io/docs/reference/kubectl/generated/kubectl_delete/ (checked 2026-11-12)
- Local help: checked with kubectl (`kubectl create --help`, `kubectl delete --help`). Use `create`, not `apply`, because `apply` changes a policy that already exists.

Notes:

- Each read below is READ-ONLY, SENSITIVE. Ask the human before each read. Save each output.
- Before the create, list the policies in the namespace with `kubectl --context '<context>' get networkpolicy -n <namespace> -o yaml`.
- Pick a `<policy-name>` that the list does not show.
- In that list, find each policy whose `podSelector` selects a target pod and that has an `ingress` or `egress` rule. An empty `podSelector` selects every pod. Such a policy still allows its traffic after the create. Tell the human. Do not call the pods contained until the human decides about that policy.
- Before the create, make the target pod list. Use the steps in the K8S-18 notes, or a list of pod UIDs from the human.
- Read `<policy-file>` before the create. Check each item:
  1. The file holds one YAML document, with `kind: NetworkPolicy`.
  2. `metadata.name` is `<policy-name>` and `metadata.namespace` is `<namespace>`.
  3. `podSelector.matchLabels` holds at least one pair, and each value is in double quotes. An empty `podSelector` selects all pods in the namespace.
  4. `policyTypes` holds both `Ingress` and `Egress`.
  5. The file has no `ingress` and no `egress` key.
- Build `<selector>` for the next check from the pairs in the file, not from K8S-16. Then list the pods that the selector selects:

  ```bash
  kubectl --context '<context>' get pods -n <namespace> -l '<selector>' -o jsonpath='{range .items[*]}{.metadata.uid}{" "}{.metadata.name}{" "}{.metadata.ownerReferences[*].uid}{"\n"}{end}'
  ```

- Compare the two lists. A policy applies only to the pods that its selector selects. A pod whose labels changed can be outside the selector. When a target pod UID is missing from the selector list, stop and ask the human for a different containment. When the selector list holds a pod that is not a target, stop and ask the human.
- After the create, read the stored policy. Record the `uid` and the `resourceVersion` for the rollback. Check that `spec` holds the `podSelector` from the file, both policy types, and no `ingress` or `egress` rules.

  ```bash
  kubectl --context '<context>' get networkpolicy <policy-name> -n <namespace> -o jsonpath='{.metadata.uid} {.metadata.resourceVersion} {.spec}'
  ```

- The `--dry-run=server` option on `create` checks the policy without a change. The local help lists it.
