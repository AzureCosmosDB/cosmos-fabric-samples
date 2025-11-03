<!--
---
page_type: sample
languages:
- scala
products:
- fabric
- fabric-database-cosmos-db
name: "Work with Cosmos DB using Cosmos DB Spark Connector"
description: "Use Spark and the Azure Cosmos DB Spark connector to read, query, analyze, and write data directly to Cosmos DB in Microsoft Fabric with Scala"
urlFragment: "spark-connector-operations"
---
-->

# 🔌 Work with Cosmos DB in Microsoft Fabric using the Cosmos DB Spark Connector

**Connect directly to Cosmos DB using the Spark connector for comprehensive data operations with Spark (Scala)**

This sample demonstrates how to use **Spark** and the **Azure Cosmos DB Spark connector** to read, query, analyze, and write data directly to an Azure Cosmos DB for NoSQL account in Microsoft Fabric. Unlike reading mirrored data through lakehouse shortcuts, this approach connects directly to the Cosmos DB endpoint for real-time OLTP operations.

> **🎯 Key Difference**: This sample uses the **Cosmos DB Spark connector** for direct endpoint access, enabling write operations and real-time queries, as opposed to reading mirrored OneLake data which is read-only.

## 🎯 What You'll Learn

### 🔧 **Spark Connector Configuration**

- **Custom Spark environment** setup with required libraries
- **Maven dependency** management for Cosmos DB Spark connector
- **Authentication configuration** using Fabric-specific access tokens
- **Connection settings** for direct Cosmos DB endpoint access

### 📊 **Data Operations with Spark**

- **DataFrame operations** for loading and transforming data
- **Schema inference** for automatic type detection
- **Filtering and querying** using Spark SQL syntax
- **Array operations** with explode and nested data structures

### ✍️ **Advanced Features**

- **SparkSQL Catalog API** for managing Cosmos DB resources
- **Container creation** through Spark DDL statements
- **Write operations** with ItemOverwrite strategy
- **Aggregations and analytics** on nested JSON data
- **Price history analysis** using array explode operations

## 📋 Prerequisites

### **Required Services**

- **Microsoft Fabric workspace** with appropriate permissions
- **Cosmos DB artifact** in Fabric with existing container
- **Spark notebook** with Scala kernel support
- **Runtime 1.3 (Spark 3.5)** environment

### **Required Libraries**

Download these JAR files from Maven repository:

