locals {
  # ────────────────────────────────────────────────────────────────────────────
  # Account Assignment Matrix
  # Format: "group-permissionset-account" = { group_id, permission_set_arn, account_id }
  # ────────────────────────────────────────────────────────────────────────────
  account_assignments = {

    # ── PlatformEngineers → AdministratorAccess → ALL accounts ──────────────
    "platform-admin-management"    = {
      group_id = aws_identitystore_group.platform_engineers.group_id
      ps_arn   = aws_ssoadmin_permission_set.admin.arn
      account  = local.management_account_id
    }
    "platform-admin-audit" = {
      group_id = aws_identitystore_group.platform_engineers.group_id
      ps_arn   = aws_ssoadmin_permission_set.admin.arn
      account  = local.audit_account_id
    }
    "platform-admin-logarchive" = {
      group_id = aws_identitystore_group.platform_engineers.group_id
      ps_arn   = aws_ssoadmin_permission_set.admin.arn
      account  = local.log_archive_account_id
    }
    "platform-admin-network" = {
      group_id = aws_identitystore_group.platform_engineers.group_id
      ps_arn   = aws_ssoadmin_permission_set.admin.arn
      account  = local.network_account_id
    }
    "platform-admin-sharedsvc" = {
      group_id = aws_identitystore_group.platform_engineers.group_id
      ps_arn   = aws_ssoadmin_permission_set.admin.arn
      account  = local.shared_services_account_id
    }
    "platform-admin-dev" = {
      group_id = aws_identitystore_group.platform_engineers.group_id
      ps_arn   = aws_ssoadmin_permission_set.admin.arn
      account  = local.dev_account_id
    }
    "platform-admin-prod" = {
      group_id = aws_identitystore_group.platform_engineers.group_id
      ps_arn   = aws_ssoadmin_permission_set.admin.arn
      account  = local.prod_account_id
    }
    "platform-admin-sandbox" = {
      group_id = aws_identitystore_group.platform_engineers.group_id
      ps_arn   = aws_ssoadmin_permission_set.admin.arn
      account  = local.sandbox_account_id
    }

    # ── Developers → DeveloperAccess → Dev + Sandbox ────────────────────────
    "dev-developer-dev" = {
      group_id = aws_identitystore_group.developers.group_id
      ps_arn   = aws_ssoadmin_permission_set.developer.arn
      account  = local.dev_account_id
    }
    "dev-developer-sandbox" = {
      group_id = aws_identitystore_group.developers.group_id
      ps_arn   = aws_ssoadmin_permission_set.developer.arn
      account  = local.sandbox_account_id
    }

    # ── Developers → ReadOnlyAccess → Prod ──────────────────────────────────
    "dev-readonly-prod" = {
      group_id = aws_identitystore_group.developers.group_id
      ps_arn   = aws_ssoadmin_permission_set.read_only.arn
      account  = local.prod_account_id
    }

    # ── SecurityTeam → SecurityAuditAccess → All accounts except management ─
    "security-audit-audit" = {
      group_id = aws_identitystore_group.security_team.group_id
      ps_arn   = aws_ssoadmin_permission_set.security_audit.arn
      account  = local.audit_account_id
    }
    "security-audit-logarchive" = {
      group_id = aws_identitystore_group.security_team.group_id
      ps_arn   = aws_ssoadmin_permission_set.security_audit.arn
      account  = local.log_archive_account_id
    }
    "security-audit-network" = {
      group_id = aws_identitystore_group.security_team.group_id
      ps_arn   = aws_ssoadmin_permission_set.security_audit.arn
      account  = local.network_account_id
    }
    "security-audit-sharedsvc" = {
      group_id = aws_identitystore_group.security_team.group_id
      ps_arn   = aws_ssoadmin_permission_set.security_audit.arn
      account  = local.shared_services_account_id
    }
    "security-audit-dev" = {
      group_id = aws_identitystore_group.security_team.group_id
      ps_arn   = aws_ssoadmin_permission_set.security_audit.arn
      account  = local.dev_account_id
    }
    "security-audit-prod" = {
      group_id = aws_identitystore_group.security_team.group_id
      ps_arn   = aws_ssoadmin_permission_set.security_audit.arn
      account  = local.prod_account_id
    }
    "security-audit-sandbox" = {
      group_id = aws_identitystore_group.security_team.group_id
      ps_arn   = aws_ssoadmin_permission_set.security_audit.arn
      account  = local.sandbox_account_id
    }

    # ── Finance → BillingAccess → Management account only ───────────────────
    "finance-billing-management" = {
      group_id = aws_identitystore_group.finance.group_id
      ps_arn   = aws_ssoadmin_permission_set.billing.arn
      account  = local.management_account_id
    }
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.account_assignments

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.ps_arn

  principal_id   = each.value.group_id
  principal_type = "GROUP"

  target_id   = each.value.account
  target_type = "AWS_ACCOUNT"
}