# State & blast radius

One state file per layer, all in the bucket created by `00-bootstrap`, locked
through one DynamoDB table.

```
s3://<org>-lz-terraform-state-<id>/
  lz/01-organization/terraform.tfstate
  lz/02-logging/terraform.tfstate
  lz/03-config-recorders/terraform.tfstate
  lz/04-security/terraform.tfstate
  lz/05-network/terraform.tfstate
  lz/06-identity/terraform.tfstate
```

`00-bootstrap` starts on a local backend and migrates into this bucket once it
exists — see its README.

## Blast radius per layer

What breaks if a layer is destroyed or badly applied. This is the table to read
before running `apply` on something you did not write.

| Layer | Radius | Worst case |
|---|---|---|
| `00-bootstrap` | 🔴 **Everything** | Losing this bucket loses every state file. `prevent_destroy` on the bucket and lock table |
| `01-organization` | 🔴 **Org-wide** | Detaches every guardrail at once. Accounts survive — AWS will not delete them via API |
| `02-logging` | 🟠 High | Org audit trail gone. `protect-log-archive` should block it, so a destroy may fail by design |
| `03-config-recorders` | 🟡 Medium | Recording stops; history already in S3 survives |
| `04-security` | 🟠 High | Org-wide threat detection off; findings history lost with the detectors |
| `05-network` | 🔴 High, **immediate** | Removing an attachment or route breaks live connectivity the moment it applies |
| `06-identity` | 🟠 High, recoverable | Everyone loses SSO at once. Fallback is the management root user — which is why break-glass matters |

## Dependency graph

```
00-bootstrap
     │  (state bucket + lock table)
     ▼
01-organization ─────────────┬──────────────┬─────────────┐
     │  (account_ids)        │              │             │
     ▼                       ▼              ▼             ▼
02-logging              04-security     05-network    06-identity
     │  (config bucket)
     ▼
03-config-recorders  ──────► (recorders must exist before 04's aggregator
                              has anything to aggregate)
```

Layers 04, 05 and 06 depend only on `01-organization` and are independent of each
other — they can be applied in any order, or in parallel. `02` and `03` are a
chain.

## Reading upstream outputs

Every downstream layer does this, with the key varying:

```hcl
data "terraform_remote_state" "org" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "lz/01-organization/terraform.tfstate"
    region = var.state_bucket_region
  }
}
```

This is read-only. A layer never writes to another layer's state. The coupling and
its alternative are discussed in [DECISIONS.md §2](DECISIONS.md).

## Locking

Every layer uses the same DynamoDB table. Concurrent applies of *different* layers
are safe — the lock key includes the state path. Two people applying the *same*
layer will block, which is the point.

## What is not split

State is per layer, **not per account or per region**. One `05-network` apply can
affect five accounts in two regions. For production, split further — per layer ×
account-group × region — which pairs naturally with the root-module-per-account
pattern in [KNOWN-LIMITS.md §1](KNOWN-LIMITS.md).

## Recovery

The bucket is versioned. A corrupted or truncated state file can be restored to a
previous version through the console or:

```bash
aws s3api list-object-versions --bucket <state-bucket> --prefix lz/05-network/
aws s3api get-object --bucket <state-bucket> --key lz/05-network/terraform.tfstate \
  --version-id <id> restored.tfstate
```

Versioning is why it is enabled, and why `prevent_destroy` guards the bucket.
