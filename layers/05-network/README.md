# 05-network

Hub-and-spoke networking: a Transit Gateway per region in the Network account,
shared org-wide over RAM, with a VPC in each workload account attached to it.

**Runs in:** Network, Dev, Prod, SharedServices, Sandbox (assume-role), both regions
**Depends on:** `01-organization`
**Blast radius:** 🔴 High and *immediate*. Removing a TGW attachment or a route
breaks connectivity for running workloads the moment it applies. Plan carefully
here; this is the layer most likely to cause an outage.

## The address plan

CIDRs are written inline in `network-vpc.tf`, `workload-vpcs.tf` and
`sandbox-vpc.tf` rather than passed as variables — so the whole plan is readable
in one place instead of assembled from a tfvars file at plan time. Change them
there.

| Account | us-east-1 | ap-south-1 |
|---|---|---|
| Network (hub) | `10.0.0.0/16` | `10.10.0.0/16` |
| Dev | `10.1.0.0/16` | `10.11.0.0/16` |
| Prod | `10.2.0.0/16` | `10.12.0.0/16` |
| SharedServices | `10.3.0.0/16` | `10.13.0.0/16` |
| Sandbox | `10.9.0.0/16` | `10.19.0.0/16` |

Non-overlapping is not optional — a TGW cannot route between two VPCs with the
same CIDR, and there is no fixing it after the fact without rebuilding a VPC.

At this size a spreadsheet is fine. Past roughly twenty accounts, hand-allocation
starts producing collisions and **AWS IPAM** is the answer — it hands out
non-overlapping blocks from a managed pool automatically.

## Topology

- **Dev / SharedServices** — public + private subnets, NAT, attached to TGW
- **Prod** — private subnets only (`create_public_subnets = false`), default route
  points at the TGW so all egress is forced through the Network account
- **Sandbox** — deliberately *not* attached to the TGW. Isolated by construction,
  reinforced by the `deny-network-bridging` SCP on the Sandbox OU.
- **Route53 private hosted zones** created in Network, associated into the spokes

## Two traps in here

**Prod's default route currently points at the TGW, but nothing terminates it.**
`0.0.0.0/0 → TGW` only reaches the internet if the Network account runs a NAT or
firewall in an egress VPC *and* the TGW route tables send it there. Verify that
path before you rely on it — otherwise Prod egress black-holes.

**AZ names are not consistent across accounts.** `us-east-1a` in the Dev account
and `us-east-1a` in the Prod account are usually different physical datacentres.
For latency-sensitive or cost-sensitive placement, pin by AZ *ID*
(`use1-az1`) via `aws_availability_zones`, not by name.

## Flow logs

Every VPC ships flow logs straight to the central bucket in LogArchive, created by
`02-logging`. S3 delivery rather than CloudWatch Logs: no IAM role needed in each
account, and materially cheaper at volume. Aggregation is 10 minutes — drop to 60
seconds only if you need fast forensics, it costs roughly ten times as much.

Pass `flow_logs_destination_arn = null` to the VPC module to turn them off.

## Known gaps

- Single region. Cross-region TGW peering was removed rather than duplicated —
  see below for how to add it back.
- No inspection VPC / Network Firewall — see `docs/KNOWN-LIMITS.md`
- No Route53 resolver query logging, no Network Access Analyzer scope

## Adding a second region

Everything here is single-region on purpose: a second copy of the same five
providers, four VPCs, four TGW route tables and twenty routes taught nothing the
first copy does not, and doubled the file you have to read.

To add one back:

1. **Providers** — duplicate every block in `providers.tf` with
   `region = local.allowed_regions.secondary` and a `_<region>` alias suffix.
2. **Transit Gateway** — a second `aws_ec2_transit_gateway`, then peer them:

   ```hcl
   resource "aws_ec2_transit_gateway_peering_attachment" "global_peer" {
     provider                = aws.network_use1
     transit_gateway_id      = aws_ec2_transit_gateway.use1.id
     peer_transit_gateway_id = aws_ec2_transit_gateway.aps1.id
     peer_region             = "ap-south-1"
     peer_account_id         = local.network_account
   }

   resource "aws_ec2_transit_gateway_peering_attachment_accepter" "global_peer_accepter" {
     provider                      = aws.network_aps1
     transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.global_peer.id
   }
   ```

3. **RAM** — a separate resource share per region; a share cannot span regions.
4. **VPCs, attachments, routes** — duplicate, using the second-region CIDR column
   in the table above.
5. **Hub route** — point each region's hub route table at the peering attachment
   for the other region's supernet.

**The supernet gotcha:** covering `10.10.0.0/16`–`10.13.0.0/16` looks like
`10.10.0.0/14`, but that is not a valid network address — the mask does not align
to the base. Use `10.8.0.0/13`, which covers `10.8.x.x`–`10.15.x.x`. AWS rejects
the misaligned form with a bare "invalid CIDR block".
