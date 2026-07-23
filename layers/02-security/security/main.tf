# ──────────────────────────────────────────────
# GuardDuty Deployment (Multi-Region)
# ──────────────────────────────────────────────

module "guardduty_use1" {
  source           = "../modules/security-guardduty"
  audit_account_id = local.audit_account_id
  
  providers = {
    aws.management = aws.management_use1
    aws.audit      = aws.audit_use1
  }
}

module "guardduty_aps1" {
  source           = "../modules/security-guardduty"
  audit_account_id = local.audit_account_id
  
  providers = {
    aws.management = aws.management_aps1
    aws.audit      = aws.audit_aps1
  }
}

# ──────────────────────────────────────────────
# Security Hub Deployment (Multi-Region)
# ──────────────────────────────────────────────

module "securityhub_use1" {
  source           = "../modules/security-securityhub"
  audit_account_id = local.audit_account_id
  
  providers = {
    aws.management = aws.management_use1
    aws.audit      = aws.audit_use1
  }
}

module "securityhub_aps1" {
  source           = "../modules/security-securityhub"
  audit_account_id = local.audit_account_id
  
  providers = {
    aws.management = aws.management_aps1
    aws.audit      = aws.audit_aps1
  }
}

# ──────────────────────────────────────────────
# Security Hub Cross-Region Aggregation
# ──────────────────────────────────────────────
# This pulls all findings from ap-south-1 (and any future regions) 
# into us-east-1 inside the Audit account.

resource "aws_securityhub_finding_aggregator" "global_aggregator" {
  provider     = aws.audit_use1
  linking_mode = "ALL_REGIONS"
  
  depends_on = [
    module.securityhub_use1,
    module.securityhub_aps1
  ]
}


# ──────────────────────────────────────────────
# IAM Access Analyzer Delegation (Global)
# ──────────────────────────────────────────────

resource "aws_iam_service_linked_role" "access_analyzer" {
  aws_service_name = "access-analyzer.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "analyzer_admin" {
  account_id        = local.audit_account_id
  service_principal = "access-analyzer.amazonaws.com"
}


# ──────────────────────────────────────────────
# IAM Access Analyzer Deployment (Multi-Region)
# ──────────────────────────────────────────────

module "access_analyzer_use1" {
  source           = "../modules/security-access-analyzer"
  audit_account_id = local.audit_account_id
  
  providers = {
    aws.audit = aws.audit_use1
  }

  depends_on = [
    aws_organizations_delegated_administrator.analyzer_admin,
    aws_iam_service_linked_role.access_analyzer
  ]
}

module "access_analyzer_aps1" {
  source           = "../modules/security-access-analyzer"
  audit_account_id = local.audit_account_id
  
  providers = {
    aws.audit = aws.audit_aps1
  }

  depends_on = [
    aws_organizations_delegated_administrator.analyzer_admin,
    aws_iam_service_linked_role.access_analyzer
  ]
}

# ──────────────────────────────────────────────
# Amazon Inspector Deployment (Multi-Region)
# ──────────────────────────────────────────────

module "inspector_use1" {
  source           = "../modules/security-inspector"
  audit_account_id = local.audit_account_id
  all_account_ids  = local.all_account_ids
  
  providers = {
    aws.management = aws.management_use1
    aws.audit      = aws.audit_use1
  }
}

module "inspector_aps1" {
  source           = "../modules/security-inspector"
  audit_account_id = local.audit_account_id
  all_account_ids  = local.all_account_ids
  
  providers = {
    aws.management = aws.management_aps1
    aws.audit      = aws.audit_aps1
  }
}

# ──────────────────────────────────────────────
# Security Alerting (SNS & EventBridge)
# ──────────────────────────────────────────────

module "alerts" {
  source      = "../modules/security-alerts"
  alert_email = var.alert_email
  
  providers = {
    aws.audit = aws.audit_use1
  }
}