%python
# MS Authentication
STORAGE_CONTAINER_NAME = 'myapp-external-catalog'
STORAGE_ACCOUNT_NAME = 'xxx'
TENANT_ID = "xxx"
oauth2_scope= 'api:/'
oauth2_uri= 'xxxx'
client_id = dbutils.secrets.get(scope = "xxx-prj-kv-secret-scope", key = "AzureProjectServicePrincipalClientId")
client_secret = dbutils.secrets.get(scope = "xxx-prj-kv-secret-scope", key = "AzureProjectServicePrincipalSecret")

spark.conf.set(f"fs.azure.account.oauth2.client.endpoint.{STORAGE_ACCOUNT_NAME}.dfs.core.windows.net", f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/token")
spark.conf.set(f"fs.azure.account.oauth2.client.secret.{STORAGE_ACCOUNT_NAME}.dfs.core.windows.net", client_secret)
spark.conf.set(f"fs.azure.account.oauth.provider.type.{STORAGE_ACCOUNT_NAME}.dfs.core.windows.net", "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set(f"fs.azure.account.auth.type.{STORAGE_ACCOUNT_NAME}.dfs.core.windows.net", "OAuth")
spark.conf.set(f"fs.azure.account.oauth2.client.id.{STORAGE_ACCOUNT_NAME}.dfs.core.windows.net", client_id)

# Iceberg Catalog Configuration
# iceberg_catalog = {
# "name": "myapp",
# "endpoint": "myapp",
# "warehouse": "abfss://myapp-external-catalog@uapcpwmyappc001.dfs.core.windows.net/",
# }

iceberg_catalog = {
"name": "myapp",
"endpoint": "polaris",
"warehouse": "myapp",
}

backend_name = iceberg_catalog["name"]
warehouse = iceberg_catalog["warehouse"]
endpoint = iceberg_catalog["endpoint"]
spark.conf.set(f"spark.sql.catalog.{backend_name}", "org.apache.iceberg.spark.SparkCatalog")
spark.conf.set("spark.sql.defaultCatalog", backend_name)
spark.conf.set(f"spark.sql.catalog.{backend_name}.type", "rest")
spark.conf.set(f"spark.sql.catalog.{backend_name}.uri", f"https://xxx/myapp/{endpoint}")
spark.conf.set(f"spark.sql.catalog.{backend_name}.warehouse", warehouse)
spark.conf.set(f"spark.sql.catalog.{backend_name}.default-namespace", "raw")
spark.conf.set("spark.sql.catalog.iceberg.type", "rest")
spark.conf.set(f'spark.sql.catalog.{backend_name}.token-refresh-enabled', 'true')
spark.conf.set(f'spark.sql.catalog.{backend_name}.credential', f"{client_id}:{client_secret}")
spark.conf.set(f'spark.sql.catalog.{backend_name}.scope', oauth2_scope)
spark.conf.set(f'spark.sql.catalog.{backend_name}.oauth2-server-uri', oauth2_uri)

spark.conf.set("spark.sql.parquet.enableVectorizedReader", "false")