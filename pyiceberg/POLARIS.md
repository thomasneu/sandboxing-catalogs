
## Polaris

- https://polaris.apache.org/releases/1.0.0/getting-started/deploying-polaris/quickstart-deploy-gcp/
- https://github.com/apache/polaris/blob/main/getting-started/assets/cloud_providers/deploy-gcp.sh 
- https://polaris.apache.org/releases/1.0.0/getting-started/using-polaris/
- https://polaris.apache.org/releases/1.0.0/configuring-polaris-for-production/

Terraform to create a vm for polaris including SP and bucket. The startup script in the tf installs docker and java dependencies as well as setting JAVA-Home (for user thomas). ssh to the machine with gcloud compute ssh. 
Deployment works via the deploy-gxp.sh in the polaris repo - change some details to be cost efficient.
The initial user needs to be set up using polaris comand (install python )
created a pyiceberg example to check if table could be read. To create a table you can also use the spark docker on the vm (see getting started polaris)


#ensure java is installed (should be done ins tartup script)


# Verify Installation and deploy
java -version


#prereq
getent group docker
sudo usermod -aG docker $USER
git clone https://github.com/apache/polaris.git
cd polaris

nano getting-started/assets/cloud_providers/deploy-gcp.sh
#the sample is quite expensive - add --no-backup and edition Enterprise_Plus to Enterprise and choose $DB_TIER db-custom-2-3840

chmod +x getting-started/assets/cloud_providers/deploy-gcp.sh
export ASSETS_PATH=$(pwd)/getting-started/assets/
export CLIENT_ID=root
export CLIENT_SECRET=s3cr3t
export DB_TIER=db-custom-2-3840
./getting-started/assets/cloud_providers/deploy-gcp.sh


# Set the correct database connection parameters and start
export QUARKUS_DATASOURCE_JDBC_URL="jdbc:postgresql://104.199.43.78:5432/POLARIS"
export QUARKUS_DATASOURCE_USERNAME="postgres"
export QUARKUS_DATASOURCE_PASSWORD="postgres"
export $RANDOM_SUFFIX = "twlh5kg3"
export STORAGE_LOCATION="gs://polaris-test-gcs-twlh5kg3"

docker compose -p polaris -f getting-started/jdbc/docker-compose-bootstrap-db.yml -f getting-started/jdbc/docker-compose.yml up -d

export ASSETS_PATH=$(pwd)/getting-started/assets/
docker compose -p polaris -f getting-started/eclipselink/docker-compose.yml down




# create principal and permissions


#intall python and install pip dependency 
sudo apt update
sudo apt install python3 python3-pip
sudo apt install python3.10-venv

python3 -m venv polaris-venv
source polaris-venv/bin/activate
pip install polaris-catalog

cd ~/polaris


./polaris \
  --client-id ${CLIENT_ID} \
  --client-secret ${CLIENT_SECRET} \
  principals \
  create \
  thomas_user

  {"clientId": "4c96c5904c9e3523", "clientSecret": "XXX"}

export USER_CLIENT_ID=4c96c5904c9e3523
export USER_CLIENT_SECRET=XXX


./polaris \
  --client-id ${CLIENT_ID} \
  --client-secret ${CLIENT_SECRET} \
  principal-roles \
  create \
  thomas_user_role

./polaris \
  --client-id ${CLIENT_ID} \
  --client-secret ${CLIENT_SECRET} \
  catalog-roles \
  create \
  --catalog quickstart_catalog \
  thomas_catalog_role

  ----

  ./polaris \
  --client-id ${CLIENT_ID} \
  --client-secret ${CLIENT_SECRET} \
  principal-roles \
  grant \
  --principal thomas_user \
  thomas_user_role

./polaris \
  --client-id ${CLIENT_ID} \
  --client-secret ${CLIENT_SECRET} \
  catalog-roles \
  grant \
  --catalog quickstart_catalog \
  --principal-role thomas_user_role \
  thomas_catalog_role
  
  ----

  ./polaris \
  --client-id ${CLIENT_ID} \
  --client-secret ${CLIENT_SECRET} \
  privileges \
  catalog \
  grant \
  --catalog quickstart_catalog \
  --catalog-role thomas_catalog_role \
  CATALOG_MANAGE_CONTENT