1. **azure-cosmos-spark_3-5_2-12-4.41.0.jar**
   - [Download Link](https://repo1.maven.org/maven2/com/azure/cosmos/spark/azure-cosmos-spark_3-5_2-12/4.41.0/azure-cosmos-spark_3-5_2-12-4.41.0.jar)

2. **fabric-cosmos-spark-auth_3-1.1.0.jar**
   - [Download Link](https://repo1.maven.org/maven2/com/azure/cosmos/spark/fabric-cosmos-spark-auth_3/1.1.0/fabric-cosmos-spark-auth_3-1.1.0.jar)

### **Data Requirements**

- **CosmosSampleDatabase** - Existing Cosmos DB database
- **SampleData** container with product and review data
- **fabricSampleData.json** loaded into your container

### **Skills**

- Basic Scala programming knowledge
- Understanding of Spark DataFrames
- Familiarity with SQL queries
- JSON data structure concepts

## 🚀 Getting Started

### Step 1: Download Required Libraries

1. **Download the Cosmos DB Spark Connector libraries**:
   - Download both JAR files from the links above
   - Save them to a location you can access during environment setup

### Step 2: Create Custom Spark Environment

1. **Create a new notebook** in Microsoft Fabric
2. **Select Spark (Scala)** as the language
3. **Check workspace settings**:
   - Ensure you're using **Runtime 1.3 (Spark 3.5)**
4. **Create new environment**:
   - Click the **environment dropdown** → **New environment**
   - Provide a name (e.g., "CosmosDB-Spark-Environment")
   - Confirm **Runtime 1.3 (Spark 3.5)** is selected
5. **Upload custom libraries**:
   - Choose **Custom Library** from the **Libraries** folder
   - Upload both downloaded `.jar` files
   - Click **Save** → **Publish** → **Publish all**
6. **Verify success**:
   - Ensure libraries show **success** status
7. **Attach environment**:
   - Return to your notebook
   - Click environment dropdown → **Change environment**
   - Select your newly created environment

### Step 3: Retrieve Cosmos DB Endpoint

1. **Open the Fabric portal** (https://app.fabric.microsoft.com)
2. **Navigate to your Cosmos DB database**
3. **Select Settings** in the menu bar
4. **Go to Connection section**
5. **Copy the endpoint** value:
   - Look for "Endpoint for Cosmos DB NoSQL database"
   - Copy the full URI (e.g., `https://....cosmos.fabric.microsoft.com:443/`)

### Step 4: Download and Import the Notebook

#### Option A: Download from GitHub

1. **Download the notebook**:
   - Click on `spark-scala.ipynb` in this folder
   - Click the "Download" button or "Raw" and save the file
2. **Import into Fabric**:
   - In your Fabric workspace, click **"Import"** → **"Notebook"**
   - Select the downloaded `.ipynb` file and upload

#### Option B: Clone the Repository

1. **Clone this repository** to your local machine:

   ```bash
   git clone https://github.com/azurecosmosdb/cosmos-fabric-samples.git
   ```

2. **Import the notebook**:
   - Navigate to the `spark-scala` folder
   - In your Fabric workspace, click **"Import"** → **"Notebook"**
   - Select and upload the `spark-scala.ipynb` file

### Step 5: Configure the Notebook

1. **Open the imported notebook** in Fabric
2. **Ensure Spark (Scala) kernel** is selected
3. **Attach your custom environment** (created in Step 2)
4. **Update configuration in the first code cell**:
   - `ENDPOINT` - Your Cosmos DB endpoint from Step 3
   - `DATABASE` - Your Cosmos DB database name (e.g., "CosmosSampleDatabase")
   - `CONTAINER` - Your container name (e.g., "SampleData")

**Example configuration:**

```scala
val ENDPOINT = "https://your-endpoint.cosmos.fabric.microsoft.com:443/"
val DATABASE = "CosmosSampleDatabase"
val CONTAINER = "SampleData"
```

## 📖 Notebook Walkthrough

### Section 1: Environment Setup and Configuration

**What it does:**
- Provides instructions for custom Spark environment setup
- Explains how to retrieve your Cosmos DB endpoint
- Configures connection settings with authentication

**Key concepts:**
- Maven dependencies for Spark connector
- Fabric-specific authentication using AccessToken
- Gateway mode for Fabric connectivity

### Section 2: Connect and Read Data

**What it does:**
- Connects to Cosmos DB using the Spark connector
- Loads data into a DataFrame with schema inference
- Displays the first 5 rows of data

**Key code:**
```scala
val df = spark.read.format("cosmos.oltp")
  .options(config)
  .option("spark.cosmos.read.inferSchema.enabled", "true")
  .load()
```

### Section 3: Filter Data by Document Type

**What it does:**
- Filters products from mixed document types
- Demonstrates `where` and `filter` functions
- Shows category-specific filtering

**Key concepts:**
- The `docType` property distinguishes schemas
- Multiple filtering methods (where vs filter)
- DataFrame chaining operations

### Section 4: Query Using SparkSQL

**What it does:**
- Configures the Catalog API for SparkSQL access
- Executes SQL queries against Cosmos DB
- Demonstrates SQL syntax with catalog references

**Key code:**
```scala
spark.conf.set("spark.sql.catalog.cosmosCatalog", "com.azure.cosmos.spark.CosmosCatalog")
val queryString = s"SELECT * FROM cosmosCatalog.$DATABASE.$CONTAINER"
```

### Section 5: Analyze Price History with Arrays

**What it does:**
- Queries products with embedded price history arrays
- Uses `explode` to flatten nested arrays
- Calculates minimum historical prices through aggregation

**Key concepts:**
- Working with nested JSON structures
- Array explosion and transformation
- GroupBy aggregations with min function

**Analysis approach:**
1. Select products with priceHistory arrays
2. Explode the array to create one row per price point
3. Extract date and price fields from structs
4. Group by product and calculate minimum price

### Section 6: Create Container and Write Data

**What it does:**
- Creates a new Cosmos DB container using Catalog API DDL
- Prepares data with required `id` property
- Writes processed results to the new container

**Key code:**
```scala
spark.sql("""
  CREATE TABLE IF NOT EXISTS cosmosCatalog.$DATABASE.$NEW_CONTAINER 
  USING cosmos.oltp 
  TBLPROPERTIES(partitionKeyPath = '/id', autoScaleMaxThroughput = '1000')
""")
```

**Write strategy:**
- ItemOverwrite mode for upsert operations
- APPEND mode for DataFrame save
- Verification query to confirm data

## 💡 Key Concepts Demonstrated

### 1. Direct Cosmos DB Access vs Mirrored Data

**Cosmos DB Spark Connector (this sample):**
- ✅ Direct connection to Cosmos DB endpoint
- ✅ Read and write operations supported
- ✅ Real-time OLTP queries
- ✅ Container creation and management
- ✅ Requires custom library setup

**Lakehouse Shortcuts (mirrored data):**
- ✅ Read-only access through OneLake
- ✅ No library setup required
- ✅ Optimized for analytical queries
- ❌ Write operations not supported
- ❌ Cannot create/modify containers

### 2. Schema Inference

The connector automatically detects multiple document schemas within a single container:

```scala
.option("spark.cosmos.read.inferSchema.enabled", "true")
```

This samples both document types (product and review) and creates a unified schema with nullable fields.

### 3. Array Explosion for Nested Data

```scala
val explodedDF = productPriceMinDF
   .withColumn("priceHistory", explode(col("priceHistory")))
   .withColumn("priceDate", col("priceHistory").getField("date"))
   .withColumn("newPrice", col("priceHistory").getField("price"))
```

Transforms nested arrays into flat rows for aggregation and analysis.

### 4. Catalog API for Resource Management

```scala
CREATE TABLE IF NOT EXISTS cosmosCatalog.$DATABASE.$NEW_CONTAINER 
USING cosmos.oltp 
TBLPROPERTIES(partitionKeyPath = '/id', autoScaleMaxThroughput = '1000')
```

Enables DDL operations through SparkSQL for container lifecycle management.

## 🔧 Troubleshooting

### Common Issues

**Library Loading Errors**
- Ensure both JAR files are uploaded to your custom environment
- Verify environment is published and attached to notebook
- Check that Runtime 1.3 (Spark 3.5) is selected
- Restart notebook if libraries don't load

**Connection Errors**
- Verify endpoint URL is correct (should end with `:443/`)
- Ensure database and container names match exactly
- Check that Fabric authentication is configured
- Confirm network connectivity to Cosmos DB endpoint

**Schema Inference Issues**
- Ensure container has data before querying
- Check that `inferSchema.enabled` is set to `true`
- Verify document structure matches expected format
- Sample different documents if schema detection fails

**Write Operation Failures**
- Confirm `id` field exists in DataFrame before writing
- Verify partition key matches container configuration
- Check throughput settings are adequate (minimum 1000 RU/s)
- Ensure write permissions on Cosmos DB container

**Spark Kernel Issues**
- Select **Spark (Scala)** kernel, not Python
- Restart kernel if Scala code doesn't execute
- Clear outputs and re-run if variables aren't defined
- Check for syntax errors in Scala code blocks

## 🎯 Production Best Practices

### Performance Optimization

- **Partition key selection**: Choose keys with even distribution
- **Throughput sizing**: Start with autoscale, monitor RU consumption
- **Batch operations**: Use bulk writes for large datasets
- **Query optimization**: Filter early, select only needed columns

### Data Management

- **Schema evolution**: Plan for document schema changes
- **Indexing policies**: Exclude paths not needed for queries
- **Retention policies**: Archive or delete old data regularly
- **Monitoring**: Track RU usage and query performance

### Security

- **Access control**: Use Fabric's built-in RBAC
- **Data encryption**: Cosmos DB encrypts at rest by default
- **Network security**: Consider private endpoints for production
- **Audit logging**: Enable diagnostic logs for compliance

## 🔄 Next Steps

After completing this sample, explore:

- **Advanced Analytics** - Window functions and time-series analysis
- **Batch Processing** - ETL pipelines with Spark connector
- **Change Feed** - Real-time data processing patterns
- **Multi-Container Joins** - Combining data from multiple sources
- **Machine Learning** - Feature engineering on Cosmos DB data
- **Performance Tuning** - Optimizing throughput and query patterns

## 📚 Additional Resources

### Documentation

- [Azure Cosmos DB Spark Connector](https://learn.microsoft.com/azure/cosmos-db/nosql/tutorial-spark-connector)
- [Azure Cosmos DB Spark Connector Source Code on GitHub](https://github.com/Azure/azure-sdk-for-java/tree/main/sdk/cosmos/)
- [Microsoft Fabric Spark](https://learn.microsoft.com/fabric/data-engineering/)
- [Cosmos DB in Fabric](https://learn.microsoft.com/fabric/database/cosmos-db/)
- [Spark SQL Reference](https://spark.apache.org/docs/latest/sql-ref.html)

### Related Samples

- **spark-analytics-powerbi** - Analytics using lakehouse shortcuts
- **management** - Container management with Python SDK
- **vector-search** - AI-powered semantic search
- **user-data-functions** - Reusable business logic functions

## 🤝 Contributing

Found an issue or have suggestions for improving this Spark connector sample? Please open an issue in the main repository or submit a pull request with enhancements.

---

**Happy querying with Cosmos DB Spark Connector! 🚀**
