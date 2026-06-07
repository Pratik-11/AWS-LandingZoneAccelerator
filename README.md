# AWS Landing Zone Architecture - Custom Built

Welcome to the custom-built, Terraform-based AWS Landing Zone project. 

This architecture is deployed in sequential, isolated phases to decouple state files, manage cross-account IAM provider complexity, and handle AWS organizational bootstrapping gracefully.

---

## Standard Landing Zone Target Architecture

```text
Organization (Management Account)
│
├── Security OU
│   ├── Audit Account
│   │   ├── GuardDuty (Delegated Admin)
│   │   ├── Security Hub (Delegated Admin)
│   │   ├── Access Analyzer
│   │   └── Inspector
│   │
│   └── LogArchive Account
│       ├── Organization CloudTrail S3 Bucket
│       ├── Config Logs S3 Bucket
│       └── Access Logs S3 Bucket
│
├── Infrastructure OU
│   ├── Network Account
│   │   ├── Transit Gateway
│   │   ├── Shared VPCs
│   │   └── DNS (Route53)
│   │
│   └── SharedServices Account
│       ├── CI/CD Pipelines
│       └── Shared Tooling
│
├── Sandbox OU
│   └── Sandbox Account
│       └── Experimentation VPC
│
└── Workloads OU
    ├── Dev Account
    │   └── Dev VPC
    └── Prod Account
        └── Prod VPC
```

**Total Accounts: 8** (7 member + 1 management)

---

## Development Phases

THE TERRAFORM DIRECTORY STRUCTURE WILL BE  :

```
landing-zone/
│
├── modules/                        ← reusable building blocks, never run directly
│   ├── ou/
│   │   ├── main.tf                 ← defines aws_organizations_organizational_unit resources
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── account/
│   │   ├── main.tf                 ← defines aws_organizations_account resource
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── scp/
│   ├── iam-baseline/
│   ├── config-recorder/
│   ├── logging-bucket/
│   └── vpc/
│
├── organizations/                  ← ROOT 1 — run terraform apply here first
│   ├── main.tf                     ← calls module "ou" and module "account"
│   ├── providers.tf
│   ├── backend.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── security/                       ← ROOT 2 — run after organizations/
│   ├── main.tf
│   ├── providers.tf
│   ├── backend.tf
│   └── ...
│
├── logging/                        ← ROOT 3
├── networking/                     ← ROOT 4
└── identity/                       ← ROOT 5

```
> *The key insight: modules/ is a library. The top-level folders are deployment units. There is no root-level main.tf because nothing orchestrates the others — We have to do that manually by cd-ing into each directory in the right order.*

Correct Order of setting up this LandingZone from scratch : 

> Organisation  >  logging  >  configSetup  > 

So, we are supposed to go inside each directory and do terraform init, plan and apply one by one for LANDING ZONE SETUP USING THIS TERRA_CODE_DIRECTORY

### Phase 1: Organisation Bootstrapping
**Goal:** Create the org structure and all 7 member accounts.

| Task | Module/Location | Status |
|:-----|:----------------|:-------|
| Enable AWS Organizations (ALL features) | `organisation/main.tf` | Already done ✅ |
| Create 4 OUs (Security, Infrastructure, Sandbox, Workloads) | `modules/ou/` | Already done ✅ |
| Create 7 member accounts dynamically via `for_each` | `modules/accounts/` | Already done ✅ |
| Deploy on new AWS account with `terraform-admin-new` profile | `organisation/provider.tf` | Already done ✅ |
| Verify all accounts created and in correct OUs | CLI verification | Already done ✅ |

**Deliverable:** Clean org with all accounts in their respective OUs.

---

### Phase 2: Service Control Policies (SCPs)
**Goal:** Enforce governance guardrails at the OU level.

| Task | Module/Location | Status |
|:-----|:----------------|:-------|
| Create `modules/scp/` — reusable SCP module | `modules/scp/main.tf` | Already done ✅ |
| Deny root user access in all member accounts | SCP on Root OU | Already done ✅ |
| Deny leaving the organization | SCP on Root OU | Already done ✅ |
| Restrict regions to allowed regions only | SCP on all OUs | Already done ✅ |
| Protect the LogArchive and Audit accounts (deny S3 deletion, deny CloudTrail stop) | SCP on Security OU | Already done ✅ |
| Allow full access in Sandbox OU (with spend guardrails) | SCP on Sandbox OU | Already done ✅ |
| Deny expensive services in Dev | SCP on Workloads OU (optional) | Already done ✅ |

