# ──────────────────────────────────────────────
# us-east-1 Config Recorders (renamed)
# ──────────────────────────────────────────────

module "config_recorder_dev_use1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.dev_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
  # create_iam_role defaults to true
}

module "config_recorder_prod_use1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.prod_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_audit_use1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.audit_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_log_archive_use1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.log_archive_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_network_use1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.network_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_shared_services_use1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.shared_services_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_sandbox_use1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.sandbox_use1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

# ──────────────────────────────────────────────
# ap-south-1 Config Recorders (NEW)
# ──────────────────────────────────────────────

module "config_recorder_dev_aps1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.dev_aps1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
  create_iam_role = false
  existing_role_arn = module.config_recorder_dev_use1.config_role_arn
}

module "config_recorder_prod_aps1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.prod_aps1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
  create_iam_role = false
  existing_role_arn = module.config_recorder_prod_use1.config_role_arn
}

module "config_recorder_audit_aps1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.audit_aps1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
  create_iam_role = false
  existing_role_arn = module.config_recorder_audit_use1.config_role_arn
}

module "config_recorder_log_archive_aps1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.log_archive_aps1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
  create_iam_role = false
  existing_role_arn = module.config_recorder_log_archive_use1.config_role_arn
}

module "config_recorder_network_aps1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.network_aps1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
  create_iam_role = false
  existing_role_arn = module.config_recorder_network_use1.config_role_arn
}

module "config_recorder_shared_services_aps1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.shared_services_aps1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
  create_iam_role = false
  existing_role_arn = module.config_recorder_shared_services_use1.config_role_arn
}

module "config_recorder_sandbox_aps1" {
  source    = "../modules/config-recorder"
  providers = { aws = aws.sandbox_aps1 }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
  create_iam_role = false
  existing_role_arn = module.config_recorder_sandbox_use1.config_role_arn
}

# ──────────────────────────────────────────────
# Config Aggregator (runs in the Management Account)
# ──────────────────────────────────────────────
# This creates a single aggregator that pulls Config data
# from ALL accounts in the Organization into one view.


# IAM Role for the Config Aggregator
#data "aws_iam_policy_document" "aggregator_assume" {
#  statement {
#    effect = "Allow"
#    principals {
#      type        = "Service"
#      identifiers = ["config.amazonaws.com"]
#    }
#    actions = ["sts:AssumeRole"]
#  }
#}
#
#resource "aws_iam_role" "config_aggregator_role" {
#  name               = "AWSConfigAggregatorRole"
#  assume_role_policy = data.aws_iam_policy_document.aggregator_assume.json
#}
#
#resource "aws_iam_role_policy_attachment" "aggregator_policy" {
#  role       = aws_iam_role.config_aggregator_role.name
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
#}
#
#
#resource "aws_config_configuration_aggregator" "org_aggregator" {
#  name = "organization-aggregator"
#
#  organization_aggregation_source {
#    all_regions = true
#    role_arn    = aws_iam_role.config_aggregator_role.arn
#  }
#
#  depends_on = [
#    aws_iam_role_policy_attachment.aggregator_policy
#  ]
#}
#
#
#