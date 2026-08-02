# 03-config-recorders

Turns on AWS Config in every member account, in both regions, all writing to the
central Config bucket.

**Runs in:** every member account (assume-role), both regions
**Depends on:** `01-organization` (account IDs) and `02-logging` (Config bucket)
**Blast radius:** 🟡 Medium. Destroying stops configuration recording; it does not
delete already-recorded history in S3.

## Why this is a separate layer

Config recorders must exist *before* the Config aggregator in `04-security` has
anything to aggregate. Splitting them means `04-security` can be re-applied
without touching seven accounts' recorders.

## The provider wall, made visible

This is the clearest example in the repo of a Terraform limitation worth
understanding before you copy this pattern: **provider blocks cannot use `for_each`
or `count`.**

Seven accounts means seven provider blocks in `providers.tf` and seven module
blocks in `main.tf`, all identical except for the account they point at. There is
no way to loop them inside a single root module — and `providers = {}` on a module
call takes a literal alias, not an expression, so `for_each` does not help there
either. Adding an eighth account means hand-writing one more of each.

This layer originally carried all seven accounts in *both* regions — fourteen of
everything. The second region is now one worked example, because the other six
copies taught nothing the first did not.

The escape hatch is to make this a root module parameterised on one account, and
loop it from outside — a `Makefile`, a shell script, or a CI matrix. Read
`docs/KNOWN-LIMITS.md` before you scale this past a handful of accounts.

## The second-region trick

An IAM role is global, so the `_aps1` recorders reuse the role created by their
`_use1` counterpart rather than making a duplicate:

```hcl
create_iam_role   = false
existing_role_arn = module.config_recorder_dev_use1.config_role_arn
```

Doing it the other way produces an `EntityAlreadyExists` error on the second region.

## Outputs

None. `04-security` creates its aggregator against the organization as a whole,
not against individual recorders, so nothing downstream needs a handle on these.