**Deliverable:** Governance guardrails enforced across the org before any workloads exist.

---

### Phase 3: Centralized Logging
**Goal:** All accounts ship logs to the LogArchive account.

**Execution 1: Central Buckets & Organization CloudTrail**
| Task | Module/Location | Status |
|:-----|:----------------|:-------|
| Create `logging/` root module | `logging/main.tf` | Already done ✅ |
| Create `modules/logging-bucket/` — S3 bucket with encryption, versioning, lifecycle | `modules/logging-bucket/` | Already done ✅ |
| Create Organization CloudTrail (management account, logs to LogArchive S3) | `logging/main.tf` | Already done ✅ |
| Ensure bucket policies allow cross-account writes from CloudTrail and Config | `modules/logging-bucket/` | Already done ✅ |

**Execution 2: AWS Config Recorders & Config Aggregator**
| Task | Module/Location | Status |
|:-----|:----------------|:-------|
| Create `configSetup/` root module | `configSetup/main.tf` | Already done ✅ |
| Create AWS Config Recorder module | `modules/cofig-recorder/` | Already done ✅ |
| Deploy AWS Config Recorder in each of the 7 member accounts | `configSetup/main.tf` | Already done ✅ |
| Create Config Aggregator in Management account | `configSetup/main.tf` | Already done ✅ |

**Cross-account setup required:** 
- Execution 1: Terraform must assume a role in the LogArchive account to create the S3 buckets, then configure CloudTrail from the management account.
- Execution 2: Terraform must use 7 different `assume_role` provider aliases to deploy Config into each member account, and run the aggregator in the management account.

**Deliverable:** Every API call across the org is logged to a tamper-proof centralized bucket, and resource configurations are actively recorded.

---

### Phase 4: Security Tooling
**Goal:** Centralized security monitoring in the Audit account.

| Task | Module/Location | Status |
|:-----|:----------------|:-------|
| Create `security/` root module | `security/main.tf` | done ✅ |
| Set Audit account as Delegated Admin for AWS Config | `security/config-admin.tf` | done ✅ |
| Move Config Aggregator from Management to Audit account | `security/config-aggregator.tf` | done ✅ |
| Enable GuardDuty organization-wide, delegate admin to Audit account | `security/guardduty.tf` | done ✅ |
| Enable Security Hub organization-wide, delegate admin to Audit account | `security/securityhub.tf` | done ✅|
| Enable IAM Access Analyzer (organization-level) | `security/access-analyzer.tf` | done ✅ |
| Enable Inspector organization-wide, delegate admin to Audit account | `security/inspector.tf` | done ✅ |
| Create SNS topic in Audit account for security alerts | `security/alerts.tf` | done ✅ |

**Cross-account setup required:** Enable services from management account, delegate administration to the Audit account.

**Deliverable:** Single pane of glass for security findings across all accounts.

Since in this PHASE 4 : I am destroying my management account config aggregator and creating it in audit account now, so no scp on aggregator deletion was during implementation of this phase 

> NOTE : AFTER COMPLETION OF PHASE 4 : 
> Implement a org wide or securityOU specific scp : 

1. deny for aggregator deletion

2. deny guardduty disable orgwide

3. deny securityHub aggregator and orgwide service disabling

4. IAM access-analyzer and inspector deny disabling scp

5. Inspector can't be closed scp

6. Alert level scp -> if any

> Services configured in security tooling :

1. AWS Config
2. Guardduty
3. Security Hub
4. Inspector
5. IAM Access Analyzer
6. SNS alerting

---

### Phase 5: Networking
**Goal:** Centralized network architecture with account-level VPC isolation.

