# ===============================
# ACCOUNT-LEVEL USER & GROUP MANAGEMENT
# ===============================

# Create account-level groups for different roles
resource "databricks_group" "account_admins" {
  provider     = databricks.accounts
  display_name = "Account Admins"
}

resource "databricks_group" "workspace_admins" {
  provider     = databricks.accounts
  display_name = "Workspace Admins"
}

resource "databricks_group" "data_engineers" {
  provider     = databricks.accounts
  display_name = "Data Engineers"
}

resource "databricks_group" "data_analysts" {
  provider     = databricks.accounts
  display_name = "Data Analysts"
}

# Create or get the current user at account level
resource "databricks_user" "me" {
  provider  = databricks.accounts
  user_name = data.google_client_openid_userinfo.me.email
  force     = true
}

# Add additional users if specified
resource "databricks_user" "additional_users" {
  provider  = databricks.accounts
  for_each  = toset(var.additional_users)
  user_name = each.value
  force     = true
}

# Add current user to account admins group
resource "databricks_group_member" "me_account_admin" {
  provider  = databricks.accounts
  group_id  = databricks_group.account_admins.id
  member_id = databricks_user.me.id
}

# Add current user to workspace admins group
resource "databricks_group_member" "me_workspace_admin" {
  provider  = databricks.accounts
  group_id  = databricks_group.workspace_admins.id
  member_id = databricks_user.me.id
}

# Add additional users to appropriate groups based on their roles
resource "databricks_group_member" "additional_user_memberships" {
  provider  = databricks.accounts
  for_each  = var.user_group_assignments
  group_id  = local.group_id_map[each.value]
  member_id = databricks_user.additional_users[each.key].id
}