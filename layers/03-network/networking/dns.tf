resource "aws_route53_zone" "internal_use1" {
  provider = aws.network_use1
  name     = "internal.company.local"
  vpc { vpc_id = module.network_vpc_use1.vpc_id }
}

# ──────────────────────────────────────────────
# 1. Authorize Cross-Account VPCs (Network Provider)
# ──────────────────────────────────────────────
resource "aws_route53_vpc_association_authorization" "dev_use1" {
  provider = aws.network_use1
  vpc_id   = module.dev_vpc_use1.vpc_id
  zone_id  = aws_route53_zone.internal_use1.id
}
resource "aws_route53_vpc_association_authorization" "dev_aps1" {
  provider   = aws.network_use1
  vpc_id     = module.dev_vpc_aps1.vpc_id
  zone_id    = aws_route53_zone.internal_use1.id
  vpc_region = "ap-south-1"
}

resource "aws_route53_vpc_association_authorization" "prod_use1" {
  provider = aws.network_use1
  vpc_id   = module.prod_vpc_use1.vpc_id
  zone_id  = aws_route53_zone.internal_use1.id
}
resource "aws_route53_vpc_association_authorization" "prod_aps1" {
  provider   = aws.network_use1
  vpc_id     = module.prod_vpc_aps1.vpc_id
  zone_id    = aws_route53_zone.internal_use1.id
  vpc_region = "ap-south-1"
}

resource "aws_route53_vpc_association_authorization" "shared_use1" {
  provider = aws.network_use1
  vpc_id   = module.shared_vpc_use1.vpc_id
  zone_id  = aws_route53_zone.internal_use1.id
}
resource "aws_route53_vpc_association_authorization" "shared_aps1" {
  provider   = aws.network_use1
  vpc_id     = module.shared_vpc_aps1.vpc_id
  zone_id    = aws_route53_zone.internal_use1.id
  vpc_region = "ap-south-1"
}

# ──────────────────────────────────────────────
# 2. Actually Associate VPCs (Workload Providers)
# ──────────────────────────────────────────────
resource "aws_route53_zone_association" "dev_use1" {
  provider   = aws.dev_use1
  vpc_id     = module.dev_vpc_use1.vpc_id
  zone_id    = aws_route53_zone.internal_use1.id
  depends_on = [aws_route53_vpc_association_authorization.dev_use1]
}
resource "aws_route53_zone_association" "dev_aps1" {
  provider   = aws.dev_aps1
  vpc_id     = module.dev_vpc_aps1.vpc_id
  zone_id    = aws_route53_zone.internal_use1.id
  vpc_region = "ap-south-1"
  depends_on = [aws_route53_vpc_association_authorization.dev_aps1]
}

resource "aws_route53_zone_association" "prod_use1" {
  provider   = aws.prod_use1
  vpc_id     = module.prod_vpc_use1.vpc_id
  zone_id    = aws_route53_zone.internal_use1.id
  depends_on = [aws_route53_vpc_association_authorization.prod_use1]
}
resource "aws_route53_zone_association" "prod_aps1" {
  provider   = aws.prod_aps1
  vpc_id     = module.prod_vpc_aps1.vpc_id
  zone_id    = aws_route53_zone.internal_use1.id
  vpc_region = "ap-south-1"
  depends_on = [aws_route53_vpc_association_authorization.prod_aps1]
}

resource "aws_route53_zone_association" "shared_use1" {
  provider   = aws.shared_use1
  vpc_id     = module.shared_vpc_use1.vpc_id
  zone_id    = aws_route53_zone.internal_use1.id
  depends_on = [aws_route53_vpc_association_authorization.shared_use1]
}
resource "aws_route53_zone_association" "shared_aps1" {
  provider   = aws.shared_aps1
  vpc_id     = module.shared_vpc_aps1.vpc_id
  zone_id    = aws_route53_zone.internal_use1.id
  vpc_region = "ap-south-1"
  depends_on = [aws_route53_vpc_association_authorization.shared_aps1]
}