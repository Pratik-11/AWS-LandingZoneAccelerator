terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.audit]
    }
  }
}

# 1. Create the SNS Topic
resource "aws_sns_topic" "security_alerts" {
  provider = aws.audit
  name     = "security-hub-critical-alerts"
}

# 2. Allow EventBridge to publish to the SNS Topic
resource "aws_sns_topic_policy" "default" {
  provider = aws.audit
  arn      = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEventBridgePublish"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

# 3. Subscribe the email to the SNS Topic
resource "aws_sns_topic_subscription" "email" {
  provider  = aws.audit
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 4. Create EventBridge Rule to match CRITICAL and HIGH severity findings
resource "aws_cloudwatch_event_rule" "sh_critical_high" {
  provider    = aws.audit
  name        = "security-hub-critical-high-alerts"
  description = "Routes CRITICAL and HIGH severity Security Hub findings to SNS"

  event_pattern = jsonencode({
    source        = ["aws.securityhub"]
    "detail-type" = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL", "HIGH"]
        }
        RecordState = ["ACTIVE"]
        Workflow = {
          Status = ["NEW", "NOTIFIED"]
        }
      }
    }
  })
}

# 5. Route the EventBridge Rule to the SNS Topic
resource "aws_cloudwatch_event_target" "sns" {
  provider  = aws.audit
  rule      = aws_cloudwatch_event_rule.sh_critical_high.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn
}
variable "alert_email" {
  description = "The email address to receive critical security alerts"
  type        = string
}
