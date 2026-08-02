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
