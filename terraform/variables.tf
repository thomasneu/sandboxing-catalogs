# variables.tf

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west1"
}

variable "databricks_account_id" {
  description = "Databricks Account ID"
  type        = string
}

variable "databricks_account_console_url" {
  description = "Databricks Account Console URL"
  type        = string
  default     = "https://accounts.gcp.databricks.com"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "sandbox"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "sandboxcat"
}

variable "databricks_client_id" {
  description = "Databricks service principal client ID"
  type        = string
  sensitive   = true
}

variable "databricks_client_secret" {
  description = "Databricks service principal client secret"
  type        = string
  sensitive   = true
}

# Optional: Custom tags for resources
variable "resource_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Optional: Custom workspace configurations
variable "workspace_settings" {
  description = "Custom workspace settings"
  type = object({
    enable_ip_access_lists                = optional(bool, false)
    enable_tokens                        = optional(bool, true)
    enable_dbfs_file_browser             = optional(bool, true)
    enable_web_terminal                  = optional(bool, true)
    max_token_lifetime_seconds           = optional(number, 7776000) # 90 days
  })
  default = {}
}

# Storage class for buckets - optimized for cost
variable "storage_class" {
  description = "GCS storage class for Unity Catalog buckets"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}
