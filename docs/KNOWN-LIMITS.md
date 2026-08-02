# Known limits

What this repo cannot do, what AWS will not let you automate, and the traps that
cost real time. Read this before deciding how far to copy any pattern here.

---

## 1. Terraform provider blocks cannot be looped

**The single most important constraint in multi-account Terraform.**

`provider` blocks accept no `for_each` and no `count`. Their configuration must be
resolvable before Terraform builds the dependency graph, so it cannot depend on
anything computed during the run.

Which means: you cannot loop N accounts and get N `assume_role` providers.

Look at `layers/03-config-recorders/providers.tf` — fourteen near-identical blocks,
one per account per region. `layers/05-network/providers.tf` has ten. This is not
sloppiness; it is the only thing HCL allows inside a single root module.

Consequence: **adding an account is not a one-line change.** It touches
`01-organization/terraform.tfvars`, plus provider and module blocks in layers 03,
05 and 06.

### The three real options

| Approach | How | Trade-off |
|---|---|---|
| **Hand-written providers** *(what this repo does)* | One block per account | Readable, obvious, does not scale past ~10 accounts |
| **Root module per account + external loop** | Root module takes one `account_id`; a Makefile / shell script / CI matrix runs it once per account | Scales to hundreds. The loop lives in the runner, not in HCL. **This is the answer for a real deployment.** |
| **Codegen** | A script reads your account list and writes `providers.tf` before `plan` | Works, but generated HCL is unpleasant to hand anyone |

A fourth exists — HCP Terraform Stacks — but it is a paid platform feature, not
something you get from open-source Terraform.

This repo takes the first option because you can read it. **If you are building
for more than a handful of accounts, take the second**, and keep this repo as the
reference for what each account's configuration should contain.

Anyone who claims "just add it to the YAML and 100 accounts appear" is either
generating HCL or looping outside Terraform. There is no third mechanism.

---

## 2. Things AWS will not let Terraform do

| Manual step | Where it bites | Symptom if skipped |
|---|---|---|
| **Enable IAM Identity Center** | before `06-identity` | `tolist(...)[0]` index error on an empty list |
| **Activate IAM access to billing** | management account | `BillingAccess` users see "You need permissions" and the IAM policy is ignored entirely |
| **Confirm the SNS subscription** | after `04-security` | Subscription sits `PendingConfirmation`; no alerts, no error |
| **Root user MFA per account** | every account | — |
| **Security Hub central configuration** | `04-security` | See §3 |
| **Closing an account** | — | `aws_organizations_account` destroy removes it from state, not from AWS. Closure is manual and rate-limited |

---

## 3. This repo is not reproducible from a clean org

`layers/04-security/securityhub-central-config.tf` manages a Security Hub
configuration policy that was **created in the console and imported into state**,
with a `# match exactly` comment pinning the name. The comment cites IAM race
conditions on first-time setup.

Applying `04-security` to a fresh organization will not reproduce it. Either
create the policy in the console and `terraform import` it, or rewrite the file to
create it outright and accept retrying the first apply.

Flagged loudly because "clone and apply" is the promise this repo makes everywhere
else.

---

## 4. Networking traps

**Prod egress may black-hole.** `05-network` sends Prod's `0.0.0.0/0` to the
Transit Gateway. That only reaches the internet if the Network account runs NAT or
a firewall in an egress VPC *and* the TGW route tables forward to it. Verify the
whole path before relying on it.

**AZ names differ per account.** `us-east-1a` in Dev and `us-east-1a` in Prod are
usually different physical datacentres — AWS randomises the mapping per account.
For latency- or cost-sensitive placement, pin by AZ ID (`use1-az1`) using
`aws_availability_zones`, not by name.

**CIDRs are hand-allocated.** Fine at this size. Past ~20 accounts, use AWS IPAM.

**No inspection or centralised egress.** There is no Network Firewall and no
inspection VPC. Traffic between spokes transits the TGW uninspected.

---

## 5. Guardrail limits

**SCPs never apply to the management account.** AWS exempts it. `deny-root-user`
and friends do not protect it. Keep workloads out of it and protect it with MFA
and minimal access instead.

**SCPs are a ceiling, not a grant.** They cap what IAM can allow. An SCP alone
gives nobody access.

**Only `SERVICE_CONTROL_POLICY` is enabled.** Tag policies, backup policies and
AI opt-out policies are available in Organizations and are not turned on here.

**Not covered at all:** AWS Backup with Vault Lock, budgets and cost anomaly
detection, `terraform test` or policy tests, drift detection, break-glass access,
S3 Object Lock on the log buckets, and tag *enforcement* (tags are applied via
`default_tags`, but nothing denies untagged resources — that needs a tag policy
plus an SCP).

**Partially covered:** KMS — the CloudTrail bucket uses a customer-managed key
with a full cross-account key policy (`layers/02-logging/kms.tf`); the Config and
flow-log buckets are still SSE-S3. Copy the pattern if you need CMKs everywhere.

---

## 6. State

State is split per layer, one file each, all in one bucket. Blast radius per layer
is documented in [STATE.md](STATE.md).

Not split per account or per region. A mistake in `05-network` can affect five
accounts in one apply. Splitting further is the standard next step and pairs
naturally with the root-module-per-account pattern in §1.

`00-bootstrap` holds the bucket that holds everything else. Both it and the lock
table carry `prevent_destroy`. Removing that lifecycle block to "just clean up" is
how people lose an entire landing zone's state.
