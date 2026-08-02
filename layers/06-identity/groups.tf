resource "aws_identitystore_group" "platform_engineers" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "PlatformEngineers"
  description       = "Landing zone operators — full admin across all accounts"
}

resource "aws_identitystore_group" "developers" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "Developers"
  description       = "App developers — dev access to Dev/Sandbox, read-only to Prod"
}

resource "aws_identitystore_group" "security_team" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "SecurityTeam"
  description       = "Security engineers — security audit access across all accounts"
}

resource "aws_identitystore_group" "finance" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "Finance"
  description       = "Finance team — billing access to management account only"
}
