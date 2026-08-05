#!/usr/bin/env bash
# Destroys the landing zone in reverse dependency order.
#
# Read this before running it:
#
#   * Member ACCOUNTS ARE NOT DELETED. AWS has no API for closing an account.
#     Terraform drops them from state and they keep existing, keep billing, and
#     keep their email addresses reserved — which means you cannot recreate the
#     landing zone with the same emails afterwards.
#   * 02-logging may refuse to destroy. The protect-log-archive SCP denies
#     deletion of the audit buckets. That is the guardrail working.
#   * 00-bootstrap holds the state bucket and lock table, both carrying
#     prevent_destroy. It is deliberately NOT torn down here.
set -euo pipefail
cd "$(dirname "$0")/.."

# reverse of deploy order
LAYERS=(06-identity 05-network 04-security 03-config-recorders 02-logging 01-organization)

cat <<'WARN'
This destroys the landing zone: Identity Center assignments, VPCs and the
Transit Gateway, all security tooling, Config recorders, the audit log buckets,
and every SCP guardrail in the organization.

Member accounts will NOT be deleted and their emails stay reserved.
00-bootstrap (state bucket + lock table) is left alone.

WARN
read -rp "Type 'destroy the landing zone' to continue: " ok
[[ "$ok" == "destroy the landing zone" ]] || { echo "aborted"; exit 1; }

for layer in "${LAYERS[@]}"; do
  echo
  echo "==> destroying $layer"
  terraform -chdir="layers/$layer" init -input=false -reconfigure \
    -backend-config=backend.s3.tfbackend
  terraform -chdir="layers/$layer" destroy -input=false || {
    echo "!! $layer did not destroy cleanly — likely an SCP denying it, which"
    echo "   is the intended behaviour. Continuing."
  }
done

cat <<'DONE'

Teardown finished.

Still present, by design:
  * every member account (close them manually in the console if you must)
  * the state bucket and lock table in 00-bootstrap
DONE
