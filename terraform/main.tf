# Generate random suffix for unique resource names
resource "random_string" "suffix" {
  special = false
  upper   = false
  length  = 6
}

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

# Provider configurations
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "databricks" {
  alias                  = "accounts"
  host                   = "https://accounts.gcp.databricks.com"
  google_service_account = var.databricks_google_service_account
  account_id             = var.databricks_account_id
}

provider "databricks" {
  alias                  = "workspace-1"
  host                   = databricks_mws_workspaces.workspaces["workspace-1"].workspace_url
  google_service_account = var.databricks_google_service_account
}

provider "databricks" {
  alias                  = "workspace-2"
  host                   = databricks_mws_workspaces.workspaces["workspace-2"].workspace_url
  google_service_account = var.databricks_google_service_account
}

# Data sources
data "google_client_openid_userinfo" "me" {}
data "google_client_config" "current" {}

# Service Account for Databricks Provisioning
resource "google_service_account" "databricks_provisioning" {
  account_id   = "${var.prefix}-databricks-sa-${random_string.suffix.result}"
  display_name = "Service Account for Databricks Provisioning"
  #important for terrafrom destroy - since there is no depend um
  lifecycle {
    prevent_destroy = true
  }

}

# IAM policy for service account impersonation
data "google_iam_policy" "impersonation" {
  binding {
    role    = "roles/iam.serviceAccountTokenCreator"
    members = [
      "user:${data.google_client_openid_userinfo.me.email}"
    ]
  }
}

resource "google_service_account_iam_policy" "impersonatable" {
  service_account_id = google_service_account.databricks_provisioning.name
  policy_data        = data.google_iam_policy.impersonation.policy_data
}

# Custom role for Databricks Workspace Creator
resource "google_project_iam_custom_role" "workspace_creator" {
  role_id = "${var.prefix}_workspace_creator_${random_string.suffix.result}"
  title   = "Databricks Workspace Creator"
  permissions = [
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.get",
    "iam.roles.create",
    "iam.roles.delete",
    "iam.roles.get",
    "iam.roles.update",
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
    "serviceusage.services.get",
    "serviceusage.services.list",
    "serviceusage.services.enable",
    "compute.networks.get",
    "compute.networks.updatePolicy",
    "compute.projects.get",
    "compute.subnetworks.get",
    "compute.subnetworks.getIamPolicy",
    "compute.subnetworks.setIamPolicy",
    "compute.firewalls.get",
    "compute.firewalls.create",
  ]
}

# Assign custom role to service account
resource "google_project_iam_member" "sa_workspace_creator" {
  project = var.project
  role    = google_project_iam_custom_role.workspace_creator.id
  member  = "serviceAccount:${google_service_account.databricks_provisioning.email}"
}

# ===============================
# SHARED NETWORKING RESOURCES
# ===============================

# VPC Network (shared)
resource "google_compute_network" "dbx_private_vpc" {
  name                    = "${var.prefix}-network-${random_string.suffix.result}"
  auto_create_subnetworks = false
}

# Cloud Router for NAT (shared)
resource "google_compute_router" "router" {
  name    = "${var.prefix}-router-${random_string.suffix.result}"
  region  = var.region
  network = google_compute_network.dbx_private_vpc.id
}

# NAT Gateway (shared)
resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefix}-nat-${random_string.suffix.result}"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# ===============================
# PER-WORKSPACE NETWORKING
# ===============================

# Subnets (per workspace for isolation)
resource "google_compute_subnetwork" "dbx_subnets" {
  for_each                 = local.workspaces
  name                     = "${var.prefix}-subnet-${each.key}-${random_string.suffix.result}"
  ip_cidr_range            = each.value.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.dbx_private_vpc.id
  private_ip_google_access = true
}

