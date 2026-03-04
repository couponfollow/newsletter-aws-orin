# CLAUDE.md

## Product Overview

**Goal:** Infrastructure-as-code for the Newsletter project. Manages AWS resources (Lambda, IAM, CloudWatch) via Terraform. Deploys a Python Lambda function for newsletter processing.

### Key Concepts

- **Terraform managed:** All infrastructure is defined declaratively in `.tf` files. Never create AWS resources manually.
- **Lambda packaging:** Python source in `lambda/` is zipped automatically via `archive_file` data source and deployed to AWS Lambda.
- **IAM least-privilege:** Lambda role gets only `AWSLambdaBasicExecutionRole`. Add permissions incrementally as needed.
- **Environment-driven:** `var.environment` controls deployment context (dev/staging/prod). Resource naming uses `var.project_name` prefix.

---

## Tech Stack

- **IaC:** Terraform >= 1.0, AWS provider ~> 5.0
- **Cloud:** AWS (Lambda, IAM, CloudWatch Logs)
- **Runtime:** Python 3.12 (Lambda)
- **Tooling:** terraform fmt, terraform validate, tflint (recommended)

---

## Repository Structure

```
.                  — Root Terraform configuration
├── main.tf        — Provider config, Lambda, IAM, CloudWatch resources
├── variables.tf   — Input variables (region, project name, environment)
├── outputs.tf     — Output values (function name, ARNs)
├── lambda/        — Python Lambda source code
│   └── index.py   — Lambda handler
├── build/         — Generated artifacts (lambda.zip) — gitignored
└── .claude/       — Claude Code settings
```

### Key Files

- `main.tf` — all resource definitions
- `variables.tf` — input variables with defaults
- `outputs.tf` — exported resource attributes
- `lambda/index.py` — Lambda handler entry point

---

## Development Patterns

### Adding a new AWS resource

