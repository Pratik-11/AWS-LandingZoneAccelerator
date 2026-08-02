# Adapting this repo

Everything you must change before your first apply, in the order you hit it.

Work through it top to bottom. Nothing here is optional — the repo ships with
placeholder values that will not work in your account.

---

## 1. Before you touch Terraform

| # | Do this | Why |
|---|---|---|
| 1 | Create the management (payer) account, or use an existing one | Everything is created from here |
| 2 | Configure an AWS CLI profile with admin access to it | Every layer takes `terraform-profile` |
| 3 | Decide your email convention — `aws+<account>@yourdomain.com` | Account emails must be globally unique and permanent |
| 4 | Enable **IAM Identity Center** in the console | Terraform cannot create it; `06-identity` reads it as a data source |
| 5 | Activate **IAM access to billing** in the management account | Otherwise `BillingAccess` silently does nothing |

Steps 4 and 5 are one-time console actions with no Terraform equivalent. See
[KNOWN-LIMITS.md](KNOWN-LIMITS.md).

---

## 2. Every value you must change

Each layer ships a `terraform.tfvars.example`. Copy it and edit:

```bash
cd layers/<layer>
cp terraform.tfvars.example terraform.tfvars
```

| Value | Where | Notes |
|---|---|---|
| `aws_profile` / `terraform-profile` | every layer | Your management account CLI profile |
| `org_name` | `00-bootstrap` | Prefixes state bucket and lock table |
| `unique_id` | `00-bootstrap` | S3 names are globally unique — collisions are guaranteed without this |
| `github_org` / `github_repo` | `00-bootstrap` | Who may assume the CI OIDC role |
| `state_bucket` / `state_bucket_region` | layers 02–06 | From `00-bootstrap` outputs |
| `allowed_regions` | `01-organization`, `04-security` | **Must match.** The `restrict-regions` SCP denies everything outside this set |
| `accounts` | `01-organization` | Emails must be unique, unused, and permanent |
| `cloudtrail_bucket_name` / `config_bucket_name` / `flow_logs_bucket_name` | `02-logging` | All globally unique |
| `alert_email` | `04-security` | Confirm the SNS subscription email or alerts go nowhere |
| `sso_users` | `06-identity` | Or delete and connect an external IdP |
| VPC CIDRs | `05-network` **(in `.tf` files, not tfvars)** | See below |

Also write a `backend.s3.tfbackend` per layer from the committed
`backend.s3.tfbackend.example`, using the `00-bootstrap` outputs.

---

## 3. The three renames that break things

These are the traps. Everything else is a one-line edit.

### Account map keys

Downstream layers index the account map by exact string:

```hcl
account_ids["Audit"]  account_ids["LogArchive"]  account_ids["Network"]
account_ids["SharedServices"]  account_ids["Dev"]  account_ids["Prod"]
account_ids["Sandbox"]
```

Renaming `Dev` to `Development` in `01-organization/terraform.tfvars` means editing
provider blocks in `03-config-recorders`, `05-network` and `06-identity`. It is a
deliberate trade — explicit lookups are readable, and they are also rigid.

**Adding** an account is safe. **Renaming** one is a repo-wide change.

### OU names

`scps.tf` looks up `module.org_units["Security"]`, `["Infrastructure"]`,
`["Sandbox"]`, `["Workloads"]`. Change `ou_names` and you must change `scps.tf`
to match, or the plan fails.

### SSO group keys

`sso_users[*].groups` accepts only `platform_engineers`, `developers`,
`security_team`, `finance` — the keys of `local.group_membership_map` in
`06-identity/users.tf`. Adding a group means adding a resource in `groups.tf`, an
entry in that map, and rows in `assignments.tf`.

---

## 4. VPC CIDRs are in the code, not in tfvars

Deliberate: the whole address plan is readable in three files instead of being
assembled at plan time.

Edit `layers/05-network/network-vpc.tf`, `workload-vpcs.tf`, `sandbox-vpc.tf`.
Current plan is in [`layers/05-network/README.md`](../layers/05-network/README.md).

Rules: never overlap (a TGW cannot route between identical CIDRs), leave room to
grow — `/16` per account per region is generous and cheap — and keep the second
region in a clearly separate block so the plan stays readable.

---

## 5. Apply order

Strict. Each layer reads the one before it.

```bash
00-bootstrap → 01-organization → 02-logging → 03-config-recorders
            → 04-security → 05-network → 06-identity
```

Per layer:

```bash
cd layers/<layer>
cp terraform.tfvars.example terraform.tfvars          # edit
cp backend.s3.tfbackend.example backend.s3.tfbackend  # edit
terraform init -backend-config=backend.s3.tfbackend
terraform plan
terraform apply
```

`00-bootstrap` is the exception — local backend first, then migrate. See its README.

**Account creation is slow.** `01-organization` takes several minutes per account
and AWS rate-limits it. A timeout mid-run is normal; re-apply and it continues.

---

## 6. Deciding what to delete

This is a reference, not a product. Deleting is expected.

| If you don't need | Delete |
|---|---|
| A second region | Already cut. `03-config-recorders` keeps one `_aps1` block as the worked example — delete it and its provider |
| A sandbox account | Its entry in `accounts`, `sandbox-vpc.tf`, the Sandbox OU and its two SCPs |
| Config recording everywhere | `03-config-recorders` entirely, and the aggregator in `04-security` |
| Some guardrails | The matching module blocks in `01-organization/scps.tf` |
| Terraform-managed SSO users | `06-identity/users.tf` and the `sso_users` variable — connect an IdP instead |
| Transit Gateway connectivity | `05-network` — accounts still work, just isolated |

There is no feature flag anywhere in this repo. What you can read is what you get.

---

## 7. Before you call it done

- [ ] Every account's root user has MFA and its credentials are in a vault
- [ ] The SNS alert subscription is **confirmed** (check the email)
- [ ] `restrict-regions` lists every region you actually use
- [ ] The CI OIDC role has a permissions policy — it ships with none
- [ ] Prod egress works end to end (see the trap in `05-network/README.md`)
- [ ] Log buckets have a lifecycle policy matching your retention requirement
- [ ] A break-glass path exists for Identity Center being unavailable
- [ ] `terraform.tfvars` and `*.tfbackend` are gitignored — verify before pushing
