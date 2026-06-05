{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RestrictRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "sts:*",
        "organizations:*",
        "support:*",
        "budgets:*",
        "cloudfront:*",
        "route53:*",
        "waf:*",
        "wafv2:*",
        "globalaccelerator:*",
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ${allowed_regions}
        }
      }
    }
  ]
}