1. Define the resource in `main.tf` (or a new `.tf` file if it's a distinct concern)
2. Add any new input variables to `variables.tf` with descriptions and sensible defaults
3. Export useful attributes (ARNs, IDs, endpoints) in `outputs.tf`
4. Run `terraform fmt` and `terraform validate`
5. Run `terraform plan` to review changes before applying

### Terraform workflow

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize providers and backend |
| `terraform fmt` | Format `.tf` files |
| `terraform validate` | Validate configuration syntax |
| `terraform plan` | Preview infrastructure changes |
| `terraform apply` | Apply changes (requires confirmation) |
| `terraform destroy` | Tear down all resources |

### Variable conventions

- Use descriptive `description` fields on all variables
- Provide `default` values for non-sensitive, environment-agnostic variables
- Sensitive values (API keys, secrets) use `sensitive = true` and should never be committed
- Use `terraform.tfvars` or environment-specific `.tfvars` files for overrides (gitignored)

---

## Working Principles

> Ship correct, minimal changes quickly. Prefer clarity over cleverness. Never guess when correctness is at risk.

### Planning

Enter plan mode when ANY of these apply:

- 3+ steps or significant scope
- Architectural decisions (new services, networking, IAM changes)
- Unclear or ambiguous requirements
- Touches IAM policies, security groups, data stores, or destructive operations
- Debugging where root cause isn't obvious quickly

**Plan output must include:** Goal + non-goals, assumptions, proposed approach, acceptance criteria, verification plan, and risk/rollback notes if non-trivial.

**Re-plan rule:** If reality diverges from the plan (unexpected plan output, wrong assumptions, new constraints) — stop, update the plan, then continue.

### Documentation & Context

- For Terraform provider/resource uncertainty: consult the official Terraform AWS provider docs before coding.
- Prefer primary sources: official docs, Terraform registry, AWS documentation.
- If docs are unclear or missing: ask for a reference, or choose conservative behavior and document the decision.

### Constants & Configuration

- **No inline magic values:** All repeated values (ARN patterns, policy documents, timeouts, memory sizes) should be variables or locals.
- **Environment-specific values** (account IDs, domain names, secrets) go in `.tfvars` files or environment variables — never hardcoded.
- **Before adding a new variable,** check if it already exists in `variables.tf`.

### DRY & Code Reuse

- **Before writing new resources,** check if similar patterns already exist in the codebase.
- Use Terraform `locals` for computed values referenced in multiple places.
- Use modules when a group of resources forms a reusable pattern across environments or projects.
- Watch for: duplicated IAM policy documents, repeated tags blocks, copy-pasted resource configurations.

### Change Discipline

- Prefer the smallest change that fully addresses the requirement.
- Always run `terraform plan` before `terraform apply` — review the diff carefully.
- Never mix unrelated infrastructure changes in a single commit.
- Destructive changes (resource replacement, deletion) must be called out explicitly.
- `terraform apply` should never be run without user confirmation.

### Error Handling

- **No silent failures:** If a resource depends on another, make dependencies explicit.
- **Validate early:** Use `validation` blocks on variables where appropriate.
- **State management:** Never manually edit `.tfstate` files. Use `terraform state` commands if state manipulation is needed.
- **If `terraform plan` shows unexpected changes,** investigate before applying — do not blindly apply.

### Testing & Verification

- Run `terraform validate` after every change.
- Run `terraform plan` to verify expected changes before applying.
- After `terraform apply`, verify resources exist and behave correctly (e.g., invoke Lambda, check CloudWatch logs).
- For Lambda code changes: test locally with `python3 lambda/index.py` when possible.

### Definition of Done

A task is only DONE when all applicable items are satisfied:

- [ ] Acceptance criteria met
- [ ] `terraform fmt` produces no changes
- [ ] `terraform validate` passes
- [ ] `terraform plan` reviewed and changes are as expected
- [ ] No sensitive values hardcoded
- [ ] Variables have descriptions and sensible defaults
- [ ] Outputs added for useful resource attributes
- [ ] Risks noted + rollback steps for non-trivial changes

---

## Git Discipline

- Commit early and often in small, reviewable chunks — one logical change per commit.
- Prefer atomic commits: don't mix refactors/formatting with functional changes.
- Commit after reaching a green checkpoint (`terraform validate` passes) when practical.
- Write messages that explain **intent**, not mechanics (e.g., "Add S3 bucket for newsletter assets", not "Change main.tf").
- For risky changes, leave a breadcrumb: how you verified + how to roll back.
- Before each commit, review and update the top-level `README.md` to reflect the current state.

---

## Operational Rules

### Subagents

- Use for research, exploration, parallel options, and edge cases.
- One task per subagent with crisp goals + constraints.
- Main agent owns coherence, integration, and verification. Never merge unverified subagent output.

### Observability

- All Lambda functions should have CloudWatch log groups with appropriate retention.
- Use structured logging in Lambda code (JSON format preferred).

### Lessons Loop

After any user correction or post-apply issue, add an entry to `lessons.md`: mistake pattern, why it happened, and the rule/check that prevents it next time.

### When Unsure

- Surface uncertainty explicitly.
- Prefer asking for clarification over guessing.
- If forced to choose: pick the safest, most explicit behavior and document it.

### Large File Writes

**The `Write` tool silently fails on files >~500 lines / ~15KB** with "missing required parameter" or "Invalid tool parameters" errors. This is a known platform limitation.

**Mandatory rule:** When writing any file likely to exceed 500 lines (plan documents, large generated code, etc.), **never use the `Write` tool directly.** Instead, use Bash with `cat <<'EOF'` heredoc syntax, splitting into multiple sequential append operations if needed. For subagent-delegated writes, ensure the subagent also follows this rule.

**If you see "Invalid tool parameters" on a Write call, do NOT retry Write** — switch to the Bash heredoc approach immediately.

### Deletion Policy

**Never use `rm` or `rmdir` — always use `trash` instead.** If `trash` is unavailable, stop and surface the issue rather than falling back to `rm`.

### Terraform Safety

- **Never run `terraform destroy` without explicit user confirmation.**
- **Never run `terraform apply -auto-approve` unless the user explicitly requests it.**
- **Never modify `.tfstate` files directly.**
- **Always review `terraform plan` output before applying.**
