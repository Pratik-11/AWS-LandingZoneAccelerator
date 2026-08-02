terraform {
  required_version = ">= 1.5"
}

provider "aws" {
  profile = var.terraform-profile
  region  = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Layer     = "01-organization"
    }
  }
}
