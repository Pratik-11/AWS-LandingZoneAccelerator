# All three buckets live in the LogArchive account, so a compromised workload
# account cannot reach the evidence. That separation is the entire reason a
# dedicated log archive account exists.

# 1. CloudTrail — every API call in the organization.
module "cloudtrail_bucket" {
  source    = "../../modules/logging-bucket"
  providers = { aws = aws.log_archive }

  bucket_name  = var.cloudtrail_bucket_name
  org_id       = local.org_id
  service_type = "cloudtrail"
  kms_key_arn  = aws_kms_key.cloudtrail.arn
}

# 2. Config — resource configuration history, written by 03-config-recorders.
module "config_bucket" {
  source    = "../../modules/logging-bucket"
  providers = { aws = aws.log_archive }

  bucket_name  = var.config_bucket_name
  org_id       = local.org_id
  service_type = "config"
}

# 3. VPC flow logs — consumed by 05-network.
module "flow_logs_bucket" {
  source    = "../../modules/logging-bucket"
  providers = { aws = aws.log_archive }

  bucket_name  = var.flow_logs_bucket_name
  org_id       = local.org_id
  service_type = "flow-logs"
}

# 4. The organization trail itself, created FROM the management account.
#
# Only the management account can set is_organization_trail, and that single
# flag is what captures every member account with no per-account setup. The
# trail lives here; the bucket lives in LogArchive. That split is the point.
resource "aws_cloudtrail" "org_trail" {
  name                          = "organization-audit-trail"
  s3_bucket_name                = module.cloudtrail_bucket.bucket_id
  kms_key_id                    = aws_kms_key.cloudtrail.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_log_file_validation    = true

  depends_on = [module.cloudtrail_bucket]
}