# Databricks Network Configurations (per workspace)
resource "databricks_mws_networks" "networks" {
  for_each     = local.workspaces
  provider     = databricks.accounts
  account_id   = var.databricks_account_id
  network_name = "${var.prefix}-network-${each.key}-${random_string.suffix.result}"
  gcp_network_info {
    network_project_id = var.project
    vpc_id             = google_compute_network.dbx_private_vpc.name
    subnet_id          = google_compute_subnetwork.dbx_subnets[each.key].name
    subnet_region      = google_compute_subnetwork.dbx_subnets[each.key].region
  }
}

# ===============================
# DATABRICKS WORKSPACES
# ===============================

# Databricks Workspaces (per workspace)
resource "databricks_mws_workspaces" "workspaces" {
  for_each       = local.workspaces
  provider       = databricks.accounts
  account_id     = var.databricks_account_id
  workspace_name = "${var.prefix}-${each.key}"
  location       = var.region

  cloud_resource_container {
    gcp {
      project_id = var.project
    }
  }

  network_id = databricks_mws_networks.networks[each.key].network_id
  depends_on = [google_compute_router_nat.nat]
}

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

# ===============================
# WORKSPACE-LEVEL PERMISSIONS
# ===============================

# Assign workspace admin permissions to workspace admins group
resource "databricks_mws_permission_assignment" "workspace_admins" {
  for_each     = local.workspaces
  provider     = databricks.accounts
  workspace_id = databricks_mws_workspaces.workspaces[each.key].workspace_id
  principal_id = databricks_group.workspace_admins.id
  permissions  = ["ADMIN"]
}

# Assign workspace user permissions to data engineers group
resource "databricks_mws_permission_assignment" "data_engineers" {
  for_each     = local.workspaces
  provider     = databricks.accounts
  workspace_id = databricks_mws_workspaces.workspaces[each.key].workspace_id
  principal_id = databricks_group.data_engineers.id
  permissions  = ["USER"]
}

# Assign workspace user permissions to data analysts group
resource "databricks_mws_permission_assignment" "data_analysts" {
  for_each     = local.workspaces
  provider     = databricks.accounts
  workspace_id = databricks_mws_workspaces.workspaces[each.key].workspace_id
  principal_id = databricks_group.data_analysts.id
  permissions  = ["USER"]
}

# ===============================
# UNITY CATALOG SETUP (SHARED)
# ===============================

# Unity Catalog Metastore (shared across workspaces)
resource "databricks_metastore" "this" {
  provider      = databricks.accounts
  name          = "${var.prefix}-metastore-${random_string.suffix.result}"
  region        = var.region
  force_destroy = true
}

# Metastore Assignment (per workspace)
resource "databricks_metastore_assignment" "assignments" {
  for_each             = local.workspaces
  provider             = databricks.accounts
  workspace_id         = databricks_mws_workspaces.workspaces[each.key].workspace_id
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "hive_metastore"
}

# ===============================
# PER-WORKSPACE STORAGE & CATALOGS
# ===============================

