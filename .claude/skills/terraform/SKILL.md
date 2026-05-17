---
name: terraform
description: |
  Terraform and Infrastructure-as-Code expertise covering Terraform 1.12+
  (current stable 1.15.2), OpenTofu 1.12, Pulumi, CloudFormation/CDK v2, and
  HCP Terraform Stacks. Use this skill whenever the user mentions Terraform,
  HCL, OpenTofu, or IaC work — even if they don't explicitly name the tool.
  Covers: module structure and HCP Stacks for monorepos, provider and version
  pinning, modern language features (ephemeral resources, write-only args,
  resource identity, import/moved blocks, check blocks, terraform query,
  actions, typed outputs, dynamic module sources), layered testing strategy
  (terraform validate, tflint, Checkov, terraform test with mock providers,
  Terratest), AWS patterns (IAM least-privilege, default_tags, S3/VPC/SG/RDS),
  OIDC workload identity for CI/CD, state management, drift detection, and
  security. Includes Trivy CVE advisory GHSA-69fq-xp46-6x23 (safe versions:
  trivy <= v0.69.3 / trivy-action v0.35.0). CDKTF is deprecated Dec 2025.
  Trigger on: terraform, opentofu, tofu, hcl, tfvars, tfstate, .tf files,
  iac, infrastructure-as-code, pulumi, cloudformation, hcp stacks, state
  backend, drift detection, terraform test, tftest, mock provider, checkov,
  tflint, terratest, ephemeral resource, moved block, import block, check
  block, terraform query, oidc workload identity, aws provider, trivy cve,
  GHSA-69fq-xp46-6x23, cdktf, state surgery, plan apply, terraform plan,
  remote backend, module refactor
---

# Terraform / IaC Skill

## General Principles

- **Plan before apply** — always run `terraform plan` (or equivalent) and review output before applying. Never auto-approve in production.
- **State is sacred** — remote backends (S3+DynamoDB, GCS, etc.), never commit `.tfstate`, enable state locking.
- **Immutable infrastructure** — prefer replacing resources over in-place mutation.
- **Drift detection** — `terraform plan` on schedule in CI. Use `check` blocks for continuous validation.

## Module Structure

Standard layout: `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `terraform.tf`, `locals.tf`, `data.tf`, `modules/`.

- One resource type per file for large projects (e.g., `vpc.tf`, `iam.tf`).
- Keep modules small and single-purpose. Compose in root.
- Run `terraform fmt` and `terraform validate` before every commit.
- **HCP Terraform Stacks** (GA): Native `stack` configurations enable multi-module deployments with automatic cross-configuration dependency tracking — useful for large monorepos where modules have output→input dependencies.

## Naming Conventions

- Resources: `snake_case`, descriptive (e.g., `aws_s3_bucket.app_logs`).
- Variables: `snake_case` with `description`, `type`, and `validation` blocks.
- Outputs: `snake_case` with `description`.
- Modules: `kebab-case` directories, `snake_case` internal names.

## Provider & Version Pinning

```hcl
terraform {
  required_version = ">= 1.12"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}
