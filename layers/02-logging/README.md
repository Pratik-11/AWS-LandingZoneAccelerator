# 02-logging

Central audit logging. Buckets live in the LogArchive account; the org-wide
CloudTrail is created from the management account and writes into them.

**Runs in:** management account + LogArchive (assume-role)
**Depends on:** `01-organization`
**Blast radius:** 🟠 High. Destroying this deletes the org audit trail. In a real
deployment the `protect-log-archive` SCP should be blocking exactly that — which
also means a destroy from here may fail, by design.

## Creates

- KMS customer-managed key + alias, in LogArchive
- CloudTrail bucket — versioned, **SSE-KMS with the CMK**, public access blocked
- Config bucket — versioned, SSE-S3, public access blocked
- VPC flow logs bucket — consumed by `05-network`
- `aws_cloudtrail` with `is_organization_trail = true`, multi-region,
  log file validation on, encrypted with the CMK

## Why the trail is in the management account but the bucket isn't

Only the management account can create an *organization* trail — that is what
makes it capture every member account with no per-account setup. The bucket lives
in LogArchive so that compromising a workload account does not give access to the
evidence. This split is the whole point of a separate log archive account.

The cross-account bucket policy that makes this work is in
`modules/logging-bucket/main.tf` — worth reading, it is the part people get wrong.

## Outputs

`cloudtrail_bucket_id` · `config_bucket_id` · `config_bucket_arn` ·
`flow_logs_bucket_arn` · `cloudtrail_kms_key_arn`

`03-config-recorders` reads the Config bucket; `05-network` reads the flow-logs
bucket ARN.

## The KMS example

`kms.tf` is the one worked CMK in this repo, and the key *policy* is the reason it
exists. A CloudTrail key in LogArchive is written by CloudTrail on behalf of the
**management** account and read by engineers in **Audit** — three principals, none
of which get access implicitly. KMS denies by default, and unlike IAM an
incomplete key policy locks out everyone including you.

Three statements, in the order they matter:

1. `EnableIAMUserPermissions` — delegates to IAM in the owning account. Without
   it the key can never be managed again.
2. `AllowCloudTrailEncrypt` — the service principal, constrained by
   `aws:SourceOrgID` and an encryption-context match on the trail ARN, so no
   other AWS customer can use your key.
3. `AllowAuditAccountDecrypt` — without this, security engineers get ciphertext
   and an AccessDenied.

`bucket_key_enabled` is on. Without it every object write is a separate KMS API
call, which gets expensive fast on a high-volume log bucket.

## Known gaps

- Config and flow-log buckets are still SSE-S3. Copy the CMK pattern if your
  compliance regime requires customer-managed keys everywhere.
- **No S3 Object Lock.** SCPs protect these buckets from deletion, but an SCP is
  an authorisation control — Object Lock in compliance mode is what makes logs
  genuinely immutable. Object Lock must be enabled at bucket *creation*.
- No lifecycle policy. Add one matching your retention requirement before these
  buckets get expensive.
