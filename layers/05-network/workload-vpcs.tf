# ──────────────────────────────────────────────
# DEV VPC — public + private subnets, egress via its own NAT
# ──────────────────────────────────────────────
module "dev_vpc_use1" {
  source          = "../../modules/vpc"
  providers       = { aws = aws.dev_use1 }
  cidr            = "10.1.0.0/16"
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.11.0/24", "10.1.12.0/24"]
  azs             = ["${local.allowed_regions.primary}a", "${local.allowed_regions.primary}b"]

  flow_logs_destination_arn = local.flow_logs_bucket_arn
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev_use1" {
  provider           = aws.dev_use1
  subnet_ids         = module.dev_vpc_use1.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.use1.id
  vpc_id             = module.dev_vpc_use1.vpc_id
  depends_on         = [aws_ram_resource_association.tgw_use1]
}

# Only org-internal traffic (10/8) goes to the TGW. Everything else exits
# through this VPC's own NAT gateway.
resource "aws_route" "dev_use1_to_org" {
  provider               = aws.dev_use1
  route_table_id         = module.dev_vpc_use1.private_route_table_id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.use1.id
}

# ──────────────────────────────────────────────
# PROD VPC — private only, no IGW, no NAT
# ──────────────────────────────────────────────
module "prod_vpc_use1" {
  source                = "../../modules/vpc"
  providers             = { aws = aws.prod_use1 }
  cidr                  = "10.2.0.0/16"
  private_subnets       = ["10.2.11.0/24", "10.2.12.0/24"]
  azs                   = ["${local.allowed_regions.primary}a", "${local.allowed_regions.primary}b"]
  create_public_subnets = false # the Prod security control that matters most

  flow_logs_destination_arn = local.flow_logs_bucket_arn
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod_use1" {
  provider           = aws.prod_use1
  subnet_ids         = module.prod_vpc_use1.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.use1.id
  vpc_id             = module.prod_vpc_use1.vpc_id
  depends_on         = [aws_ram_resource_association.tgw_use1]
}

# ⚠️ Prod has no NAT, so its DEFAULT route points at the TGW — all egress is
# meant to leave through the Network account.
#
# This only reaches the internet if the Network account actually runs NAT or a
# firewall in an egress VPC AND the TGW route tables forward to it. Neither is
# built in this repo. Until you add that, Prod egress black-holes here.
# See docs/KNOWN-LIMITS.md §4.
resource "aws_route" "prod_use1_to_tgw" {
  provider               = aws.prod_use1
  route_table_id         = module.prod_vpc_use1.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.use1.id
}

# ──────────────────────────────────────────────
# SHARED SERVICES VPC — CI runners, artifact registries, internal tooling
# ──────────────────────────────────────────────
module "shared_vpc_use1" {
  source          = "../../modules/vpc"
  providers       = { aws = aws.shared_use1 }
  cidr            = "10.3.0.0/16"
  public_subnets  = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnets = ["10.3.11.0/24", "10.3.12.0/24"]
  azs             = ["${local.allowed_regions.primary}a", "${local.allowed_regions.primary}b"]

  flow_logs_destination_arn = local.flow_logs_bucket_arn
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
