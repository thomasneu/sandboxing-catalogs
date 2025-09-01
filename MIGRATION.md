# Remove old catalog resources from state
terraform state rm databricks_catalog.catalog_ws1
terraform state rm databricks_catalog.catalog_ws2

# Remove related schema resources from state  
terraform state rm databricks_schema.default_schema_ws1
terraform state rm databricks_schema.default_schema_ws2

# Remove grants that reference old catalogs
terraform state rm databricks_grants.catalog_grants_ws1
terraform state rm databricks_grants.catalog_grants_ws2
terraform state rm databricks_grants.schema_grants_ws1
terraform state rm databricks_grants.schema_grants_ws2

_____
# Terraform - für destroy den acc aus dem state nehmen und danach weider importieren -

# Remove what you want to KEEP from Terraform state
terraform state rm google_service_account.databricks_provisioning
terraform state rm google_service_account_iam_policy.impersonatable
terraform state rm google_project_iam_member.sa_workspace_creator

# Import service account
terraform import google_service_account.databricks_provisioning projects/GOOGLE_PROJECT_ID/serviceAccounts/snd-databricks-sa-0mpem4@GOOGLE_PROJECT_ID.iam.gserviceaccount.com

# Import IAM policy  
terraform import google_service_account_iam_policy.impersonatable projects/GOOGLE_PROJECT_ID/serviceAccounts/snd-databricks-sa-0mpem4@GOOGLE_PROJECT_ID.iam.gserviceaccount.com

# Import project IAM member
terraform import google_project_iam_member.sa_workspace_creator "GOOGLE_PROJECT_ID roles/YOUR_CUSTOM_ROLE_ID serviceAccount:snd-databricks-sa-0mpem4@GOOGLE_PROJECT_ID.iam.gserviceaccount.com"


_____


Phase 1: Destroy Clusters & Permissions
bash# Cluster permissions first
terraform destroy -target=databricks_permissions.admin_cluster_permissions_ws1 -auto-approve
terraform destroy -target=databricks_permissions.admin_cluster_permissions_ws2  -auto-approve
terraform destroy -target=databricks_permissions.shared_cluster_permissions_ws1 -auto-approve
terraform destroy -target=databricks_permissions.shared_cluster_permissions_ws2 -auto-approve

# Then clusters
terraform destroy -target=databricks_cluster.admin_cluster_ws1 -auto-approve
terraform destroy -target=databricks_cluster.admin_cluster_ws2 -auto-approve
terraform destroy -target=databricks_cluster.shared_cluster_ws1 -auto-approve
terraform destroy -target=databricks_cluster.shared_cluster_ws2 -auto-approve
Phase 2: Destroy Unity Catalog Permissions & Schemas
bash# Schema permissions
terraform destroy -target=databricks_grants.schema_grants_ws1 -auto-approve
terraform destroy -target=databricks_grants.schema_grants_ws2 -auto-approve

# Catalog permissions  
terraform destroy -target=databricks_grants.catalog_grants_ws1 -auto-approve
terraform destroy -target=databricks_grants.catalog_grants_ws2 -auto-approve

# Metastore permissions
terraform destroy -target=databricks_grants.metastore_grants_ws1 -auto-approve
terraform destroy -target=databricks_grants.metastore_grants_ws2 -auto-approve

# Schemas
terraform destroy -target=databricks_schema.default_schema_ws1 -auto-approve
terraform destroy -target=databricks_schema.default_schema_ws2 -auto-approve


# Storage bucket IAM
terraform destroy -target=google_storage_bucket_iam_member.catalog_admin_ws1 -auto-approve
terraform destroy -target=google_storage_bucket_iam_member.catalog_reader_ws1 -auto-approve
terraform destroy -target=google_storage_bucket_iam_member.catalog_admin_ws2 -auto-approve
terraform destroy -target=google_storage_bucket_iam_member.catalog_reader_ws2 -auto-approve
Phase 4: Destroy Catalogs & Bindings
bash# Catalog workspace bindings
terraform destroy -target=databricks_catalog_workspace_binding.catalog_a_binding -auto-approve
terraform destroy -target=databricks_catalog_workspace_binding.catalog_b_binding -auto-approve

# Catalogs
terraform destroy -target=databricks_catalog.catalog_a -auto-approve
terraform destroy -target=databricks_catalog.catalog_b -auto-approve
Phase 5: Destroy Workspace Access & Users 
bash# Workspace permissions
terraform destroy -target=databricks_mws_permission_assignment.workspace_admins -auto-approve
terraform destroy -target=databricks_mws_permission_assignment.data_engineers  -auto-approve
terraform destroy -target=databricks_mws_permission_assignment.data_analysts -auto-approve
Phase 3: Destroy External Locations & Storage
bash# External locations
terraform destroy -target=databricks_external_location.catalog_location_ws1 -auto-approve
terraform destroy -target=databricks_external_location.catalog_location_ws2 -auto-approve

# Storage credentials  
terraform destroy -target=databricks_storage_credential.catalog_credential_ws1 -auto-approve
terraform destroy -target=databricks_storage_credential.catalog_credential_ws2 -auto-approve

# Group memberships
terraform destroy -target=databricks_group_member.me_account_admin -auto-approve
terraform destroy -target=databricks_group_member.me_workspace_admin -auto-approve
terraform destroy -target=databricks_group_member.additional_user_memberships -auto-approve

# Users & groups
terraform destroy -target=databricks_user.additional_users -auto-approve
terraform destroy -target=databricks_user.me -auto-approve
terraform destroy -target=databricks_group.account_admins -auto-approve
terraform destroy -target=databricks_group.workspace_admins -auto-approve
terraform destroy -target=databricks_group.data_engineers -auto-approve
terraform destroy -target=databricks_group.data_analysts -auto-approve
Phase 6: Destroy Metastore & Workspaces
bash# Metastore assignments
terraform destroy -target=databricks_metastore_assignment.assignments -auto-approve

# Workspaces
terraform destroy -target=databricks_mws_workspaces.workspaces -auto-approve

# Metastore
terraform destroy -target=databricks_metastore.this -auto-approve
Phase 7: Destroy Networking & Storage
bash# Databricks networks
terraform destroy -target=databricks_mws_networks.networks -auto-approve

# Storage buckets
terraform destroy -target=google_storage_bucket.catalog_buckets -auto-approve
terraform destroy -target=google_storage_bucket.unmanaged_buckets -auto-approve

# NAT & Router
terraform destroy -target=google_compute_router_nat.nat -auto-approve
terraform destroy -target=google_compute_router.router -auto-approve

# Subnets & VPC
terraform destroy -target=google_compute_subnetwork.dbx_subnets -auto-approve
terraform destroy -target=google_compute_network.dbx_private_vpc -auto-approve

# Custom role (but keep service account)
terraform destroy -target=google_project_iam_custom_role.workspace_creator -auto-approve

# Random suffix 
terraform destroy -target=random_string.suffix -auto-approve