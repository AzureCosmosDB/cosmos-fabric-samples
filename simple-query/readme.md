<!--
---
page_type: sample
languages:
- python
- nosql
products:
- fabric
name: |
  Simple Query for Cosmos DB in Microsoft Fabric
urlFragment: simple-query
description: Learn Cosmos DB query operations in Microsoft Fabric: connect, authenticate, and perform CRUD operations on product data with reviews.
---
-->

# Simple Query for Cosmos DB in Microsoft Fabric

This sample demonstrates fundamental query operations in Cosmos DB using Microsoft Fabric. You'll learn how to connect, authenticate, and perform basic CRUD operations on a product catalog dataset with customer reviews.

## 📋 What You'll Learn

- **Authentication** - How to connect to Cosmos DB in Fabric using FabricTokenCredential
- **Database & Container Setup** - Getting references to your Cosmos DB resources
- **Basic Queries** - Simple SELECT operations with WHERE clauses
- **Parameterized Queries** - Using parameters to prevent injection attacks
- **Cross-Partition Queries** - Querying across multiple partitions
- **Data Modeling** - Working with co-located entities (products and reviews)

## 🗂️ Sample Dataset

This notebook uses the **SampleData** dataset which contains:

- **Product Catalog** - Technology products with pricing, inventory, and descriptions
- **Customer Reviews** - Reviews associated with products
- **Co-located Design** - Products and reviews share the same partition key (`categoryName`)

### Sample Data Structure

```json
{
  "docType": "product",
  "productId": "77be013f-4036-4311-9b5a-dab0c3d022be",
  "categoryName": "Computers, Laptops",
  "name": "Adventure Works Laptop15",
  "description": "Adventure Works Laptop15, 4GB RAM",
  "currentPrice": 1200.99,
  "inventory": 25,
  "priceHistory": [...]
}
```

## 🚀 Getting Started

### Prerequisites

- Microsoft Fabric workspace
- Sample data loaded in your Cosmos DB container

### Step 1: Load Sample Data in Fabric

1. **Open Microsoft Fabric** - Navigate to your workspace
2. **Create Cosmos DB artifact** - Click "New" → "Cosmos DB"
3. **Load sample data**:
   - On the Cosmos DB home screen, click **"SampleData"**
   - This creates a `SampleData` container with product and review data
   - Wait for the data loading to complete

### Step 2: Download and Import the Notebook

#### Option A: Download from GitHub

1. **Download the notebook**:
   - Click on `Simple Query Samples.ipynb` in this folder
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
   - Navigate to the `simple-query` folder
   - In your Fabric workspace, click **"Import"** → **"Notebook"**
   - Select and upload the `Simple Query Samples.ipynb` file

### Step 3: Configure the Notebook

1. **Get your Cosmos DB connection URI**:
   - In your Cosmos DB artifact in Fabric, click the **Gear icon** (⚙️) in the Data Explorer
   - Click on the **"Connection"** tab
   - **Copy the URI** displayed in the connection details
   - In Cell 3 of the notebook, **replace `{your-cosmos-endpoint}`** with your copied URI

2. **Set your database name**:
   - **Replace `{your-cosmos-artifact-name}`** with the name of your Cosmos DB artifact
   - This is typically the same name you gave your Cosmos DB artifact when you created it in Fabric

3. **Verify container name**:
   - Confirm `COSMOS_CONTAINER_NAME = 'SampleData'` matches your container name
   - If you used a different name when loading sample data, update this value

4. **Install required packages**:
   - The notebook includes package installation cells
   - Run the first few cells to install dependencies

**Example configuration:**

```python
COSMOS_ENDPOINT = 'https://my-cosmos-endpoint.cosmos.fabric.microsoft.com:443/'
COSMOS_DATABASE_NAME = 'my-cosmos-artifact'
COSMOS_CONTAINER_NAME = 'SampleData'
```

## 📖 Notebook Walkthrough

### Cell 1: Introduction and Overview

Markdown cell explaining the sample's purpose and features.

### Cell 2: Package Installation

```python
%pip install azure-cosmos
```

Installs the Azure Cosmos DB Python SDK.

### Cell 3: Imports and Configuration

Sets up imports and connection variables for your Cosmos DB instance.

### Cell 4: Authentication Setup

Implements `FabricTokenCredential` for seamless authentication in Microsoft Fabric.

### Cell 5: Database and Container Connection

Establishes connection to your Cosmos DB database and container.

### Cell 6: Product Search Function

Demonstrates parameterized queries to search products by category with ordering and limiting.

### Cell 7: Execute Product Search

Runs the search function and displays results in JSON format.

### Cell 8: Product and Reviews Function

Shows how to query for a specific product and all its associated reviews.

### Cell 9: Execute Product and Reviews Query

Retrieves a product with its reviews and displays the results.

## 💡 Key Concepts Demonstrated

### 1. Fabric Authentication

```python
class FabricTokenCredential(TokenCredential):
    def get_token(self, *scopes: str, **kwargs) -> AccessToken:
        access_token = notebookutils.credentials.getToken("https://cosmos.azure.com/")
        # Token processing logic...
```

### 2. Parameterized Queries

```python
query = """
    SELECT c.name, c.currentPrice 
    FROM c 
    WHERE c.categoryName = @categoryName 
    AND c.docType = @docType
"""
parameters = [
    {"name": "@categoryName", "value": "Computers, Laptops"},
    {"name": "@docType", "value": "product"}
]
```

### 3. Async Operations

All database operations use async/await patterns for optimal performance in Fabric notebooks.

## 🔧 Troubleshooting

### Common Issues

#### Authentication Errors

- Ensure you're running the notebook in Microsoft Fabric
- Verify you have access to your Cosmos DB artifact

#### Container Not Found

- Confirm you've loaded the SampleData using the Cosmos DB Data Explorer
- Check that `COSMOS_CONTAINER_NAME = 'SampleData'` matches your container name

#### No Results Returned

- Verify sample data was loaded correctly
- Check that category names match exactly (case-sensitive)

#### Package Installation Issues

- Re-run the `%pip install azure-cosmos` cell
- Restart the kernel if packages don't load properly

## 🎯 Next Steps

After completing this sample, consider exploring:

- **Vector Search** - AI-powered similarity search
- **Management Operations** - Creating indexes and containers and changing throughput

## 📚 Additional Resources

- [Cosmos DB SQL Query Reference](https://learn.microsoft.com/nosql/query/overview?context=%2Ffabric%2Fcontext%2Fcontext-database)
- [Python SDK API Documentation](https://docs.microsoft.com/python/api/azure-cosmos/)
- [Quickstart: Cosmos DB in Fabric](https://learn.microsoft.com/fabric/database/cosmos-db/quickstart-portal)

## 🤝 Contributing

Found an issue or have suggestions? Please open an issue in the main repository or submit a pull request with improvements.
