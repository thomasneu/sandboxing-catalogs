# ===============================
# DATA SOURCES FOR COMPUTE
# ===============================

# Data sources for workspace-1
data "databricks_spark_version" "latest_lts_ws1" {
  provider          = databricks.workspace-1
  long_term_support = true
  depends_on        = [databricks_mws_workspaces.workspaces]
}

data "databricks_node_type" "smallest_ws1" {
  provider   = databricks.workspace-1
  local_disk = true
  depends_on = [databricks_mws_workspaces.workspaces]
}

# Data sources for workspace-2
data "databricks_spark_version" "latest_lts_ws2" {
  provider          = databricks.workspace-2
  long_term_support = true
  depends_on        = [databricks_mws_workspaces.workspaces]
}

data "databricks_node_type" "smallest_ws2" {
  provider   = databricks.workspace-2
  local_disk = true
  depends_on = [databricks_mws_workspaces.workspaces]
}

# ===============================
# WORKSPACE-1 CLUSTERS
# ===============================

# Admin cluster for workspace-1
resource "databricks_cluster" "admin_cluster_ws1" {
  provider                = databricks.workspace-1
  cluster_name            = "${var.prefix}-admin-cluster-workspace-1"
  spark_version           = data.databricks_spark_version.latest_lts_ws1.id
  node_type_id            = data.databricks_node_type.smallest_ws1.id
  autotermination_minutes = 30
  num_workers             = 1
  data_security_mode      = "USER_ISOLATION"

  depends_on = [databricks_metastore_assignment.assignments]
}

# Shared cluster for workspace-1
resource "databricks_cluster" "shared_cluster_ws1" {
  provider                = databricks.workspace-1
  cluster_name            = "${var.prefix}-shared-cluster-workspace-1"
  spark_version           = data.databricks_spark_version.latest_lts_ws1.id
  node_type_id            = data.databricks_node_type.smallest_ws1.id
  autotermination_minutes = 30
  num_workers             = local.workspaces["workspace-1"].cluster_workers
  data_security_mode      = "USER_ISOLATION"

  depends_on = [databricks_metastore_assignment.assignments]
}

# ===============================
# WORKSPACE-2 CLUSTERS
# ===============================

# Admin cluster for workspace-2
resource "databricks_cluster" "admin_cluster_ws2" {
  provider                = databricks.workspace-2
  cluster_name            = "${var.prefix}-admin-cluster-workspace-2"
  spark_version           = data.databricks_spark_version.latest_lts_ws2.id
  node_type_id            = data.databricks_node_type.smallest_ws2.id
  autotermination_minutes = 30
  num_workers             = 1
  data_security_mode      = "USER_ISOLATION"

  depends_on = [databricks_metastore_assignment.assignments]
}

# Shared cluster for workspace-2
resource "databricks_cluster" "shared_cluster_ws2" {
  provider                = databricks.workspace-2
  cluster_name            = "${var.prefix}-shared-cluster-workspace-2"
  spark_version           = data.databricks_spark_version.latest_lts_ws2.id
  node_type_id            = data.databricks_node_type.smallest_ws2.id
  autotermination_minutes = 30
  num_workers             = local.workspaces["workspace-2"].cluster_workers
  data_security_mode      = "USER_ISOLATION"

  depends_on = [databricks_metastore_assignment.assignments]
}