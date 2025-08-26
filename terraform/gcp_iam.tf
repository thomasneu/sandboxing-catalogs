# gcp_iam.tf

# Enable required Google Cloud APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "storage-api.googleapis.com", 
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com"
  ])
  
  project = var.gcp_project_id
  service = each.value
  
  disable_on_destroy = false
  
  timeouts {
    create = "10m"
    read   = "10m"
  }
}

# Service Account for Databricks Workspace Operations
resource "google_service_account" "databricks_workspace_sa" {
  account_id   = local.service_accounts.databricks_workspace
  display_name = "Databricks Workspace Service Account"
  description  = "Service account for Databricks workspace operations and compute resources"
  
  depends_on = [google_project_service.required_apis]
}

# Service Account for Unity Catalog Storage Operations
resource "google_service_account" "unity_catalog_sa" {
  account_id   = local.service_accounts.unity_catalog
  display_name = "Unity Catalog Service Account"
  description  = "Service account for Unity Catalog storage operations and metastore access"
  
  depends_on = [google_project_service.required_apis]
}

# IAM roles for Databricks Workspace Service Account
resource "google_project_iam_member" "databricks_workspace_sa_roles" {
  for_each = toset([
    "roles/compute.instanceAdmin.v1",
    "roles/compute.networkAdmin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator"
  ])
  
  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.databricks_workspace_sa.email}"
}

# Storage-specific roles for Unity Catalog Service Account
resource "google_project_iam_member" "unity_catalog_sa_storage_roles" {
  for_each = toset([
    "roles/storage.admin",
    "roles/storage.objectAdmin"
  ])
  
  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.unity_catalog_sa.email}"
}

# Service Account Keys (for Unity Catalog authentication)
resource "google_service_account_key" "databricks_workspace_sa_key" {
  service_account_id = google_service_account.databricks_workspace_sa.name
}

resource "google_service_account_key" "unity_catalog_sa_key" {
  service_account_id = google_service_account.unity_catalog_sa.name
}

# Allow Databricks service account to impersonate Unity Catalog service account
resource "google_service_account_iam_member" "sa_impersonation" {
  service_account_id = google_service_account.unity_catalog_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.databricks_workspace_sa.email}"
}
