# ──────────────────────────────────────────────
# Deploy AWS Config Recorder into each member account
# ──────────────────────────────────────────────

module "config_recorder_dev" {
  source    = "../modules/cofig-recorder"
  providers = { aws = aws.dev }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_prod" {
  source    = "../modules/cofig-recorder"
  providers = { aws = aws.prod }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_audit" {
  source    = "../modules/cofig-recorder"
  providers = { aws = aws.audit }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_log_archive" {
  source    = "../modules/cofig-recorder"
  providers = { aws = aws.log_archive }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_network" {
  source    = "../modules/cofig-recorder"
  providers = { aws = aws.network }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_shared_services" {
  source    = "../modules/cofig-recorder"
  providers = { aws = aws.shared_services }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

module "config_recorder_sandbox" {
  source    = "../modules/cofig-recorder"
  providers = { aws = aws.sandbox }

  config_logs_bucket_name = local.config_bucket_id
  config_logs_bucket_arn  = local.config_bucket_arn
}

# ──────────────────────────────────────────────
# Config Aggregator (runs in the Management Account)
# ──────────────────────────────────────────────
# This creates a single aggregator that pulls Config data
# from ALL accounts in the Organization into one view.

resource "aws_config_configuration_aggregator" "org_aggregator" {
  name = "organization-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator_role.arn
  }

  depends_on = [
    module.config_recorder_dev,
    module.config_recorder_prod,
    module.config_recorder_audit,
    module.config_recorder_log_archive,
    module.config_recorder_network,
    module.config_recorder_shared_services,
    module.config_recorder_sandbox
  ]
}

# IAM Role for the Config Aggregator
data "aws_iam_policy_document" "aggregator_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "config_aggregator_role" {
  name               = "AWSConfigAggregatorRole"
  assume_role_policy = data.aws_iam_policy_document.aggregator_assume.json
}

resource "aws_iam_role_policy_attachment" "aggregator_policy" {
  role       = aws_iam_role.config_aggregator_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}