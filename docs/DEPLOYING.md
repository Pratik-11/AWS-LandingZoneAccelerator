# Deploying

Start to finish, from an empty AWS account to a running landing zone.

```bash
make check                            # confirms terraform + pyyaml
$EDITOR configs/landing-zone.yaml     # the only file you edit
make deploy                           # applies layers 00 → 06
```

Everything below is detail on those three lines: what to put in the YAML, what
each layer does, how long it takes, and what to do when it stops.

---

## 1. Before you start

**Tools**

| | |
|---|---|
| Terraform ≥ 1.6 | `make check` verifies |
| Python 3 + pyyaml | `pip install pyyaml` |
| AWS CLI profile | admin in the management (payer) account |

**Two console steps Terraform cannot do**

1. **Enable IAM Identity Center** in the management account. It is a per-org
   singleton with no Terraform resource. Layer 06 reads it as a data source and
   fails without it.
2. **Activate IAM access to billing.** Management account → account menu
   (top right) → Account → *IAM User and Role Access to Billing Information* →
   Edit → Activate. Without it, `BillingAccess` users see "You need permissions"
   and your IAM policy is ignored entirely.

**Before you commit to anything**

You are about to create seven AWS accounts. **AWS has no API for deleting an
account** — closing one is a manual, rate-limited console action, and the email
address stays reserved afterwards, so you cannot rebuild with the same
addresses. Get the emails right the first time.

---

## 2. Fill in the config

Everything lives in `configs/landing-zone.yaml`. In practice you change five
things:

```yaml
org_name: acme                              # 1. your slug
unique_id: a1b2                             # 2. anything unique — S3 names are global
aws_profile: my-management-profile          # 3. your CLI profile

regions:
  primary: us-east-1                        # 4. where everything is built
  secondary: ap-south-1                     #    only used by the region SCP

email_pattern: "aws+{account}@example.com"  # 5. your domain
alert_email: security-alerts@example.com
```

That is enough to deploy. The rest of the file has sensible defaults.

**What gets derived, so you never type it twice**

```
acme-lz-terraform-state-a1b2     state bucket
acme-lz-terraform-locks-a1b2     lock table
acme-lz-cloudtrail-logs-a1b2     audit trail
acme-lz-config-logs-a1b2         config history
acme-lz-flow-logs-a1b2           VPC flow logs
aws+audit@example.com            from email_pattern, per account
```

Override any bucket name under `bucket_overrides`, or any single email with an
explicit `email:` on that account.

**Check it before you spend money:**

```bash
make render     # fails loudly on a bad OU, a missing key, an unmatched account
```

---

## 3. Deploy

**One shot:**

```bash
make deploy
```

It asks you to type `deploy` first. `make deploy --yes` skips that if you are
scripting it.

**Or a layer at a time** — better while you are still reading the code:

```bash
make plan  LAYER=01-organization
make apply LAYER=01-organization
```

Order is fixed and each layer reads the one before it:

```
00-bootstrap → 01-organization → 02-logging → 03-config-recorders
             → 04-security → 05-network → 06-identity
```

### What each layer does

| Layer | Creates | Roughly | Watch for |
|---|---|---|---|
| `00-bootstrap` | state bucket, lock table, CI OIDC role | 1 min | Bucket name collision |
| `01-organization` | org, 4 OUs, 7 accounts, 14 SCPs | **10–25 min** | Slow; AWS rate-limits account creation |
| `02-logging` | KMS key, 3 log buckets, org CloudTrail | 2 min | Bucket name collisions |
| `03-config-recorders` | AWS Config in all 7 accounts | 3 min | — |
| `04-security` | GuardDuty, Security Hub, Inspector, Access Analyzer, all delegated to Audit | 5 min | Delegation races; Security Hub policy (see §5) |
| `05-network` | TGW, 5 VPCs, RAM share, private DNS | 5–8 min | NAT gateways start billing here |
| `06-identity` | permission sets, groups, users, 21 assignments | 2 min | Needs Identity Center enabled |

`make deploy` is re-runnable. If it stops, fix the cause and run it again — it
is a normal `terraform apply` per layer, so completed work is a no-op.

---

