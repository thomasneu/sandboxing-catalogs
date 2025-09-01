# ===============================
# WORKSPACE-LEVEL PERMISSIONS
# ===============================

# Assign workspace admin permissions to workspace admins group
resource "databricks_mws_permission_assignment" "workspace_admins" {
  for_each     = local.workspaces
  provider     = databricks.accounts
  workspace_id = databricks_mws_workspaces.workspaces[each.key].workspace_id
  principal_id = databricks_group.workspace_admins.id
  permissions  = ["ADMIN"]
}

# Assign workspace user permissions to data engineers group
resource "databricks_mws_permission_assignment" "data_engineers" {
  for_each     = local.workspaces
  provider     = databricks.accounts
  workspace_id = databricks_mws_workspaces.workspaces[each.key].workspace_id
  principal_id = databricks_group.data_engineers.id
  permissions  = ["USER"]
}

# Assign workspace user permissions to data analysts group
resource "databricks_mws_permission_assignment" "data_analysts" {
  for_each     = local.workspaces
  provider     = databricks.accounts
  workspace_id = databricks_mws_workspaces.workspaces[each.key].workspace_id
  principal_id = databricks_group.data_analysts.id
  permissions  = ["USER"]
}

# ===============================
# UNITY CATALOG PERMISSIONS
# ===============================

# Grant metastore admin to workspace admins - workspace-1
resource "databricks_grants" "metastore_grants_ws1" {
  provider  = databricks.workspace-1
  metastore = databricks_metastore.this.id
  
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["CREATE_CATALOG", "CREATE_CONNECTION", "CREATE_EXTERNAL_LOCATION", "CREATE_RECIPIENT", "CREATE_SHARE", "CREATE_STORAGE_CREDENTIAL", "USE_MARKETPLACE_ASSETS"]
  }
  
  depends_on = [
    databricks_metastore_assignment.assignments,
    databricks_catalog.catalog_a
  ]
}

# Grant metastore admin to workspace admins - workspace-2
resource "databricks_grants" "metastore_grants_ws2" {
  provider  = databricks.workspace-2
  metastore = databricks_metastore.this.id
  
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["CREATE_CATALOG", "CREATE_CONNECTION", "CREATE_EXTERNAL_LOCATION", "CREATE_RECIPIENT", "CREATE_SHARE", "CREATE_STORAGE_CREDENTIAL", "USE_MARKETPLACE_ASSETS"]
  }
  
  depends_on = [
    databricks_metastore_assignment.assignments,
    databricks_catalog.catalog_b
  ]
}

# Grant catalog permissions - workspace-1
resource "databricks_grants" "catalog_grants_ws1" {
  provider = databricks.workspace-1
  catalog  = databricks_catalog.catalog_a.name
  
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_SCHEMA", "CREATE_TABLE", "CREATE_FUNCTION"]
  }
  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }
  
  depends_on = [
    databricks_metastore_assignment.assignments,
    databricks_catalog.catalog_a
  ]
}

# Grant catalog permissions - workspace-2
resource "databricks_grants" "catalog_grants_ws2" {
  provider = databricks.workspace-2
  catalog  = databricks_catalog.catalog_b.name
  
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_SCHEMA", "CREATE_TABLE", "CREATE_FUNCTION"]
  }
  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }
  
  depends_on = [
    databricks_metastore_assignment.assignments,
    databricks_catalog.catalog_b
  ]
}

# Grant schema permissions - workspace-1
resource "databricks_grants" "schema_grants_ws1" {
  provider = databricks.workspace-1
  schema   = "${databricks_catalog.catalog_a.name}.${databricks_schema.default_schema_ws1.name}"
  
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_FUNCTION"]
  }
  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_SCHEMA", "SELECT"]
  }
  
  depends_on = [
    databricks_metastore_assignment.assignments,
    databricks_catalog.catalog_a
  ]
}

# Grant schema permissions - workspace-2
resource "databricks_grants" "schema_grants_ws2" {
  provider = databricks.workspace-2
  schema   = "${databricks_catalog.catalog_b.name}.${databricks_schema.default_schema_ws2.name}"
  
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_FUNCTION"]
  }
  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_SCHEMA", "SELECT"]
  }
  
  depends_on = [
    databricks_metastore_assignment.assignments,
    databricks_catalog.catalog_b
  ]
}

# Grant permissions on unmanaged external location workspace-1
resource "databricks_grants" "unmanaged_location_grants_ws1" {
  provider          = databricks.workspace-1
  external_location = databricks_external_location.unmanaged_location_ws1.id
  
  grant {
    principal  = databricks_group.workspace_admins.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }
  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }
  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["READ_FILES"]
  }
  
  depends_on = [databricks_external_location.unmanaged_location_ws1]
}

# ===============================
# CLUSTER PERMISSIONS
# ===============================

# Admin cluster permissions - workspace-1
resource "databricks_permissions" "admin_cluster_permissions_ws1" {
  provider   = databricks.workspace-1
  cluster_id = databricks_cluster.admin_cluster_ws1.id
  
  access_control {
    group_name       = databricks_group.workspace_admins.display_name
    permission_level = "CAN_MANAGE"
  }
}

# Admin cluster permissions - workspace-2
resource "databricks_permissions" "admin_cluster_permissions_ws2" {
  provider   = databricks.workspace-2
  cluster_id = databricks_cluster.admin_cluster_ws2.id
  
  access_control {
    group_name       = databricks_group.workspace_admins.display_name
    permission_level = "CAN_MANAGE"
  }
}

# Shared cluster permissions - workspace-1
resource "databricks_permissions" "shared_cluster_permissions_ws1" {
  provider   = databricks.workspace-1
  cluster_id = databricks_cluster.shared_cluster_ws1.id
  
  access_control {
    group_name       = databricks_group.workspace_admins.display_name
    permission_level = "CAN_MANAGE"
  }
  access_control {
    group_name       = databricks_group.data_engineers.display_name
    permission_level = "CAN_ATTACH_TO"
  }
  access_control {
    group_name       = databricks_group.data_analysts.display_name
    permission_level = "CAN_ATTACH_TO"
  }
}

# Shared cluster permissions - workspace-2
resource "databricks_permissions" "shared_cluster_permissions_ws2" {
  provider   = databricks.workspace-2
  cluster_id = databricks_cluster.shared_cluster_ws2.id
  
  access_control {
    group_name       = databricks_group.workspace_admins.display_name
    permission_level = "CAN_MANAGE"
  }
  access_control {
    group_name       = databricks_group.data_engineers.display_name
    permission_level = "CAN_ATTACH_TO"
  }
  access_control {
    group_name       = databricks_group.data_analysts.display_name
    permission_level = "CAN_ATTACH_TO"
  }
}