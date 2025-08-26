# databricks_metastore.tf

# Unity Catalog Metastore
resource "databricks_metastore" "unity_catalog" {
  provider = databricks.accounts
  
  name           = local.metastore_name
  storage_root   = "gs://${google_storage_bucket.metastore.name}/metastore"
  region         = var.gcp_region
  force_destroy  = true # For demo/sandbox purposes
  
  depends_on = [
    google_storage_bucket.metastore,
    google_storage_bucket_iam_member.metastore_admin
  ]
}

# Storage Credential for Unity Catalog
resource "databricks_storage_credential" "unity_catalog_credential" {
  provider = databricks.accounts
  
  name = "${local.prefix}-unity-catalog-credential"
  comment = "Storage credential for Unity Catalog with GCS access"
  
  gcp_service_account_key {
    email       = google_service_account.unity_catalog_sa.email
    private_key = base64decode(google_service_account_key.unity_catalog_sa_key.private_key)
    private_key_id = google_service_account_key.unity_catalog_sa_key.name
  }
  
  depends_on = [
    databricks_metastore.unity_catalog,
    google_service_account_key.unity_catalog_sa_key
  ]
}

# Metastore Data Access Configuration
resource "databricks_metastore_data_access" "unity_catalog_data_access" {
  provider = databricks.accounts
  
  metastore_id = databricks_metastore.unity_catalog.id
  name         = "${local.prefix}-metastore-data-access"
  
  gcp_service_account_key {
    email       = google_service_account.unity_catalog_sa.email
    private_key = base64decode(google_service_account_key.unity_catalog_sa_key.private_key)
    private_key_id = google_service_account_key.unity_catalog_sa_key.name
  }
  
  is_default = true
  
  depends_on = [
    databricks_storage_credential.unity_catalog_credential
  ]
}

# Assign metastore to workspaces (done after workspace creation)
resource "databricks_metastore_assignment" "workspace_metastore_assignments" {
  provider = databricks.accounts
  
  for_each = {
    workspace_1 = databricks_mws_workspaces.sandbox_workspace_1.workspace_id
    workspace_2 = databricks_mws_workspaces.sandbox_workspace_2.workspace_id
  }
  
  workspace_id         = each.value
  metastore_id         = databricks_metastore.unity_catalog.id
  default_catalog_name = "main"
  
  depends_on = [
    databricks_mws_workspaces.sandbox_workspace_1,
    databricks_mws_workspaces.sandbox_workspace_2,
    databricks_metastore_data_access.unity_catalog_data_access,
    time_sleep.workspace_provisioning
  ]
}
