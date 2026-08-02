# AWS Landing Zone — Terraform Reference Implementation

A complete, working, multi-account AWS landing zone built in plain Terraform. No
Control Tower, no AFT, no framework.

**This is a reference, not a product.** There is no wizard, no config language and
no feature flags. You clone it, read it, delete what you don't need and change the
rest. It is meant to save you the weeks of working out *what* a landing zone
contains and *in what order* it has to be built — not to hand you a running one.

If you want a turnkey deployment, use Control Tower. If you want to understand
what Control Tower does so you can build and own the equivalent, start here.

---

## What it builds

```text
Organization (Management Account)
│
├── Security OU
│   ├── Audit          → GuardDuty · Security Hub · Inspector · Access Analyzer · Config aggregator
│   └── LogArchive     → CloudTrail bucket (KMS CMK) · Config bucket · flow-logs bucket
│
├── Infrastructure OU
│   ├── Network        → Transit Gateway · hub VPC · Route53 private zones
│   └── SharedServices → shared tooling VPC
│
├── Workloads OU
│   ├── Dev            → VPC, public + private, attached to TGW
│   └── Prod           → VPC, private only, egress via TGW
│
└── Sandbox OU
    └── Sandbox        → isolated VPC, deliberately not attached
```

8 accounts · 4 OUs · 14 SCPs · 5 org-wide security services, all delegated to
Audit. Single region, with second-region instructions where they matter.

---

## How to read this repo

Read in this order. It takes about half an hour and it is the point of the repo.

| Read | For |
|---|---|
| **[docs/DECISIONS.md](docs/DECISIONS.md)** | Why it is shaped this way, and what the alternatives were |
| **[docs/STATE.md](docs/STATE.md)** | How state is split, and the blast radius of each layer |
| **[docs/KNOWN-LIMITS.md](docs/KNOWN-LIMITS.md)** | What Terraform and AWS will not let you do. **Read §1 before copying anything** |
| **[docs/ADAPTING.md](docs/ADAPTING.md)** | Every value you must change before your first apply |
| `layers/*/README.md` | What each layer creates, depends on, and can break |

Then read `layers/01-organization/scps.tf` and
`layers/03-config-recorders/providers.tf`. The first is the entire guardrail story
in one file. The second shows the central constraint of multi-account Terraform
more clearly than any explanation.

---

## Layout

```
layers/          ← deployment units. Applied in order. Each has its own state.
  00-bootstrap        state bucket, lock table, CI OIDC role
  01-organization     org, OUs, accounts, SCPs
  02-logging          central CloudTrail + Config buckets in LogArchive
  03-config-recorders AWS Config in every account
  04-security         GuardDuty, Security Hub, Inspector, Access Analyzer → Audit
  05-network          Transit Gateway, VPCs, RAM sharing, private DNS
  06-identity         Identity Center: permission sets, groups, assignments

modules/         ← library. Never applied directly.
policies/scp/    ← SCP documents as JSON
docs/            ← the part that makes this a reference rather than a snapshot
.github/         ← CI: fmt, validate, tflint. No credentials, no plan.
```

The numbers are dependency order, not decoration. `02` cannot run before `01`.

There is no root `main.tf`. Nothing orchestrates the layers — you apply them in
sequence, deliberately. See [docs/DECISIONS.md §1](docs/DECISIONS.md).

---

## Running it

Full detail in **[docs/ADAPTING.md](docs/ADAPTING.md)**. The shape:

```bash
# Once, in the console: enable IAM Identity Center, activate IAM billing access.

cd layers/00-bootstrap
cp terraform.tfvars.example terraform.tfvars     # edit
terraform init && terraform apply
terraform output                                 # every other layer needs these

# Then, for 01 → 06 in order:
cd ../01-organization
cp terraform.tfvars.example terraform.tfvars           # edit
cp backend.s3.tfbackend.example backend.s3.tfbackend   # edit
terraform init -backend-config=backend.s3.tfbackend
terraform plan && terraform apply
```

Neither `terraform.tfvars` nor `*.tfbackend` is committed — only the `.example`
files are. Both are gitignored.

**`01-organization` is slow and effectively one-way.** Account creation takes
minutes each and AWS rate-limits it; a mid-run timeout is normal, just re-apply.
Accounts cannot be deleted through the API afterwards, so get the emails right.

---

## What is deliberately not here

A landing zone touches everything, so the useful question is where the line is.
This repo stops at the platform. It does not include:

**Not built:** AWS Backup + Vault Lock · budgets and cost anomaly detection ·
break-glass access · IPAM · Network Firewall / inspection VPC · S3 Object Lock ·
tag policies · `terraform test` · drift detection · workload infrastructure of
any kind.

**Not automated, because AWS does not allow it:** enabling Identity Center ·
activating IAM billing access · confirming SNS subscriptions · root MFA ·
closing accounts.

Each is listed in [docs/KNOWN-LIMITS.md](docs/KNOWN-LIMITS.md) with what it would
take to add. The gaps are documented rather than hidden — a reference that
overstates what it covers is worse than one that admits its edges.

---

## The one thing to take away

**Terraform `provider` blocks cannot use `for_each` or `count`.** You cannot loop
N accounts into N assume-role providers. That is why
`03-config-recorders/providers.tf` contains eight near-identical blocks, and it is
the constraint every multi-account Terraform design has to answer.

This repo answers it by writing them out, because that is readable. Past roughly
ten accounts the answer is a root module parameterised on one account, looped by a
Makefile or a CI matrix — the loop lives in the runner, not in HCL.

[docs/KNOWN-LIMITS.md §1](docs/KNOWN-LIMITS.md) covers all three options and their
trade-offs. Read it before you copy this structure at scale.
