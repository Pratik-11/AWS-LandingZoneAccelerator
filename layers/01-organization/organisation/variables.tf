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

variable "accounts" {
  description = "A map of accounts to be created, specifying their email and the parent OU name."
  type = map(object({
    email   = string
    ou_name = string
  }))
}

variable "allowed_regions" {
  description = "List of AWS regions that are permitted across the organization"
  type        = list(string)
  default     = ["us-east-1"]
}