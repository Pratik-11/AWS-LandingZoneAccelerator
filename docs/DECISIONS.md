# Decisions

Why this repo is shaped the way it is. Each entry is a choice with a real
alternative — if you disagree with the reasoning, change it; that is the point of
a reference.

---

## 1. Numbered layers, not one root module

**Decision:** seven independently-applied root modules under `layers/`, numbered in
dependency order, sharing a library of modules under `modules/`.

**Why:** one root module for an entire organization means one state file, and one
state file means a bad `terraform destroy` can take out everything from the org
down. Splitting by layer bounds the damage and lets you re-apply networking
without re-planning the org.

The numbering is the documentation. `02` cannot run before `01`.

**Alternative:** Terraform workspaces. Rejected — workspaces vary *inputs* to the
same configuration, not the configuration itself. These layers create genuinely
different resources.

**Cost:** seven `terraform apply` runs instead of one, and cross-layer values must
be passed through remote state.

---

## 2. Layers read each other through `terraform_remote_state`

**Decision:** downstream layers read `01-organization`'s outputs directly from its
state file in S3.

**Why:** it is the built-in mechanism, needs no extra infrastructure, and the
dependency is visible in `providers.tf` where you look for it anyway.

**Alternative:** publish shared values to SSM Parameter Store and have layers read
those. Looser coupling — layers depend on a contract rather than on another
layer's state file, and refactoring `01-organization` cannot break `05-network`.
Better at scale, and worth adopting if this grows.

**Cost:** the coupling is real. Renaming an output in `01-organization` breaks
every layer that reads it, and you find out at plan time.

---

## 3. Security services are administered from Audit, not from management

**Decision:** enable GuardDuty, Security Hub, Config, Inspector and Access Analyzer
from the management account, then immediately delegate administration to Audit.

**Why:** the management account has unlimited billing authority and **cannot be
constrained by SCPs**. Anything that requires day-to-day access to it is a standing
risk. Delegation lets the security team operate entirely in Audit.

**Alternative:** run everything from management. Simpler, one fewer account, and
the first thing a security reviewer flags.

**Cost:** two providers per service instead of one, and `depends_on` ordering that
matters — delegation must land before configuration, and IAM propagation is not
instant.

---

## 4. `OrganizationAccountAccessRole` for cross-account access

**Decision:** assume the role AWS creates automatically in every account made
through Organizations.

**Why:** it exists the moment the account does, with no bootstrap. That solves the
chicken-and-egg of "you need a role to create the role."

**Alternative:** a purpose-built least-privilege Terraform role per account, created
during account baseline. Correct for production — `OrganizationAccountAccessRole`
is effectively `AdministratorAccess`, which is more than any pipeline should hold.

**Cost:** every layer runs with admin in every account. Acceptable for a reference;
tighten it before production.

---

## 5. SCPs attach to OUs, never to accounts

**Why:** accounts inherit from their OU, so moving an account between OUs changes
its guardrails with no Terraform edit. Attaching to accounts means editing
Terraform every time an account changes purpose.

**Cost:** your OU design has to actually reflect your policy boundaries. If two
accounts in one OU need different guardrails, the OU is wrong.

---

## 6. No feature flags, no persona toggles, no config language

**Decision:** no `enable_*` variables, no `landing_zone_type`, no YAML. To remove
something, delete its module block.

**Why:** this repo's job is to be *read*. A toggle means the resources you get
depend on a variable somewhere else, and the reader has to simulate the conditional
to know what exists. Deleting a visible block is unambiguous.

There was a persona toggle here. It gated SCP creation on a name allow-list whose
strings had drifted from the names actually passed in, so **eight of ten guardrails
silently failed to deploy** while `terraform apply` reported success. That is the
characteristic failure of configurable-by-default: it fails quietly. It was
removed rather than fixed.

**Alternative:** a real config surface. Right for a product you ship to many
customers. Wrong for a template someone forks once and owns.

**Cost:** no single knob to switch environments. Correct — this repo is meant to be
edited, not configured.

---

## 7. Providers are hand-written, one per account

**Decision:** fourteen provider blocks in `03-config-recorders`, ten in
`05-network`, written out by hand.

**Why:** Terraform does not allow `for_each` on providers, so within one root
module there is no alternative. Given that, being explicit is a feature — reading
`providers.tf` shows you exactly which accounts a layer touches.

**Alternative and the real answer at scale:** a root module parameterised on a
single `account_id`, looped by a Makefile or CI matrix. See
[KNOWN-LIMITS.md §1](KNOWN-LIMITS.md).

**Cost:** does not scale past roughly ten accounts.

---

## 8. VPC CIDRs live in `.tf` files, not in variables

**Why:** the address plan is something you read as a whole. Spread across a tfvars
file it is only assembled at plan time, and reviewing it means reconstructing it in
your head.

**Alternative:** AWS IPAM, which allocates non-overlapping blocks automatically.
The right answer past ~20 accounts, and it removes an entire class of
human error.

**Cost:** hand-allocation. Collisions are unrecoverable without rebuilding a VPC.

---

## 9. The account assignment matrix is written out longhand

**Decision:** twenty-one explicit entries in `06-identity/assignments.tf` rather
than a nested loop over groups × accounts.

**Why:** this is the file an auditor reads to answer "who can reach production."
An explicit list answers that by inspection. A comprehension has to be executed
mentally, and the edge cases — developers get ReadOnly on Prod but Developer on
Dev, security gets everything except management — are exactly where a clever loop
grows special cases and becomes harder to read than the list it replaced.

**Cost:** adding an account means adding rows. Deliberate: an access grant should
be a visible diff.
