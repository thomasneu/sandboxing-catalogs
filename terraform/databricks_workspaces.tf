# databricks_workspaces.tf

# Databricks Workspace 1
resource "databricks_mws_workspaces" "sandbox_workspace_1" {
  provider = databricks.accounts
  
  account_id     = var.databricks_account_id
  workspace_name = local.workspaces.workspace_1.name
  location       = var.gcp_region
  
  cloud_resource_container {
    gcp {
      project_id = var.gcp_project_id
    }
  }
  

  
  # Network configuration (using default networking)
  # network_id = ""
  
  # Custom tags/labels
  custom_tags = merge(local.common_labels, {
    workspace_type = "sandbox"
    workspace_id   = "workspace-1"
    catalog_access = "a-c"
  })
  

}

# Databricks Workspace 2
resource "databricks_mws_workspaces" "sandbox_workspace_2" {
  provider = databricks.accounts
  
  account_id     = var.databricks_account_id
  workspace_name = local.workspaces.workspace_2.name
  location       = var.gcp_region
  
  cloud_resource_container {
    gcp {
      project_id = var.gcp_project_id
    }
  }
  
  # Network configuration (using default networking)
  # network_id = ""
  
  # Custom tags/labels
  custom_tags = merge(local.common_labels, {
    workspace_type = "sandbox"
    workspace_id   = "workspace-2"
    catalog_access = "b-c"
  })
  


}

# Workspace settings for Workspace 1
resource "databricks_workspace_conf" "workspace_1_settings" {
  provider = databricks.workspace1
  
  custom_config = {
    "enableIpAccessLists"          = tostring(var.workspace_settings.enable_ip_access_lists)
    "enableTokensConfig"           = tostring(var.workspace_settings.enable_tokens)
    "enableDbfsFileBrowser"        = tostring(var.workspace_settings.enable_dbfs_file_browser)
    "enableWebTerminal"            = tostring(var.workspace_settings.enable_web_terminal)
    "maxTokenLifetimeDays"         = tostring(var.workspace_settings.max_token_lifetime_seconds / 86400)
  }
  
  depends_on = [
    databricks_metastore_assignment.workspace_metastore_assignments,
    time_sleep.workspace_provisioning
  ]
}

# Workspace settings for Workspace 2
resource "databricks_workspace_conf" "workspace_2_settings" {
  provider = databricks.workspace2
  
  custom_config = {
    "enableIpAccessLists"          = tostring(var.workspace_settings.enable_ip_access_lists)
    "enableTokensConfig"           = tostring(var.workspace_settings.enable_tokens)
    "enableDbfsFileBrowser"        = tostring(var.workspace_settings.enable_dbfs_file_browser)
    "enableWebTerminal"            = tostring(var.workspace_settings.enable_web_terminal)
    "maxTokenLifetimeDays"         = tostring(var.workspace_settings.max_token_lifetime_seconds / 86400)
  }
  
  depends_on = [
    databricks_metastore_assignment.workspace_metastore_assignments,
    time_sleep.workspace_provisioning
  ]
}
