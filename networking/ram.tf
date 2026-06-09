data "aws_organizations_organization" "org" {
  provider = aws.network_use1 # Needs a provider, but reads global org data
}

# US-EAST-1 Share
resource "aws_ram_resource_share" "tgw_use1" {
  provider                  = aws.network_use1
  name                      = "tgw-share-use1"
  allow_external_principals = false
}

resource "aws_ram_principal_association" "org_use1" {
  provider           = aws.network_use1
  principal          = data.aws_organizations_organization.org.arn
  resource_share_arn = aws_ram_resource_share.tgw_use1.arn
}

resource "aws_ram_resource_association" "tgw_use1" {
  provider           = aws.network_use1
  resource_arn       = aws_ec2_transit_gateway.use1.arn
  resource_share_arn = aws_ram_resource_share.tgw_use1.arn
}

# AP-SOUTH-1 Share
resource "aws_ram_resource_share" "tgw_aps1" {
  provider                  = aws.network_aps1
  name                      = "tgw-share-aps1"
  allow_external_principals = false
}

resource "aws_ram_principal_association" "org_aps1" {
  provider           = aws.network_aps1
  principal          = data.aws_organizations_organization.org.arn
  resource_share_arn = aws_ram_resource_share.tgw_aps1.arn
}

resource "aws_ram_resource_association" "tgw_aps1" {
  provider           = aws.network_aps1
  resource_arn       = aws_ec2_transit_gateway.aps1.arn
  resource_share_arn = aws_ram_resource_share.tgw_aps1.arn
}