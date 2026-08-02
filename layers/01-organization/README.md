# 01-organization

The org itself: OUs, member accounts, and the SCP guardrails attached to them.
Everything downstream reads its account IDs from here.

**Runs in:** management account, no assume-role
**Depends on:** `00-bootstrap`
**Blast radius:** 🔴 **highest of any layer.** This is the only place accounts are
created. A destroy here does not delete accounts (AWS does not allow it from the
API) but it will detach every guardrail in the org at once.

## Creates

- `aws_organizations_organization` with `feature_set = ALL` and service access
  enabled for CloudTrail, Config, GuardDuty, Security Hub, Access Analyzer, Inspector
- 4 OUs — Security, Infrastructure, Sandbox, Workloads
- 7 member accounts, from the `accounts` map
- 14 SCPs, attached to OUs (not to accounts)
- Org-wide RAM sharing, so the Transit Gateway in `05-network` can be shared

## The guardrails

| SCP | Attached to |
|---|---|
| `deny-root-user` | Root |
| `deny-leave-org` | Root |
| `deny-disable-cloudtrail` | Root |
| `deny-disable-config` | Root |
| `deny-disable-guardduty` | Root |
| `restrict-regions` | Root |
| `deny-public-s3` | Root |
| `protect-log-archive` | Security OU |
| `protect-security-tooling` | Security OU |
| `protect-networking` | Infrastructure OU |
| `deny-expensive-services` | Sandbox OU |
| `deny-network-bridging` | Sandbox OU |
| `deny-iam-user-creation` | Workloads OU |
| `require-imdsv2` | Workloads OU |
| `require-ebs-encryption` | Workloads OU |
| `deny-unencrypted-rds` | Workloads OU |

To drop a guardrail, delete or comment out its module block in `scps.tf`. There is
no enable/disable variable on purpose — the SCPs you get are the module blocks you
can read.

**SCPs never apply to the management account.** AWS exempts it. Do not put
workloads there and assume `deny-*` protects them.

## OUs and accounts are resources, not modules

Both wrap exactly one AWS resource with no added logic, so `for_each` on a plain
resource does everything a module would have. A module earns its keep when it
bundles several resources that always ship together — `modules/vpc` creates
eleven. One-resource modules are indirection with no payoff.

## Two things that are load-bearing

The keys in `ou_names` and in the `accounts` map are looked up by exact string,
here and in four downstream layers (`account_ids["Audit"]`,
`module.org_units["Security"]`, …). Renaming one is a multi-file change. See
`terraform.tfvars.example` and `docs/ADAPTING.md`.

## Outputs

`account_ids` · `management_account_id` · `org_id` · `ou_ids` · `allowed_regions`

Every layer from 02 onward reads `account_ids` to build its provider blocks.
