# ──────────────────────────────────────────────
# Root-Level SCPs (apply to all member accounts)
# ──────────────────────────────────────────────

locals {
  root_id = aws_organizations_organization.org.roots[0].id
}

module "scp_deny_root_user" {
  source = "../../modules/scp"

  name        = "deny-root-user"
  description = "Deny all actions by the root user in member accounts"
  policy_json = file("${path.module}/../../policies/scp/deny-root-user.json")
  target_ids  = [local.root_id]
}

module "scp_deny_leave_org" {
  source = "../../modules/scp"

  name        = "deny-leave-org"
  description = "Deny accounts from leaving the organization"
  policy_json = file("${path.module}/../../policies/scp/deny-leave-org.json")
  target_ids  = [local.root_id]
}

module "scp_deny_disable_cloudtrail" {
  source = "../../modules/scp"

  name        = "deny-disable-cloudtrail"
  description = "Deny disabling or deleting CloudTrail"
  policy_json = file("${path.module}/../../policies/scp/deny-disable-cloudtrail.json")
  target_ids  = [local.root_id]
}

module "scp_deny_disable_config" {
  source = "../../modules/scp"

  name        = "deny-disable-config"
  description = "Deny disabling AWS Config"
  policy_json = file("${path.module}/../../policies/scp/deny-disable-config.json")
  target_ids  = [local.root_id]
}

module "scp_deny_disable_guardduty" {
  source = "../../modules/scp"

  name        = "deny-disable-guardduty"
  description = "Deny disabling GuardDuty"
  policy_json = file("${path.module}/../../policies/scp/deny-disable-guardduty.json")
  target_ids  = [local.root_id]
}

module "scp_restrict_regions" {
  source = "../../modules/scp"

  name        = "restrict-regions"
  description = "Restrict all actions to allowed AWS regions only"
  policy_json = templatefile("${path.module}/../../policies/scp/restrict-regions.json.tpl", {
    allowed_regions = jsonencode(values(var.regions))
  })
  target_ids = [local.root_id]
}

# ──────────────────────────────────────────────
# Security OU SCPs
# ──────────────────────────────────────────────

module "scp_protect_log_archive" {
  source = "../../modules/scp"

  name        = "protect-log-archive"
  description = "Protect log archive S3 buckets from deletion and tampering"
  policy_json = file("${path.module}/../../policies/scp/protect-log-archive.json")
  target_ids  = [module.org_units["Security"].ou_id]
}

# ──────────────────────────────────────────────
# Sandbox OU SCPs
# ──────────────────────────────────────────────

module "scp_deny_expensive_services" {
  source = "../../modules/scp"

  name        = "deny-expensive-services"
  description = "Deny creation of expensive AWS resources in Sandbox"
  policy_json = file("${path.module}/../../policies/scp/deny-expensive-services.json")
  target_ids  = [module.org_units["Sandbox"].ou_id]
}

module "scp_deny_network_bridging" {
  source = "../../modules/scp"

  name        = "deny-network-bridging"
  description = "Deny Sandbox from bridging to other networks"
  policy_json = file("${path.module}/../../policies/scp/deny-network-bridging.json")
  target_ids  = [module.org_units["Sandbox"].ou_id]
}

# ──────────────────────────────────────────────
# Workloads OU SCPs
# ──────────────────────────────────────────────

module "scp_deny_iam_user_creation" {
  source = "../../modules/scp"

  name        = "deny-iam-user-creation"
  description = "Deny creation of IAM users — enforce SSO access"
  policy_json = file("${path.module}/../../policies/scp/deny-iam-user-creation.json")
  target_ids  = [module.org_units["Workloads"].ou_id]
}

# ──────────────────────────────────────────────
# Infrastructure OU SCPs
# ──────────────────────────────────────────────

# Policy to prevent non-authorized modification of networking resources
resource "aws_organizations_policy" "protect_networking" {
  name        = "protect-networking"
  description = "Protect networking resources in the Infrastructure OU"
  content     = file("${path.module}/../../policies/scp/protect-networking.json")
}

# Attach the protect-networking SCP to the Infrastructure OU
resource "aws_organizations_policy_attachment" "protect_networking_attach" {
  policy_id = aws_organizations_policy.protect_networking.id
  target_id = module.org_units["Infrastructure"].ou_id
}

# ──────────────────────────────────────────────
# Security OU SCPs (Additional)
# ──────────────────────────────────────────────

# Policy to prevent tampering with security tooling
resource "aws_organizations_policy" "protect_security_tooling" {
  name        = "protect-security-tooling"
  description = "Protect security tooling in the Security OU"
  content     = file("${path.module}/../../policies/scp/protect-security-tooling.json")
}

# Attach the protect-security-tooling SCP to the Security OU
resource "aws_organizations_policy_attachment" "protect_security_tooling_attach" {
  policy_id = aws_organizations_policy.protect_security_tooling.id
  target_id = module.org_units["Security"].ou_id
}