## 4. Check it worked

```bash
aws organizations list-accounts --profile <your-profile> --output table
aws organizations list-policies --filter SERVICE_CONTROL_POLICY --profile <your-profile>
terraform -chdir=layers/05-network output vpc_ids
```

Then, in the console:

- **Audit account** → GuardDuty and Security Hub both show all accounts as members
- **LogArchive** → the CloudTrail bucket has objects under `AWSLogs/`
- **Your inbox** → confirm the SNS subscription. Until someone clicks that link
  the subscription sits `PendingConfirmation` and **no alert is ever delivered**,
  with no error anywhere.

---

## 5. When it stops

Real failure modes, in the order you are likely to hit them.

**`BucketAlreadyExists` in 00-bootstrap or 02-logging**
S3 names are global across every AWS customer. Change `unique_id` and
`make render` again.

**`EmailAlreadyExists` in 01-organization**
That address already belongs to an AWS account somewhere, possibly one you
forgot. Use a different one — you cannot reuse it.

**01-organization times out part way through**
Expected. AWS rate-limits account creation and Terraform gives up before AWS
does. Re-run `make apply LAYER=01-organization`; accounts already created are
left alone.

**`FinalizingOrganizationException`**
The org is still settling from the previous call. Wait a minute, re-run.

**04-security fails with AccessDenied or a missing delegated admin**
Delegation has to land before the service is configured in Audit, and IAM
propagation is not instant. The `depends_on` chains handle ordering but not
propagation delay. Re-run the layer.

**04-security fails on `aws_securityhub_configuration_policy`**
Known limitation. That resource was originally created in the console and
imported, and the file carries a `# match exactly` comment on its name. On a
fresh org it may not create cleanly on the first attempt. Either re-run, or
comment out `layers/04-security/securityhub-central-config.tf` and create the
policy in the console. See [KNOWN-LIMITS.md §3](KNOWN-LIMITS.md).

**06-identity fails on `tolist(...)[0]` or an index out of range**
IAM Identity Center is not enabled. That is §1 step 1. The error message will
not tell you this.

**A `BillingAccess` user sees "You need permissions"**
§1 step 2, the billing console activation. The IAM policy is correct and being
ignored.

**Prod instances cannot reach the internet**
Not a bug in the deploy — by design and incomplete. Prod has no NAT and routes
`0.0.0.0/0` to the Transit Gateway, but nothing in this repo terminates that
path. You need a NAT or firewall in an egress VPC in the Network account plus
TGW routes to it. See [KNOWN-LIMITS.md §4](KNOWN-LIMITS.md).

---

## 6. Changing things afterwards

**A value** — edit the YAML, then:

```bash
make plan  LAYER=<the affected layer>
make apply LAYER=<the affected layer>
```

**Adding an account** — add it under `accounts:` and re-apply
`01-organization`. Then wire it into the layers that reference accounts by
name: providers and modules in `03-config-recorders`, `05-network`,
`06-identity`. It is not a one-line change, and
[KNOWN-LIMITS.md §1](KNOWN-LIMITS.md) explains why Terraform makes that
unavoidable.

**Renaming** an account or OU is a repo-wide change — those strings are looked
up in four layers. See [ADAPTING.md §3](ADAPTING.md).

**Removing a guardrail** — delete its module block in
`layers/01-organization/scps.tf`. There is no switch in the YAML on purpose;
[DECISIONS.md §6](DECISIONS.md) explains why.

**VPC CIDRs** are in `layers/05-network/*.tf`, not the YAML, so the whole
address plan reads in one place.

---

## 7. Tearing it down

```bash
make teardown
```

Reverses the order and asks you to type a full confirmation phrase. Three
things it will not do:

- **Accounts are not deleted.** No API exists. They keep existing, keep
  billing, and keep their emails reserved.
- **02-logging may refuse.** The `protect-log-archive` SCP denies deletion of
  the audit buckets. That is the guardrail working correctly.
- **00-bootstrap is left alone.** It holds the state bucket and lock table,
  both carrying `prevent_destroy`.

Check for leftover NAT gateways and the Transit Gateway afterwards — those bill
hourly whether or not anything uses them.
