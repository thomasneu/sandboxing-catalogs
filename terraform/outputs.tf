# Service Account outputs
output "databricks_service_account_email" {
  value       = google_service_account.databricks_provisioning.email
  description = "Email of the Databricks provisioning service account"
}

output "custom_role_url" {
  value = "https://console.cloud.google.com/iam-admin/roles/details/projects%2F${data.google_client_config.current.project}%2Froles%2F${google_project_iam_custom_role.workspace_creator.role_id}"
  description = "URL to view the custom workspace creator role in GCP Console"
}

# Workspace outputs
output "databricks_workspace_urls" {
  value = {
    for k, v in databricks_mws_workspaces.workspaces : k => v.workspace_url
  }
  description = "URLs of the Databricks workspaces"
}

output "databricks_workspace_ids" {
  value = {
    for k, v in databricks_mws_workspaces.workspaces : k => v.workspace_id
  }
  description = "IDs of the Databricks workspaces"
}

# Unity Catalog outputs
output "metastore_id" {
  value       = databricks_metastore.this.id
  description = "ID of the shared Unity Catalog metastore"
}

output "catalog_names" {
  value = {
    "workspace-1" = databricks_catalog.catalog_a.name
    "workspace-2" = databricks_catalog.catalog_b.name
  }
  description = "Names of the isolated catalogs per workspace"
}

output "catalog_isolation_info" {
  value = {
    "workspace-1" = {
      catalog_name   = databricks_catalog.catalog_a.name
      isolation_mode = databricks_catalog.catalog_a.isolation_mode
      #workspace_id   = databricks_catalog_workspace_binding.catalog_a_binding.workspace_id
    }
    "workspace-2" = {
      catalog_name   = databricks_catalog.catalog_b.name
      isolation_mode = databricks_catalog.catalog_b.isolation_mode
      #workspace_id   = databricks_catalog_workspace_binding.catalog_b_binding.workspace_id
    }
  }
  description = "Isolation information for each catalog including mode and bound workspace"
}

# Storage outputs
output "catalog_bucket_names" {
  value = {
    for k, v in google_storage_bucket.catalog_buckets : k => v.name
  }
  description = "Names of the catalog storage buckets per workspace"
}

output "unmanaged_bucket_names" {
  value = {
    for k, v in google_storage_bucket.unmanaged_buckets : k => v.name
  }
  description = "Names of the unmanaged iceberg tables buckets per workspace"
}

output "unmanaged_bucket_urls" {
  value = {
    for k, v in google_storage_bucket.unmanaged_buckets : k => "gs://${v.name}"
  }
  description = "GCS URLs for the unmanaged iceberg tables buckets per workspace"
}

# Cluster outputs
output "admin_cluster_ids" {
  value = {
    "workspace-1" = databricks_cluster.admin_cluster_ws1.id
    "workspace-2" = databricks_cluster.admin_cluster_ws2.id
  }
  description = "IDs of the admin clusters per workspace"
}

output "shared_cluster_ids" {
  value = {
    "workspace-1" = databricks_cluster.shared_cluster_ws1.id
    "workspace-2" = databricks_cluster.shared_cluster_ws2.id
  }
  description = "IDs of the shared clusters per workspace"
}

# Network outputs
output "vpc_name" {
  value       = google_compute_network.dbx_private_vpc.name
  description = "Name of the shared VPC network"
}

output "subnet_names" {
  value = {
    for k, v in google_compute_subnetwork.dbx_subnets : k => v.name
  }
  description = "Names of the subnets per workspace"
}

output "subnet_cidrs" {
  value = {
    for k, v in local.workspaces : k => v.subnet_cidr
  }
  description = "CIDR ranges of the subnets per workspace"
}

# User and Group outputs
output "current_user_id" {
  value       = databricks_user.me.id
  description = "ID of the current user in Databricks account"
}

output "group_ids" {
  value = {
    account_admins   = databricks_group.account_admins.id
    workspace_admins = databricks_group.workspace_admins.id
    data_engineers   = databricks_group.data_engineers.id
    data_analysts    = databricks_group.data_analysts.id
  }
  description = "IDs of created groups"
}

