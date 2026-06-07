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


#
#module "inspector" {
#  source           = "../modules/security-inspector"
#  audit_account_id = local.audit_account_id
#  all_account_ids  = local.all_account_ids
#  providers = {
#    aws       = aws
#    aws.audit = aws.audit
#  }
#}
#
#module "access_analyzer" {
#  source           = "../modules/security-access-analyzer"
#  audit_account_id = local.audit_account_id
#  providers = {
#    aws       = aws
#    aws.audit = aws.audit
#  }
#}
#
#module "alerts" {
#  source      = "../modules/security-alerts"
#  alert_email = var.alert_email
#  providers = {
#    aws       = aws
#    aws.audit = aws.audit
#  }
#}