<!--
---
page_type: sample
languages:
- python
- nosql
products:
- fabric
name: |
  Management Operations for Cosmos DB in Microsoft Fabric
urlFragment: management
description: Learn container management operations in Cosmos DB using Microsoft Fabric: create containers with indexing/vector policies, manage throughput, and implement reliable data loading with retry logic.
---
-->

# Management Operations for Cosmos DB in Fabric

This sample demonstrates **container management operations** in Cosmos DB using Microsoft Fabric. Learn how to programmatically create containers with custom policies, manage throughput settings, and implement robust data loading patterns with retry logic for production scenarios.

## 📋 What You'll Learn

- **Container Creation** - How to create containers with custom indexing and vector policies
- **Vector Index Configuration** - Setting up quantizedFlat vector indexes for AI scenarios
- **Throughput Management** - Reading and updating autoscale throughput settings
- **Robust Data Loading** - Implementing retry logic with 429 rate limiting handling
- **Production Patterns** - Best practices for container management at scale

## 🏗️ Management Operations Covered

### Container Management

| Operation | Description | Use Case |
|-----------|-------------|----------|
| **Create Container** | Create container with policies and throughput | Initial setup for new workloads |
| **Vector Policies** | Configure vector embeddings and indexes | AI/ML applications with semantic search |
| **Indexing Policies** | Define included/excluded paths | Performance optimization |
| **Throughput Operations** | Read and modify autoscale settings | Scaling for changing workloads |

### Data Loading Operations

- **Bulk Data Loading** - Efficient loading of large datasets
- **Retry Logic** - Handling rate limiting (429 errors) with backoff
- **Error Handling** - Robust exception management for production scenarios

## 🗂️ Sample Data & Configuration

This notebook creates a new container and loads vector-enabled product data:

- **Container Name** - `samplecontainer` (configurable)
- **Partition Key** - `/categoryName` for optimal distribution
- **Vector Configuration** - 1536-dimension cosine similarity for OpenAI Ada-002
- **Indexing Policy** - Optimized for queries with vector exclusions
- **Throughput** - Autoscale starting at 5000 RU/s

### Container Configuration Structure

```python
# Vector embedding policy
vector_embedding_policy = {
    "vectorEmbeddings": [
        {
            "path": "/vectors",
            "dataType": "float32", 
            "distanceFunction": "cosine",
            "dimensions": 1536
        }
    ]
}

# Indexing policy with vector optimization
indexing_policy = {
    "includedPaths": [{"path": "/*"}],
    "excludedPaths": [
        {"path": "/vectors/*"},
        {"path": "/\"_etag\"/?"}
    ],
    "vectorIndexes": [
        {
            "path": "/vectors",
            "type": "quantizedFlat"
        }
    ]
}
```

## 🚀 Getting Started

### Prerequisites

- Microsoft Fabric workspace
- Empty Cosmos DB artifact (no pre-existing containers required)

### Step 1: Create Empty Cosmos DB Artifact

1. **Open Microsoft Fabric** - Navigate to your workspace
2. **Create Cosmos DB artifact** - Click "New" → "Cosmos DB"
3. **Leave empty** - Don't load any sample data (the notebook will create its own container)
4. **Note the artifact name** - You'll need this for configuration

### Step 2: Download and Import the Notebook

#### Option A: Download from GitHub

1. **Download the notebook**:
   - Click on `management.ipynb` in this folder
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
   - Navigate to the `management` folder
   - In your Fabric workspace, click **"Import"** → **"Notebook"**
   - Select and upload the `management.ipynb` file

### Step 3: Configure the Notebook

1. **Get your Cosmos DB connection URI**:
   - In your Cosmos DB artifact in Fabric, click the **Gear icon** (⚙️) in the Data Explorer
   - Click on the **"Connection"** tab
   - **Copy the URI** displayed in the connection details
   - In Cell 3 of the notebook, **replace the existing URI** with your copied URI

2. **Set your database name**:
   - **Update `COSMOS_DATABASE_NAME`** to match your Cosmos DB artifact name
   - This is typically the same name you gave your Cosmos DB artifact when you created it

3. **Verify container name** (optional):
   - The default `COSMOS_CONTAINER_NAME = 'samplecontainer'` will work for most cases
   - Change if you prefer a different container name

4. **Install required packages**:
   - The notebook includes package installation cells
   - Run the first few cells to install dependencies

**Example configuration:**

```python
COSMOS_ENDPOINT = 'https://my-cosmos-endpoint.cosmos.fabric.microsoft.com:443/'
COSMOS_DATABASE_NAME = 'my-cosmos-artifact'
COSMOS_CONTAINER_NAME = 'samplecontainer'
```

