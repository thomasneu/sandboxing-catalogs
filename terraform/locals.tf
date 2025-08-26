# locals.tf

locals {
  # Resource naming convention - improved for clarity
  prefix = "${var.project_name}-${var.environment}"
  
  # Common resource labels
  common_labels = merge({
    project     = var.project_name
    environment = var.environment
    terraform   = "true"
    created_by  = "terraform-databricks"
    purpose     = "unity-catalog-demo"
  }, var.resource_tags)
  
  # Unity Catalog configuration
  unity_catalogs = {
    catalog_a = {
      name        = "${local.prefix}-catalog-a"
      description = "Unity Catalog A - Accessible by Workspace 1"
      workspace_access = ["workspace_1"]
    }
    catalog_b = {
      name        = "${local.prefix}-catalog-b" 
      description = "Unity Catalog B - Accessible by Workspace 2"
      workspace_access = ["workspace_2"]
    }
    catalog_c = {
      name        = "${local.prefix}-catalog-c"
      description = "Unity Catalog C - Shared catalog for both workspaces"
      workspace_access = ["workspace_1", "workspace_2"]
    }
  }
  
  # Storage bucket names (must be globally unique)
  storage_buckets = {
    metastore         = "${local.prefix}-metastore-${random_id.bucket_suffix.hex}"
    catalog_a         = "${local.prefix}-uc-catalog-a-${random_id.bucket_suffix.hex}"
    catalog_b         = "${local.prefix}-uc-catalog-b-${random_id.bucket_suffix.hex}"
    catalog_c         = "${local.prefix}-uc-catalog-c-${random_id.bucket_suffix.hex}"
    unmanaged_iceberg = "${local.prefix}-unmanaged-iceberg-${random_id.bucket_suffix.hex}"
  }
  
  # Workspace configuration
  workspaces = {
    workspace_1 = {
      name        = "${local.prefix}-workspace-1"
      description = "Sandbox Workspace 1 - Access to Catalogs A and C"
    }
    workspace_2 = {
      name        = "${local.prefix}-workspace-2"
      description = "Sandbox Workspace 2 - Access to Catalogs B and C"
    }
  }
  
  # Service account configuration
  service_accounts = {
    databricks_workspace = "${local.prefix}-wa-sa"
    unity_catalog       = "${local.prefix}-unity-ctl-sa"
  }
  
  # GCS bucket location - use region for better performance
  bucket_location = var.gcp_region
  
  # Metastore configuration
  metastore_name = "${local.prefix}-metastore"
}