# Workspace configuration summary
output "workspace_summary" {
  value = {
    "workspace-1" = {
      workspace_url      = databricks_mws_workspaces.workspaces["workspace-1"].workspace_url
      catalog_name       = local.workspaces["workspace-1"].catalog_name
      use_case          = local.workspaces["workspace-1"].use_case
      subnet_cidr       = local.workspaces["workspace-1"].subnet_cidr
      cluster_workers   = local.workspaces["workspace-1"].cluster_workers
      catalog_isolated  = true
      #bound_workspace_id = databricks_catalog_workspace_binding.catalog_a_binding.workspace_id
    }
    "workspace-2" = {

      workspace_url      = databricks_mws_workspaces.workspaces["workspace-2"].workspace_url
      catalog_name       = local.workspaces["workspace-2"].catalog_name
      use_case          = local.workspaces["workspace-2"].use_case
      subnet_cidr       = local.workspaces["workspace-2"].subnet_cidr
      cluster_workers   = local.workspaces["workspace-2"].cluster_workers
      catalog_isolated  = true
      #bound_workspace_id = databricks_catalog_workspace_binding.catalog_b_binding.workspace_id
    }
  }
  description = "Summary of workspace configurations including catalog isolation status"
}

# Polaris outputs
output "polaris_vm_external_ip" {
  value       = google_compute_instance.polaris_vm.network_interface[0].access_config[0].nat_ip
  description = "External IP address of the Polaris VM"
}

output "polaris_service_account_email" {
  value       = google_service_account.polaris_sa.email
  description = "Email of the Polaris service account"
}

output "polaris_connection_info" {
  value = {
    polaris_url             = "http://${google_compute_instance.polaris_vm.network_interface[0].access_config[0].nat_ip}:8181"
    management_url          = "http://${google_compute_instance.polaris_vm.network_interface[0].access_config[0].nat_ip}:8182"
    default_catalog_name    = "quickstart_catalog"
    bucket_used             = google_storage_bucket.unmanaged_buckets["workspace-1"].name
    default_credentials     = "CLIENT_ID=root, CLIENT_SECRET=s3cr3t"
    deployment_directory    = "/home/[username]/polaris"
  }
  description = "Information needed to connect to Polaris catalog"
}

output "polaris_setup_commands" {
  value = {
    ssh_to_vm                = "gcloud compute ssh ${google_compute_instance.polaris_vm.name} --zone=${var.zone}"
    clone_and_deploy         = "git clone https://github.com/apache/polaris.git && cd polaris && export ASSETS_PATH=$(pwd)/getting-started/assets/ && export CLIENT_ID=root && export CLIENT_SECRET=s3cr3t && chmod +x getting-started/assets/cloud_providers/deploy-gcp.sh && ./getting-started/assets/cloud_providers/deploy-gcp.sh"
    check_polaris_status     = "docker ps | grep polaris"
    check_deployment_logs    = "docker compose -p polaris -f getting-started/eclipselink/docker-compose.yml logs"
    stop_polaris             = "cd ~/polaris && export ASSETS_PATH=$(pwd)/getting-started/assets/ && docker compose -p polaris -f getting-started/eclipselink/docker-compose.yml down"
    restart_polaris          = "cd ~/polaris && export ASSETS_PATH=$(pwd)/getting-started/assets/ && docker compose -p polaris -f getting-started/eclipselink/docker-compose.yml up -d"
  }
  description = "Commands to deploy and manage the Polaris installation"
}

output "polaris_usage_examples" {
  value = {
    test_connection      = "curl -X POST http://${google_compute_instance.polaris_vm.network_interface[0].access_config[0].nat_ip}:8181/api/catalog/v1/oauth/tokens -d 'grant_type=client_credentials' -d 'client_id=root' -d 'client_secret=s3cr3t'"
    attach_to_spark      = "docker attach $(docker ps -q --filter name=spark-sql)"
    attach_to_trino      = "docker exec -it $(docker ps -q --filter name=trino) trino"
    polaris_cli_example  = "cd ~/polaris && ./polaris --client-id root --client-secret s3cr3t catalogs list"
  }
  description = "Example commands to test and use Polaris after deployment"
}