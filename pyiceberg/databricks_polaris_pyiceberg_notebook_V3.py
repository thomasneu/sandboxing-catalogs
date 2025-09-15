# Databricks notebook source
# MAGIC %md
# MAGIC # Connect to Polaris Iceberg Catalog using PyIceberg on Databricks
# MAGIC
# MAGIC This notebook uses PyIceberg to connect to Polaris and then converts data to Spark DataFrames for joining with Unity Catalog tables.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Install PyIceberg

# COMMAND ----------

# Install PyIceberg with S3 support
%pip install pyiceberg[s3] pandas pyarrow

# COMMAND ----------

# Restart Python to ensure clean import
dbutils.library.restartPython()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Connect to Polaris Catalog

# COMMAND ----------

from pyiceberg.catalog import load_catalog
import pandas as pd

# Configure and connect to Polaris catalog
try:
    catalog = load_catalog(
        "quickstart_catalog",
        type="rest",
        uri="http://34.34.139.123:8181/api/catalog",
        warehouse="quickstart_catalog",
        credential="4c96c5904c9e3523:XXX",  # Replace XXXXXX with your actual secret
        scope="PRINCIPAL_ROLE:ALL"
    )
    print("✅ Successfully connected to Polaris catalog!")
except Exception as e:
    print(f"❌ Failed to connect to Polaris: {e}")
    raise

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Explore Catalog Structure

# COMMAND ----------

# List namespaces (equivalent to your original catalog.list_namespaces())
print("📁 Available Namespaces:")
try:
    namespaces = catalog.list_namespaces()
    for i, namespace in enumerate(namespaces, 1):
        print(f"  {i}. {'.'.join(namespace)}")
    print(f"\nTotal namespaces: {len(namespaces)}")
except Exception as e:
    print(f"Error listing namespaces: {e}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. List Tables in Namespaces

# COMMAND ----------

# List tables in different namespace structures
print("📋 Available Tables:")

# Try different namespace patterns based on your original code
namespace_patterns = [
    ("quickstart_namespace",),
    ("quickstart_namespace", "schema"),
]

for namespace in namespace_patterns:
    try:
        print(f"\n🔍 Checking namespace: {'.'.join(namespace)}")
        tables = catalog.list_tables(namespace)
        if tables:
            for i, table in enumerate(tables, 1):
                print(f"  {i}. {'.'.join(table)}")
        else:
            print("  No tables found in this namespace")
    except Exception as e:
        print(f"  Error: {e}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Load and Inspect Table

# COMMAND ----------

# Load the table (adjust identifier based on your actual structure)
table_identifier = ("quickstart_namespace", "schema", "quickstart_table")

try:
    print(f"📊 Loading table: {'.'.join(table_identifier)}")
    table = catalog.load_table(table_identifier)
    
    print("✅ Table loaded successfully!")
    
    # Show table schema (equivalent to your original table.schema())
    print("\n📋 Table Schema:")
    schema = table.schema()
    for field in schema.fields:
        print(f"  - {field.name}: {field.field_type}")
    
    # Show current snapshot info (equivalent to your original table.current_snapshot())
    print(f"\n📸 Current Snapshot:")
    current_snapshot = table.current_snapshot()
    if current_snapshot:
        print(f"  - Snapshot ID: {current_snapshot.snapshot_id}")
        print(f"  - Timestamp: {current_snapshot.timestamp_ms}")
        print(f"  - Summary: {current_snapshot.summary}")
    else:
        print("  No snapshots found")
        
except Exception as e:
    print(f"❌ Failed to load table: {e}")
    print("🔧 Trying alternative table identifiers...")
    
    # Try different table identifier patterns
    alternative_patterns = [
        ("quickstart_namespace", "quickstart_table"),
        ("schema", "quickstart_table"),
    ]
    
    for alt_identifier in alternative_patterns:
        try:
            print(f"  Trying: {'.'.join(alt_identifier)}")
            table = catalog.load_table(alt_identifier)
            table_identifier = alt_identifier
            print(f"✅ Success with identifier: {'.'.join(table_identifier)}")
            break
        except Exception as alt_e:
            print(f"    Failed: {alt_e}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Query Data with PyIceberg

# COMMAND ----------

# Scan and convert data to Pandas (equivalent to your original tbl.scan().to_pandas())
try:
    print("🔄 Scanning table data...")
    
    # Get all data as Pandas DataFrame
    pandas_df = table.scan().to_pandas()
    
    print(f"✅ Data loaded successfully!")
    print(f"📊 DataFrame shape: {pandas_df.shape}")
    
    # Display basic info
    print(f"\n📈 Data Info:")
    print(f"  - Rows: {len(pandas_df):,}")
    print(f"  - Columns: {len(pandas_df.columns)}")
    print(f"  - Memory usage: {pandas_df.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    # Show column types
    print(f"\n📋 Column Types:")
    for col, dtype in pandas_df.dtypes.items():
        print(f"  - {col}: {dtype}")
    
    # Show first few rows (equivalent to df.head())
    print(f"\n🔍 First 5 rows:")
    display(pandas_df.head())
    
except Exception as e:
    print(f"❌ Failed to scan data: {e}")