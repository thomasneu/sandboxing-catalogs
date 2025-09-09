# Databricks Multi-Workspace Terraform

Enterprise Databricks deployment on GCP with Unity Catalog, workspace isolation, and RBAC.

## Overview

Deploys 2 isolated Databricks workspaces sharing a Unity Catalog metastore:
- **Workspace-1**: Analytics (`catalog-a`, 1 worker)
- **Workspace-2**: ML Training (`catalog-b`, 2 workers)

**Key Features:**
- Isolated catalogs per workspace using Unity Catalog `ISOLATED` mode
- Shared networking with dedicated subnets (10.1.0.0/24, 10.2.0.0/24)
- Role-based access control across 4 user groups
- Private clusters with NAT gateway for internet access

## Infrastructure Components

### Networking
- **Shared VPC** with Cloud Router and NAT Gateway
- **Per-workspace subnets** for compute isolation
- **Private IP ranges** with Google API access

### Storage
- **Catalog buckets**: Unity Catalog managed tables (per workspace)
- **Unmanaged buckets**: External Iceberg tables (per workspace)
- **Storage credentials**: Databricks-managed service accounts

### Databricks Resources
- **Shared metastore**: Central data governance
- **Isolated catalogs**: Workspace-specific data access
- **Admin clusters**: Single-node for admin tasks
- **Shared clusters**: Multi-worker for data processing

## Permission Management

### User Groups

| Group | Metastore | Catalog | Workspace | Clusters |
|-------|-----------|---------|-----------|----------|
| **Account Admins** | Full access | All privileges | Admin access | Manage all |
| **Workspace Admins** | Create resources | All privileges | Admin access | Manage all |
| **Data Engineers** | - | Create/modify tables | User access | Attach to shared |
| **Data Analysts** | - | Read-only | User access | Attach to shared |

### Catalog Isolation
- Each workspace sees **only its own catalog**
- Cross-workspace data sharing requires explicit grants
- Storage credentials scoped to workspace buckets

## Quick Deploy

```bash
# 1. Configure variables
cat > terraform.tfvars << EOF
project                            = "your-gcp-project"
databricks_account_id             = "your-account-id"
databricks_google_service_account = "your-sa@project.iam.gserviceaccount.com"
EOF

# 2. Deploy
terraform init
terraform apply

# 3. Get workspace URLs
terraform output databricks_workspace_urls
```

## Key Variables

```hcl
variable "project" { type = string }                     # GCP project ID
variable "databricks_account_id" { type = string }       # Databricks account ID  
variable "databricks_google_service_account" { type = string } # Service account email
variable "additional_users" { type = list(string) }      # Extra users to create
variable "user_group_assignments" { type = map(string) } # User -> group mappings
```

## Important Notes

- Service account has `prevent_destroy = true` for safety
- Catalogs use `ISOLATED` mode for complete workspace separation
- All clusters use `USER_ISOLATION` security mode
- Resources use random suffix for unique naming

