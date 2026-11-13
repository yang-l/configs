# GitHub commands

This file covers the organisation audit log, deploy keys, Actions secrets metadata, secret-scanning alerts, access checks, and deploy key removal. Every command uses the `gh` CLI.
Labels and the approval rules are in `../SKILL.md`. Read them before you run any command from this file.

## Contents

- [Before you start](#before-you-start)
- [Audit log](#audit-log)
  - [GH-01 Search the organisation audit log](#gh-01-search-the-organisation-audit-log)
- [Deploy keys](#deploy-keys)
  - [GH-02 List deploy keys of a repository](#gh-02-list-deploy-keys-of-a-repository)
- [Actions secrets metadata](#actions-secrets-metadata)
  - [GH-03 List Actions secret names of a repository](#gh-03-list-actions-secret-names-of-a-repository)
  - [GH-04 List Actions secret names of an environment](#gh-04-list-actions-secret-names-of-an-environment)
  - [GH-05 List Actions secret names of an organisation](#gh-05-list-actions-secret-names-of-an-organisation)
- [Secret-scanning alerts](#secret-scanning-alerts)
  - [GH-06 List open secret-scanning alerts of an organisation](#gh-06-list-open-secret-scanning-alerts-of-an-organisation)
  - [GH-07 List open secret-scanning alerts of a repository](#gh-07-list-open-secret-scanning-alerts-of-a-repository)
- [Access checks](#access-checks)
  - [GH-08 List organisation members without 2FA](#gh-08-list-organisation-members-without-2fa)
  - [GH-09 List outside collaborators](#gh-09-list-outside-collaborators)
  - [GH-10 List installed GitHub Apps](#gh-10-list-installed-github-apps)
- [Containment](#containment)
  - [GH-11 Delete a deploy key](#gh-11-delete-a-deploy-key)
  - [GH-12 Disable one workflow](#gh-12-disable-one-workflow)

## Before you start

Token:

- `gh` reads `GH_TOKEN` or `GITHUB_TOKEN` for `github.com` and for subdomains of `ghe.com`. It reads `GH_ENTERPRISE_TOKEN` or `GITHUB_ENTERPRISE_TOKEN` for a GitHub Enterprise Server host. When no token is set for the host, it uses the stored login on the machine ([gh environment](https://cli.github.com/manual/gh_help_environment)).
- A human sets these variables. The agent never reads, prints, or stores them.
- A token or a stored login does not prove which account runs the commands. Before the first command for a host, check the login with the read below. Run it again before each WRITE command. It is READ-ONLY, SENSITIVE, because the login can name a person. Ask the human first. Save the output.

  ```bash
  gh api --hostname <host> user --jq '.login'
  ```

  Compare the login with the account that the human approved. When they differ, or when the call fails, stop and tell the human. Doc: https://docs.github.com/en/rest/users/users#get-the-authenticated-user (checked 2026-11-12). Local help: checked with `gh api --help` (`--hostname`, `--jq`) and `gh help environment`.

- The agent never runs `gh auth`. The human fixes sign-in problems.
- Each entry names the token permission that the call needs. Most calls need an organisation owner or a repository admin.

Host:

- Ask the human for the GitHub host, for example `github.com` or a GitHub Enterprise Server host. Use it as `<host>`.
- Every command names the host: `gh api --hostname <host>`, `--repo <host>/<owner>/<repo>`, or `GH_HOST='<host>'` where no repository flag exists. Without it, `gh` can pick the host from `GH_HOST` or from the local Git repository ([gh environment](https://cli.github.com/manual/gh_help_environment)).
- The per-host settings `api_host` and `http_unix_socket` can send requests for `<host>` to another host or through a local socket ([gh config](https://cli.github.com/manual/gh_config)). Before the first command, and again before each WRITE command, run the two reads below. They read the local `gh` configuration only. They are READ-ONLY, SENSITIVE, because a value can show an internal gateway. Ask the human first. Save the output.

  ```bash
  gh config get api_host --host <host>
  gh config get http_unix_socket --host <host>
  ```

  When either read prints a value, stop and tell the human. Local help: checked with `gh help config` and `gh config get --help`. The help marks `api_host` as experimental and "not a security boundary".

Placeholders:

| Placeholder                      | Meaning                                                                                                                                                                        |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `<host>`                         | The GitHub host, such as `github.com`.                                                                                                                                         |
| `<org>`                          | The GitHub organisation login.                                                                                                                                                 |
| `<owner>`                        | The owner of the repository, a user or an organisation.                                                                                                                        |
| `<repo>`                         | The repository name, without the owner.                                                                                                                                        |
| `<user>`                         | The GitHub login of a person.                                                                                                                                                  |
| `<environment-name>`             | The name of a deployment environment in a repository.                                                                                                                          |
| `<environment-name-url-encoded>` | `<environment-name>` with each character other than letters, digits, `-`, `_`, `.`, and `~` written as `%` and two hex digits. For example, `/` is `%2F` and a space is `%20`. |
| `<start-date>`                   | The first day of the window, as `YYYY-MM-DD`.                                                                                                                                  |
| `<end-date>`                     | The last day of the window, as `YYYY-MM-DD`.                                                                                                                                   |
| `<key-id>`                       | The numeric ID of a deploy key. Get it with GH-02.                                                                                                                             |
| `<key-title>`                    | The title of a deploy key, recorded before deletion.                                                                                                                           |
| `<public-key-file>`              | A local file that holds the recorded public key of a deploy key.                                                                                                               |

Rules that apply to all entries:

- Every `gh api` call that has `--raw-field` also has `--method GET`. Without it, `gh` sends a POST.
- Never add `--verbose`, `--include`, or `--cache` to a secret-scanning command. They can print or store the raw response.
- Audit data, repository names, and secret names are SENSITIVE. They show internal context.

## Audit log

### GH-01 Search the organisation audit log

- Purpose: Show the audit log events of an actor in the organisation in a date window. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: Organisation owner. A classic token needs the `read:audit_log` scope. The API needs GitHub Enterprise Cloud.
- Command:

  ```bash
  gh api --hostname <host> "/orgs/<org>/audit-log" --method GET --paginate \
    --raw-field phrase="actor:<user> created:<start-date>..<end-date>" \
    --raw-field include=all \
    --raw-field order=asc \
    --raw-field per_page=100 \
    --jq '.[]'
  ```

- Output: One event per record. Fields include the action name, the actor, and the time. Look for: unexpected `action` names such as `repo.access`, `repo.add_member`, `oauth_access.create`, or `org.add_member`, or an unknown IP address. The audit log does not show every action. GitHub says that each access method shows a different subset of the data. The audit log keeps Git events for seven days only. The web interface and the REST API list other events for the last 180 days. Record each missing event type and period as a gap. When the incident needs more, ask the human for streamed audit logs or other logs. Change `phrase` to find other events: `action:repo.access`, `repo:<owner>/<repo>`, or `created:>=<start-date>`.
- Cost note: The window can return many pages. Narrow it with `created:` and `actor:` before you run the command.
- Approval: ask the human first.
- Doc: https://docs.github.com/en/enterprise-cloud@latest/rest/orgs/orgs#get-the-audit-log-for-an-organization and https://docs.github.com/en/enterprise-cloud@latest/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization (checked 2026-11-12)
- Local help: checked with gh (`gh api --help`).

## Deploy keys

### GH-02 List deploy keys of a repository

- Purpose: List the SSH keys that can reach one repository. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Repository admin access. A classic token needs the `repo` scope.
- Command: Run one of the two forms. The API form also shows `added_by` and `last_used`.

  ```bash
  gh repo deploy-key list --repo <host>/<owner>/<repo> --json id,title,readOnly,createdAt,key
  ```

  ```bash
  gh api --hostname <host> "/repos/<owner>/<repo>/keys" --paginate \
    --jq '.[] | {id, title, read_only, verified, created_at, added_by, last_used, enabled, key}'
  ```

- Output: One object per key. Look for: `readOnly` false (`read_only` false in the API form), which means the key can write. Also look for a `created_at` in the incident window, an unknown `title`, or a `last_used` that matches the incident.
- Approval: ask the human first.
- Doc: https://docs.github.com/en/rest/deploy-keys/deploy-keys and https://cli.github.com/manual/gh_repo_deploy-key_list (checked 2026-11-12)
- Local help: checked with gh (`gh repo deploy-key list --help`, `gh api --help`).

## Actions secrets metadata

The list calls return metadata only. The API never returns secret values. The fields that come back are `name`, `created_at`, and `updated_at`. The organisation list adds `visibility` and `selected_repositories_url`.

### GH-03 List Actions secret names of a repository

- Purpose: Show which Actions secrets a repository has and when each changed. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Repository collaborator. A classic token needs the `repo` scope.
- Command: Run one of the two forms. Only the API form shows `created_at`.

  ```bash
  gh secret list --repo <host>/<owner>/<repo> --json name,updatedAt,visibility
  ```

  ```bash
  gh api --hostname <host> "/repos/<owner>/<repo>/actions/secrets" --paginate \
    --jq '.secrets[] | {name, created_at, updated_at}'
  ```

- Output: One object per secret. It holds no value. Look for: an `updated_at` in the incident window, or a secret name that nobody knows. Add `--app dependabot` to the CLI form to list Dependabot secrets.
- Approval: ask the human first.
- Doc: https://docs.github.com/en/rest/actions/secrets and https://cli.github.com/manual/gh_secret_list (checked 2026-11-12)
- Local help: checked with gh (`gh secret list --help`, `gh api --help`).

### GH-04 List Actions secret names of an environment

- Purpose: Show which secrets one deployment environment has and when each changed. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Repository collaborator. A classic token needs the `repo` scope.
- Command: Run one of the two forms.

  ```bash
  gh secret list --repo <host>/<owner>/<repo> --env '<environment-name>' --json name,updatedAt,visibility
  ```

  ```bash
  gh api --hostname <host> "/repos/<owner>/<repo>/environments/<environment-name-url-encoded>/secrets" --paginate \
    --jq '.secrets[] | {name, created_at, updated_at}'
  ```

- Output: One object per secret. It holds no value. Look for: an `updated_at` in the incident window, or a new secret name. The Doc page says that the API path needs the URL-encoded name.
- Approval: ask the human first.
- Doc: https://docs.github.com/en/rest/actions/secrets and https://cli.github.com/manual/gh_secret_list (checked 2026-11-12)
- Local help: checked with gh (`gh secret list --help`, `gh api --help`).

### GH-05 List Actions secret names of an organisation

- Purpose: Show organisation secrets, who can use each, and when each changed. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Organisation access. A classic token needs the `admin:org` scope, and `repo` for private repositories.
- Command: Run one of the two forms. Only the API form shows `created_at`.

  ```bash
  GH_HOST='<host>' gh secret list --org <org> --json name,updatedAt,visibility,numSelectedRepos
  ```

  ```bash
  gh api --hostname <host> "/orgs/<org>/actions/secrets" --paginate \
    --jq '.secrets[] | {name, created_at, updated_at, visibility, selected_repositories_url}'
  ```

- Output: One object per secret. It holds no value. Look for: `visibility` of `all` on a sensitive secret, a new secret name, or an `updated_at` in the incident window.
- Approval: ask the human first.
- Doc: https://docs.github.com/en/rest/actions/secrets and https://cli.github.com/manual/gh_secret_list (checked 2026-11-12)
- Local help: checked with gh (`gh secret list --help`, `gh api --help`).

## Secret-scanning alerts

The alert response can hold the leaked secret in the `secret` field. Both commands below ask GitHub to hide it with `hide_secret=true`. Both also drop the field with `jq` before any output appears. Keep both parts of each command.

### GH-06 List open secret-scanning alerts of an organisation

- Purpose: List leaked secrets that GitHub found in the organisation. The command removes the secret value. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: Organisation administrator or security manager. A classic token needs the `repo` or `security_events` scope.
- Command:

  ```bash
  gh api --hostname <host> "/orgs/<org>/secret-scanning/alerts" --method GET --paginate \
    --raw-field state=open \
    --raw-field hide_secret=true \
    --raw-field per_page=100 \
    --jq '.[] | del(.secret)'
  ```

- Output: One object per alert, with no `secret` field. Look for: `validity` of `active` (the secret still works), `publicly_leaked` true, and `push_protection_bypassed` true. The alert `html_url` leads to the secret in the web UI. Do not open it in the agent.
- Approval: ask the human first.
- Doc: https://docs.github.com/en/rest/secret-scanning/secret-scanning (checked 2026-11-12)
- Local help: checked with gh (`gh api --help`).

### GH-07 List open secret-scanning alerts of a repository

- Purpose: List leaked secrets that GitHub found in one repository. The command removes the secret value. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: Repository admin, or organisation admin. A classic token needs the `repo` or `security_events` scope.
- Command:

  ```bash
  gh api --hostname <host> "/repos/<owner>/<repo>/secret-scanning/alerts" --method GET --paginate \
    --raw-field state=open \
    --raw-field hide_secret=true \
    --raw-field per_page=100 \
    --jq '.[] | del(.secret)'
  ```

- Output: One object per alert, with no `secret` field. Look for: `validity` of `active`, `publicly_leaked` true, and an alert that matches the credential from the incident.
- Approval: ask the human first.
- Doc: https://docs.github.com/en/rest/secret-scanning/secret-scanning (checked 2026-11-12)
- Local help: checked with gh (`gh api --help`).

## Access checks

### GH-08 List organisation members without 2FA

- Purpose: Find members who have no two-factor authentication. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Organisation owner. The `filter` option works for owners only.
- Command:

  ```bash
  gh api --hostname <host> "/orgs/<org>/members" --method GET --paginate \
    --raw-field filter=2fa_disabled \
    --raw-field per_page=100 \
    --jq '.[] | {login, id, type, site_admin}'
  ```

- Output: One object per member without 2FA. Look for: any member who also has admin rights or access to the affected repository. Use `filter=2fa_insecure` to find members with weak 2FA methods.
- Approval: ask the human first.
- Doc: https://docs.github.com/en/rest/orgs/members (checked 2026-11-12)
- Local help: checked with gh (`gh api --help`).

### GH-09 List outside collaborators

- Purpose: List people with repository access who are not organisation members. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Organisation owner. The docs page does not state the permission.
- Command:

  ```bash
  gh api --hostname <host> "/orgs/<org>/outside_collaborators" --method GET --paginate \
    --raw-field filter=all \
    --raw-field per_page=100 \
    --jq '.[] | {login, id, type, site_admin}'
  ```

- Output: One object per collaborator. Look for: a login that nobody knows. Use `filter=2fa_disabled` to list collaborators without 2FA.
- Approval: ask the human first.
- Doc: https://docs.github.com/en/rest/orgs/outside-collaborators (checked 2026-11-12)
- Local help: checked with gh (`gh api --help`).

### GH-10 List installed GitHub Apps

- Purpose: List the GitHub Apps installed on the organisation and their permissions. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: Organisation owner. A classic token needs the `admin:read` scope.
- Command:

  ```bash
  gh api --hostname <host> "/orgs/<org>/installations" --method GET --paginate \
    --raw-field per_page=100 \
    --jq '.installations[] | {id, app_slug, repository_selection, permissions, created_at, updated_at, suspended_at}'
  ```

- Output: One object per installed app. Look for: an app that was installed in the incident window, `repository_selection` of `all`, and write permissions such as `contents` or `administration`.
- Approval: ask the human first.
- Doc: https://docs.github.com/en/rest/orgs/orgs#list-app-installations-for-an-organization (checked 2026-11-12)
- Local help: checked with gh (`gh api --help`).

## Containment

### GH-11 Delete a deploy key

- Purpose: Remove one deploy key so that it can no longer reach the repository. Phase: containment.
- Label: WRITE
- Permission: a fine-grained token needs the `Administration` repository permission (write). The rollback add needs the same permission. A classic token needs the `repo` scope.
- Command: Record the key first with GH-02. Save `id`, `title`, `key`, and `readOnly` in the incident record. Then run:

  ```bash
  gh repo deploy-key delete <key-id> --repo <host>/<owner>/<repo>
  ```

- Output: `gh` prints a confirmation. Run GH-02 again. Look for: the key is gone from the list.
- Side effect: Any job or host that uses the key loses access to the repository at once.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Save the recorded `key` value to `<public-key-file>`. Then add the key back with the recorded title. Add `--allow-write` only if the recorded `readOnly` was false.

  ```bash
  gh repo deploy-key add <public-key-file> --repo <host>/<owner>/<repo> --title "<key-title>"
  ```

  The new key gets a new `id` and a new `created_at`. GitHub does not allow edits to a deploy key. GitHub ties a key to the token that added it. For a personal access token, a delete of that token also deletes the key. For an OAuth app token, a revoke of the token deletes the key. For a GitHub App user token, a revoke does not delete the key. For a GitHub App installation token, an uninstall of the app does not delete the key. To remove a key, delete it with GH-11. Then check with GH-02 that it is gone.

- Approval: human approval required.
- Doc: https://docs.github.com/en/rest/deploy-keys/deploy-keys and https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens (checked 2026-11-12)
- Local help: checked with gh (`gh repo deploy-key delete --help`, `gh repo deploy-key add --help`).

### GH-12 Disable one workflow

- Purpose: stop one GitHub Actions workflow from starting new runs. Phase: containment.
- Label: WRITE
- Permission: a fine-grained token needs the `Actions` repository permission (write) for the disable and the rollback enable, and `Actions` (read) for the state check. The repository and branch reads need read access to the repository contents. A classic token needs the `repo` scope.
- Command: run the three reads first. Each read is READ-ONLY, SENSITIVE. Ask the human before each read. Save each output in the incident record.

  ```bash
  gh api --hostname <host> "/repos/<owner>/<repo>/actions/workflows/<workflow-id>" --jq '{id, name, path, state}'
  gh api --hostname <host> "/repos/<owner>/<repo>" --jq '.default_branch'
  gh api --hostname <host> "/repos/<owner>/<repo>/branches/<default-branch>" --jq '.commit.sha'
  ```

  The third read gives the commit of the default branch. It covers the workflow file and the scripts and local actions that the workflow uses from that branch. Run the disable command only when the recorded `state` is `active`. For any other state, the workflow cannot start runs now. A disable would change the state to `disabled_manually`. Then the rollback cannot restore the old state.

  ```bash
  gh workflow disable <workflow-id> -R <host>/<owner>/<repo>
  ```

- Output: the first read prints the `id`, `name`, `path`, and `state` of the target workflow. The `state` is `active`, `deleted`, `disabled_fork`, `disabled_inactivity`, or `disabled_manually`. Run the first read again after the change. Look for: `state` is `disabled_manually`.
- Side effect: no event can start the workflow. GitHub does not cancel runs that already exist. You cannot run those runs again while the workflow is disabled. The workflow file stays in the repository.
- Rollback: follow safety rule 16 in `../SKILL.md` first. When the recorded `state` was `active`, enable the workflow again. Before the enable, run all three reads again. Continue only when the state is `disabled_manually`. The default branch and its commit must also be the ones that you recorded before the disable. Scheduled workflows run on the latest commit of the default branch, so a new default branch can run different code. When the commit differs, the workflow file, a script, or a local action can have changed. After the enable, the next event would run that code. Stop and ask the human to review the changes. Each run uses the file at the commit or ref of its event, so another branch can hold different code. A `uses:` line can name an action or a reusable workflow by a tag or a branch. Such a line can also run new code, because someone can move a tag. Only a full commit SHA is fixed. List each such `uses:` line in the approval request. Name both risks there.

  ```bash
  gh workflow enable <workflow-id> -R <host>/<owner>/<repo>
  ```

  When the recorded `state` was any other value, do nothing.

- Approval: human approval required.
- Doc: https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows and https://docs.github.com/en/rest/actions/workflows and https://docs.github.com/en/rest/branches/branches and https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax and https://docs.github.com/en/actions/reference/security/secure-use and https://docs.github.com/en/actions/concepts/workflows-and-actions/workflows and https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens (checked 2026-11-12)
- Local help: checked with gh (`gh api --help`, `gh workflow disable --help`, `gh workflow enable --help`).

Notes:

- Do not record the state with `gh workflow list --all`. It fetches 50 workflows by default (`--limit`), so the target can be missing.
- Always pass the workflow ID. Without an argument, `gh` opens an interactive menu.
- A disable does not stop a run that is in progress. The human decides whether to cancel it.