| Task | Module/Location | Status |
|:-----|:----------------|:-------|
| Create `networking/` root module | `networking/main.tf` | TODO |
| Create `modules/vpc/` — reusable VPC module (public/private subnets, NAT, IGW) | `modules/vpc/` | TODO |
| Create Transit Gateway in Network account | `networking/transit-gateway.tf` | TODO |
| Create shared VPC in Network account | `networking/main.tf` | TODO |
| Create VPCs in Dev and Prod accounts, attach to Transit Gateway | `networking/workload-vpcs.tf` | TODO |
| Create VPC in Sandbox account (isolated, no TGW attachment) | `networking/sandbox-vpc.tf` | TODO |
| Set up Route53 Private Hosted Zones (optional) | `networking/dns.tf` | TODO |

**Cross-account setup required:** Transit Gateway sharing via RAM (Resource Access Manager), VPC creation in each workload account.

**Deliverable:** All accounts have networking, centrally managed, with controlled connectivity.

---

### Phase 6: Identity & Access Management
**Goal:** Centralized identity with SSO-based access to all accounts.

| Task | Module/Location | Status |
|:-----|:----------------|:-------|
| Create `identity/` root module | `identity/main.tf` | TODO |
| Enable IAM Identity Center (SSO) in management account | `identity/sso.tf` | TODO |
| Create Permission Sets (AdministratorAccess, ReadOnly, DeveloperAccess) | `identity/permission-sets.tf` | TODO |
| Create Groups and assign Permission Sets to accounts | `identity/assignments.tf` | TODO |
| Create IAM baseline roles in each account (for cross-account Terraform execution) | `modules/iam-baseline/` | TODO |

**Deliverable:** Humans access accounts via SSO. Terraform accesses accounts via assume-role chains.

---

### Phase 7: Workload Account Baseline
**Goal:** Every member account gets a consistent security and operational baseline.

| Task | Module/Location | Status |
|:-----|:----------------|:-------|
| Create `modules/account-baseline/` composite module | `modules/account-baseline/` | TODO |
| Apply Config Recorder | included from Phase 3 | TODO |
| Apply IAM baseline roles | included from Phase 6 | TODO |
| Apply VPC | included from Phase 5 | TODO |
| Apply password policy | `modules/account-baseline/` | TODO |
| Enable EBS default encryption | `modules/account-baseline/` | TODO |
| Enable S3 account-level public access block | `modules/account-baseline/` | TODO |

**Deliverable:** Every account is hardened and consistent from the moment it's created.

---

## Phase Dependency Graph

```text
Phase 1: Organisation ──────────────────────────────┐
                                                     │
Phase 2: SCPs ──────────────────────────────────────┐│
                                                    ││
Phase 3: Logging ───────────────┐                   ││
                                │                   ││
Phase 4: Security ──────────────┤ (needs Phase 1,3) ││
                                │                   ││
Phase 5: Networking ────────────┤ (needs Phase 1)   ││
                                │                   ││
Phase 6: Identity ──────────────┤ (needs Phase 1)   ││
                                │                   ││
Phase 7: Account Baseline ──────┘ (needs 3,5,6)     ││
```

Phases 2 through 6 can be developed in parallel after Phase 1 is complete. Phase 7 is a composite that ties everything together.

---

## Cross-Account Terraform Execution Pattern

Since you will be creating resources in member accounts (not just the management account), your Terraform will need to assume roles across accounts. The pattern is:

```hcl
# In provider.tf of each root module (e.g., logging/, security/, networking/)
provider "aws" {
  alias   = "log_archive"
  region  = var.aws_region
  profile = "terraform-admin-new"

  assume_role {
    role_arn = "arn:aws:iam::${var.log_archive_account_id}:role/OrganizationAccountAccessRole"
  }
}
```

AWS automatically creates an `OrganizationAccountAccessRole` in every member account created via Organizations. This role trusts the management account. Your Terraform running as `terraform-admin-new` in the management account can assume this role to provision resources in any member account.

---



## VALIDATING ORGANISATION SETUP 

1. Organisation Enabling and OU Structure
2. Account Creation
3. scp-enforcement validations
4. logging validations
5. config-recording and aggregation validations
6. securityhub -> configuration policies, standards, controls, CSPM dashboard
7. accessAnalyzer -> confirm creation status from creating to enabled
8. Inspector -> confirm it works or not
9. Alerting System -> email for HIGH and CRITICAL security findings

