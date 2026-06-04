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
