# Terraform AWS Landing Zone Project Context

## Project Goal

Build a modular AWS Landing Zone using Terraform that follows AWS Organizations and AWS Security Reference Architecture (SRA) principles while remaining usable for small organizations that have AWS account count limitations.

The Landing Zone must support multiple deployment profiles (Minimal, Standard, Enterprise) from the same Terraform codebase.

The architecture should be modular, reusable, and future-proof so that organizations can start small and later expand to a full multi-account enterprise landing zone without redesigning the Terraform structure.

---

# Current Terraform Structure

```text
landing-zone/
│
├── modules/
│   ├── ou/
│   ├── account/
│   ├── scp/
│   ├── iam-baseline/
│   ├── config-recorder/
│   ├── logging-bucket/
│   └── vpc/
│
├── organisation/
│   ├── main.tf
│   ├── provider.tf
│   ├── backend.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── security/
├── logging/
├── networking/
└── identity/
```

---

# Current State

Already implemented:

* AWS Organization enabled with ALL features.
* Organizational Units (OUs) creation through reusable OU module.
* OU hierarchy created through Terraform.

Current OU structure:

```text
Organization
│
├── Security OU
├── Infrastructure OU
├── Sandbox OU
└── Workloads OU
```

---

# Architectural Decision: Reduced Landing Zone

The original architecture was:

```text
Organization
│
├── Infrastructure OU
│   ├── Network Account
│   └── Shared Services Account
│
├── Security OU
│   ├── Audit Account
│   └── Log Archive Account
│
├── Sandbox OU
│   ├── Sandbox Account
│   └── Playground Account
│
└── Workloads OU
    ├── Dev Account
    ├── Stage Account
    └── Prod Account
```

This architecture requires many AWS accounts.

Because of AWS account limits and to make the landing zone usable for smaller organizations, a reduced architecture has been adopted.

---

# Approved Minimal Architecture

```text
Organization
│
├── Security OU
│   ├── Audit Account
│   └── Log Archive Account
│
├── Infrastructure OU
│   └── Network Account
│
├── Sandbox OU
│   └── (No accounts initially)
│
└── Workloads OU
    └── Application Account
```

Application Account contains:

```text
Application Account
│
├── Dev VPC
├── Stage VPC
└── Prod VPC
```

instead of separate AWS accounts.

---

# Reasoning Behind Reduced Architecture

## Security Accounts Remain Separate

Audit and Log Archive accounts remain mandatory because they provide:

* Centralized security operations
* Centralized log retention
* Better security isolation
* AWS SRA alignment

These accounts are considered non-negotiable.

---

## Infrastructure Reduced

Shared Services account is removed initially.

Only Network Account remains.

Any shared services can temporarily reside inside the Application Account until the landing zone grows.

---

## Sandbox Deferred

Sandbox OU remains present.

No Sandbox or Playground accounts are created initially.

Reason:

* Preserve future architecture.
* Preserve SCP inheritance model.
* Allow future expansion without OU restructuring.

The Sandbox OU should still receive its own SCPs and baseline configuration.

Future accounts can be added without redesign.

---

## Workloads Simplified

Instead of:

```text
Dev Account
Stage Account
Prod Account
```

use:

```text
Application Account
├── Dev VPC
├── Stage VPC
└── Prod VPC
```

This reduces account consumption while still allowing environment separation.

Future migration path:

```text
Application Account
    ↓
Dev Account
Stage Account
Prod Account
```

should be supported.

---

# Landing Zone Deployment Profiles

The Terraform project must support multiple deployment modes from the same codebase.

The goal is:

```text
Single Terraform Codebase
          │
          ▼
   Deployment Profile
          │
 ┌────────┼────────┐
 │        │        │
Minimal Standard Enterprise
```

---

# Profile 1: Minimal

Target:

* Personal projects
* Learning environments
* Small teams
* Startups with AWS account limitations
* Organizations that want core AWS governance and security controls with the lowest possible account count

Architecture:

```text
Organization
│
├── Security OU
│   ├── Audit
│   └── Log Archive
│
├── Infrastructure OU
│   └── Network
│
├── Sandbox OU
│
└── Workloads OU
    └── Application
```

Application Account Structure:

```text
Application
│
├── Dev VPC
├── Stage VPC
└── Prod VPC
```

Accounts Created: 5 [including management account]

```text
Audit
LogArchive
Network
Application
```

Characteristics:

* Dedicated Security OU following AWS SRA principles.
* Dedicated Audit account for security administration, delegated administrators, and centralized security tooling.
* Dedicated Log Archive account for centralized CloudTrail, Config, and audit log retention.
* Dedicated Network account for future networking expansion and centralized networking services.
* Single Application account hosting all workload environments.
* Environment separation achieved through VPCs and resource boundaries rather than separate AWS accounts.
* Sandbox OU exists but does not initially contain accounts.
* Lowest operational complexity and lowest AWS account consumption.
* Provides a migration path toward more mature multi-account architectures.

Trade-offs:

* Reduced isolation between Dev, Stage, and Prod workloads.
* Greater reliance on IAM, networking, and operational discipline.
* Shared account blast radius for application workloads.
* Some enterprise security patterns are deferred until additional accounts are introduced.

