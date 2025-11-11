<!--
---
page_type: sample
languages:
- python
products:
- fabric
- fabric-database-cosmos-db
name: |
    Management Operations
urlFragment: management
description: Learn container management operations in Cosmos DB using Microsoft Fabric with type-safe Python SDK usage, custom indexing and vector policies, throughput management, and robust data loading with retry logic.
---
-->

# Management Operations for Cosmos DB in Fabric

This sample demonstrates **container management operations** in Cosmos DB using Microsoft Fabric with **type-safe Python SDK patterns**. Learn how to programmatically create containers with custom policies, manage throughput settings, and implement robust data loading patterns with proper error handling and retry logic for production scenarios.

## 📋 What You'll Learn

- **Type-Safe Container Management** - Using proper type annotations for robust SDK interactions
- **Container Creation** - How to create containers with custom indexing and vector policies
- **Vector Index Configuration** - Setting up quantizedFlat vector indexes for multiple AI scenarios
- **Throughput Management** - Reading and updating autoscale throughput settings programmatically
- **Robust Data Loading** - Implementing retry logic with 429 rate limiting handling
- **Production Patterns** - Best practices for container management at scale with error handling

## 🏗️ Management Operations Covered

### Type-Safe Container Management

| Operation | Type Annotations | Description |
|-----------|-----------------|-------------|
| **ContainerProxy** | `ContainerProxy` type hints | Proper SDK type safety for container operations |
| **Indexing Policies** | `Dict[str, Any]` annotations | Type-safe policy configuration |
| **Vector Policies** | `Dict[str, Any]` annotations | Structured vector embedding definitions |
| **Error Handling** | Exception type checking | Robust error management patterns |

### Container Operations

| Operation | Description | Use Case |
|-----------|-------------|----------|
| **Basic Container** | Create container with indexing policies | Standard document storage workloads |
| **Vector Container** | Configure vector embeddings and indexes | AI/ML applications with semantic search |
| **Multi-Vector Support** | Support for different embedding dimensions | Multiple AI models (OpenAI, Azure OpenAI) |
| **Throughput Operations** | Read and modify autoscale settings | Scaling for changing workloads |

### Data Loading Operations

- **Bulk Data Loading** - Efficient loading of large datasets
- **Retry Logic** - Handling rate limiting (429 errors) with backoff
- **Error Handling** - Robust exception management for production scenarios

## 🗂️ Sample Data & Configuration

This notebook demonstrates creating multiple containers with different configurations:

### Container 1: Basic Sample Data

- **Container Name** - `SampleData`
- **Partition Key** - `/categoryName` for optimal distribution
- **Throughput** - Autoscale starting at 5000 RU/s
- **Data Source** - Standard product catalog without vectors

### Container 2: Vector-Enabled Data (OpenAI Ada-002)

- **Container Name** - `SampleVectorData`
- **Partition Key** - `/categoryName`
- **Vector Configuration** - 1536-dimension cosine similarity for OpenAI Ada-002
- **Throughput** - Autoscale starting at 5000 RU/s
- **Data Source** - Product data with Ada-002 embeddings

### Container 3: Vector-Enabled Data (Text-3-Large)

- **Container Name** - `SampleVectorDataText3`
- **Partition Key** - `/categoryName`
- **Vector Configuration** - 512-dimension cosine similarity for Text-3-Large
- **Throughput** - Autoscale starting at 1000 RU/s
- **Data Source** - Product data with Text-3-Large embeddings

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

3. **Install required packages**:
   - The notebook includes package installation cells
   - Run the first few cells to install dependencies

**Example configuration:**

```python
COSMOS_ENDPOINT = 'https://my-cosmos-endpoint.cosmos.fabric.microsoft.com:443/'
COSMOS_DATABASE_NAME = 'my-cosmos-artifact'
```

## 📖 Notebook Walkthrough

### Cell 1: Introduction and Overview

Markdown cell explaining the management operations and sample features with type safety focus.

### Cell 2: Package Installation

```python
%pip install azure-cosmos
```

Installs the Azure Cosmos DB Python SDK.

### Cell 3: Imports and Configuration with Type Safety

```python
from typing import List, Dict, Any, Optional
from azure.cosmos.aio import CosmosClient, ContainerProxy
from azure.cosmos import PartitionKey, ThroughputProperties
```

Sets up type-safe imports and connection variables for your Cosmos DB instance.

### Cell 4: Authentication Setup

