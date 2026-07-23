resource "aws_identitystore_user" "users" {
  for_each = var.sso_users

  identity_store_id = local.sso_identity_store_id
  user_name         = each.key
  display_name      = each.value.display_name

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    type    = "work"
    primary = true
  }
}

# Group memberships — flatten the user-to-groups mapping into individual membership resources
locals {
  group_membership_map = {
    "platform_engineers" = aws_identitystore_group.platform_engineers.group_id
    "developers"         = aws_identitystore_group.developers.group_id
    "security_team"      = aws_identitystore_group.security_team.group_id
    "finance"            = aws_identitystore_group.finance.group_id
  }

  # Flatten: for each user, for each group they belong to, create a membership entry
  user_group_memberships = merge([
    for username, user_config in var.sso_users : {
      for group in user_config.groups :
      "${username}-${group}" => {
        user_id  = aws_identitystore_user.users[username].user_id
        group_id = local.group_membership_map[group]
      }
    }
  ]...)
}

resource "aws_identitystore_group_membership" "memberships" {
  for_each = local.user_group_memberships

  identity_store_id = local.sso_identity_store_id
  group_id          = each.value.group_id
  member_id         = each.value.user_id
}
