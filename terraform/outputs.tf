# outputs.tf

output "project_information" {
  description = "General project information"
  value = {
    project_name = var.project_name
    environment  = var.environment
    gcp_project  = var.gcp_project_id
    gcp_region   = var.gcp_region
  }
}

output "workspaces" {
  description = "Databricks workspace information"
  value = {
    workspace_1 = {
      id          = databricks_mws_workspaces.sandbox_workspace_1.workspace_id
      url         = databricks_mws_workspaces.sandbox_workspace_1.workspace_url
      name        = databricks_mws_workspaces.sandbox_workspace_1.workspace_name
      deployment_name = databricks_mws_workspaces.sandbox_workspace_1.deployment_name
      catalog_access = ["catalog_a", "catalog_c"]
    }
    workspace_2 = {
      id          = databricks_mws_workspaces.sandbox_workspace_2.workspace_id
      url         = databricks_mws_workspaces.sandbox_workspace_2.workspace_url
      name        = databricks_mws_workspaces.sandbox_workspace_2.workspace_name
      deployment_name = databricks_mws_workspaces.sandbox_workspace_2.deployment_name
      catalog_access = ["catalog_b", "catalog_c"]
    }
  }
}

output "unity_catalog_information" {
  description = "Unity Catalog setup information"
  value = {
    metastore = {
      id           = databricks_metastore.unity_catalog.id
      name         = databricks_metastore.unity_catalog.name
      region       = databricks_metastore.unity_catalog.region
      storage_root = databricks_metastore.unity_catalog.storage_root
    }
    catalogs = {
      for key, catalog in databricks_catalog.unity_catalogs : key => {
        id           = catalog.id
        name         = catalog.name
        storage_root = catalog.storage_root
        accessible_by = local.unity_catalogs[key].workspace_access
      }
    }
  }
}

output "storage_buckets" {
  description = "GCS bucket information"
  value = {
    metastore = {
      name     = google_storage_bucket.metastore.name
      url      = google_storage_bucket.metastore.url
      location = google_storage_bucket.metastore.location
      purpose  = "Unity Catalog metastore storage"
    }
    catalog_a = {
      name     = google_storage_bucket.unity_catalog_a.name
      url      = google_storage_bucket.unity_catalog_a.url
      location = google_storage_bucket.unity_catalog_a.location
      purpose  = "Unity Catalog A storage"
    }
    catalog_b = {
      name     = google_storage_bucket.unity_catalog_b.name
      url      = google_storage_bucket.unity_catalog_b.url
      location = google_storage_bucket.unity_catalog_b.location
      purpose  = "Unity Catalog B storage"
    }
    catalog_c = {
      name     = google_storage_bucket.unity_catalog_c.name
      url      = google_storage_bucket.unity_catalog_c.url
      location = google_storage_bucket.unity_catalog_c.location
      purpose  = "Unity Catalog C storage (shared)"
    }
    unmanaged_iceberg = {
      name     = google_storage_bucket.unmanaged_iceberg.name
      url      = google_storage_bucket.unmanaged_iceberg.url
      location = google_storage_bucket.unmanaged_iceberg.location
      purpose  = "Unmanaged Iceberg tables storage"
    }
  }
}

output "external_locations" {
  description = "External location information"
  value = {
    for key, location in databricks_external_location.catalog_locations : key => {
      name = location.name
      url  = location.url
    }
  }
  depends_on = [databricks_external_location.catalog_locations]
}

output "service_accounts" {
  description = "Service account information"
  value = {
    databricks_workspace = {
      email        = google_service_account.databricks_workspace_sa.email
      unique_id    = google_service_account.databricks_workspace_sa.unique_id
      display_name = google_service_account.databricks_workspace_sa.display_name
    }
    unity_catalog = {
      email        = google_service_account.unity_catalog_sa.email
      unique_id    = google_service_account.unity_catalog_sa.unique_id
      display_name = google_service_account.unity_catalog_sa.display_name
    }
  }
}

output "access_matrix" {
  description = "Access matrix showing which workspace can access which catalog"
  value = {
    workspace_1 = {
      name    = databricks_mws_workspaces.sandbox_workspace_1.workspace_name
      catalogs = ["catalog_a", "catalog_c"]
      url     = databricks_mws_workspaces.sandbox_workspace_1.workspace_url
    }
    workspace_2 = {
      name    = databricks_mws_workspaces.sandbox_workspace_2.workspace_name
      catalogs = ["catalog_b", "catalog_c"]
      url     = databricks_mws_workspaces.sandbox_workspace_2.workspace_url
    }
    shared_resources = {
      catalog_c_name = databricks_catalog.unity_catalogs["catalog_c"].name
      unmanaged_iceberg_bucket = google_storage_bucket.unmanaged_iceberg.name
    }
  }
}

output "next_steps" {
  description = "Recommended next steps after deployment"
  value = [
    "1. Access Workspace 1 at: ${databricks_mws_workspaces.sandbox_workspace_1.workspace_url}",
    "2. Access Workspace 2 at: ${databricks_mws_workspaces.sandbox_workspace_2.workspace_url}",
    "3. Verify Unity Catalog access in each workspace",
    "4. Create test tables in the available catalogs",
    "5. Test cross-workspace data sharing using Catalog C",
    "6. Use unmanaged Iceberg bucket at: gs://${google_storage_bucket.unmanaged_iceberg.name}"
  ]
}

# Sensitive outputs (marked as sensitive)
output "databricks_account_details" {
  description = "Databricks account information"
  sensitive   = true
  value = {
    account_id      = var.databricks_account_id
    console_url     = var.databricks_account_console_url
    metastore_id    = databricks_metastore.unity_catalog.id
    credential_name = databricks_storage_credential.unity_catalog_credential.name
  }
}
