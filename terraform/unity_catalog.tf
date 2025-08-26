# unity_catalog.tf

# External Locations for Unity Catalogs
resource "databricks_external_location" "catalog_locations" {
  provider = databricks.accounts
  
  for_each = {
    catalog_a = {
      url    = "gs://${google_storage_bucket.unity_catalog_a.name}/"
      name   = "${local.prefix}-catalog-a-location"
      bucket = google_storage_bucket.unity_catalog_a.name
    }
    catalog_b = {
      url    = "gs://${google_storage_bucket.unity_catalog_b.name}/"
      name   = "${local.prefix}-catalog-b-location"
      bucket = google_storage_bucket.unity_catalog_b.name
    }
    catalog_c = {
      url    = "gs://${google_storage_bucket.unity_catalog_c.name}/"
      name   = "${local.prefix}-catalog-c-location"
      bucket = google_storage_bucket.unity_catalog_c.name
    }
  }
  
  name            = each.value.name
  url             = each.value.url
  credential_name = databricks_storage_credential.unity_catalog_credential.name
  
  comment = "External location for ${each.key} Unity Catalog storage"
  
  depends_on = [
    databricks_storage_credential.unity_catalog_credential,
    databricks_metastore_assignment.workspace_metastore_assignments
  ]
}

# Additional external location for unmanaged Iceberg tables
resource "databricks_external_location" "unmanaged_iceberg_location" {
  provider = databricks.accounts
  
  name            = "${local.prefix}-unmanaged-iceberg-location"
  url             = "gs://${google_storage_bucket.unmanaged_iceberg.name}/"
  credential_name = databricks_storage_credential.unity_catalog_credential.name
  
  comment = "External location for unmanaged Iceberg tables"
  
  depends_on = [
    databricks_storage_credential.unity_catalog_credential,
    databricks_metastore_assignment.workspace_metastore_assignments
  ]
}

# Unity Catalogs
resource "databricks_catalog" "unity_catalogs" {
  provider = databricks.accounts
  
  for_each = local.unity_catalogs
  
  metastore_id = databricks_metastore.unity_catalog.id
  name         = each.value.name
  storage_root = databricks_external_location.catalog_locations[each.key].url
  
  comment = each.value.description
  
  properties = {
    purpose = "sandbox-unity-catalog"
    created_by = "terraform"
  }
  
  depends_on = [
    databricks_external_location.catalog_locations,
    databricks_metastore_assignment.workspace_metastore_assignments
  ]
}

# Default schemas for each catalog
resource "databricks_schema" "default_schemas" {
  provider = databricks.accounts
  
  for_each = local.unity_catalogs
  
  catalog_name    = databricks_catalog.unity_catalogs[each.key].name
  name            = "default"
  comment         = "Default schema for ${each.value.name}"
  storage_root    = "${databricks_external_location.catalog_locations[each.key].url}schemas/default/"
  
  properties = {
    kind = "default"
    created_by = "terraform"
  }
  
  depends_on = [databricks_catalog.unity_catalogs]
}

# Example schemas for demonstration
resource "databricks_schema" "example_schemas" {
  provider = databricks.accounts
  
  for_each = local.unity_catalogs
  
  catalog_name = databricks_catalog.unity_catalogs[each.key].name
  name         = "bronze"
  comment      = "Bronze/raw data schema for ${each.value.name}"
  storage_root = "${databricks_external_location.catalog_locations[each.key].url}schemas/bronze/"
  
  properties = {
    layer = "bronze"
    data_classification = "raw"
    created_by = "terraform"
  }
  
  depends_on = [databricks_catalog.unity_catalogs]
}
