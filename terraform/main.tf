# Generate random suffix for unique resource names
resource "random_string" "suffix" {
  special = false
  upper   = false
  length  = 6
}