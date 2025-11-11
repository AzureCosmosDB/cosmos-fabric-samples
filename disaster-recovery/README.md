<!--
---
page_type: sample
languages:
- scala
products:
- fabric
- fabric-database-cosmos-db
name: |
   Disaster Recovery
urlFragment: disaster-recovery
description: Business continuity and disaster recovery procedures for Cosmos DB artifacts in Microsoft Fabric using Git integration and OneLake mirroring
---
-->

# 🔄 Disaster Recovery for Cosmos DB Artifact in Fabric

Comprehensive disaster recovery procedures for Cosmos DB artifacts in Microsoft Fabric. In the event of a regional outage, this guide provides two approaches to recover or restore functionality in a secondary region.

## 📋 Overview

This sample demonstrates enterprise-grade disaster recovery strategies for Cosmos DB in Microsoft Fabric, including:

- **Git-based artifact recovery** - Restore container configurations and metadata
- **OneLake data mirroring** - Leverage automatic data replication
- **Spark-based data ingestion** - Re-ingest mirrored data to recovered artifacts
- **Multi-region redundancy** - Maintain duplicate artifacts across regions

## 🎯 Disaster Recovery Approaches

### Approach 1: Git Integration + OneLake Mirroring (Recommended)

Restore the Cosmos DB artifact and its data in a new region using Git integration for configuration and OneLake mirrored data for content.

**Recovery Time Objective (RTO):** Minutes to hours (depending on data volume)  
**Recovery Point Objective (RPO):** < 15 minutes (OneLake mirroring latency)

### Approach 2: Multi-Region Duplication (High Availability)

Maintain duplicate Cosmos DB artifacts on dedicated Fabric capacities across multiple regions with continuous synchronization.

**Recovery Time Objective (RTO):** Near-zero  
**Recovery Point Objective (RPO):** Near-zero

---

## 🚀 Approach 1: Git Integration + OneLake Mirroring

### Prerequisites

**Before a disaster occurs, you must complete these setup steps:**

- **Git integration enabled** for your Workspace and Cosmos DB artifact
- **Lakehouse created** in the primary region
- **OneLake shortcut configured** to access mirrored Cosmos DB data
- **Fabric workspace** available in a secondary region for recovery

### Architecture Flow

```text
Primary Region (Region A)              Secondary Region (Region B)
┌─────────────────────┐                ┌─────────────────────┐
│  Cosmos DB Artifact │                │  New Workspace      │
│  - Databases        │──Git Sync──────▶ Git Repository     │
│  - Containers       │                │                     │
│  - Settings         │                └─────────────────────┘
└─────────────────────┘                          │
         │                                       │ Import
         │ Mirror                                ▼
         ▼                                ┌─────────────────────┐
┌─────────────────────┐                  │  Cosmos DB Artifact │
│  OneLake (Delta)    │                  │  (Recovered)        │
│  - Mirrored Data    │──Replicated──────▶                    │
│  - RPO < 15 min     │   to Region B    │                     │
└─────────────────────┘                  └─────────────────────┘
         │                                       ▲
         │                                       │
         │                                 Spark Ingestion
         └───────────────────────────────────────┘
```

---

## 📝 Step-by-Step Recovery Guide

### Step 1: Configure Git Integration (Before Disaster)

**⚠️ This must be done BEFORE a regional outage occurs.**

Git integration automatically synchronizes your Cosmos DB artifact configuration - including databases, containers, and metadata (partition keys, indexing policies, etc.) - with your Git repository.

#### A. Enable Git Integration in Primary Region

1. Navigate to your **workspace** in the primary region (Region A)
2. From the menu bar, select **Settings**
3. In the workspace settings dialog, select **Git integration**
4. Choose your Git provider (GitHub, Azure DevOps, etc.) and authorize the connection
   - **Note:** For GitHub, ensure "Users can sync workspace items with GitHub repositories" is **Enabled** in the Admin Portal tenant settings
5. Select the appropriate **repository**, **branch**, and **folder** for your destination
6. Click **Connect and sync** to export Cosmos DB artifact metadata and settings to Git

**What gets synchronized:**
- Database names and configurations
- Container names and settings
- Partition key definitions
- Indexing policies
- Throughput configurations (if applicable)

#### B. Recover Cosmos DB Artifact from Git (After Disaster)

Once a regional outage occurs and you need to recover in Region B:

1. Create or navigate to a **new workspace** in the recovery region (Region B)
2. In the new workspace, connect to your Git or Azure DevOps repository
3. Select the **Source control** button
4. Choose the relevant **branch** that contains your Cosmos DB artifact configuration
5. Select **Update all**
6. The original Cosmos DB artifact and containers with their settings are recreated in the new workspace

**Important:** The import process automatically generates:
- New **Cosmos Account Endpoints** for the recovered artifact
- New **SQL Analytics Endpoints**

