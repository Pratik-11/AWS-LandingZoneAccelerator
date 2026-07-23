# 1. Create the CloudTrail Bucket IN THE LOG ARCHIVE ACCOUNT
module "cloudtrail_bucket" {
  source = "../../modules/logging-bucket"
  
  # Tell Terraform to use the log_archive provider for this module
  providers = {
    aws = aws.log_archive
  }

  bucket_name       = var.cloudtrail_bucket_name
  org_id            = data.terraform_remote_state.org.outputs.org_id
  service_type = "cloudtrail" 
}

# 2. Create the Config Bucket IN THE LOG ARCHIVE ACCOUNT
module "config_bucket" {
  source = "../../modules/logging-bucket"

  providers = {
    aws = aws.log_archive
  }

  bucket_name       = var.config_bucket_name
  org_id            = data.terraform_remote_state.org.outputs.org_id
  service_type = "config"
}

# 3. Create Organization CloudTrail IN THE MANAGEMENT ACCOUNT
resource "aws_cloudtrail" "org_trail" {
  name                          = "organization-audit-trail"
  s3_bucket_name                = module.cloudtrail_bucket.bucket_id
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true # This flag Applies to ALL accounts.
  enable_log_file_validation    = true

  depends_on = [module.cloudtrail_bucket]
}