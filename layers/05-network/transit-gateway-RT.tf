# ──────────────────────────────────────────────
# US-EAST-1 TRANSIT GATEWAY ROUTE TABLES
# ──────────────────────────────────────────────

# 1. Hub Route Table (Network Account)
resource "aws_ec2_transit_gateway_route_table" "hub_use1" {
  provider           = aws.network_use1
  transit_gateway_id = aws_ec2_transit_gateway.use1.id
  tags               = { Name = "TGW-Hub-RT-use1" }
}

# 2. Dev Route Table
resource "aws_ec2_transit_gateway_route_table" "dev_use1" {
  provider           = aws.network_use1
  transit_gateway_id = aws_ec2_transit_gateway.use1.id
  tags               = { Name = "TGW-Dev-RT-use1" }
}

# 3. Prod Route Table
resource "aws_ec2_transit_gateway_route_table" "prod_use1" {
  provider           = aws.network_use1
  transit_gateway_id = aws_ec2_transit_gateway.use1.id
  tags               = { Name = "TGW-Prod-RT-use1" }
}

# 4. Shared Services Route Table
resource "aws_ec2_transit_gateway_route_table" "shared_use1" {
  provider           = aws.network_use1
  transit_gateway_id = aws_ec2_transit_gateway.use1.id
  tags               = { Name = "TGW-SharedServices-RT-use1" }
}


# ──────────────────────────────────────────────
# HUB RT (us-east-1): Associations, Propagations, and Routes
# ──────────────────────────────────────────────
resource "aws_ec2_transit_gateway_route_table_association" "hub_use1_net" {
  provider                       = aws.network_use1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_use1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_use1.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "hub_use1_net" {
  provider                       = aws.network_use1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_use1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_use1.id
}

resource "aws_ec2_transit_gateway_route" "hub_use1_to_dev" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_use1.id
  destination_cidr_block         = "10.1.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_use1.id
}

resource "aws_ec2_transit_gateway_route" "hub_use1_to_prod" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_use1.id
  destination_cidr_block         = "10.2.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod_use1.id
}


resource "aws_ec2_transit_gateway_route" "hub_use1_to_shared" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_use1.id
  destination_cidr_block         = "10.3.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_use1.id
}


# ──────────────────────────────────────────────
# DEV RT (us-east-1): Associations, Propagations, and Routes
# ──────────────────────────────────────────────
resource "aws_ec2_transit_gateway_route_table_association" "dev_use1_dev" {
  provider                       = aws.network_use1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_use1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev_use1.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "dev_use1_dev" {
  provider                       = aws.network_use1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_use1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev_use1.id
}

resource "aws_ec2_transit_gateway_route" "dev_use1_to_net" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev_use1.id
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_use1.id
}


resource "aws_ec2_transit_gateway_route" "dev_use1_to_shared" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev_use1.id
  destination_cidr_block         = "10.3.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_use1.id
}


# ──────────────────────────────────────────────
# PROD RT (us-east-1): Associations, Propagations, and Routes
# ──────────────────────────────────────────────
resource "aws_ec2_transit_gateway_route_table_association" "prod_use1_prod" {
  provider                       = aws.network_use1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod_use1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_use1.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "prod_use1_prod" {
  provider                       = aws.network_use1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod_use1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_use1.id
}

resource "aws_ec2_transit_gateway_route" "prod_use1_to_net" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_use1.id
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_use1.id
}

resource "aws_ec2_transit_gateway_route" "prod_use1_to_inet" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_use1.id
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_use1.id
}


resource "aws_ec2_transit_gateway_route" "prod_use1_to_shared" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_use1.id
  destination_cidr_block         = "10.3.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_use1.id
}


# ──────────────────────────────────────────────
# SHARED SERVICES RT (us-east-1): Associations, Propagations, and Routes
# ──────────────────────────────────────────────

resource "aws_ec2_transit_gateway_route_table_association" "shared_use1_shared" {
  provider                       = aws.network_use1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_use1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_use1.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared_use1_shared" {
  provider                       = aws.network_use1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_use1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_use1.id
}

resource "aws_ec2_transit_gateway_route" "shared_use1_to_net" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_use1.id
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_use1.id
}

resource "aws_ec2_transit_gateway_route" "shared_use1_to_dev" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_use1.id
  destination_cidr_block         = "10.1.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_use1.id
}
