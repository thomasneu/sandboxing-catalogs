# Provider configurations
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "databricks" {
  alias                  = "accounts"
  host                   = "https://accounts.gcp.databricks.com"
  google_service_account = var.databricks_google_service_account
  account_id             = var.databricks_account_id
}

provider "databricks" {
  alias                  = "workspace-1"
  host                   = databricks_mws_workspaces.workspaces["workspace-1"].workspace_url
  google_service_account = var.databricks_google_service_account
}

provider "databricks" {
  alias                  = "workspace-2"
  host                   = databricks_mws_workspaces.workspaces["workspace-2"].workspace_url
  google_service_account = var.databricks_google_service_account
}