<!--
---
page_type: sample
languages:
- python
products:
- fabric
name: |
  Python CRUD Fundamentals for Cosmos DB in Microsoft Fabric
urlFragment: python-crud-fundamentals
description: Learn fundamental CRUD operations on Cosmos DB in Fabric artifacts. Explore how to connect, authenticate, and perform essential tasks such as querying, point reads, container management, and document insertion.
---
-->

# Python CRUD Fundamentals for Cosmos DB in Microsoft Fabric
This sample demonstrates fundamental CRUD (Create, Read, Update, Delete) operations in Cosmos DB using Microsoft Fabric. You'll learn how to connect, authenticate, and perform essential database operations including querying, point reads, container management, and document insertion.

## 📋 What You'll Learn
- **Authentication** - How to connect to Cosmos DB in Fabric using FabricTokenCredential
- **Database & Container Setup** - Getting references to your Cosmos DB resources
- **Querying Data** - Parameterized queries with partition key optimization
- **Point Reads** - High-performance document retrieval by ID and partition key
- **Container Management** - Configure autoscale throughput settings
- **Document Operations** - Insert documents with different schemas and structures

## 🗂️ Sample Dataset
This notebook uses the **SampleData** dataset which contains:

- **Product Catalog** - Technology products with pricing, inventory, and descriptions
- **Customer Reviews** - Reviews associated with products  
- **Co-located Design** - Products and reviews share the same partition key (`categoryName`)

The notebook also demonstrates creating new data by:
- **Customer Orders** - New order documents created during the tutorial with shipping and payment details

### Sample Data Structure
```json
{
  "docType": "product",
  "productId": "cb919d62-80e4-4234-9403-b1f272e0c020",
  "categoryName": "Devices, Tablets",
  "name": "Adventure Works Tablet Pro",
  "description": "High-performance tablet with advanced features",
  "currentPrice": 599.99,
  "inventory": 15,
  "countryOfOrigin": "United States",
  "firstAvailable": "2024-01-15"
}
```

## 🚀 Getting Started

### Prerequisites
- Microsoft Fabric workspace
- Sample data loaded in your Cosmos DB container

### Step 1: Load Sample Data in Fabric
1. **Open Microsoft Fabric** - Navigate to your workspace
2. **Create Cosmos DB artifact** - Click "New" → "Cosmos DB"  
3. **Load sample data:**
   - On the Cosmos DB home screen, click "SampleData"
   - This creates a SampleData container with product and review data
   - Wait for the data loading to complete

### Step 2: Download and Import the Notebook

#### Option A: Download from GitHub
1. **Download the notebook:**
   - Click on `python-crud-fundamentals.ipynb` in this folder
   - Click the "Download" button or "Raw" and save the file
2. **Import into Fabric:**
   - In your Fabric workspace, click "Import" → "Notebook"
   - Select the downloaded .ipynb file and upload

#### Option B: Clone the Repository
1. Clone this repository to your local machine:
```bash
git clone https://github.com/azurecosmosdb/cosmos-fabric-samples.git
```
2. **Import the notebook:**
   - Navigate to the `python-crud-fundamentals` folder
   - In your Fabric workspace, click "Import" → "Notebook"  
   - Select and upload the `python-crud-fundamentals.ipynb` file

### Step 3: Configure the Notebook
1. **Get your Cosmos DB connection URI:**
   - In your Cosmos DB artifact in Fabric, click the Gear icon (⚙️) in the Data Explorer
   - Click on the "Connection" tab
   - Copy the URI displayed in the connection details

2. **Set your Cosmos DB endpoint URI:**
   - In Cell 4 of the notebook, set `COSMOS_ENDPOINT` your copied URI

3. **Set your database name:**
   - In Cell 4 of the notebook, set `COSMOS_DATABASE_NAME` to the name of your Cosmos DB artifact
   - This is the same name you gave your Cosmos DB artifact when you created it in Fabric

4. **Verify container name:**
   - Confirm `COSMOS_CONTAINER_NAME = 'SampleData'` matches your container name
   - If you used a different name when loading sample data, update this value

5. **Install required packages:**
   - The notebook includes package installation cells
   - Run the first few cells to install dependencies

