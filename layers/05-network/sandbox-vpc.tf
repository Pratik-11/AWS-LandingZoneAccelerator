module "sandbox_use1" {
  source          = "../../modules/vpc"
  providers       = { aws = aws.sandbox_use1 }
  cidr            = "10.9.0.0/16"
  public_subnets  = ["10.9.1.0/24"]
  private_subnets = ["10.9.11.0/24"]
  azs             = ["${local.allowed_regions.primary}a"]
}

module "sandbox_aps1" {
  source          = "../../modules/vpc"
  providers       = { aws = aws.sandbox_aps1 }
  cidr            = "10.19.0.0/16"
  public_subnets  = ["10.19.1.0/24"]
  private_subnets = ["10.19.11.0/24"]
  azs             = ["${local.allowed_regions.secondary}a"]
}