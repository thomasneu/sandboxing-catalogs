# random.tf

# Generate random suffix for globally unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
  
  keepers = {
    project_id = var.gcp_project_id
    prefix     = local.prefix
  }
}

# Generate random password for service accounts if needed
resource "random_password" "sa_password" {
  length  = 32
  special = true
  
  keepers = {
    project_id = var.gcp_project_id
  }
}
