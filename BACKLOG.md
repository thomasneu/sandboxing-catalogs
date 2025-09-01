1) Add workspace bindings 

resource "databricks_catalog" "sandbox" {
  name           = "sandbox"
  isolation_mode = "ISOLATED"
}

resource "databricks_catalog_workspace_binding" "sandbox" {
  securable_name = databricks_catalog.sandbox.name
  workspace_id   = databricks_mws_workspaces.other.workspace_id
}

2) st unmanage-bucket unmanaged_buckets als external location - grant wenn notwendieg 

unmanaged_buckets
catalog_buckets 

 resource "databricks_storage_credential" "ext" {
  name = "the-creds"
  databricks_gcp_service_account {}
}

resource "databricks_external_location" "some" {
  name = "the-ext-location"
  url  = "gs://${google_storage_bucket.ext_bucket.name}"

  credential_name = databricks_storage_credential.ext.id
  comment         = "Managed by TF"
}

resource "databricks_grants" "some" {
  external_location = databricks_external_location.some.id
  grant {
    principal  = "Data Engineers"
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES"]
  }
} 

2) Shared Catalog c for both

3) implement via foreach - variable input or local to crate workspace

4) create sample tables 
    a) Delta Table 
    b) externa