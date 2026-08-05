# Adapting this repo

What to change to make this repo yours, and which changes are bigger than they
look.

**To actually deploy, read [DEPLOYING.md](DEPLOYING.md) instead** — prerequisites,
apply order, verification and troubleshooting all live there. This page is the
reference you come back to when you want to alter something.

---

## 1. Every value you must change

All of them live in **`configs/landing-zone.yaml`**. There is one file, and no
value appears in it twice.

```bash
$EDITOR configs/landing-zone.yaml
make render     # fans it out to layers/*/terraform.tfvars.json + backend.s3.tfbackend
```

Both generated files are gitignored — the YAML is the thing you keep.

| Key | Notes |
|---|---|
| `aws_profile` | CLI profile with admin in the management account |
| `org_name`, `unique_id` | Prefix and uniqueness suffix for every generated name |
| `regions.primary` / `.secondary` | The `restrict-regions` SCP denies everything outside this pair |
| `github.org` / `.repo` | Who may assume the CI OIDC role |
| `accounts` | Account → OU. Emails derive from `email_pattern` unless you set one |
| `alert_email` | Confirm the SNS subscription or alerts go nowhere |
| `sso_users` | Or delete the block and connect an external IdP |
| VPC CIDRs | **Not in the YAML** — they live in `layers/05-network/*.tf`. See §4 |

Derived for you, never typed: the state bucket, lock table, and all three log
bucket names come from `org_name` + `unique_id`. Override under
`bucket_overrides` only if you must match an existing naming standard.

---

## 2. The three renames that break things

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

## 3. VPC CIDRs are in the code, not in tfvars

Deliberate: the whole address plan is readable in three files instead of being
assembled at plan time.

Edit `layers/05-network/network-vpc.tf`, `workload-vpcs.tf`, `sandbox-vpc.tf`.
Current plan is in [`layers/05-network/README.md`](../layers/05-network/README.md).

Rules: never overlap (a TGW cannot route between identical CIDRs), leave room to
grow — `/16` per account per region is generous and cheap — and keep the second
region in a clearly separate block so the plan stays readable.

---

## 4. Deciding what to delete

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

---

## 5. After deploying

The checks worth doing once the landing zone is up are in
[DEPLOYING.md §4](DEPLOYING.md). The two that catch people:

- The SNS alert subscription stays `PendingConfirmation` until someone clicks
  the link in the email. No alert is delivered until then, and nothing warns you.
- The CI OIDC role from `00-bootstrap` ships with **no permissions policy
  attached**. It can be assumed and can do nothing until you attach one.