#Pretty print catalog list
./polaris --client-id ${CLIENT_ID} --client-secret ${CLIENT_SECRET} catalogs list | jq .

#Pretty print specific catalog details
./polaris --client-id ${CLIENT_ID} --client-secret ${CLIENT_SECRET} catalogs get quickstart_catalog | jq .

# List all namespaces in a catalog
./polaris --client-id ${CLIENT_ID} --client-secret ${CLIENT_SECRET} namespaces list --catalog quickstart_catalog | jq .
# List nested namespaces (if any exist)
./polaris --client-id ${CLIENT_ID} --client-secret ${CLIENT_SECRET} namespaces list --catalog quickstart_catalog --parent some_namespace | jq .


  # DELETE 
  
export DB_INSTANCE_NAME="polaris-backend-test-$RANDOM_SUFFIX"
gcloud sql instances delete $DB_INSTANCE_NAME


gcloud sql instances list
gcloud sql instances delete INSTANCE_NAME

gcloud sql backups list
gcloud sql backups delete projects/applied-light-128913/backups/ce4c205c-0979-4abe-b3e0-df1037e95168

gcloud storage buckets list   --format="table(name,location,storageClass,uniformBucketLevelAccess)"
gcloud storage buckets delete gs://polaris-test-gcs-fkqvgn0d/



# Polaris in databrick


## Installs
# allow and install 
org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.9.2
org.apache.iceberg:iceberg-gcp-bundle:1.9.2


## test with spark docker 
docker compose -p polaris -f getting-started/eclipselink/docker-compose.yml stop spark-sql
docker compose -p polaris -f getting-started/eclipselink/docker-compose.yml rm -f spark-sql
docker compose -p polaris -f getting-started/eclipselink/docker-compose.yml up -d --no-deps spark-sql
docker attach $(docker ps -q --filter name=spark-sql)

SHOW TABLES IN quickstart_catalog;
SHOW TABLES IN quickstart_catalog.quickstart_namespace.schema;
SHOW NAMESPACES IN quickstart_catalog;



## Aktuelle Spark config vom docker abgeleitet
spark.sql.extensions org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
spark.jars.packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.9.2,org.apache.iceberg:iceberg-gcp-bundle:1.9.2
spark.sql.catalog.quickstart_catalog org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.quickstart_catalog.type rest
spark.sql.catalog.quickstart_catalog.catalog-impl org.apache.iceberg.rest.RESTCatalog
spark.sql.catalog.quickstart_catalog.warehouse quickstart_catalog
spark.sql.catalog.quickstart_catalog.uri http://34.34.139.123:8181/api/catalog
spark.sql.catalog.quickstart_catalog.credential 4c96c5904c9e3523:XXX
spark.sql.catalog.quickstart_catalog.scope PRINCIPAL_ROLE:ALL
spark.sql.catalog.quickstart_catalog.header.X-Iceberg-Access-Delegation vended-credentials
spark.sql.catalog.quickstart_catalog.token-refresh-enabled true


# Final Config 

#Iceberg Extensions
spark.sql.extensions org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions

#Polaris Catalog Configuration  
spark.sql.catalog.quickstart_catalog org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.quickstart_catalog.type rest
spark.sql.catalog.quickstart_catalog.catalog-impl org.apache.iceberg.rest.RESTCatalog
spark.sql.catalog.quickstart_catalog.warehouse quickstart_catalog
spark.sql.catalog.quickstart_catalog.uri http://34.34.139.123:8181/api/catalog

#Authentication
spark.sql.catalog.quickstart_catalog.credential 4c96c5904c9e3523:XXX
spark.sql.catalog.quickstart_catalog.scope PRINCIPAL_ROLE:ALL

#Databricks-specific configurations
spark.sql.catalog.quickstart_catalog.header.X-Iceberg-Access-Delegation vended-credentials
spark.sql.catalog.quickstart_catalog.token-refresh-enabled true
spark.sql.catalog.quickstart_catalog.io-impl org.apache.iceberg.gcp.gcs.GCSFileIO

#additional stability configs for Databricks
spark.databricks.delta.autoCompact.enabled false
spark.databricks.delta.optimizeWrite.enabled false

# Result
it seems Polaris and Unity are not usable at the same time in Databricks. UC enabled is not connectiong to polaris at all. Spark config works like a charm 