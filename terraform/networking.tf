# ===============================
# SHARED NETWORKING RESOURCES
# ===============================

# VPC Network (shared)
resource "google_compute_network" "dbx_private_vpc" {
  name                    = "${var.prefix}-network-${random_string.suffix.result}"
  auto_create_subnetworks = false
}

# Cloud Router for NAT (shared)
resource "google_compute_router" "router" {
  name    = "${var.prefix}-router-${random_string.suffix.result}"
  region  = var.region
  network = google_compute_network.dbx_private_vpc.id
}

# NAT Gateway (shared)
resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefix}-nat-${random_string.suffix.result}"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# ===============================
# PER-WORKSPACE NETWORKING
# ===============================

# Subnets (per workspace for isolation)
resource "google_compute_subnetwork" "dbx_subnets" {
  for_each                 = local.workspaces
  name                     = "${var.prefix}-subnet-${each.key}-${random_string.suffix.result}"
  ip_cidr_range            = each.value.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.dbx_private_vpc.id
  private_ip_google_access = true
}

# Databricks Network Configurations (per workspace)
resource "databricks_mws_networks" "networks" {
  for_each     = local.workspaces
  provider     = databricks.accounts
  account_id   = var.databricks_account_id
  network_name = "${var.prefix}-network-${each.key}-${random_string.suffix.result}"
  
  gcp_network_info {
    network_project_id = var.project
    vpc_id             = google_compute_network.dbx_private_vpc.name
    subnet_id          = google_compute_subnetwork.dbx_subnets[each.key].name
    subnet_region      = google_compute_subnetwork.dbx_subnets[each.key].region
  }
}