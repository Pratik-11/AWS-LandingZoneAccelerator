# Nothing downstream reads this layer's state. These exist so you can confirm a
# deployment with `terraform output` instead of clicking through the console.
#
# The TGW route-table and attachment IDs that used to live here were dropped —
# fifteen opaque IDs is not verification, it is noise. Add one back if you have
# a concrete use for it.

output "tgw_id" {
  description = "Transit Gateway ID in the Network account"
  value       = aws_ec2_transit_gateway.use1.id
}

output "vpc_ids" {
  description = "Map of account name to its VPC ID"
  value = {
    network         = module.network_vpc_use1.vpc_id
    dev             = module.dev_vpc_use1.vpc_id
    prod            = module.prod_vpc_use1.vpc_id
    shared_services = module.shared_vpc_use1.vpc_id
    sandbox         = module.sandbox_use1.vpc_id
  }
}