## 📖 Notebook Walkthrough

### Cell 1: Introduction and Overview

Markdown cell explaining the management operations and sample features.

### Cell 2: Package Installation

```python
%pip install azure-cosmos
```

Installs the Azure Cosmos DB Python SDK.

### Cell 3: Imports and Configuration

Sets up imports and connection variables for your Cosmos DB instance.

### Cell 4: Authentication Setup

Implements `FabricTokenCredential` for seamless authentication in Microsoft Fabric.

### Cell 5: Imports for Management Operations

Additional imports required for container management and data loading operations.

### Cell 6: Container Creation Function

Demonstrates creating a container with vector and indexing policies, plus autoscale throughput.

### Cell 7: Data Loading with Retry Logic

Shows robust data loading implementation with 429 rate limiting retry logic.

### Cell 8: Throughput Management

Demonstrates reading current throughput and updating autoscale settings.

## 💡 Key Concepts Demonstrated

### 1. Container Creation with Policies

```python
CONTAINER = await DATABASE.create_container_if_not_exists(
    id=COSMOS_CONTAINER_NAME,
    partition_key=PartitionKey(path='/categoryName', kind='Hash'),
    indexing_policy=indexing_policy,
    vector_embedding_policy=vector_embedding_policy,
    offer_throughput=ThroughputProperties(auto_scale_max_throughput=5000)
)
```

### 2. Retry Logic for Rate Limiting

```python
except CosmosHttpResponseError as e:
    if e.status_code == 429:  # Rate limited
        retry_after_ms = e.headers.get('x-ms-retry-after-ms', '1000')
        retry_after_seconds = int(retry_after_ms) / 1000.0
        await asyncio.sleep(retry_after_seconds)
```

### 3. Throughput Management

```python
# Read current throughput
throughput_properties = await CONTAINER.get_throughput()
current_aru = throughput_properties.auto_scale_max_throughput

# Update throughput
await CONTAINER.replace_throughput(
    ThroughputProperties(auto_scale_max_throughput=new_throughput)
)
```

## 🔧 Troubleshooting

### Common Issues

**Container Creation Errors**
- Ensure your Cosmos DB artifact exists and is accessible
- Verify you have write permissions to the database
- Check that container names follow Cosmos DB naming conventions

**Data Loading Issues**
- The retry logic handles 429 errors automatically
- Large datasets may take time to load - this is normal
- Monitor the console output for progress updates

**Throughput Update Errors**
- Autoscale minimum is 1000 RU/s, maximum is 1,000,000 RU/s
- Throughput updates may take a few minutes to take effect
- Ensure you have permissions to modify container settings

**Vector Policy Errors**
- Vector dimensions must match your embedding model (1536 for Ada-002)
- Ensure vector paths are consistent with your data structure
- QuantizedFlat is the recommended vector index type for most scenarios

## 🎯 Production Best Practices

### Container Design
- **Plan partition keys** carefully for even distribution
- **Use autoscale throughput** for variable workloads  
- **Exclude vector paths** from general indexing for performance
- **Test vector policies** with sample data before production

### Data Loading
- **Implement retry logic** for 429 rate limiting scenarios
- **Use batch operations** for large datasets when possible
- **Monitor throughput consumption** during bulk operations
- **Handle partial failures** gracefully with proper logging

### Throughput Management
- **Start conservative** and scale up based on usage patterns
- **Monitor RU consumption** to optimize throughput settings
- **Use autoscale** for unpredictable traffic patterns
- **Consider regional distribution** for global applications

## 🔄 Next Steps

After completing this sample, explore:

- **Advanced Indexing** - Custom composite and spatial indexes
- **Global Distribution** - Multi-region container configuration
- **Conflict Resolution** - Custom conflict resolution policies
- **Change Feed** - Real-time data processing patterns
- **Backup and Restore** - Point-in-time recovery operations

## 📚 Additional Resources

- [Cosmos DB Container Management](https://docs.microsoft.com/azure/cosmos-db/manage-with-sdk)
- [Vector Search Configuration](https://docs.microsoft.com/azure/cosmos-db/vector-search)
- [Indexing Policies](https://docs.microsoft.com/azure/cosmos-db/index-policy)
- [Throughput Management](https://docs.microsoft.com/azure/cosmos-db/set-throughput)
- [Error Handling Best Practices](https://docs.microsoft.com/azure/cosmos-db/troubleshoot-sdk)

## 🤝 Contributing

Found an issue or have suggestions for improving this management operations sample? Please open an issue in the main repository or submit a pull request with enhancements.