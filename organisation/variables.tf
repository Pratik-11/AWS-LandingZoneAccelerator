variable "aws_region" {
  type = string
}

variable "terraform-profile"{
    type = string
}

# Define a single variable that holds all desired OU names
variable "ou_names" {
  description = "A set of Organizational Unit names to be created under the root"
  type        = set(string)
  default     = [
    "Security",
    "Infrastructure",
    "Sandbox",
    "Workloads"
  ]
}

variable "network_account_email" {
  type = string
}

variable "shared_services_account_email" {
  type = string
}

variable "audit_account_email" {
  type = string
}

variable "log_archive_account_email" {
  type = string
}

variable "sandbox_account_email" {
  type = string
}

variable "dev_account_email" {
  type = string
}

variable "prod_account_email" {
  type = string
}