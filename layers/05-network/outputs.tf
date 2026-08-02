# Transit Gateway Creation and Cross-Region Peering

output "tgw_use1_id" {
  description = "The ID of the Transit Gateway in us-east-1"
  value       = aws_ec2_transit_gateway.use1.id
}

output "tgw_use1_arn" {
  description = "The ARN of the Transit Gateway in us-east-1"
  value       = aws_ec2_transit_gateway.use1.arn
}

output "tgw_aps1_id" {
  description = "The ID of the Transit Gateway in ap-south-1"
  value       = aws_ec2_transit_gateway.aps1.id
}

output "tgw_aps1_arn" {
  description = "The ARN of the Transit Gateway in ap-south-1"
  value       = aws_ec2_transit_gateway.aps1.arn
}

output "tgw_peering_attachment_id" {
  description = "The ID of the TGW Peering Attachment connecting us-east-1 and ap-south-1"
  value       = aws_ec2_transit_gateway_peering_attachment.global_peer.id
}


# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────


# Transit Gateway Route Tables

# ──────────────────────────────────────────────
# TGW Route Tables (us-east-1)
# ──────────────────────────────────────────────
output "tgw_hub_rt_use1_id" {
  description = "ID of the Hub TGW Route Table in us-east-1"
  value       = aws_ec2_transit_gateway_route_table.hub_use1.id
}

output "tgw_dev_rt_use1_id" {
  description = "ID of the Dev TGW Route Table in us-east-1"
  value       = aws_ec2_transit_gateway_route_table.dev_use1.id
}

output "tgw_prod_rt_use1_id" {
  description = "ID of the Prod TGW Route Table in us-east-1"
  value       = aws_ec2_transit_gateway_route_table.prod_use1.id
}

output "tgw_shared_rt_use1_id" {
  description = "ID of the Shared Services TGW Route Table in us-east-1"
  value       = aws_ec2_transit_gateway_route_table.shared_use1.id
}

# ──────────────────────────────────────────────
# TGW Route Tables (ap-south-1)
# ──────────────────────────────────────────────
output "tgw_hub_rt_aps1_id" {
  description = "ID of the Hub TGW Route Table in ap-south-1"
  value       = aws_ec2_transit_gateway_route_table.hub_aps1.id
}

output "tgw_dev_rt_aps1_id" {
  description = "ID of the Dev TGW Route Table in ap-south-1"
  value       = aws_ec2_transit_gateway_route_table.dev_aps1.id
}

output "tgw_prod_rt_aps1_id" {
  description = "ID of the Prod TGW Route Table in ap-south-1"
  value       = aws_ec2_transit_gateway_route_table.prod_aps1.id
}

output "tgw_shared_rt_aps1_id" {
  description = "ID of the Shared Services TGW Route Table in ap-south-1"
  value       = aws_ec2_transit_gateway_route_table.shared_aps1.id
}


# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Workloads VPC IDs

# ──────────────────────────────────────────────
# VPC IDs (us-east-1)
# ──────────────────────────────────────────────
output "network_vpc_use1_id" {
  description = "ID of the Network VPC in us-east-1"
  value       = module.network_vpc_use1.vpc_id
}

output "dev_vpc_use1_id" {
  description = "ID of the Dev VPC in us-east-1"
  value       = module.dev_vpc_use1.vpc_id
}

output "prod_vpc_use1_id" {
  description = "ID of the Prod VPC in us-east-1"
  value       = module.prod_vpc_use1.vpc_id
}

output "sandbox_vpc_use1_id" {
  description = "ID of the Sandbox VPC in us-east-1"
  value       = module.sandbox_use1.vpc_id
}


output "shared_vpc_use1_id" {
  description = "ID of the Shared Services VPC in us-east-1"
  value       = module.shared_vpc_use1.vpc_id
}


# ──────────────────────────────────────────────
# VPC IDs (ap-south-1)
# ──────────────────────────────────────────────
output "network_vpc_aps1_id" {
  description = "ID of the Network VPC in ap-south-1"
  value       = module.network_vpc_aps1.vpc_id
}

output "dev_vpc_aps1_id" {
  description = "ID of the Dev VPC in ap-south-1"
  value       = module.dev_vpc_aps1.vpc_id
}

output "prod_vpc_aps1_id" {
  description = "ID of the Prod VPC in ap-south-1"
  value       = module.prod_vpc_aps1.vpc_id
}

output "sandbox_vpc_aps1_id" {
  description = "ID of the Sandbox VPC in ap-south-1"
  value       = module.sandbox_aps1.vpc_id
}

output "shared_vpc_aps1_id" {
  description = "ID of the Shared Services VPC in ap-south-1"
  value       = module.shared_vpc_aps1.vpc_id
}


# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# VPC Attachments

# ──────────────────────────────────────────────
# TGW VPC Attachments (us-east-1)
# ──────────────────────────────────────────────
output "tgw_attach_net_use1_id" {
  description = "ID of the Network VPC TGW Attachment in us-east-1"
  value       = aws_ec2_transit_gateway_vpc_attachment.net_use1.id
}

output "tgw_attach_dev_use1_id" {
  description = "ID of the Dev VPC TGW Attachment in us-east-1"
  value       = aws_ec2_transit_gateway_vpc_attachment.dev_use1.id
}

output "tgw_attach_prod_use1_id" {
  description = "ID of the Prod VPC TGW Attachment in us-east-1"
  value       = aws_ec2_transit_gateway_vpc_attachment.prod_use1.id
}

output "tgw_attach_shared_use1_id" {
  description = "ID of the Shared Services VPC TGW Attachment in us-east-1"
  value       = aws_ec2_transit_gateway_vpc_attachment.shared_use1.id
}

# ──────────────────────────────────────────────
# TGW VPC Attachments (ap-south-1)
# ──────────────────────────────────────────────
output "tgw_attach_net_aps1_id" {
  description = "ID of the Network VPC TGW Attachment in ap-south-1"
  value       = aws_ec2_transit_gateway_vpc_attachment.net_aps1.id
}

output "tgw_attach_dev_aps1_id" {
  description = "ID of the Dev VPC TGW Attachment in ap-south-1"
  value       = aws_ec2_transit_gateway_vpc_attachment.dev_aps1.id
}

output "tgw_attach_prod_aps1_id" {
  description = "ID of the Prod VPC TGW Attachment in ap-south-1"
  value       = aws_ec2_transit_gateway_vpc_attachment.prod_aps1.id
}

output "tgw_attach_shared_aps1_id" {
  description = "ID of the Shared Services VPC TGW Attachment in ap-south-1"
  value       = aws_ec2_transit_gateway_vpc_attachment.shared_aps1.id
}
