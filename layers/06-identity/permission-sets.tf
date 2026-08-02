# ══════════════════════════════════════════════════════════════════════════════
# PowerUserAccess (Platform Engineers)
# ══════════════════════════════════════════════════════════════════════════════
resource "aws_ssoadmin_permission_set" "power" {
  name             = "PowerUserAccess"
  description      = "Power user access - platform engineers"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT1H"
  tags             = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "power" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.power.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# ══════════════════════════════════════════════════════════════════════════════
# ReadOnlyAccess
# ══════════════════════════════════════════════════════════════════════════════
resource "aws_ssoadmin_permission_set" "read_only" {
  name             = "ReadOnlyAccess"
  description      = "Read-only access for auditors and cross-account visibility"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
  tags             = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ══════════════════════════════════════════════════════════════════════════════
# DeveloperAccess (custom policy created)
# ══════════════════════════════════════════════════════════════════════════════
resource "aws_ssoadmin_permission_set" "developer" {
  name             = "DeveloperAccess"
  description      = "Developer access - compute, storage, monitoring. No IAM, no billing."
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
  tags             = var.tags
}

resource "aws_ssoadmin_permission_set_inline_policy" "developer" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ComputeAccess"
        Effect = "Allow"
        Action = [
          "ec2:*", "ecs:*", "eks:Describe*", "eks:List*", "lambda:*", "autoscaling:*"
        ]
        Resource = "*"
      },
      {
        Sid      = "StorageAccess"
        Effect   = "Allow"
        Action   = ["s3:*", "rds:*", "dynamodb:*", "elasticache:*"]
        Resource = "*"
      },
      {
        Sid      = "ObservabilityAccess"
        Effect   = "Allow"
        Action   = ["cloudwatch:*", "logs:*", "xray:*", "cloudformation:*"]
        Resource = "*"
      },
      {
        Sid      = "MessagingAccess"
        Effect   = "Allow"
        Action   = ["sns:*", "sqs:*", "events:*"]
        Resource = "*"
      },
      {
        Sid    = "DenyIAMWrite"
        Effect = "Deny"
        Action = [
          "iam:Create*", "iam:Delete*", "iam:Attach*", "iam:Detach*", "iam:Put*", "iam:Update*", "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile"
        ]
        Resource = "*"
      },
      {
        Sid      = "DenyBilling"
        Effect   = "Deny"
        Action   = ["aws-portal:*", "budgets:*", "ce:*", "cur:*", "billing:*"]
        Resource = "*"
      },
      {
        Sid      = "DenyOrganizationActions"
        Effect   = "Deny"
        Action   = ["organizations:*"]
        Resource = "*"
      }
    ]
  })
}

# ══════════════════════════════════════════════════════════════════════════════
# SecurityAuditAccess
# ══════════════════════════════════════════════════════════════════════════════
resource "aws_ssoadmin_permission_set" "security_audit" {
  name             = "SecurityAuditAccess"
  description      = "Security team - read security findings, no modifications"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
  tags             = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "security_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# Additional managed policy for GuardDuty/SecurityHub read access
resource "aws_ssoadmin_managed_policy_attachment" "security_audit_guardduty" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AmazonGuardDutyReadOnlyAccess"
}

# ══════════════════════════════════════════════════════════════════════════════
# BillingAccess
# ══════════════════════════════════════════════════════════════════════════════
resource "aws_ssoadmin_permission_set" "billing" {
  name             = "BillingAccess"
  description      = "Finance team - billing and cost management only"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
  tags             = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "billing" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.billing.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess"
}
