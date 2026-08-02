# 00-bootstrap

Creates the things every other layer depends on: the S3 bucket that stores state,
the DynamoDB table that locks it, and the OIDC role CI uses to authenticate.

**Runs in:** management account, no assume-role
**Depends on:** nothing — this is the first apply
**Blast radius:** 🔴 **the entire landing zone.** Destroying this loses every state file.
Both the bucket and the lock table carry `prevent_destroy`.

## Creates

- S3 state bucket — versioned, encrypted, public access blocked, `prevent_destroy`
- DynamoDB lock table — `PAY_PER_REQUEST`, hash key `LockID`
- GitHub Actions OIDC provider + an IAM role scoped to one org/repo

## The chicken-and-egg problem

This layer creates the backend that holds state — so on the first run there is
nowhere to put its own state. That is why `backend.tf` here says `backend "local"`
while every other layer says `backend "s3" {}`.

Apply locally first, then migrate this layer's state into the bucket it just made:

```bash
cp terraform.tfvars.example terraform.tfvars   # edit it
terraform init
terraform apply

# Note the outputs — every other layer needs them.
terraform output

# Now point this layer at its own bucket and move the state file in.
# Replace backend.tf's `backend "local"` block with `backend "s3" {}`,
# write a backend.s3.tfbackend like the other layers have, then:
terraform init -backend-config=backend.s3.tfbackend -migrate-state
```

Terraform will ask to copy the existing state into S3. Answer yes. From then on
this layer behaves like all the others.

Leaving it on local state also works, as long as you understand that
`terraform.tfstate` on one laptop is then the only record of the backend.

## Outputs

| Output | Used by |
|---|---|
| `state_bucket_name` | every layer's `.tfbackend` and `state_bucket` var |
| `dynamodb_table_name` | every layer's `.tfbackend` |
| `github_actions_role_arn` | CI workflow |

## Known gap

The OIDC role is created with a trust policy but **no permissions policy attached** —
it can be assumed and can then do nothing. Attach a policy scoped to what your
pipeline actually needs. Deliberately left empty rather than guessing at
`AdministratorAccess`.