# Storage Buckets for Unity Catalog (per workspace)
resource "google_storage_bucket" "catalog_buckets" {
  for_each      = local.workspaces
  name          = "${var.prefix}-catalog-${each.key}-${random_string.suffix.result}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

# Storage Buckets for Unmanaged Iceberg Tables (per workspace)
resource "google_storage_bucket" "unmanaged_buckets" {
  for_each      = local.workspaces
  name          = "${var.prefix}-unmanaged-${each.key}-${random_string.suffix.result}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

# ===============================
# WORKSPACE-1 SPECIFIC RESOURCES
# ===============================

# Storage Credential for workspace-1
resource "databricks_storage_credential" "catalog_credential_ws1" {
  provider = databricks.workspace-1
  name     = "${local.workspaces["workspace-1"].catalog_name}-credential"
  databricks_gcp_service_account {}
  depends_on = [databricks_metastore_assignment.assignments]
}

# IAM permissions for catalog bucket workspace-1
resource "google_storage_bucket_iam_member" "catalog_admin_ws1" {
  bucket = google_storage_bucket.catalog_buckets["workspace-1"].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${databricks_storage_credential.catalog_credential_ws1.databricks_gcp_service_account[0].email}"
}

resource "google_storage_bucket_iam_member" "catalog_reader_ws1" {
  bucket = google_storage_bucket.catalog_buckets["workspace-1"].name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${databricks_storage_credential.catalog_credential_ws1.databricks_gcp_service_account[0].email}"
}

# External Location for workspace-1
resource "databricks_external_location" "catalog_location_ws1" {
  provider        = databricks.workspace-1
  name            = "${local.workspaces["workspace-1"].catalog_name}-location"
  url             = "gs://${google_storage_bucket.catalog_buckets["workspace-1"].name}"
  credential_name = databricks_storage_credential.catalog_credential_ws1.id
  comment         = "External location for ${local.workspaces["workspace-1"].catalog_name}"
  depends_on = [
    databricks_metastore_assignment.assignments,
    google_storage_bucket_iam_member.catalog_reader_ws1,
    google_storage_bucket_iam_member.catalog_admin_ws1
  ]
}

# Unity Catalog for workspace-1
resource "databricks_catalog" "catalog_ws1" {
  provider     = databricks.workspace-1
  name         = local.workspaces["workspace-1"].catalog_name
  storage_root = "gs://${google_storage_bucket.catalog_buckets["workspace-1"].name}"
  comment      = "Catalog for workspace-1 - ${local.workspaces["workspace-1"].use_case}"
  properties = {
    purpose   = local.workspaces["workspace-1"].use_case
    workspace = "workspace-1"
  }
  depends_on = [databricks_metastore_assignment.assignments]
}

# Default schema for workspace-1
resource "databricks_schema" "default_schema_ws1" {
  provider     = databricks.workspace-1
  catalog_name = databricks_catalog.catalog_ws1.name
  name         = "default"
  comment      = "Default schema for ${local.workspaces["workspace-1"].catalog_name}"
}

# Data sources for workspace-1
data "databricks_spark_version" "latest_lts_ws1" {
  provider          = databricks.workspace-1
  long_term_support = true
  depends_on        = [databricks_mws_workspaces.workspaces]
}

data "databricks_node_type" "smallest_ws1" {
  provider   = databricks.workspace-1
  local_disk = true
  depends_on = [databricks_mws_workspaces.workspaces]
}

# Admin cluster for workspace-1
resource "databricks_cluster" "admin_cluster_ws1" {
  provider                = databricks.workspace-1
  cluster_name            = "${var.prefix}-admin-cluster-workspace-1"
  spark_version           = data.databricks_spark_version.latest_lts_ws1.id
  node_type_id            = data.databricks_node_type.smallest_ws1.id
  autotermination_minutes = 30
  num_workers             = 1
  data_security_mode      = "USER_ISOLATION"

  depends_on = [databricks_metastore_assignment.assignments]
}

# Shared cluster for workspace-1
resource "databricks_cluster" "shared_cluster_ws1" {
  provider                = databricks.workspace-1
  cluster_name            = "${var.prefix}-shared-cluster-workspace-1"
  spark_version           = data.databricks_spark_version.latest_lts_ws1.id
  node_type_id            = data.databricks_node_type.smallest_ws1.id
  autotermination_minutes = 30
  num_workers             = local.workspaces["workspace-1"].cluster_workers
  data_security_mode      = "USER_ISOLATION"

  depends_on = [databricks_metastore_assignment.assignments]
}

# ===============================
# WORKSPACE-2 SPECIFIC RESOURCES
# ===============================

# Storage Credential for workspace-2
resource "databricks_storage_credential" "catalog_credential_ws2" {
  provider = databricks.workspace-2
  name     = "${local.workspaces["workspace-2"].catalog_name}-credential"
  databricks_gcp_service_account {}
  depends_on = [databricks_metastore_assignment.assignments]
}

# IAM permissions for catalog bucket workspace-2
resource "google_storage_bucket_iam_member" "catalog_admin_ws2" {
  bucket = google_storage_bucket.catalog_buckets["workspace-2"].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${databricks_storage_credential.catalog_credential_ws2.databricks_gcp_service_account[0].email}"
}

resource "google_storage_bucket_iam_member" "catalog_reader_ws2" {
  bucket = google_storage_bucket.catalog_buckets["workspace-2"].name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${databricks_storage_credential.catalog_credential_ws2.databricks_gcp_service_account[0].email}"
}

# External Location for workspace-2
resource "databricks_external_location" "catalog_location_ws2" {
  provider        = databricks.workspace-2
  name            = "${local.workspaces["workspace-2"].catalog_name}-location"
  url             = "gs://${google_storage_bucket.catalog_buckets["workspace-2"].name}"
  credential_name = databricks_storage_credential.catalog_credential_ws2.id
  comment         = "External location for ${local.workspaces["workspace-2"].catalog_name}"
  depends_on = [
    databricks_metastore_assignment.assignments,
    google_storage_bucket_iam_member.catalog_reader_ws2,
    google_storage_bucket_iam_member.catalog_admin_ws2
  ]
}

# Unity Catalog for workspace-2
resource "databricks_catalog" "catalog_ws2" {
  provider     = databricks.workspace-2
  name         = local.workspaces["workspace-2"].catalog_name
  storage_root = "gs://${google_storage_bucket.catalog_buckets["workspace-2"].name}"
  comment      = "Catalog for workspace-2 - ${local.workspaces["workspace-2"].use_case}"
  properties = {
    purpose   = local.workspaces["workspace-2"].use_case
    workspace = "workspace-2"
  }
  depends_on = [databricks_metastore_assignment.assignments]
}

# Default schema for workspace-2
resource "databricks_schema" "default_schema_ws2" {
  provider     = databricks.workspace-2
  catalog_name = databricks_catalog.catalog_ws2.name
  name         = "default"
  comment      = "Default schema for ${local.workspaces["workspace-2"].catalog_name}"
}

# Data sources for workspace-2
data "databricks_spark_version" "latest_lts_ws2" {
  provider          = databricks.workspace-2
  long_term_support = true
  depends_on        = [databricks_mws_workspaces.workspaces]
}

data "databricks_node_type" "smallest_ws2" {
  provider   = databricks.workspace-2
  local_disk = true
  depends_on = [databricks_mws_workspaces.workspaces]
}

# Admin cluster for workspace-2
resource "databricks_cluster" "admin_cluster_ws2" {
  provider                = databricks.workspace-2
  cluster_name            = "${var.prefix}-admin-cluster-workspace-2"
  spark_version           = data.databricks_spark_version.latest_lts_ws2.id
  node_type_id            = data.databricks_node_type.smallest_ws2.id
  autotermination_minutes = 30
  num_workers             = 1
  data_security_mode      = "USER_ISOLATION"

  depends_on = [databricks_metastore_assignment.assignments]
}

# Shared cluster for workspace-2
resource "databricks_cluster" "shared_cluster_ws2" {
  provider                = databricks.workspace-2
  cluster_name            = "${var.prefix}-shared-cluster-workspace-2"
  spark_version           = data.databricks_spark_version.latest_lts_ws2.id
  node_type_id            = data.databricks_node_type.smallest_ws2.id
  autotermination_minutes = 30
  num_workers             = local.workspaces["workspace-2"].cluster_workers
  data_security_mode      = "USER_ISOLATION"

  depends_on = [databricks_metastore_assignment.assignments]
}

# ===============================
# UNITY CATALOG PERMISSIONS
# ===============================

# Grant metastore admin to workspace admins - workspace-1
resource "databricks_grants" "metastore_grants_ws1" {
  provider  = databricks.workspace-1
  metastore = databricks_metastore.this.id
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["CREATE_CATALOG", "CREATE_CONNECTION", "CREATE_EXTERNAL_LOCATION", "CREATE_RECIPIENT", "CREATE_SHARE", "CREATE_STORAGE_CREDENTIAL", "USE_MARKETPLACE_ASSETS"]
  }
  depends_on = [databricks_metastore_assignment.assignments]
}

# Grant metastore admin to workspace admins - workspace-2
resource "databricks_grants" "metastore_grants_ws2" {
  provider  = databricks.workspace-2
  metastore = databricks_metastore.this.id
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["CREATE_CATALOG", "CREATE_CONNECTION", "CREATE_EXTERNAL_LOCATION", "CREATE_RECIPIENT", "CREATE_SHARE", "CREATE_STORAGE_CREDENTIAL", "USE_MARKETPLACE_ASSETS"]
  }
  depends_on = [databricks_metastore_assignment.assignments]
}

