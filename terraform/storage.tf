# storage.tf

# Metastore Storage Bucket
resource "google_storage_bucket" "metastore" {
  name     = local.storage_buckets.metastore
  location = local.bucket_location
  
  storage_class                = var.storage_class
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = "unity-catalog-metastore"
    bucket_type = "metastore"
  })
  
  depends_on = [google_project_service.required_apis]
}

# Unity Catalog A Storage Bucket
resource "google_storage_bucket" "unity_catalog_a" {
  name     = local.storage_buckets.catalog_a
  location = local.bucket_location
  
  storage_class                = var.storage_class
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = "unity-catalog-a"
    bucket_type = "catalog-storage"
    accessible_by = "workspace-1"
  })
  
  depends_on = [google_project_service.required_apis]
}

# Unity Catalog B Storage Bucket
resource "google_storage_bucket" "unity_catalog_b" {
  name     = local.storage_buckets.catalog_b
  location = local.bucket_location
  
  storage_class                = var.storage_class
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = "unity-catalog-b"
    bucket_type = "catalog-storage"
    accessible_by = "workspace-2"
  })
  
  depends_on = [google_project_service.required_apis]
}

# Unity Catalog C Storage Bucket (Shared)
resource "google_storage_bucket" "unity_catalog_c" {
  name     = local.storage_buckets.catalog_c
  location = local.bucket_location
  
  storage_class                = var.storage_class
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = "unity-catalog-c-shared"
    bucket_type = "catalog-storage"
    accessible_by = "workspace-1-2"
  })
  
  depends_on = [google_project_service.required_apis]
}

# Unmanaged Iceberg Tables Bucket
resource "google_storage_bucket" "unmanaged_iceberg" {
  name     = local.storage_buckets.unmanaged_iceberg
  location = local.bucket_location
  
  storage_class                = var.storage_class
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 180  # Longer retention for unmanaged data
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(local.common_labels, {
    purpose = "unmanaged-iceberg-tables"
    bucket_type = "unmanaged-storage"
    accessible_by = "both-workspaces"
  })
  
  depends_on = [google_project_service.required_apis]
}

# IAM bindings for metastore bucket
resource "google_storage_bucket_iam_member" "metastore_admin" {
  bucket = google_storage_bucket.metastore.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.unity_catalog_sa.email}"
}

# IAM bindings for Unity Catalog buckets
resource "google_storage_bucket_iam_member" "unity_catalog_bucket_access" {
  for_each = {
    catalog_a = google_storage_bucket.unity_catalog_a.name
    catalog_b = google_storage_bucket.unity_catalog_b.name
    catalog_c = google_storage_bucket.unity_catalog_c.name
  }
  
  bucket = each.value
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.unity_catalog_sa.email}"
}

# IAM binding for unmanaged Iceberg bucket
resource "google_storage_bucket_iam_member" "unmanaged_iceberg_admin" {
  bucket = google_storage_bucket.unmanaged_iceberg.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.unity_catalog_sa.email}"
}

# Additional read access for workspace service account
resource "google_storage_bucket_iam_member" "workspace_sa_bucket_read" {
  for_each = {
    metastore         = google_storage_bucket.metastore.name
    catalog_a         = google_storage_bucket.unity_catalog_a.name
    catalog_b         = google_storage_bucket.unity_catalog_b.name
    catalog_c         = google_storage_bucket.unity_catalog_c.name
    unmanaged_iceberg = google_storage_bucket.unmanaged_iceberg.name
  }
  
  bucket = each.value
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.databricks_workspace_sa.email}"
}
