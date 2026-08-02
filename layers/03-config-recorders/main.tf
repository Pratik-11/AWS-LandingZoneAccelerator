# ──────────────────────────────────────────────────────────────────────────────
# AWS Config recorders — one per account, in the primary region.
#
# Seven near-identical blocks. They cannot be collapsed into a for_each because
# each needs a DIFFERENT provider, and `providers = {}` on a module accepts no
# expressions — only a literal alias. This is the same wall as providers.tf.
# See docs/KNOWN-LIMITS.md §1.
# ──────────────────────────────────────────────────────────────────────────────

module "config_recorder_dev_use1" {
  source    = "../../modules/config-recorder"
  providers = { aws = aws.dev_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_prod_use1" {
  source    = "../../modules/config-recorder"
  providers = { aws = aws.prod_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_audit_use1" {
  source    = "../../modules/config-recorder"
  providers = { aws = aws.audit_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_log_archive_use1" {
  source    = "../../modules/config-recorder"
  providers = { aws = aws.log_archive_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_network_use1" {
  source    = "../../modules/config-recorder"
  providers = { aws = aws.network_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_shared_services_use1" {
  source    = "../../modules/config-recorder"
  providers = { aws = aws.shared_services_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_sandbox_use1" {
  source    = "../../modules/config-recorder"
  providers = { aws = aws.sandbox_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

# ──────────────────────────────────────────────────────────────────────────────
# Second region — ONE worked example.
#
# IAM roles are global, so recording the same account in a second region must
# REUSE the role created above. Creating it again fails with EntityAlreadyExists,
# which is the mistake this block exists to demonstrate.
#
# To record every account in the second region, repeat this for each of the six
# others and add the matching provider aliases. Seven accounts × two regions is
# fourteen blocks; the earlier version of this repo had all fourteen, and they
# taught nothing the first two do not.
# ──────────────────────────────────────────────────────────────────────────────

module "config_recorder_dev_aps1" {
  source    = "../../modules/config-recorder"
  providers = { aws = aws.dev_aps1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn

  create_iam_role   = false
  existing_role_arn = module.config_recorder_dev_use1.config_role_arn
}
