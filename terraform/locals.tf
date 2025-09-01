# Local configuration for workspaces
locals {
  workspaces = {
    "workspace-1" = {
      catalog_name    = "catalog-a"
      use_case        = "analytics"
      subnet_cidr     = "10.1.0.0/24"
      cluster_workers = 1
    }
    "workspace-2" = {
      catalog_name    = "catalog-b"
      use_case        = "ml-training"
      subnet_cidr     = "10.2.0.0/24"
      cluster_workers = 2
    }
  }
  
  group_id_map = {
    "account_admin"   = databricks_group.account_admins.id
    "workspace_admin" = databricks_group.workspace_admins.id
    "data_engineer"   = databricks_group.data_engineers.id
    "data_analyst"    = databricks_group.data_analysts.id
  }
}

# Data sources
data "google_client_openid_userinfo" "me" {}
data "google_client_config" "current" {}