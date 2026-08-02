# Every service below follows the same two-step: enable it from the MANAGEMENT
# account, then administer it from AUDIT. Each module takes both providers for
# exactly that reason.

# ──────────────────────────────────────────────
# GuardDuty
# ──────────────────────────────────────────────
module "guardduty" {
  source           = "../../modules/security-guardduty"
  audit_account_id = local.audit_account_id

  providers = {
    aws.management = aws.management_use1
    aws.audit      = aws.audit_use1
  }
}

# ──────────────────────────────────────────────
# Security Hub
# ──────────────────────────────────────────────
module "securityhub" {
  source           = "../../modules/security-securityhub"
  audit_account_id = local.audit_account_id

  providers = {
    aws.management = aws.management_use1
    aws.audit      = aws.audit_use1
  }
}

# Pulls findings from every region into the primary one, inside Audit. Worth
# keeping even in a single-region deployment: Security Hub still reports from
# regions you never deploy to, and those are the interesting ones.
resource "aws_securityhub_finding_aggregator" "global_aggregator" {
  provider     = aws.audit_use1
  linking_mode = "ALL_REGIONS"

  depends_on = [module.securityhub]
}

# ──────────────────────────────────────────────
# IAM Access Analyzer
# ──────────────────────────────────────────────

resource "aws_iam_service_linked_role" "access_analyzer" {
  aws_service_name = "access-analyzer.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "analyzer_admin" {
  account_id        = local.audit_account_id
  service_principal = "access-analyzer.amazonaws.com"
}

# Plain resource, not a module — it is one resource with no configuration to
# bundle. The depends_on is load-bearing: delegation and the service-linked role
# must both exist first, and IAM propagation is not instant.
resource "aws_accessanalyzer_analyzer" "org" {
  provider      = aws.audit_use1
  analyzer_name = "organization-access-analyzer"
  type          = "ORGANIZATION"

  depends_on = [
    aws_organizations_delegated_administrator.analyzer_admin,
    aws_iam_service_linked_role.access_analyzer
  ]
}

# ──────────────────────────────────────────────
# Amazon Inspector
# ──────────────────────────────────────────────
module "inspector" {
  source           = "../../modules/security-inspector"
  audit_account_id = local.audit_account_id
  all_account_ids  = local.all_account_ids

  providers = {
    aws.management = aws.management_use1
    aws.audit      = aws.audit_use1
  }
}

# ──────────────────────────────────────────────
# Alerting — SNS + EventBridge, in Audit
# ──────────────────────────────────────────────
module "alerts" {
  source      = "../../modules/security-alerts"
  alert_email = var.alert_email

  providers = {
    aws.audit = aws.audit_use1
  }
}