```python
%pip install azure-core
class FabricTokenCredential(TokenCredential):
    # Custom implementation for Fabric authentication
```
Implements `FabricTokenCredential` for seamless authentication in Microsoft Fabric.

### Cell 5: Client Initialization

```python
COSMOS_CLIENT = CosmosClient(COSMOS_ENDPOINT, FabricTokenCredential())
DATABASE = COSMOS_CLIENT.get_database_client(COSMOS_DATABASE_NAME)
```
Initializes the Cosmos DB client and database connection.

### Cell 6: Data Loading Function with Retry Logic

```python
async def load_data(url: str, container: ContainerProxy):
    # Robust retry logic for 429 rate limiting
```

Shows robust data loading implementation with 429 rate limiting retry logic.

### Cell 7: Basic Container Creation
```python

async def create_container_basic(containerName: str, partitionKey: str, throughput: int):
    indexing_policy: Dict[str, Any] = {
        # Type-safe indexing policy configuration
    }
```

Creates a basic container with proper type annotations and indexing policies.

### Cell 8: Basic Container Usage

Creates and loads the `SampleData` container with standard product data.

### Cell 9: Vector Container Creation Function

```python
async def create_sample_vector_data_container(
    containerName: str, partitionKey: str, throughput: int, dimensions: int):
    vector_embedding_policy: Dict[str, Any] = {
        # Type-safe vector policy configuration
    }
```

Advanced container creation with vector embedding and indexing policies.

### Cell 10: Vector Container Usage (Ada-002)

Creates and loads the `SampleVectorData` container with 1536-dimension vectors.

### Cell 11: Vector Container Usage (Text-3-Large)

Creates and loads the `SampleVectorDataText3` container with 512-dimension vectors.

### Cell 12: Throughput Management

```python
throughput_properties = await CONTAINER.get_throughput()
autoscale_throughput = throughput_properties.auto_scale_max_throughput
new_throughput = autoscale_throughput + 1000
```
Demonstrates reading current throughput and updating autoscale settings.

## 💡 Key Concepts Demonstrated

### 1. Type-Safe Container Creation with Policies

```python
async def create_container_basic(containerName: str, partitionKey: str, throughput: int):
    indexing_policy: Dict[str, Any] = {
        "includedPaths": [{"path": "/*"}],
        "excludedPaths": [{"path": "/\"_etag\"/?"}]
    }
    
    CONTAINER = await DATABASE.create_container_if_not_exists(
        id=containerName,
        partition_key=PartitionKey(path=partitionKey, kind='Hash'),
        indexing_policy=indexing_policy,
        offer_throughput=ThroughputProperties(auto_scale_max_throughput=throughput)
    )
    return CONTAINER
```

### 2. Vector-Enabled Container with Type Safety

```python
async def create_sample_vector_data_container(
    containerName: str, partitionKey: str, throughput: int, dimensions: int):
    
    vector_embedding_policy: Dict[str, Any] = {
        "vectorEmbeddings": [{
            "path": "/vectors",
            "dataType": "float32",
            "distanceFunction": "cosine", 
            "dimensions": dimensions
        }]
    }
    
    indexing_policy: Dict[str, Any] = {
        "includedPaths": [{"path": "/*"}],
        "excludedPaths": [
            {"path": "/vectors/*"},
            {"path": "/\"_etag\"/?"}
        ],
        "vectorIndexes": [{
            "path": "/vectors",
            "type": "quantizedFlat"
        }]
    }
```

### 3. Robust Data Loading with Retry Logic

```python
async def load_data(url: str, container: ContainerProxy):
    data = requests.get(url).json()
    
    for item in data:
        retry_count = 0
        max_retries = 5
        
        while retry_count <= max_retries:
            try:
                await container.create_item(item)
                break
            except CosmosHttpResponseError as e:
                if e.status_code == 429:  # Rate limited
                    retry_after_ms = e.headers.get('x-ms-retry-after-ms', '1000')
                    retry_after_seconds = int(retry_after_ms) / 1000.0
                    await asyncio.sleep(retry_after_seconds)
                    retry_count += 1
```

### 4. Throughput Management Operations

```python
# Read current throughput
throughput_properties = await CONTAINER.get_throughput()
autoscale_throughput = throughput_properties.auto_scale_max_throughput

# Update throughput
new_throughput = autoscale_throughput + 1000
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

- Autoscale minimum is 1000 RU/s, maximum is 50,000 RU/s (you can update this with a support ticket)
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