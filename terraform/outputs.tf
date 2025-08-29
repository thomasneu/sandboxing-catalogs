# Service Account outputs
output "databricks_service_account_email" {
  value       = google_service_account.databricks_provisioning.email
  description = "Email of the Databricks provisioning service account"
}

output "custom_role_url" {
  value = "https://console.cloud.google.com/iam-admin/roles/details/projects%2F${data.google_client_config.current.project}%2Froles%2F${google_project_iam_custom_role.workspace_creator.role_id}"
  description = "URL to view the custom workspace creator role in GCP Console"
}

# Workspace outputs
output "databricks_workspace_urls" {
  value = {
    for k, v in databricks_mws_workspaces.workspaces : k => v.workspace_url
  }
  description = "URLs of the Databricks workspaces"
}

output "databricks_workspace_ids" {
  value = {
    for k, v in databricks_mws_workspaces.workspaces : k => v.workspace_id
  }
  description = "IDs of the Databricks workspaces"
}

# Unity Catalog outputs
output "metastore_id" {
  value       = databricks_metastore.this.id
  description = "ID of the shared Unity Catalog metastore"
}

output "catalog_names" {
  value = {
    "workspace-1" = databricks_catalog.catalog_ws1.name
    "workspace-2" = databricks_catalog.catalog_ws2.name
  }
  description = "Names of the catalogs per workspace"
}

# Storage outputs
output "catalog_bucket_names" {
  value = {
    for k, v in google_storage_bucket.catalog_buckets : k => v.name
  }
  description = "Names of the catalog storage buckets per workspace"
}

output "unmanaged_bucket_names" {
  value = {
    for k, v in google_storage_bucket.unmanaged_buckets : k => v.name
  }
  description = "Names of the unmanaged iceberg tables buckets per workspace"
}

output "unmanaged_bucket_urls" {
  value = {
    for k, v in google_storage_bucket.unmanaged_buckets : k => "gs://${v.name}"
  }
  description = "GCS URLs for the unmanaged iceberg tables buckets per workspace"
}

# Cluster outputs
output "admin_cluster_ids" {
  value = {
    "workspace-1" = databricks_cluster.admin_cluster_ws1.id
    "workspace-2" = databricks_cluster.admin_cluster_ws2.id
  }
  description = "IDs of the admin clusters per workspace"
}

output "shared_cluster_ids" {
  value = {
    "workspace-1" = databricks_cluster.shared_cluster_ws1.id
    "workspace-2" = databricks_cluster.shared_cluster_ws2.id
  }
  description = "IDs of the shared clusters per workspace"
}

# Network outputs
output "vpc_name" {
  value       = google_compute_network.dbx_private_vpc.name
  description = "Name of the shared VPC network"
}

output "subnet_names" {
  value = {
    for k, v in google_compute_subnetwork.dbx_subnets : k => v.name
  }
  description = "Names of the subnets per workspace"
}

output "subnet_cidrs" {
  value = {
    for k, v in local.workspaces : k => v.subnet_cidr
  }
  description = "CIDR ranges of the subnets per workspace"
}

# User and Group outputs
output "current_user_id" {
  value       = databricks_user.me.id
  description = "ID of the current user in Databricks account"
}

output "group_ids" {
  value = {
    account_admins   = databricks_group.account_admins.id
    workspace_admins = databricks_group.workspace_admins.id
    data_engineers   = databricks_group.data_engineers.id
    data_analysts    = databricks_group.data_analysts.id
  }
  description = "IDs of created groups"
}

# Workspace configuration summary
output "workspace_summary" {
  value = {
    for k, v in local.workspaces : k => {
      workspace_url   = databricks_mws_workspaces.workspaces[k].workspace_url
      catalog_name    = v.catalog_name
      use_case        = v.use_case
      subnet_cidr     = v.subnet_cidr
      cluster_workers = v.cluster_workers
    }
  }
  description = "Summary of workspace configurations"
}