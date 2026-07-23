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

# Hub RT Peering Route - Directs all ap-south-1 traffic (10.8.0.0/13 supernet covers 10.8 to 10.15) over the peering attachment
resource "aws_ec2_transit_gateway_route" "hub_use1_peering" {
  provider                       = aws.network_use1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_use1.id
  destination_cidr_block         = "10.8.0.0/13"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.global_peer.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.global_peer_accepter]
}


# Adjusted your aps1 supernet to 10.8.0.0/13 instead of 10.10.0.0/14. This is because 10.10.0.0/14 is mathematically invalid as a network address in AWS 
# (AWS would throw an "invalid CIDR block" error). A /13 mask starting at 10.8.0.0 perfectly covers 10.8.x.x through 10.15.x.x, which cleanly encapsulates 
# all your aps1 VPCs (10.10 through 10.13)!

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




# ──────────────────────────────────────────────
# AP-SOUTH-1 TRANSIT GATEWAY ROUTE TABLES
# ──────────────────────────────────────────────

# 1. Hub Route Table (Network Account)
resource "aws_ec2_transit_gateway_route_table" "hub_aps1" {
  provider           = aws.network_aps1
  transit_gateway_id = aws_ec2_transit_gateway.aps1.id
  tags               = { Name = "TGW-Hub-RT-aps1" }
}

# 2. Dev Route Table
resource "aws_ec2_transit_gateway_route_table" "dev_aps1" {
  provider           = aws.network_aps1
  transit_gateway_id = aws_ec2_transit_gateway.aps1.id
  tags               = { Name = "TGW-Dev-RT-aps1" }
}

# 3. Prod Route Table
resource "aws_ec2_transit_gateway_route_table" "prod_aps1" {
  provider           = aws.network_aps1
  transit_gateway_id = aws_ec2_transit_gateway.aps1.id
  tags               = { Name = "TGW-Prod-RT-aps1" }
}

# 4. Shared Services Route Table
resource "aws_ec2_transit_gateway_route_table" "shared_aps1" {
  provider           = aws.network_aps1
  transit_gateway_id = aws_ec2_transit_gateway.aps1.id
  tags               = { Name = "TGW-SharedServices-RT-aps1" }
}

# Hub RT Peering Route - Directs all us-east-1 traffic (10.0.0.0/14 supernet covers 10.0 to 10.3) over the peering attachment
resource "aws_ec2_transit_gateway_route" "hub_aps1_peering" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_aps1.id
  destination_cidr_block         = "10.0.0.0/14"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.global_peer.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.global_peer_accepter]
}

# ──────────────────────────────────────────────
# HUB RT (ap-south-1): Associations, Propagations, and Routes
# ──────────────────────────────────────────────
resource "aws_ec2_transit_gateway_route_table_association" "hub_aps1_net" {
  provider                       = aws.network_aps1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_aps1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_aps1.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "hub_aps1_net" {
  provider                       = aws.network_aps1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_aps1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_aps1.id
}

resource "aws_ec2_transit_gateway_route" "hub_aps1_to_dev" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_aps1.id
  destination_cidr_block         = "10.11.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_aps1.id
}

resource "aws_ec2_transit_gateway_route" "hub_aps1_to_prod" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_aps1.id
  destination_cidr_block         = "10.12.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod_aps1.id
}


resource "aws_ec2_transit_gateway_route" "hub_aps1_to_shared" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_aps1.id
  destination_cidr_block         = "10.13.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_aps1.id
}


# ──────────────────────────────────────────────
# DEV RT (ap-south-1): Associations, Propagations, and Routes
# ──────────────────────────────────────────────
resource "aws_ec2_transit_gateway_route_table_association" "dev_aps1_dev" {
  provider                       = aws.network_aps1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_aps1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev_aps1.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "dev_aps1_dev" {
  provider                       = aws.network_aps1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_aps1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev_aps1.id
}

resource "aws_ec2_transit_gateway_route" "dev_aps1_to_net" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev_aps1.id
  destination_cidr_block         = "10.10.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_aps1.id
}


resource "aws_ec2_transit_gateway_route" "dev_aps1_to_shared" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev_aps1.id
  destination_cidr_block         = "10.13.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_aps1.id
}


# ──────────────────────────────────────────────
# PROD RT (ap-south-1): Associations, Propagations, and Routes
# ──────────────────────────────────────────────
resource "aws_ec2_transit_gateway_route_table_association" "prod_aps1_prod" {
  provider                       = aws.network_aps1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod_aps1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_aps1.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "prod_aps1_prod" {
  provider                       = aws.network_aps1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod_aps1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_aps1.id
}

resource "aws_ec2_transit_gateway_route" "prod_aps1_to_net" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_aps1.id
  destination_cidr_block         = "10.10.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_aps1.id
}

resource "aws_ec2_transit_gateway_route" "prod_aps1_to_inet" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_aps1.id
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_aps1.id
}


resource "aws_ec2_transit_gateway_route" "prod_aps1_to_shared" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_aps1.id
  destination_cidr_block         = "10.13.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_aps1.id
}


# ──────────────────────────────────────────────
# SHARED SERVICES RT (ap-south-1): Associations, Propagations, and Routes
# ──────────────────────────────────────────────

resource "aws_ec2_transit_gateway_route_table_association" "shared_aps1_shared" {
  provider                       = aws.network_aps1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_aps1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_aps1.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared_aps1_shared" {
  provider                       = aws.network_aps1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_aps1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_aps1.id
}

resource "aws_ec2_transit_gateway_route" "shared_aps1_to_net" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_aps1.id
  destination_cidr_block         = "10.10.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_aps1.id
}

resource "aws_ec2_transit_gateway_route" "shared_aps1_to_dev" {
  provider                       = aws.network_aps1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_aps1.id
  destination_cidr_block         = "10.11.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_aps1.id
}
