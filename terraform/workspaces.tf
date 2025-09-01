# ===============================
# DATABRICKS WORKSPACES
# ===============================

# Databricks Workspaces (per workspace)
resource "databricks_mws_workspaces" "workspaces" {
  for_each       = local.workspaces
  provider       = databricks.accounts
  account_id     = var.databricks_account_id
  workspace_name = "${var.prefix}-${each.key}"
  location       = var.region

  cloud_resource_container {
    gcp {
      project_id = var.project
    }
  }

  network_id = databricks_mws_networks.networks[each.key].network_id
  depends_on = [google_compute_router_nat.nat]
}