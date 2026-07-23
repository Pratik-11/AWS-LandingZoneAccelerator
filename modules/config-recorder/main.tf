terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

variable "existing_role_arn" {
  description = "ARN of an existing Config role to use when create_iam_role is false"
  type        = string
  default     = ""
}

locals {
  config_role_arn = var.create_iam_role ? aws_iam_role.config_role[0].arn : var.existing_role_arn
}



data "aws_iam_policy_document" "config_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "config_role" {
  count              = var.create_iam_role ? 1 : 0
  name               = "AWSConfigRecorderRole"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.config_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "config_s3_delivery" {
  count = var.create_iam_role ? 1 : 0
  name  = "ConfigS3DeliveryPolicy"
  role  = aws_iam_role.config_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          var.config_logs_bucket_arn,
          "${var.config_logs_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_config_configuration_recorder" "this" {
  name     = "default"
  role_arn = local.config_role_arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "default"
  s3_bucket_name = var.config_logs_bucket_name

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}