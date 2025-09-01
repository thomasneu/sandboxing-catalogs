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
  # Deprecated default_catalog_name = "hive_metastore"
}

# ===============================
# ISOLATED UNITY CATALOGS (WORKSPACE-LEVEL)
# ===============================

# Unity Catalogs with isolation mode (created in workspace-1, then bound to respective workspaces)
resource "databricks_catalog" "catalog_a" {
  provider       = databricks.workspace-1
  name           = local.workspaces["workspace-1"].catalog_name
  storage_root   = "gs://${google_storage_bucket.catalog_buckets["workspace-1"].name}"
  isolation_mode = "ISOLATED"
  force_destroy  = true
  comment        = "Isolated catalog for workspace-1 - ${local.workspaces["workspace-1"].use_case}"
  
  properties = {
    purpose   = local.workspaces["workspace-1"].use_case
    workspace = "workspace-1"
  }
  
  depends_on = [
    databricks_metastore_assignment.assignments,
    google_storage_bucket.catalog_buckets,
    google_storage_bucket_iam_member.catalog_reader_ws1,
    databricks_external_location.catalog_location_ws1
  ]
}

resource "databricks_catalog" "catalog_b" {
  provider       = databricks.workspace-2
  name           = local.workspaces["workspace-2"].catalog_name
  storage_root   = "gs://${google_storage_bucket.catalog_buckets["workspace-2"].name}"
  isolation_mode = "ISOLATED"
  force_destroy  = true
  comment        = "Isolated catalog for workspace-2 - ${local.workspaces["workspace-2"].use_case}"
  
  properties = {
    purpose   = local.workspaces["workspace-2"].use_case
    workspace = "workspace-2"
  }
  
  depends_on = [
    databricks_metastore_assignment.assignments,
    google_storage_bucket.catalog_buckets,
    google_storage_bucket_iam_member.catalog_reader_ws2,
    databricks_external_location.catalog_location_ws2
  ]
}

# Catalog Workspace Bindings (ensure ONLY access)
resource "databricks_workspace_binding" "catalog_a_binding" {
  provider       = databricks.workspace-1
  securable_name = databricks_catalog.catalog_a.name
  workspace_id   = databricks_mws_workspaces.workspaces["workspace-1"].workspace_id
}

resource "databricks_workspace_binding" "catalog_b_binding" {
  provider       = databricks.workspace-2
  securable_name = databricks_catalog.catalog_b.name
  workspace_id   = databricks_mws_workspaces.workspaces["workspace-2"].workspace_id
}

# Default schemas for each workspace
resource "databricks_schema" "default_schema_ws1" {
  provider     = databricks.workspace-1
  catalog_name = databricks_catalog.catalog_a.name
  name         = "default"
  comment      = "Default schema for ${local.workspaces["workspace-1"].catalog_name}"
  depends_on   = [databricks_catalog.catalog_a]
}

resource "databricks_schema" "default_schema_ws2" {
  provider     = databricks.workspace-2
  catalog_name = databricks_catalog.catalog_b.name
  name         = "default"
  comment      = "Default schema for ${local.workspaces["workspace-2"].catalog_name}"
  depends_on   = [databricks_catalog.catalog_b]
}