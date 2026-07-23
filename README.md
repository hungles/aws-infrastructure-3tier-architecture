# AWS Infrastructure — 3-Tier Architecture

Infrastructure as Code (IaC) project that provisions a secure, multi-tier AWS environment using **Terraform** and **GitHub Actions**. The pipeline supports two environments (`dev` and `prod`) and uses OIDC for keyless authentication with AWS.

---


## Table of Contents

- [CI/CD Pipelines](#cicd-pipelines)
  - [Terraform CI/CD](#terraform-cicd-workflow)
  - [Terraform Destroy](#terraform-destroy-workflow)
- [Environments](#environments)
- [Dynamic Environment Resolution](#dynamic-environment-resolution)
- [Secrets Configuration](#secrets-configuration)
- [Branching Strategy](#branching-strategy)
- [Pipeline Flow Diagrams](#pipeline-flow-diagrams)

---

## CI/CD Pipelines

The project includes two GitHub Actions workflows located in `.github/workflows/`:

### Terraform CI/CD Workflow

**File:** `.github/workflows/terraform.yaml`

This is the main pipeline. It validates, plans, and applies infrastructure changes automatically based on the branch and event type.

| Job | Trigger | Description |
|-----|---------|-------------|
| **Format & Validate** | `push` and `pull_request` on `main` / `dev` | Checks code formatting (`terraform fmt`), initializes the backend, and validates syntax (`terraform validate`). Posts results as a PR comment. |
| **Terraform Plan** | Runs after Format & Validate | Generates an execution plan using `configuration.tfvars` and the dynamic `TF_VAR_environment`. Saves the plan as a GitHub artifact and posts the full plan as a PR comment. |
| **Terraform Apply** | Only on `push` to `main` or `dev` | Downloads the saved plan artifact and applies it. Requires GitHub Environment approval when configured. |

### Terraform Destroy Workflow

**File:** `.github/workflows/terraform-destroy.yaml`

A manual-only workflow (`workflow_dispatch`) that destroys all managed infrastructure. It includes two safety mechanisms:

1. **Confirmation input** — The user must type `"destroy"` exactly to proceed.
2. **Environment selection** — A dropdown to choose which environment to destroy (`dev`, `staging`, or `production`).

| Job | Description |
|-----|-------------|
| **Verify Confirmation** | Validates that the user typed `"destroy"`. Fails the pipeline otherwise. |
| **Destroy Plan** | Runs `terraform plan -destroy` and saves the plan as an artifact. |
| **Terraform Destroy** | Downloads and applies the destroy plan. Requires GitHub Environment approval. Posts a summary table with actor, date, and environment. |

---

## Environments

Two GitHub Environments are configured in the repository settings (`Settings → Environments`):

| Environment | Protected Branch | Purpose |
|-------------|-----------------|---------|
| `dev` | `dev` | Development and testing. Used when the target branch is `dev`. |
| `production` | `main` | Production workloads. Used when the target branch is `main`. Recommended to have **Required Reviewers** enabled. |

Each environment can have:
- **Required reviewers** — Manual approval before `apply` or `destroy` jobs run.
- **Environment-scoped secrets** — Different `AWS_ROLE_TO_ASSUME` per environment for account isolation.
- **Deployment branches** — Restrict which branches can deploy to each environment.

> **Tip:** To configure environments, go to your repository → **Settings** → **Environments** → select or create the environment.

---

## Dynamic Environment Resolution

The pipeline dynamically determines the environment name (`dev` or `prod`) based on the target branch. This value is injected into Terraform as `var.environment` via the `TF_VAR_environment` environment variable.

### Resolution Logic

```bash
TARGET_BRANCH="${{ github.base_ref || github.ref_name }}"
if [ "$TARGET_BRANCH" = "main" ]; then
  echo "env_name=prod" >> $GITHUB_OUTPUT
else
  echo "env_name=dev" >> $GITHUB_OUTPUT
fi
```

| Event | Branch | `env_name` | Terraform `var.environment` |
|-------|--------|------------|-----------------------------|
| Pull Request → `dev` | `dev` | `dev` | `dev` |
| Pull Request → `main` | `main` | `prod` | `prod` |
| Push to `dev` | `dev` | `dev` | `dev` |
| Push to `main` | `main` | `prod` | `prod` |

- **`github.base_ref`** — Populated only on `pull_request` events (the PR's target branch).
- **`github.ref_name`** — Used as fallback on `push` events (the branch being pushed).

The resolved value is consumed in the `plan` and `apply` steps:

```yaml
env:
  TF_VAR_environment: ${{ steps.set_env.outputs.env_name }}
```

---

## Secrets Configuration

The following secrets must be configured in **Settings → Secrets and variables → Actions**:

| Secret | Scope | Description |
|--------|-------|-------------|
| `AWS_ROLE_TO_ASSUME` | Per environment | ARN of the IAM Role that GitHub Actions assumes via OIDC. Example: `arn:aws:iam::123456789012:role/GitHubActionsRole`. Each environment (`dev`, `production`) should have its own role pointing to the correct AWS account. |
| `TF_STATE_BUCKET` | Repository | Name of the S3 bucket that stores the Terraform remote state file. |
| `TF_API_TOKEN` | Repository | Terraform Cloud API token. Used to authenticate with the Terraform Cloud private registry to download modules (e.g., `hungles_terraform/secure-vpc/aws`). |
| `GITHUB_TOKEN` | Automatic | Provided automatically by GitHub Actions. Used to post comments on pull requests. No manual configuration required. |

### OIDC Authentication

This project uses **OpenID Connect (OIDC)** for keyless authentication with AWS — no long-lived access keys are stored as secrets. The flow is:

1. GitHub generates a short-lived JWT token for the workflow run.
2. The `aws-actions/configure-aws-credentials@v4` action exchanges this token with AWS STS.
3. AWS returns temporary credentials scoped to the configured IAM Role.

**Required permissions in the workflow:**

```yaml
permissions:
  id-token: write   # Required for GitHub to generate the OIDC JWT
  contents: read    # Required for actions/checkout
```

> **Important:** The IAM Role's trust policy must allow the GitHub OIDC provider. See [GitHub OIDC with AWS documentation](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services).

---

## Branching Strategy

```
feature/* ──PR──► dev ──PR──► main
                  │            │
                  ▼            ▼
              deploy         deploy
              to dev       to prod
```

| Branch | Purpose |
|--------|---------|
| `feature/*` | Short-lived branches for new features or fixes. PRs target `dev`. |
| `dev` | Integration branch. Merges trigger automatic deployment to the `dev` environment. |
| `main` | Production branch. Merges trigger deployment to the `production` environment (with approval if configured). |

### Workflow per event

| Action | What runs |
|--------|-----------|
| Open PR to `dev` or `main` | Format & Validate → Plan (comment posted on PR) |
| Merge/push to `dev` | Format & Validate → Plan → Apply (deploys to `dev`) |
| Merge/push to `main` | Format & Validate → Plan → Apply (deploys to `production`) |
| Manual trigger (Destroy) | Confirm → Destroy Plan → Destroy (on selected environment) |

---

## Pipeline Flow Diagrams

### Terraform CI/CD — Pull Request

```
┌─────────────────┐     ┌──────────────────┐
│  Format &       │────►│  Terraform Plan  │
│  Validate       │     │                  │
│                 │     │  Posts plan as    │
│  Posts status   │     │  PR comment      │
│  as PR comment  │     └──────────────────┘
└─────────────────┘
```

### Terraform CI/CD — Push (merge to `dev` or `main`)

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Format &       │────►│  Terraform Plan  │────►│  Terraform Apply │
│  Validate       │     │                  │     │                  │
│                 │     │  Saves plan as   │     │  Downloads plan  │
│                 │     │  artifact        │     │  and applies it  │
└─────────────────┘     └──────────────────┘     └──────────────────┘
```

### Terraform Destroy — Manual Trigger

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Verify         │────►│  Destroy Plan    │────►│  Terraform       │
│  Confirmation   │     │                  │     │  Destroy         │
│                 │     │  terraform plan  │     │                  │
│  User must type │     │  -destroy        │     │  Requires env    │
│  "destroy"      │     │                  │     │  approval        │
└─────────────────┘     └──────────────────┘     └──────────────────┘
```

---

## Remote State

The Terraform state is stored remotely in an **S3 bucket** with encryption enabled:

| Setting | Value |
|---------|-------|
| **Backend** | `s3` |
| **Bucket** | Configured via `TF_STATE_BUCKET` secret |
| **State Key** | `aws-infrastructure-3tier/terraform.tfstate` |
| **Region** | `us-east-1` |
| **Encryption** | `true` |

The backend is initialized dynamically at runtime using `-backend-config` flags, keeping the `providers.tf` backend block empty (`backend "s3" {}`).

---

## Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | `1.9.5` | Infrastructure as Code engine |
| AWS Provider | `>= 5.0.0` | AWS resource management |
| GitHub Actions | — | CI/CD automation |
| Terraform Cloud | — | Private module registry |
| AWS OIDC | — | Keyless authentication |