# Grant catalog permissions - workspace-1
resource "databricks_grants" "catalog_grants_ws1" {
  provider = databricks.workspace-1
  catalog  = databricks_catalog.catalog_ws1.name
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_SCHEMA", "CREATE_TABLE", "CREATE_FUNCTION"]
  }
  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }
  depends_on = [databricks_metastore_assignment.assignments]
}

# Grant catalog permissions - workspace-2
resource "databricks_grants" "catalog_grants_ws2" {
  provider = databricks.workspace-2
  catalog  = databricks_catalog.catalog_ws2.name
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_SCHEMA", "CREATE_TABLE", "CREATE_FUNCTION"]
  }
  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }
  depends_on = [databricks_metastore_assignment.assignments]
}

# Grant schema permissions - workspace-1
resource "databricks_grants" "schema_grants_ws1" {
  provider = databricks.workspace-1
  schema   = "${databricks_catalog.catalog_ws1.name}.${databricks_schema.default_schema_ws1.name}"
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_FUNCTION"]
  }
  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_SCHEMA", "SELECT"]
  }
  depends_on = [databricks_metastore_assignment.assignments]
}

# Grant schema permissions - workspace-2
resource "databricks_grants" "schema_grants_ws2" {
  provider = databricks.workspace-2
  schema   = "${databricks_catalog.catalog_ws2.name}.${databricks_schema.default_schema_ws2.name}"
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_FUNCTION"]
  }
  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_SCHEMA", "SELECT"]
  }
  depends_on = [databricks_metastore_assignment.assignments]
}