You'll need to update any applications or connection strings to use these new endpoints.

---

### Step 2: Configure OneLake Mirroring (Before Disaster)

**⚠️ This must be done BEFORE a regional outage occurs.**

Cosmos DB data is automatically mirrored into OneLake in the primary region with an RPO of less than 15 minutes (depending on data volume and replication load). OneLake data is automatically replicated to the backup region.

#### A. Create Lakehouse Shortcut for Mirrored Data

1. In the Fabric portal, select **Create** → **Data Engineering** → **Lakehouse**
2. Provide a name for the Lakehouse (e.g., `CosmosBackupLakehouse`)
3. Select **Create**
4. Once created, select **Get Data** → **New shortcut**
5. From the list of shortcut options, select **Microsoft OneLake**
6. Configure the path to the mirrored data

**OneLake Endpoint Pattern:**

```text
abfss://<workspaceName>@onelake.dfs.fabric.microsoft.com/<lakehouseName>.Lakehouse/Tables/<tableName>
```

---

### Step 3: Re-ingest Data Using Spark (After Disaster)

After recovering the Cosmos DB artifact configuration via Git, you need to restore the actual data from OneLake mirrored storage.

#### A. Create Spark Environment

1. In the new workspace in Region B, select **+New item** → **Environment**
2. Create a new **Spark environment**
3. Download and add the following Cosmos DB Spark libraries under **Custom** → **Upload**:
   - **Maven:** `com.azure.cosmos.spark:azure-cosmos-spark_3-5_2-12:4.41.0`
   - **Maven:** `com.azure.cosmos.spark:fabric-cosmos-spark-auth_3:1.0.0`

#### B. Run Data Ingestion Notebook

Use the provided Spark notebook (`disaster-recovery.ipynb`) to read mirrored data from OneLake and ingest it into the new Cosmos DB artifact.

**Configuration Required:**

```scala
// Workspace name in the disaster region (where OneLake data is mirrored)
val disasterRegionWorkspaceName = "<DISASTER_REGION_WORKSPACE_NAME>"

// Lakehouse name in the disaster region (contains shortcuts to mirrored data)
val disasterRegionLakehouseName = "<DISASTER_REGION_LAKEHOUSE_NAME>"

// Cosmos DB AccountEndpoint in the recovery region
val recoveryRegionCosmosAccountEndpoint = "<RECOVERY_REGION_COSMOS_ACCOUNT_ENDPOINT>"

// Cosmos DB Database name in the recovery region
val recoveryRegionCosmosDatabase = "<RECOVERY_REGION_COSMOS_DATABASE>"

// List of container names to recover
val containerNamesToRecover = Seq("<CONTAINER_NAME_1>", "<CONTAINER_NAME_2>", "<CONTAINER_NAME_3>")
```

The notebook will:
1. Read mirrored data from OneLake Delta tables
2. Connect to the recovered Cosmos DB artifact in Region B
3. Ingest data using `ItemOverwrite` strategy to handle duplicates
4. Process multiple containers in sequence

---

## ⚠️ Limitations of Approach 1

### 1. Schema Drift Handling

If the data type of a property changes across items, mirroring into OneLake may:
- **Upcast data** where possible (e.g., int → long)
- **Store null values** for incompatible types

This behavior aligns with native Delta Lake semantics and may cause data loss or type mismatches in recovery scenarios.

**Mitigation:** Review your schema before recovery and validate data types after ingestion.

### 2. Hierarchical Data (Arrays and Objects)

During mirroring, hierarchical data types (arrays, nested objects) are **serialized as JSON strings**.

When restoring data, you may need to deserialize these strings back into structured data if your application requires it.

**Example Deserialization in Scala:**

```scala
import org.apache.spark.sql.functions._

// Deserialize JSON string back to structured object
val dfParsed = df.withColumn(
  "nestedField", 
  from_json(col("nestedField"), schema_of_json(lit("""{"key":"value"}""")))
)
```

**Best Practice:** Review the schema of your original Cosmos DB container and apply appropriate transformations during the ingestion process.

---

## 🌍 Approach 2: Multi-Region Duplication

A proactive disaster recovery option is to maintain duplicate Cosmos DB artifacts on dedicated Fabric capacities across two or more regions.

### Architecture

```text
Region A (Primary)              Region B (Secondary)
┌─────────────────────┐        ┌─────────────────────┐
│  Cosmos DB Artifact │        │  Cosmos DB Artifact │
│  - Active Workload  │◄──────▶│  - Active Workload  │
│  - Git Sync         │        │  - Git Sync         │
│  - Data Sync        │        │  - Data Sync        │
└─────────────────────┘        └─────────────────────┘
         │                              │
         └──────────Git Repository──────┘
```

### Configuration Steps

