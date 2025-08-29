# Multi-Workspace Databricks Setup on GCP

This Terraform configuration creates a complete multi-workspace Databricks setup on Google Cloud Platform with Unity Catalog enabled, proper resource isolation, and a comprehensive permission structure.

## What it creates

### Infrastructure
- **Workspaces**: 
  - `snd-workspace-1` for analytics use case with catalog-a
  - `snd-workspace-2` for ml-training use case with catalog-b
- **Unity Catalog**: Shared metastore with separate catalogs per workspace
- **Storage**: Per-workspace isolation
  - Catalog buckets for Unity Catalog managed tables
  - Unmanaged buckets for iceberg tables
- **Compute**: Per-workspace clusters
  - Admin clusters (1 worker each) for administrators
  - Shared clusters (1-2 workers based on use case) for data teams
- **Networking**: Network isolation with shared infrastructure
  - Shared VPC and NAT gateway
  - Separate subnets per workspace (10.1.0.0/24, 10.2.0.0/24)

### Permission Structure
- **Account-level Groups** (shared across workspaces):
  - `Account Admins`: Full account management
  - `Workspace Admins`: Workspace and Unity Catalog administration
  - `Data Engineers`: Create schemas, tables, functions
  - `Data Analysts`: Read-only access to data

- **Permission Assignment Methods**:
  - **Workspace permissions**: Assigned to groups (`databricks_mws_permission_assignment`)
  - **Unity Catalog permissions**: Granted to groups (`databricks_grants`)
  - **Cluster permissions**: Controlled via group access (`databricks_permissions`)

- **Per-Workspace Permissions**:
  - Workspace Admins: ADMIN access to all workspaces
  - Data Engineers & Analysts: USER access to all workspaces

- **Per-Catalog Unity Catalog Permissions**:
  - Workspace Admins: ALL_PRIVILEGES on each catalog
  - Data Engineers: USE_CATALOG, CREATE_SCHEMA, CREATE_TABLE, etc.
  - Data Analysts: USE_CATALOG, USE_SCHEMA, SELECT

- **Per-Cluster Permissions**:
  - Admin clusters: Only workspace admins can manage
  - Shared clusters: All users can attach, admins can manage

## Resource Isolation Architecture

### Shared Resources
- **Metastore**: Single Unity Catalog metastore shared across workspaces
- **VPC Network**: Shared network infrastructure for cost efficiency
- **NAT Gateway**: Shared for internet access
- **Account Groups**: Same user groups across all workspaces
- **Service Accounts**: Shared provisioning service account

### Isolated Resources (per workspace)
- **Subnets**: Network-level isolation (10.1.0.0/24 vs 10.2.0.0/24)
- **Storage Buckets**: Separate catalog and unmanaged buckets
- **Storage Credentials**: Workspace-specific service accounts
- **Catalogs**: catalog-a vs catalog-b with isolated data
- **Clusters**: Separate compute resources per workspace
- **Permission Assignments**: Explicit per-workspace access

## Workspace Configuration

| Workspace | Catalog | Use Case | Subnet CIDR | Shared Cluster Workers |
|-----------|---------|----------|-------------|----------------------|
| workspace-1 | catalog-a | analytics | 10.1.0.0/24 | 1 |
| workspace-2 | catalog-b | ml-training | 10.2.0.0/24 | 2 |

## Prerequisites

1. **GCP Project** with billing enabled
2. **Databricks Account** on GCP
3. **Service Account** added to Databricks account console as account admin
4. **gcloud CLI** installed and authenticated
5. **Terraform** installed

## Setup Instructions

1. **Clone and configure**:
   ```bash
   cd multi-workspace-databricks-setup
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values