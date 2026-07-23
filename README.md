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

> organisation  >  logging  >  configSetup  >  security  > networking  >  identity

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
| Create AWS Config Recorder module | `modules/config-recorder/` | Already done ✅ |
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

see theory docs to understand networking architecture, tasks below are not in order

### Networking Tasks

| Sno. | Task                                                                                    | Module/Location                       | Status |
| ---- | --------------------------------------------------------------------------------------- | ------------------------------------- | ------ |
| 1    | Create networking root module                                                           | networking/main.tf                    | done ✅  |
| 2    | Create modules/vpc/ — reusable VPC module (public/private subnets, NAT, IGW, flow logs[optional]) | modules/vpc/                | done ✅   |
| 3    | Create Transit Gateway in Network account                                               | networking/transit-gateway.tf         | done ✅   |
| 4    | Create TGW route table — routes for all spoke  CIDRs [create after all VPC creation - dependency]                                     | networking/transit-gateway-RT.tf           | done ✅   |
| 5    | Create Network VPC in Network account with public + private subnets                     | networking/network-vpc.tf             | done ✅   |
| 6    | Share Transit Gateway org-wide via AWS RAM                                              | networking/ram.tf                     | done ✅   |
| 7    | Create VPC in Dev account, attach to Transit Gateway                                    | networking/workload-vpcs.tf           | done ✅   |
| 8    | Create VPC in Prod account (private subnets only), attach to Transit Gateway            | networking/workload-vpcs.tf           | done ✅   |
| 9    | Create VPC in Shared Services account, attach to Transit Gateway                        | networking/workload-vpcs.tf           | done ✅   |
| 10   | Create VPC in Sandbox account — isolated, no TGW attachment                             | networking/sandbox-vpc.tf             | done ✅   |
| 11   | TGW Route tables -> association, propagation and routing rules                          | networking/transit-gateway-RT.tf             | done ✅   |
| 12   | Create Route53 Private Hosted Zones in Network account                                  | networking/dns.tf                     | done ✅   |
| 13   | Associate PHZs with Dev, Prod, Shared Services VPCs                                     | networking/dns.tf                     | done ✅   |
| 14   | Enable Route53 Resolver Query Logs — central DNS logging  [deferred for this iteration]                               | networking/dns-query-logs.tf          | TODO   |
| 15   | Create Network Access Analyzer scope — org-wide network visibility     [deferred for this iteration]                     | networking/network-access-analyzer.tf | TODO   |



```bash
sharedService VPC and association with TGW  : deferred this until there is no usecase of sharedServices

refer to doc : .skills/learning/sharedService-networkinSetup.md

```

> Implement a org wide or securityOU specific scp : 
1. deny creation of VPC by users, only allowed to terraform user : identity based policy something

```
Optional — future phase (not in current task list):

1. Inspection VPC in Network account for centralized east-west and north-south traffic inspection
2. AWS Network Firewall — domain, IP, country, and protocol filtering

```


### Cross-Account Setup Required

TGW sharing via RAM (accepted in each spoke account), PHZ associations from Network account into workload account VPCs, VPC Flow Logs to central S3 bucket in Log Archive account.

#### VPC CIDR allocation:


| Account         | VPC CIDR                                  |
| --------------- | ----------------------------------------- |
| Network         | 10.0.0.0/16                               |
| Dev             | 10.1.0.0/16                               |
| Prod            | 10.2.0.0/16                               |
| Shared Services | 10.3.0.0/16                               |
| Sandbox         | 10.9.0.0/16 — isolated, no overlap needed |



### Deliverable: 

All accounts have non-overlapping VPCs. Dev, Prod, and Shared Services route through the Transit Gateway. Sandbox is fully isolated. Private DNS resolves consistently across all connected accounts. All DNS queries logged centrally. Network Access Analyzer provides continuous visibility into unintended internet exposure.

---

### Phase 6: Identity & Access Management
**Goal:** Centralized identity with SSO-based access to all accounts.

| Task | Module/Location | Status |
|:-----|:----------------|:-------|
| Create `identity/` root module | `identity/main.tf` | done ✅ |
| Enable IAM Identity Center (SSO) in management account | `identity/sso.tf` | done ✅ |
| Create Permission Sets (AdministratorAccess, ReadOnly, DeveloperAccess) | `identity/permission-sets.tf` | done ✅ |
| Create Groups and assign Permission Sets to accounts | `identity/assignments.tf` | done ✅ |
| Create IAM baseline roles in each account (for cross-account Terraform execution) | `modules/iam-baseline/` | done ✅ |

**Deliverable:** Humans access accounts via SSO. Terraform accesses accounts via assume-role chains.


scps specific to this  : 
1. Identity Center users - email verification - necessary
2. donot let user access sso portal until they setup MFA


// NOT PREFERRED PRACITSE TO SEND CREDS LIKE THIS : refer to docs .skills/bugs/identity-loose-user-creds.md

### ⚠️ IMPORTANT: Billing Console Access Quirk
Even if a user is assigned a permission set with full Billing/Cost Explorer IAM permissions (like `FAWSReadOnlyBillingAccesss`), **AWS strictly blocks all IAM users and SSO roles from viewing the Billing Console by default.**

AWS requires you to globally explicitly "unlock" the billing console for IAM/SSO users at the account level. Until this is unlocked, AWS completely ignores our Terraform billing policies, and the user will see a red `"You need permissions"` error.

**How to fix it (One-Time Manual Step):**
This cannot be automated via Terraform. It must be done in the console.
1. Log into the AWS Console using Administrator credentials (or the Root User of the Management Account).
2. Click your account name in the top-right corner of the console and select **Account** from the dropdown menu.
3. Scroll down the page until you find the section named **IAM User and Role Access to Billing Information**.
4. Click **Edit** next to it.
5. Check the box to **Activate IAM Access**.
6. Click **Update**.

Once activated, AWS will immediately start respecting the IAM policies we created via Terraform!
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
```

Phases 2 through 6 can be developed in parallel after Phase 1 is complete. 

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
