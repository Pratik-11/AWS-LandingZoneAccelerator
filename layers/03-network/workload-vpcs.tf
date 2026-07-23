# ──────────────────────────────────────────────
# DEV VPC (us-east-1)
# ──────────────────────────────────────────────
module "dev_vpc_use1" {
  source = "../../modules/vpc"
  providers       = { aws = aws.dev_use1 }
  cidr            = "10.1.0.0/16"
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.11.0/24", "10.1.12.0/24"]
  azs             = ["us-east-1a", "us-east-1b"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev_use1" {
  provider           = aws.dev_use1
  subnet_ids         = module.dev_vpc_use1.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.use1.id
  vpc_id             = module.dev_vpc_use1.vpc_id
  depends_on         = [aws_ram_resource_association.tgw_use1]
}

resource "aws_route" "dev_use1_to_org" {
  provider               = aws.dev_use1
  route_table_id         = module.dev_vpc_use1.private_route_table_id
  destination_cidr_block = "10.0.0.0/8" # Route internal traffic to TGW
  transit_gateway_id     = aws_ec2_transit_gateway.use1.id
}



# ──────────────────────────────────────────────
# PROD VPC (us-east-1) - NO PUBLIC INTERNET
# ──────────────────────────────────────────────
module "prod_vpc_use1" {
  source = "../../modules/vpc"
  providers             = { aws = aws.prod_use1 }
  cidr                  = "10.2.0.0/16"
  private_subnets       = ["10.2.11.0/24", "10.2.12.0/24"]
  azs                   = ["us-east-1a", "us-east-1b"]
  create_public_subnets = false # Critical Prod security control
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod_use1" {
  provider           = aws.prod_use1
  subnet_ids         = module.prod_vpc_use1.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.use1.id
  vpc_id             = module.prod_vpc_use1.vpc_id
  depends_on         = [aws_ram_resource_association.tgw_use1]
}

resource "aws_route" "prod_use1_to_tgw" {
  provider               = aws.prod_use1
  route_table_id         = module.prod_vpc_use1.private_route_table_id
  destination_cidr_block = "0.0.0.0/0" # Egress forced through Network account
  transit_gateway_id     = aws_ec2_transit_gateway.use1.id
}

# ──────────────────────────────────────────────
# REPEAT FOR AP-SOUTH-1
# ──────────────────────────────────────────────

#----------------------------------------------------------
# DEV VPC (ap-south-1)
#----------------------------------------------------------

module "dev_vpc_aps1" {
  source = "../../modules/vpc"
  providers       = { aws = aws.dev_aps1 }
  cidr            = "10.11.0.0/16"
  public_subnets  = ["10.11.1.0/24", "10.11.2.0/24"]
  private_subnets = ["10.11.11.0/24", "10.11.12.0/24"]
  azs             = ["ap-south-1a", "ap-south-1b"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev_aps1" {
  provider           = aws.dev_aps1
  subnet_ids         = module.dev_vpc_aps1.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.aps1.id
  vpc_id             = module.dev_vpc_aps1.vpc_id
  depends_on         = [aws_ram_resource_association.tgw_aps1]
}

resource "aws_route" "dev_aps1_to_org" {
  provider               = aws.dev_aps1
  route_table_id         = module.dev_vpc_aps1.private_route_table_id
  destination_cidr_block = "10.0.0.0/8" # Route internal traffic to TGW
  transit_gateway_id     = aws_ec2_transit_gateway.aps1.id
}

#----------------------------------------------------------
# PROD VPC (ap-south-1)
#----------------------------------------------------------

module "prod_vpc_aps1" {
  source = "../../modules/vpc"
  providers             = { aws = aws.prod_aps1 }
  cidr                  = "10.12.0.0/16"
  private_subnets       = ["10.12.11.0/24", "10.12.12.0/24"]
  azs                   = ["ap-south-1a", "ap-south-1b"]
  create_public_subnets = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod_aps1" {
  provider           = aws.prod_aps1
  subnet_ids         = module.prod_vpc_aps1.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.aps1.id
  vpc_id             = module.prod_vpc_aps1.vpc_id
  depends_on         = [aws_ram_resource_association.tgw_aps1]
}

resource "aws_route" "prod_aps1_to_tgw" {
  provider               = aws.prod_aps1
  route_table_id         = module.prod_vpc_aps1.private_route_table_id
  destination_cidr_block = "0.0.0.0/0" # Egress forced through Network account
  transit_gateway_id     = aws_ec2_transit_gateway.aps1.id
}



# ──────────────────────────────────────────────
# SHARED SERVICES VPC (us-east-1 & ap-south-1)
# ──────────────────────────────────────────────

# TODO: Uncomment when first service is deployed to Shared Services account.
# Current state: account exists but is empty — VPC not needed yet.
# When to enable: CI/CD runners, internal artifact registry, or any
#                 service that workload accounts need to reach over private IP.
#


#----------------------------------------------------------
# SHARED SERVICES VPC (us-east-1)
#----------------------------------------------------------

module "shared_vpc_use1" {
  source = "../../modules/vpc"
  providers       = { aws = aws.shared_use1 }
  cidr            = "10.3.0.0/16"
  public_subnets  = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnets = ["10.3.11.0/24", "10.3.12.0/24"]
  azs             = ["us-east-1a", "us-east-1b"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shared_use1" {
  provider           = aws.shared_use1
  subnet_ids         = module.shared_vpc_use1.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.use1.id
  vpc_id             = module.shared_vpc_use1.vpc_id
  depends_on         = [aws_ram_resource_association.tgw_use1]
}

resource "aws_route" "shared_use1_to_org" {
  provider               = aws.shared_use1
  route_table_id         = module.shared_vpc_use1.private_route_table_id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.use1.id
}

#----------------------------------------------------------
# SHARED SERVICES VPC (ap-south-1)
#----------------------------------------------------------

module "shared_vpc_aps1" {
  source = "../../modules/vpc"
  providers       = { aws = aws.shared_aps1 }
  cidr            = "10.13.0.0/16"
  public_subnets  = ["10.13.1.0/24", "10.13.2.0/24"]
  private_subnets = ["10.13.11.0/24", "10.13.12.0/24"]
  azs             = ["ap-south-1a", "ap-south-1b"]
}
resource "aws_ec2_transit_gateway_vpc_attachment" "shared_aps1" {
  provider           = aws.shared_aps1
  subnet_ids         = module.shared_vpc_aps1.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.aps1.id
  vpc_id             = module.shared_vpc_aps1.vpc_id
  depends_on         = [aws_ram_resource_association.tgw_aps1]
}
resource "aws_route" "shared_aps1_to_org" {
  provider               = aws.shared_aps1
  route_table_id         = module.shared_vpc_aps1.private_route_table_id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.aps1.id
}
