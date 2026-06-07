terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.audit]
    }
  }
}

# Create the Organization Analyzer in the Audit Account
resource "aws_accessanalyzer_analyzer" "org_analyzer" {
  provider      = aws.audit
  analyzer_name = "organization-access-analyzer"
  type          = "ORGANIZATION"
}