```

Current latest stable is **1.15.2** (released 2026-05-06); 1.16.0-alpha is in preview. Set `required_version` to the minimum you've tested against, not the absolute latest.

- Pin providers with pessimistic constraint (`~>`). Pin Terraform version via `.terraform-version` or `tfenv`.
- **Commit `.terraform.lock.hcl`** — this is the only supply-chain lock for providers. Modules are NOT covered; pin exact versions for critical modules.
- Run `terraform init -upgrade` deliberately, not automatically.

## Modern Language Features

- **Ephemeral resources/values** (1.10+): Not persisted in state or plan. Use for secrets and short-lived tokens. Prefer over `sensitive = true` for credentials.
- **Write-only arguments** (1.11+): Ephemeral values in managed resource attributes.
- **Resource identity** (1.12+): Enables bulk declarative import using Terraform-managed identity rather than provider-specific IDs.
- **`terraform query`** (1.14+): Query infrastructure with HCL-native `*.tfquery.hcl` files using `list` resource type; run via `terraform query` CLI for ad-hoc resource inspection without modifying state.
- **`actions` block** (1.14+): Provider-defined operations (e.g., invoke a Lambda, create a CloudFront invalidation) outside the normal CRUD resource lifecycle.
- **`deprecated` attribute** (1.15+): Mark variable or output blocks as deprecated; `terraform validate` emits warnings on use.
- **Typed outputs** (1.15+): Output blocks accept a `type` constraint enforced at `terraform validate`.
- **Dynamic module sources** (1.15+): Module `source` can reference locals and variables (previously required static strings).
- **Import blocks** (1.5+): Declarative imports in config. Prefer over CLI `terraform import`.
- **Moved blocks** (1.1+): Rename/refactor resources without state surgery. Keep for at least one release cycle after migration.
- **Provider-defined functions** (1.8+): `provider::<name>::<fn>()` syntax.
- **Check blocks**: Continuous post-plan/apply validation (run as warnings, not blockers).
- **Preconditions/postconditions**: Hard-fail guards on resource lifecycle.

## Testing

Layered approach, cheapest first:

1. **Static**: `terraform validate` + [tflint](https://github.com/terraform-linters/tflint) + [Checkov](https://www.checkov.io/) (1,000+ policies, CIS/SOC2/HIPAA mapping). Checkov replaces tfsec (deprecated/maintenance-only).
2. **Contract**: `terraform test` (native since 1.6) with `.tftest.hcl` files and mock providers (1.7+). Use for module interface contracts.
3. **Continuous**: `check` blocks for post-apply assertions. Preconditions/postconditions for hard guards.
4. **Integration**: Terratest for real-deploy tests of critical modules. Reserve for high-blast-radius infrastructure.

## AWS-Specific Conventions

### Tagging Strategy

Use `default_tags` in the provider block. Supplement with a `common_tags` local for resource-specific overrides. Enforce: Environment, Project, ManagedBy, Owner at minimum.

### IAM — Least Privilege

- Use `aws_iam_policy_document` data source for readable policies.
- Scope to specific resource ARNs (avoid `"Resource": "*"`).
- Separate roles per service/function. Prefer managed policies for reuse.

### Common Resource Patterns

- **S3**: Versioning, encryption, block public access by default.
- **VPC**: `cidrsubnet()` for subnets. Separate public/private/data tiers.
- **Security Groups**: Reference SGs over CIDR blocks. Avoid `0.0.0.0/0` ingress.
- **RDS/Aurora**: Multi-AZ, automated backups, encryption at rest, parameter groups.

## Safety & Security

- `prevent_destroy` lifecycle on critical resources (databases, stateful storage).
- `create_before_destroy` for zero-downtime replacements.
- **Ephemeral values** for secrets — never persisted to state. For non-ephemeral secrets: SSM Parameter Store, Secrets Manager, or Vault.
- **OIDC / workload identity** for CI/CD — replace long-lived credentials. Separate plan (read-only) and apply (write) identities.
- **Checkov** for policy scanning (replaces tfsec). Trivy had a confirmed supply-chain compromise (March 2026, GHSA-69fq-xp46-6x23). Safe versions: trivy binary ≤ v0.69.3, trivy-action v0.35.0, setup-trivy v0.2.6. Pin to these or later clean releases; verify checksums before upgrading.
- Use `-target` sparingly; prefer full plans. Review destroy counts before apply.

## Anti-Patterns

- **God modules** — monolithic modules with hundreds of resources. Split them.
- **Hardcoded values** — use variables and locals, not magic strings.
- **Nested provider configs** — don't pass providers deep into module chains.
- **Ignoring plan output** — always read the plan. Unexpected destroys happen.
- **State surgery** — `moved` blocks replace most `terraform state mv/rm` uses. Back up state if manual surgery is unavoidable.
- **Skipping lock file commit** — `.terraform.lock.hcl` must be in version control for reproducible provider builds.
- **No environment isolation** — separate dev/staging/prod via workspaces, state files, or directory structure.
- **Over-abstracting early** — extract modules when patterns repeat 3+ times, not before.

## Alternative Tools

- **OpenTofu**: Current version **1.12.0** (released 2026-05-14). Meaningfully diverged from Terraform. Key differentiators: native client-side state encryption (AES-GCM + KMS), provider `for_each`; 1.12 adds dynamic `prevent_destroy` (set via expressions, not just literals), improved provider checksum handling (`tofu init` auto-includes all-platform `zh:`/`h1:` hashes), and `destroy = false` lifecycle option. Migration from Terraform is easy; rollback after using OpenTofu-only features is not. Same HCL conventions apply. IBM closed its $6.4B HashiCorp acquisition (Feb 2025); BSL 1.1 unchanged, but 38% of Terraform users are evaluating or migrating to OpenTofu (Spacelift Q4 2024), making lock-in risk more concrete.
- **Pulumi**: General-purpose languages (TypeScript, Python, Go). ESC for secrets management, native testing via pytest/Jest, Deployments for drift detection. `pulumi preview` before deploy.
- **CloudFormation**: AWS CDK v2 is the recommended path for complex setups. Raw CFN templates for teams without programming expertise. Use `cfn-lint` and enable stack termination protection.
- **CDKTF**: Deprecated and archived (Dec 2025). Do not use for new projects. Migrate existing to native HCL or Pulumi.
