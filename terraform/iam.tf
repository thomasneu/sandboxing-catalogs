# Service Account for Databricks Provisioning
resource "google_service_account" "databricks_provisioning" {
  account_id   = "${var.prefix}-databricks-sa-${random_string.suffix.result}"
  display_name = "Service Account for Databricks Provisioning"
  
  # Important for terraform destroy - since there is no dependency
  lifecycle {
    prevent_destroy = true
  }
}

# IAM policy for service account impersonation
data "google_iam_policy" "impersonation" {
  binding {
    role    = "roles/iam.serviceAccountTokenCreator"
    members = [
      "user:${data.google_client_openid_userinfo.me.email}"
    ]
  }
}

resource "google_service_account_iam_policy" "impersonatable" {
  service_account_id = google_service_account.databricks_provisioning.name
  policy_data        = data.google_iam_policy.impersonation.policy_data
}

# Custom role for Databricks Workspace Creator
resource "google_project_iam_custom_role" "workspace_creator" {
  role_id = "${var.prefix}_workspace_creator_${random_string.suffix.result}"
  title   = "Databricks Workspace Creator"
  permissions = [
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.get",
    "iam.roles.create",
    "iam.roles.delete",
    "iam.roles.get",
    "iam.roles.update",
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
    "serviceusage.services.get",
    "serviceusage.services.list",
    "serviceusage.services.enable",
    "compute.networks.get",
    "compute.networks.updatePolicy",
    "compute.projects.get",
    "compute.subnetworks.get",
    "compute.subnetworks.getIamPolicy",
    "compute.subnetworks.setIamPolicy",
    "compute.firewalls.get",
    "compute.firewalls.create",
  ]
}

# Assign custom role to service account
resource "google_project_iam_member" "sa_workspace_creator" {
  project = var.project
  role    = google_project_iam_custom_role.workspace_creator.id
  member  = "serviceAccount:${google_service_account.databricks_provisioning.email}"
}