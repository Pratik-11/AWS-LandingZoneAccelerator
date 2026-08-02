# 04-security

Enables the five org-wide security services and delegates administration of all of
them to the Audit account.

**Runs in:** management account (to enable + delegate) and Audit account (to configure)
**Depends on:** `01-organization`, `03-config-recorders`
**Blast radius:** 🟠 High. Destroying disables org-wide threat detection. Findings
history is lost with the detectors.

## Creates

| Service | Delegated to Audit |
|---|---|
| AWS Config aggregator | ✅ (org-wide, all regions) |
| GuardDuty | ✅ |
| Security Hub | ✅ + cross-region finding aggregator |
| IAM Access Analyzer | ✅ |
| Inspector | ✅ |
| SNS + EventBridge alerting | — |

The Security Hub finding aggregator uses `linking_mode = "ALL_REGIONS"` even
though this is a single-region deployment. That is deliberate: Security Hub
still reports from regions you never deploy to, and those findings are the
interesting ones.

## Delegated administration — the pattern to copy

Every service here follows the same two-step: **enable from the management
account, administer from Audit.**

```hcl
resource "aws_organizations_delegated_administrator" "config_admin" {
  account_id        = local.audit_account_id
  service_principal = "config.amazonaws.com"
}
```

The reason is blast radius. The management account has unlimited billing authority
and cannot be constrained by SCPs, so the fewer people and processes that need
access to it, the better. Delegating lets the security team work day to day in
Audit without ever holding management-account credentials.

Running GuardDuty and Security Hub *from* the management account works and is what
most quick tutorials show. It is also the first thing a security reviewer will
flag.

## Ordering hazard

`aws_organizations_delegated_administrator` must land before anything tries to
configure the service in Audit, and IAM propagation is not instant. The
`depends_on` chains in `main.tf` are load-bearing, not decorative — removing them
produces intermittent failures that pass on retry, which is the worst kind.

## Known gap

`securityhub-central-config.tf` manages resources that were originally created in
the console and imported into state, with a `# match exactly` comment on the policy
name. This layer is therefore **not reproducible from a clean org** without that
manual step. See `docs/KNOWN-LIMITS.md`.