**Example configuration:**
```python
COSMOS_ENDPOINT = 'https://my-cosmos-endpoint.cosmos.fabric.microsoft.com:443/'
COSMOS_DATABASE_NAME = 'my-cosmos-artifact'
COSMOS_CONTAINER_NAME = 'SampleData'
```

## 📖 Notebook Walkthrough

**Cell 1: Introduction and Overview**  
Markdown cell explaining the sample's purpose and CRUD operations covered.

**Cell 2: Package Installation**  
```python
%pip install azure-cosmos
%pip install azure-core
```
Installs the Azure Cosmos DB Python SDK and core dependencies.

**Cell 3: Imports and Configuration**  
Sets up imports and connection variables for your Cosmos DB instance.

**Cell 4: Authentication Setup**  
Implements `FabricTokenCredential` for seamless authentication in Microsoft Fabric.

**Cell 5: Database and Container Connection**  
Establishes connection to your Cosmos DB database and container clients.

**Cell 6: Query Operations (READ)**  
Demonstrates parameterized queries to search products by category with result processing.

**Cell 7: Point Read Operations (READ)**  
Shows high-performance document retrieval using ID and partition key.

**Cell 8: Container Creation (CREATE)**  
Creates a new container with custom partition key and autoscale throughput.

**Cell 9: Document Insertion (CREATE)**  
Inserts customer order documents with complex nested structures.

**Cell 10: Document Retrieval (READ)**  
Retrieves the newly created order document using point read.

**Cell 11: Throughput Management (UPDATE)**  
Updates container autoscale throughput settings for performance optimization.

## 🔑 Key Concepts Demonstrated

### 1. Fabric Authentication
```python
class FabricTokenCredential(TokenCredential):
    def get_token(self, *scopes: str, **kwargs) -> AccessToken:
        access_token = notebookutils.credentials.getToken("https://cosmos.azure.com/.default")
        # Token processing and JWT parsing logic...
```

### 2. Parameterized Queries
```python
queryText = "SELECT * FROM c WHERE c.categoryName = @categoryName"
results = CONTAINER_CLIENT.query_items(
    query=queryText,
    parameters=[{"name": "@categoryName", "value": "Devices, Tablets"}],
    enable_cross_partition_query=False
)
```

### 3. Point Reads for Optimal Performance
```python
# Most efficient single document access
item = CONTAINER_CLIENT.read_item(
    item=item_id, 
    partition_key=partition_key
)
```

### 4. Container Management
```python
# Create container with autoscale throughput
CONTAINER_CLIENT = DATABASE_CLIENT.create_container(
    id="SampleOrders",
    partition_key=PartitionKey(path="/customerId"),
    offer_throughput=ThroughputProperties(auto_scale_max_throughput=5000)
)
```

## 🔧 Troubleshooting

### Common Issues

**Authentication Errors**
- Ensure you're running the notebook in Microsoft Fabric
- Verify you have access to your Cosmos DB artifact

**Container Not Found**
- Confirm you've loaded the SampleData using the Cosmos DB Data Explorer
- Check that `COSMOS_CONTAINER_NAME = 'SampleData'` matches your container name

**No Results Returned**
- Verify sample data was loaded correctly
- Check that category names match exactly (case-sensitive)

**Package Installation Issues**
- Re-run the `%pip install azure-cosmos` cell  
- Restart the kernel if packages don't load properly

**Throughput Limit Errors**
- Default autoscale max is 5000 RU/s
- SDK supports up to 50,000 RU/s
- For higher limits, open a support ticket

## 🎯 Next Steps

After completing this sample, consider exploring:

- **Vector Search** - AI-powered similarity search capabilities

## 📚 Additional Resources

- [Cosmos DB SQL Query Reference](https://docs.microsoft.com/azure/cosmos-db/sql/sql-query-getting-started)
- [Python SDK API Documentation](https://docs.microsoft.com/python/api/azure-cosmos/azure.cosmos)
- [Quickstart: Cosmos DB in Fabric](https://learn.microsoft.com/fabric/database/cosmos-db/overview)
- [Partitioning and Performance Best Practices](https://docs.microsoft.com/azure/cosmos-db/partitioning-overview)

## 🤝 Contributing

Found an issue or have suggestions? Please open an issue in the main repository or submit a pull request with improvements.