1. **Deploy separate Cosmos DB artifacts** in dedicated Fabric capacities in two or more regions
2. **Use Git integration** to replicate any changes to artifact configuration, schema, and container settings
3. **Establish access controls** and permissions in each region to maintain security compliance
4. **Ensure identical data plane operations** are performed in both artifacts simultaneously to maintain consistency

### Advantages

- ✅ **High availability** across multiple regions
- ✅ **Near-zero RTO** - Data and artifacts are already active in each region
- ✅ **No data ingestion delay** - Continuous synchronization

### Considerations

- ⚠️ **Higher operational complexity** - Managing multiple artifacts and synchronization
- ⚠️ **Increased cost** - Duplication of resources across regions
- ⚠️ **Data consistency** - Must validate synchronization regularly to ensure failover readiness
- ⚠️ **Application changes** - Applications must support writing to multiple regions simultaneously

---

## 📁 Sample Files

| File | Description |
|------|-------------|
| `disaster-recovery.ipynb` | Scala Spark notebook for reading OneLake mirrored data and ingesting into recovered Cosmos DB artifact |
| `README.md` | This disaster recovery guide |

---

## 🛠️ Prerequisites

### Required for Approach 1

- **Microsoft Fabric workspace** in primary and secondary regions
- **Git repository** (GitHub, Azure DevOps, etc.)
- **Lakehouse** with shortcuts to OneLake mirrored data
- **Spark environment** with Cosmos DB Spark connector libraries
- **Cosmos DB artifact** in primary region with mirroring enabled

### Required for Approach 2

- **Multiple Fabric capacities** across different regions
- **Git repository** for configuration synchronization
- **Application support** for multi-region writes
- **Monitoring and validation** processes for data consistency

---

## 🚨 Best Practices

### Before a Disaster

- ✅ **Test your recovery process** regularly (quarterly recommended)
- ✅ **Document all endpoint URLs** and configuration settings
- ✅ **Verify Git sync** is working correctly
- ✅ **Monitor OneLake mirroring lag** to understand your actual RPO
- ✅ **Create runbooks** with step-by-step recovery instructions
- ✅ **Assign roles and responsibilities** for disaster recovery team

### During Recovery

- ⚠️ **Verify data completeness** after ingestion
- ⚠️ **Check for schema drift** and handle appropriately
- ⚠️ **Validate endpoint URLs** before updating applications
- ⚠️ **Test read/write operations** before full cutover
- ⚠️ **Monitor ingestion progress** for large containers

### After Recovery

- 📊 **Conduct post-mortem analysis** to improve procedures
- 📊 **Update documentation** based on lessons learned
- 📊 **Re-establish mirroring** in the new region if staying there long-term
- 📊 **Plan for eventual failback** to primary region when available

---

## 🆘 Troubleshooting

### Git Sync Issues

**Problem:** Artifact not appearing after Git import

**Solutions:**
- Verify you selected the correct branch
- Check that Git integration permissions are configured
- Ensure the workspace has sufficient capacity
- Review Git repository for committed artifact files

### OneLake Data Access

**Problem:** Cannot read data from OneLake shortcut

**Solutions:**
- Verify the shortcut path is correct
- Check workspace permissions for cross-workspace access
- Ensure OneLake replication to Region B has completed
- Validate the lakehouse name and table name match exactly

### Spark Ingestion Failures

**Problem:** Data ingestion fails with authentication errors

**Solutions:**
- Verify Cosmos DB Spark connector libraries are installed
- Check that the Cosmos DB endpoint URL is correct
- Ensure workspace identity has permissions to write to Cosmos DB
- Validate the database and container names exist

### Schema Mismatch

**Problem:** Data types don't match after recovery

**Solutions:**
- Review the original container schema
- Apply type casting or deserialization as needed
- Use the Spark schema inference to detect issues
- Consider manual schema mapping for complex types

---

## 📚 Additional Resources

- [Cosmos DB in Fabric Documentation](https://docs.microsoft.com/fabric/database/cosmos-db/overview)
- [Git Integration in Fabric](https://docs.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration)
- [OneLake Shortcuts](https://docs.microsoft.com/fabric/onelake/onelake-shortcuts)
- [Cosmos DB Spark Connector](https://github.com/Azure/azure-sdk-for-java/tree/main/sdk/cosmos/azure-cosmos-spark_3-5_2-12)
- [Disaster Recovery Planning](https://docs.microsoft.com/azure/reliability/reliability-guidance-overview)

---

## 🤝 Contributing

This disaster recovery guide is part of the Cosmos DB in Fabric samples repository. For questions, issues, or improvements, please refer to the main repository documentation.

---

*This guide demonstrates enterprise disaster recovery patterns for Cosmos DB in Microsoft Fabric, ensuring business continuity through Git-based configuration management and OneLake data replication.*
