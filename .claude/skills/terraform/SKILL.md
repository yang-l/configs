---
name: terraform
description: |
  Terraform and Infrastructure-as-Code skill for Terraform 1.10+, OpenTofu,
  Pulumi, and CloudFormation. Load when writing or reviewing Terraform/HCL
  modules, designing state backends, planning IaC migrations, configuring
  providers, debugging plan/apply failures, or evaluating OpenTofu vs Terraform.
  Trigger: terraform, iac, infrastructure-as-code, pulumi, opentofu,
  cloudformation, tofu, hcl, tfvars, state backend, drift detection
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

## Naming Conventions

- Resources: `snake_case`, descriptive (e.g., `aws_s3_bucket.app_logs`).
- Variables: `snake_case` with `description`, `type`, and `validation` blocks.
- Outputs: `snake_case` with `description`.
- Modules: `kebab-case` directories, `snake_case` internal names.

## Provider & Version Pinning

```hcl
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
```

- Pin providers with pessimistic constraint (`~>`). Pin Terraform version via `.terraform-version` or `tfenv`.
- **Commit `.terraform.lock.hcl`** — this is the only supply-chain lock for providers. Modules are NOT covered; pin exact versions for critical modules.
- Run `terraform init -upgrade` deliberately, not automatically.

## Modern Language Features

- **Ephemeral resources/values** (1.10+): Not persisted in state or plan. Use for secrets and short-lived tokens. Prefer over `sensitive = true` for credentials.
- **Write-only arguments** (1.11+): Ephemeral values in managed resource attributes.
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
- **Checkov** for policy scanning (replaces tfsec). Trivy had a supply-chain compromise (March 2026); verify before adopting.
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

- **OpenTofu**: Meaningfully diverged from Terraform. Key differentiators: native client-side state encryption (AES-GCM + KMS), provider `for_each`. Migration from Terraform is easy; rollback after using OpenTofu-only features is not. Same HCL conventions apply.
- **Pulumi**: General-purpose languages (TypeScript, Python, Go). ESC for secrets management, native testing via pytest/Jest, Deployments for drift detection. `pulumi preview` before deploy.
- **CloudFormation**: AWS CDK v2 is the recommended path for complex setups. Raw CFN templates for teams without programming expertise. Use `cfn-lint` and enable stack termination protection.
- **CDKTF**: Deprecated and archived (Dec 2025). Do not use for new projects. Migrate existing to native HCL or Pulumi.
