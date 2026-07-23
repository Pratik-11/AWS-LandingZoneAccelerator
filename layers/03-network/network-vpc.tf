module "network_vpc_use1" {
  source = "../../modules/vpc"
  providers       = { aws = aws.network_use1 }
  cidr            = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  azs             = ["us-east-1a", "us-east-1b"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "net_use1" {
  provider           = aws.network_use1
  subnet_ids         = module.network_vpc_use1.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.use1.id
  vpc_id             = module.network_vpc_use1.vpc_id
}

module "network_vpc_aps1" {
  source = "../../modules/vpc"
  providers       = { aws = aws.network_aps1 }
  cidr            = "10.10.0.0/16"
  public_subnets  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnets = ["10.10.11.0/24", "10.10.12.0/24"]
  azs             = ["ap-south-1a", "ap-south-1b"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "net_aps1" {
  provider           = aws.network_aps1
  subnet_ids         = module.network_vpc_aps1.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.aps1.id
  vpc_id             = module.network_vpc_aps1.vpc_id
}