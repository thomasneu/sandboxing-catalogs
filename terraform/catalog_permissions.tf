# catalog_permissions.tf

# Workspace bindings - assign catalogs to workspaces
resource "databricks_workspace_binding" "catalog_workspace_bindings" {
  provider = databricks.accounts
  
  for_each = {
    # Workspace 1 gets access to Catalogs A and C
    "workspace_1_catalog_a" = {
      workspace_id = databricks_mws_workspaces.sandbox_workspace_1.workspace_id
      catalog_name = databricks_catalog.unity_catalogs["catalog_a"].name
      binding_type = "BINDING_TYPE_READ_WRITE"
    }
    "workspace_1_catalog_c" = {
      workspace_id = databricks_mws_workspaces.sandbox_workspace_1.workspace_id
      catalog_name = databricks_catalog.unity_catalogs["catalog_c"].name
      binding_type = "BINDING_TYPE_READ_WRITE"
    }
    # Workspace 2 gets access to Catalogs B and C
    "workspace_2_catalog_b" = {
      workspace_id = databricks_mws_workspaces.sandbox_workspace_2.workspace_id
      catalog_name = databricks_catalog.unity_catalogs["catalog_b"].name
      binding_type = "BINDING_TYPE_READ_WRITE"
    }
    "workspace_2_catalog_c" = {
      workspace_id = databricks_mws_workspaces.sandbox_workspace_2.workspace_id
      catalog_name = databricks_catalog.unity_catalogs["catalog_c"].name
      binding_type = "BINDING_TYPE_READ_WRITE"
    }
  }
  
  workspace_id = each.value.workspace_id
  catalog_name = each.value.catalog_name
  binding_type = each.value.binding_type
  
  depends_on = [
    databricks_catalog.unity_catalogs,
    databricks_mws_workspaces.sandbox_workspace_1,
    databricks_mws_workspaces.sandbox_workspace_2,
    databricks_metastore_assignment.workspace_metastore_assignments
  ]
}

# Grant access to external locations
resource "databricks_grants" "external_location_grants" {
  provider = databricks.accounts
  
  for_each = {
    catalog_a_location = {
      external_location = databricks_external_location.catalog_locations["catalog_a"].name
      grants = [
        {
          principal  = "account users"
          privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES"]
        }
      ]
    }
    catalog_b_location = {
      external_location = databricks_external_location.catalog_locations["catalog_b"].name
      grants = [
        {
          principal  = "account users"
          privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES"]
        }
      ]
    }
    catalog_c_location = {
      external_location = databricks_external_location.catalog_locations["catalog_c"].name
      grants = [
        {
          principal  = "account users"
          privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES"]
        }
      ]
    }
    unmanaged_iceberg_location = {
      external_location = databricks_external_location.unmanaged_iceberg_location.name
      grants = [
        {
          principal  = "account users"
          privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
        }
      ]
    }
  }
  
  external_location = each.value.external_location
  
  dynamic "grant" {
    for_each = each.value.grants
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
  
  depends_on = [
    databricks_external_location.catalog_locations,
    databricks_external_location.unmanaged_iceberg_location
  ]
}

# Grant catalog usage permissions
resource "databricks_grants" "catalog_grants" {
  provider = databricks.accounts
  
  for_each = local.unity_catalogs
  
  catalog = databricks_catalog.unity_catalogs[each.key].name
  
  grant {
    principal  = "account users"
    privileges = ["BROWSE", "USE_CATALOG"]
  }
  
  depends_on = [
    databricks_catalog.unity_catalogs,
    databricks_workspace_binding.catalog_workspace_bindings
  ]
}

# Grant schema usage permissions
resource "databricks_grants" "schema_grants" {
  provider = databricks.accounts
  
  for_each = {
    for key, catalog in local.unity_catalogs : key => {
      default_schema = "${catalog.name}.default"
      bronze_schema  = "${catalog.name}.bronze"
    }
  }
  
  # Default schema grants
  schema = each.value.default_schema
  
  grant {
    principal  = "account users"
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_EXTERNAL_TABLE"]
  }
  
  depends_on = [
    databricks_schema.default_schemas,
    databricks_grants.catalog_grants
  ]
}

# Additional grants for bronze schemas
resource "databricks_grants" "bronze_schema_grants" {
  provider = databricks.accounts
  
  for_each = {
    for key, catalog in local.unity_catalogs : key => "${catalog.name}.bronze"
  }
  
  schema = each.value
  
  grant {
    principal  = "account users"
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_EXTERNAL_TABLE"]
  }
  
  depends_on = [
    databricks_schema.example_schemas,
    databricks_grants.catalog_grants
  ]
}
