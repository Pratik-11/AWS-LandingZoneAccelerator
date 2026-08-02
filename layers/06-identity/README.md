# 06-identity

IAM Identity Center: permission sets, groups, users, and the group→account→
permission-set assignment matrix. This is how humans get into the accounts.

**Runs in:** management account
**Depends on:** `01-organization`
**Blast radius:** 🟠 High but recoverable. Destroying this removes everyone's SSO
access at once. You would fall back to the management account root user — which is
exactly the scenario a break-glass role should exist for, and does not yet.

## ⚠️ Manual prerequisite

**IAM Identity Center must be enabled in the console before this layer runs.** It
is a per-org singleton with no `aws_ssoadmin_instance` resource to create it. This
layer reads the existing instance:

```hcl
data "aws_ssoadmin_instances" "this" {}
```

If Identity Center is not enabled, that returns an empty list and
`tolist(...)[0]` fails with an unhelpful index error. That message means
"go turn it on", not "the code is broken".

## Permission sets

| Set | Policy | Session |
|---|---|---|
| `PowerUserAccess` | AWS managed PowerUser | 1h |
| `ReadOnlyAccess` | AWS managed ReadOnly | 8h |
| `DeveloperAccess` | custom inline — compute/storage/observability, denies IAM write, billing, organizations | 8h |
| `SecurityAuditAccess` | SecurityAudit + GuardDuty read | 8h |
| `BillingAccess` | AWSBillingReadOnly | 4h |

`PowerUserAccess` is 1h on purpose. The broader the permission, the shorter the
session should be.

## Groups and who gets what

| Group | Access |
|---|---|
| `platform_engineers` | PowerUser on all 8 accounts |
| `developers` | Developer on Dev + Sandbox, ReadOnly on Prod |
| `security_team` | SecurityAudit on everything except management |
| `finance` | Billing on management only |

The matrix is `local.account_assignments` in `assignments.tf`, written out
explicitly rather than generated. Twenty-one entries you can read beats a nested
loop you have to simulate in your head — and this is the file people audit.

Assign permission sets **to groups, never to users**. Group membership is the only
thing that should change when someone joins or leaves.

## Tagging

Permission sets are tagged by `default_tags` on the provider, not by a `tags`
variable. One place to change, nothing to forget.

## Billing console quirk

A user with `BillingAccess` still gets *"You need permissions"* until IAM access to
billing is switched on at the account level. It is a one-time console step that
cannot be done in Terraform. Management account → top-right account menu →
Account → *IAM User and Role Access to Billing Information* → Edit → Activate.

## Known gaps

- **No break-glass role.** If Identity Center breaks, the only way in is the
  management account root user. A dedicated emergency role with MFA and an alarm
  on every use is the standard answer.
- **Built-in directory only.** Fine for a demo. Real deployments connect an
  external IdP over SCIM so offboarding happens in one place — at which point
  `users.tf` and the `sso_users` variable are deleted.
- **No MFA enforcement** on the SSO portal.
