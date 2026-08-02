# Regional Hubs
resource "aws_ec2_transit_gateway" "use1" {
  provider                       = aws.network_use1
  description                    = "Central TGW us-east-1"
  auto_accept_shared_attachments = "enable"

  # Disable automatic use of the default route table.
  # All associations and propagations must be explicit.
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
}

resource "aws_ec2_transit_gateway" "aps1" {
  provider                       = aws.network_aps1
  description                    = "Central TGW ap-south-1"
  auto_accept_shared_attachments = "enable"

  # Disable automatic use of the default route table.
  # All associations and propagations must be explicit.
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
}

# Cross-Region Backbone Peering
resource "aws_ec2_transit_gateway_peering_attachment" "global_peer" {
  provider                = aws.network_use1
  transit_gateway_id      = aws_ec2_transit_gateway.use1.id
  peer_transit_gateway_id = aws_ec2_transit_gateway.aps1.id
  peer_region             = "ap-south-1"
  peer_account_id         = local.network_account
}

# Accept the Peering Connection in ap-south-1
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "global_peer_accepter" {
  provider                      = aws.network_aps1
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.global_peer.id
  tags                          = { Name = "Global-Peer-Accepter-aps1" }
}
