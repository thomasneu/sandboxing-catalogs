# ===============================
# STORAGE BUCKETS
# ===============================

# Storage Buckets for Unity Catalog (per workspace)
resource "google_storage_bucket" "catalog_buckets" {
  for_each      = local.workspaces
  name          = "${var.prefix}-catalog-${each.key}-${random_string.suffix.result}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
  depends_on = [
    google_service_account_iam_policy.impersonatable
  ]
}

# Storage Buckets for Unmanaged Iceberg Tables (per workspace)
resource "google_storage_bucket" "unmanaged_buckets" {
  for_each      = local.workspaces
  name          = "${var.prefix}-unmanaged-${each.key}-${random_string.suffix.result}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
  depends_on = [
    google_service_account_iam_policy.impersonatable
  ]
}

# ===============================
# STORAGE CREDENTIALS
# ===============================

# Storage Credential for workspace-1
resource "databricks_storage_credential" "catalog_credential_ws1" {
  provider = databricks.workspace-1
  name     = "${local.workspaces["workspace-1"].catalog_name}-credential"
  databricks_gcp_service_account {}
  depends_on = [
    databricks_metastore_assignment.assignments,
    google_service_account_iam_policy.impersonatable
  
  ]
}

# Storage Credential for workspace-2
resource "databricks_storage_credential" "catalog_credential_ws2" {
  provider = databricks.workspace-2
  name     = "${local.workspaces["workspace-2"].catalog_name}-credential"
  databricks_gcp_service_account {}
  depends_on = [
    google_service_account_iam_policy.impersonatable
  ]
}

# Storage Credential for unmanaged bucket workspace-1
resource "databricks_storage_credential" "unmanaged_credential_ws1" {
  provider = databricks.workspace-1
  name     = "unmanaged-${local.workspaces["workspace-1"].catalog_name}-credential"
  databricks_gcp_service_account {}
  depends_on = [
    databricks_metastore_assignment.assignments
  ]
}

# ===============================
# BUCKET IAM PERMISSIONS
# ===============================

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

# IAM permissions for unmanaged bucket workspace-1
resource "google_storage_bucket_iam_member" "unmanaged_admin_ws1" {
  bucket = google_storage_bucket.unmanaged_buckets["workspace-1"].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${databricks_storage_credential.unmanaged_credential_ws1.databricks_gcp_service_account[0].email}"
}

resource "google_storage_bucket_iam_member" "unmanaged_reader_ws1" {
  bucket = google_storage_bucket.unmanaged_buckets["workspace-1"].name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${databricks_storage_credential.unmanaged_credential_ws1.databricks_gcp_service_account[0].email}"
}

# ===============================
# EXTERNAL LOCATIONS
# ===============================

# External Location for workspace-1
resource "databricks_external_location" "catalog_location_ws1" {
  provider        = databricks.workspace-1
  name            = "${local.workspaces["workspace-1"].catalog_name}-location"
  url             = "gs://${google_storage_bucket.catalog_buckets["workspace-1"].name}"
  credential_name = databricks_storage_credential.catalog_credential_ws1.id
  comment         = "External location for ${local.workspaces["workspace-1"].catalog_name}"
  
  depends_on = [
    google_storage_bucket_iam_member.catalog_reader_ws1,
    google_storage_bucket_iam_member.catalog_admin_ws1,
    google_storage_bucket.catalog_buckets
  ]
}

# External Location for workspace-2
resource "databricks_external_location" "catalog_location_ws2" {
  provider        = databricks.workspace-2
  name            = "${local.workspaces["workspace-2"].catalog_name}-location"
  url             = "gs://${google_storage_bucket.catalog_buckets["workspace-2"].name}"
  credential_name = databricks_storage_credential.catalog_credential_ws2.id
  comment         = "External location for ${local.workspaces["workspace-2"].catalog_name}"
  
  depends_on = [
    google_storage_bucket_iam_member.catalog_reader_ws2,
    google_storage_bucket_iam_member.catalog_admin_ws2,
    google_storage_bucket.catalog_buckets
  ]
}

# External Location for unmanaged bucket workspace-1
resource "databricks_external_location" "unmanaged_location_ws1" {
  provider        = databricks.workspace-1
  name            = "unmanaged-${local.workspaces["workspace-1"].catalog_name}-location"
  url             = "gs://${google_storage_bucket.unmanaged_buckets["workspace-1"].name}"
  credential_name = databricks_storage_credential.unmanaged_credential_ws1.id
  comment         = "External location for unmanaged tables in ${local.workspaces["workspace-1"].catalog_name}"
  
  depends_on = [
    google_storage_bucket_iam_member.unmanaged_reader_ws1,
    google_storage_bucket_iam_member.unmanaged_admin_ws1
  ]
}