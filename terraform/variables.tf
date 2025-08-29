variable "project" {
  description = "GCP project ID"
  type        = string
}

variable "databricks_account_id" {
  description = "Databricks account ID"
  type        = string
}

variable "databricks_google_service_account" {
  description = "Databricks Google service account email"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "europe-west1-b"
}

variable "delegate_from" {
  description = "Allow either user:user.name@example.com, group:deployers@example.com or serviceAccount:sa1@project.iam.gserviceaccount.com to impersonate created service account"
  type        = list(string)
  default     = []
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "snd"
}

variable "additional_users" {
  description = "List of additional user emails to create in Databricks account"
  type        = list(string)
  default     = []
}

variable "user_group_assignments" {
  description = "Map of user emails to group roles (account_admin, workspace_admin, data_engineer, data_analyst)"
  type        = map(string)
  default     = {}
}