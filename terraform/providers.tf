# providers.tf

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  
  # Enable automatic Terraform labeling (new in provider 6.x)
  add_terraform_attribution_label = true
  credentials = "/Users/thomas/.config/gcloud/applied-light-128913-9574bc62a259.json"
  
  # Default labels for all resources
  default_labels = merge(local.common_labels, {
    managed-by = "terraform"
  })
}

# Provider for Databricks account-level operations
provider "databricks" {
  alias      = "accounts"
  host       = var.databricks_account_console_url
  account_id = var.databricks_account_id
  
  # Use service principal authentication for account-level operations
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

# Wait for workspaces to be ready before setting up workspace-level providers
resource "time_sleep" "workspace_provisioning" {
  depends_on = [
    databricks_mws_workspaces.sandbox_workspace_1,
    databricks_mws_workspaces.sandbox_workspace_2
  ]
  create_duration = "60s"
}

# Workspace-level provider for workspace 1
provider "databricks" {
  alias = "workspace1"
  host  = databricks_mws_workspaces.sandbox_workspace_1.workspace_url
  
  # Use service principal authentication for workspace access
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

# Workspace-level provider for workspace 2  
provider "databricks" {
  alias = "workspace2"
  host  = databricks_mws_workspaces.sandbox_workspace_2.workspace_url
  
  # Use service principal authentication for workspace access
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}
