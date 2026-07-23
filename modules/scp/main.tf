# ──────────────────────────────────────────────────────────────────────────────
# Persona toggle — controls WHICH SCPs are active based on landing_zone_type.
# startup    → baseline safety SCPs only (lowest friction)
# enterprise → startup + region restriction + encryption hygiene (default)
# regulated  → enterprise + stricter network egress controls
# ──────────────────────────────────────────────────────────────────────────────
locals {
  # Baseline SCPs every tier shares
  startup_scps = [
    "deny-leave-org",
    "deny-root-actions",
    "deny-disable-security-services",
    "protect-logging-buckets",
    "deny-public-s3",
  ]

  # Enterprise adds region control and encryption hygiene on top of startup
  enterprise_scps = concat(local.startup_scps, [
    "restrict-regions",
    "require-imdsv2",
    "require-ebs-encryption",
    "deny-unencrypted-rds",
  ])

  # Regulated adds network egress control on top of enterprise
  regulated_scps = concat(local.enterprise_scps, [
    "deny-vpc-internet-without-approval",
  ])

  # Resolve the active set based on the chosen persona
  active_scps = (
    var.landing_zone_type == "startup"   ? local.startup_scps :
    var.landing_zone_type == "regulated" ? local.regulated_scps :
    local.enterprise_scps
  )
}

# Creates the SCP policy document in AWS Organizations.
resource "aws_organizations_policy" "this" {
  # Only create this policy if its name is in the active_scps list for the chosen persona.
  count = contains(local.active_scps, var.name) ? 1 : 0

  name        = var.name
  description = var.description
  content     = var.policy_json
  type        = "SERVICE_CONTROL_POLICY"
}

# Attaches the SCP to each target OU or account — only if the policy was created.
resource "aws_organizations_policy_attachment" "this" {
  for_each = length(aws_organizations_policy.this) > 0 ? toset(var.target_ids) : toset([])

  policy_id = aws_organizations_policy.this[0].id
  target_id = each.value
}