# ===============================
# CLUSTER PERMISSIONS
# ===============================

# Admin cluster permissions - workspace-1
resource "databricks_permissions" "admin_cluster_permissions_ws1" {
  provider   = databricks.workspace-1
  cluster_id = databricks_cluster.admin_cluster_ws1.id
  access_control {
    group_name       = databricks_group.workspace_admins.display_name
    permission_level = "CAN_MANAGE"
  }
}

# Admin cluster permissions - workspace-2
resource "databricks_permissions" "admin_cluster_permissions_ws2" {
  provider   = databricks.workspace-2
  cluster_id = databricks_cluster.admin_cluster_ws2.id
  access_control {
    group_name       = databricks_group.workspace_admins.display_name
    permission_level = "CAN_MANAGE"
  }
}

# Shared cluster permissions - workspace-1
resource "databricks_permissions" "shared_cluster_permissions_ws1" {
  provider   = databricks.workspace-1
  cluster_id = databricks_cluster.shared_cluster_ws1.id
  access_control {
    group_name       = databricks_group.workspace_admins.display_name
    permission_level = "CAN_MANAGE"
  }
  access_control {
    group_name       = databricks_group.data_engineers.display_name
    permission_level = "CAN_ATTACH_TO"
  }
  access_control {
    group_name       = databricks_group.data_analysts.display_name
    permission_level = "CAN_ATTACH_TO"
  }
}

# Shared cluster permissions - workspace-2
resource "databricks_permissions" "shared_cluster_permissions_ws2" {
  provider   = databricks.workspace-2
  cluster_id = databricks_cluster.shared_cluster_ws2.id
  access_control {
    group_name       = databricks_group.workspace_admins.display_name
    permission_level = "CAN_MANAGE"
  }
  access_control {
    group_name       = databricks_group.data_engineers.display_name
    permission_level = "CAN_ATTACH_TO"
  }
  access_control {
    group_name       = databricks_group.data_analysts.display_name
    permission_level = "CAN_ATTACH_TO"
  }
}