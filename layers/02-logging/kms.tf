# ──────────────────────────────────────────────────────────────────────────────
# Customer-managed key for the CloudTrail log bucket.
#
# ONE worked KMS example, deliberately. The Config and flow-log buckets stay on
# SSE-S3 — copy this pattern to them if your compliance regime requires a CMK
# everywhere.
#
# The interesting part is the key policy, not the key. A CMK in the LogArchive
# account is written to by CloudTrail on behalf of the MANAGEMENT account, and
# read by security engineers in Audit. Three different principals, all of which
# must be named explicitly: KMS denies by default and, unlike IAM, an empty key
# policy locks out everyone including you.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_kms_key" "cloudtrail" {
  provider                = aws.log_archive
  description             = "Encrypts the organization CloudTrail log bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. Without this the key is unmanageable. IAM in the owning account can
      #    never grant access to a key whose policy does not delegate to it.
      {
        Sid       = "EnableIAMUserPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.log_archive_account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },

      # 2. CloudTrail encrypting log files as it writes them. Scoped to trails
      #    belonging to this org so no other account can use the key.
      {
        Sid       = "AllowCloudTrailEncrypt"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:GenerateDataKey*"
        Resource  = "*"
        Condition = {
          StringEquals = { "aws:SourceOrgID" = local.org_id }
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:${local.management_account_id}:trail/*"
          }
        }
      },
      {
        Sid       = "AllowCloudTrailDescribeKey"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:DescribeKey"
        Resource  = "*"
        Condition = {
          StringEquals = { "aws:SourceOrgID" = local.org_id }
        }
      },

      # 3. The Audit account must decrypt to read the logs. Without this,
      #    security engineers see ciphertext and an AccessDenied.
      {
        Sid       = "AllowAuditAccountDecrypt"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.audit_account_id}:root" }
        Action    = ["kms:Decrypt", "kms:DescribeKey"]
        Resource  = "*"
      },
    ]
  })
}

resource "aws_kms_alias" "cloudtrail" {
  provider      = aws.log_archive
  name          = "alias/lz-cloudtrail-logs"
  target_key_id = aws_kms_key.cloudtrail.key_id
}
