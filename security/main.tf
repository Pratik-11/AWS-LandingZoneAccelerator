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

#module "securityhub" {
#  source           = "../modules/security-securityhub"
#  audit_account_id = local.audit_account_id
#  providers = {
#    aws       = aws
#    aws.audit = aws.audit
#  }
#}
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