The Minimal profile is intended for organizations that want a proper AWS Landing Zone foundation while minimizing account count and operational overhead.


---

# Profile 2: Standard

Target:

* Growing startups
* Small engineering organizations
* Teams that need environment separation but are not yet operating at enterprise scale
* Organizations that want a dedicated experimentation account

Architecture:

```text
Organization
│
├── Security OU
│   ├── Audit
│   └── Log Archive
│
├── Infrastructure OU
│   ├── Network
│   └── Shared Services
│
├── Sandbox OU
│   └── Sandbox
│
└── Workloads OU
    ├── Dev
    └── Prod
```

Accounts Created: 8 [including management account]

```text
Audit
LogArchive
Network
SharedServices
Sandbox
Dev
Prod
```

Characteristics:

* Dedicated Security OU following AWS SRA principles.
* Dedicated Network account for centralized networking.
* Dedicated Shared Services account for common platform services.
* Dedicated Sandbox account for experimentation, Terraform testing, service evaluation, and proof-of-concepts.
* Separate Dev and Prod accounts for workload isolation.
* No Stage account yet.
* No Playground account yet.
* Lower operational overhead than Enterprise mode.

The Standard profile is intended to be the recommended deployment mode for most small-to-medium organizations because it provides meaningful account isolation while keeping account count relatively low.


---

# Profile 3: Enterprise

Target:

* Large engineering organizations
* Platform engineering teams
* Regulated environments
* Multi-team enterprises
* Organizations implementing AWS Security Reference Architecture (SRA) recommendations

Architecture:

```text
Organization
│
├── Security OU
│   ├── Audit
│   └── Log Archive
│
├── Infrastructure OU
│   ├── Network
│   └── Shared Services
│
├── Sandbox OU
│   ├── Sandbox
│   └── Playground
│
└── Workloads OU
    ├── Dev
    ├── Stage
    └── Prod
```

Accounts Created: 10 [including management account]

```text
Audit
LogArchive
Network
SharedServices
Sandbox
Playground
Dev
Stage
Prod
```

Characteristics:

* Dedicated Security OU implementing AWS SRA security account patterns.
* Dedicated Audit account for Security Hub, GuardDuty, Inspector, Access Analyzer, delegated administrators, and security operations.
* Dedicated Log Archive account for immutable audit and operational log retention.
* Dedicated Network account for centralized networking, Transit Gateway, inspection architectures, and shared connectivity services.
* Dedicated Shared Services account for CI/CD, artifact repositories, internal tooling, directory services, and platform services.
* Dedicated Sandbox account for experimentation, proof-of-concepts, Terraform validation, and service evaluation.
* Dedicated Playground account for short-lived testing environments and disposable experimentation.
* Complete workload isolation through separate Dev, Stage, and Prod accounts.
* Strong separation of duties between infrastructure, security, and application teams.
* Supports advanced SCP strategies, delegated administration, centralized logging, and enterprise governance controls.
* Aligns closely with AWS Landing Zone Accelerator and AWS Security Reference Architecture recommendations.

Benefits:

* Maximum security isolation.
* Reduced blast radius between environments.
* Strong governance and compliance posture.
* Clear ownership boundaries across teams.
* Scalable architecture capable of supporting multiple applications and business units.
* Simplifies implementation of enterprise security controls and auditing requirements.

Trade-offs:

* Highest AWS account count.
* Increased operational complexity.
* More cross-account access management.
* More Terraform orchestration and dependency management.

The Enterprise profile is intended for organizations that require strong governance, security isolation, compliance readiness, and long-term scalability across multiple teams and workloads.


---

# Terraform Design Requirements

## Profile Selection

Expose a variable similar to:

```hcl
variable "landing_zone_profile" {
  type = string
}
```

Supported values:

```text
minimal
standard
enterprise
```

---

## Conditional Module Creation

Accounts should be created conditionally.

Example:

```hcl
module "shared_services" {
  count = contains(
    ["standard", "enterprise"],
    var.landing_zone_profile
  ) ? 1 : 0
}
```

Sandbox accounts should only be deployed for enterprise profile.

---

## Future Module Behavior

All future modules must respect deployment profiles:

### organization/

* OUs
* Accounts

### security/

* GuardDuty
* Security Hub
* Inspector
* Macie
* Access Analyzer

### logging/

* Organization CloudTrail
* Log Archive Buckets

### networking/

* Transit Gateway
* Inspection VPC
* Shared Networking

### identity/

* IAM Identity Center
* Permission Sets

Each module must deploy only components relevant to the selected profile.

---

# Long-Term Objective

Create a reusable Terraform Landing Zone framework where users can choose:

```bash
terraform apply \
  -var-file=profiles/minimal.tfvars
```

or

```bash
terraform apply \
  -var-file=profiles/standard.tfvars
```

or

```bash
terraform apply \
  -var-file=profiles/enterprise.tfvars
```

and receive the corresponding Landing Zone architecture without changing Terraform code.

The same modules must support all deployment modes.
