<!--
---
page_type: sample
languages:
- python
products:
- fabric
- fabric-database-cosmos-db
name: | 
   Vector Search
urlFragment: vector-search
description: Learn AI-powered vector search in Cosmos DB using Microsoft Fabric's built-in OpenAI text embedding models for semantic similarity searches.
---
-->

# Vector Search for Cosmos DB in Fabric

This sample demonstrates **AI-powered vector search** capabilities in Cosmos DB using Microsoft Fabric's built-in OpenAI text embedding models. Learn how to perform semantic similarity searches on product catalogs using natural language queries.

## 🎯 What You'll Learn

- **Vector Search Fundamentals** - Understanding semantic similarity vs exact text matching
- **Fabric OpenAI Integration** - Using built-in text-embedding-ada-002 model
- **VectorDistance Function** - Cosmos DB's native vector search capabilities
- **Similarity Scoring** - Filtering and ranking results by relevance
- **Production Patterns** - Best practices for vector search in real applications

## 🧠 AI-Powered Search Concepts

### Traditional vs Vector Search

| Traditional Search | Vector Search |
|-------------------|---------------|
| Exact keyword matching | Semantic understanding |
| "gaming computer" finds only exact matches | "gaming pc" finds gaming computers, laptops, accessories |
| Limited by exact terminology | Understands intent and context |
| Boolean logic | Similarity scoring |

### How It Works

1. **Text → Embeddings** - Convert search queries into high-dimensional vectors
2. **Similarity Calculation** - Compare query vector with stored product vectors
3. **Relevance Ranking** - Return results ordered by semantic similarity
4. **Threshold Filtering** - Only return results above specified similarity score

## 🗂️ Sample Dataset

This notebook uses the **SampleVectorData** dataset which contains:

- **Product Catalog** - Technology products with detailed descriptions
- **Vector Embeddings** - Pre-computed vectors using text-embedding-ada-002
- **Rich Metadata** - Pricing, inventory, categories, and specifications

### Sample Data Structure

```json
{
  "docType": "product",
  "productId": "12345-abc-67890",
  "categoryName": "Computers, Gaming",
  "name": "Gaming Desktop Pro",
  "description": "High-performance gaming computer with RTX graphics",
  "currentPrice": 1299.99,
  "inventory": 15,
  "vectors": [0.0123, -0.0456, 0.0789, ...] // 1536 dimensions
}
```

## 🚀 Getting Started

### Prerequisites

- Microsoft Fabric workspace
- SampleVectorData container loaded in your Cosmos DB artifact

### Step 1: Load Sample Vector Data in Fabric

1. **Open Microsoft Fabric** - Navigate to your workspace
2. **Create Cosmos DB artifact** - Click "New" → "Cosmos DB"
3. **Load vector sample data**:
   - On the Cosmos DB home screen, click **"SampleVectorData"**
   - This creates a `SampleVectorData` container with products and pre-computed vectors
   - Wait for the data loading to complete

### Step 2: Download and Import the Notebook

#### Option A: Download from GitHub

1. **Download the notebook**:
   - Click on `vector-search.ipynb` in this folder
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
   - Navigate to the `vector-search` folder
   - In your Fabric workspace, click **"Import"** → **"Notebook"**
   - Select and upload the `vector-search.ipynb` file

### Step 3: Configure the Notebook

1. **Get your Cosmos DB connection URI**:
   - In your Cosmos DB artifact in Fabric, click the **Gear icon** (⚙️) in the Data Explorer
   - Click on the **"Connection"** tab
   - **Copy the URI** displayed in the connection details
   - In Cell 3 of the notebook, **replace the existing URI** with your copied URI

2. **Set your database name**:
   - **Update `COSMOS_DATABASE_NAME`** to match your Cosmos DB artifact name
   - This is typically the same name you gave your Cosmos DB artifact when you created it

3. **Verify container name**:
   - Confirm `COSMOS_CONTAINER_NAME = 'SampleVectorData'` matches your container name

4. **Install required packages**:
   - The notebook includes package installation cells
   - Run the first few cells to install dependencies

**Example configuration:**

```python
COSMOS_ENDPOINT = 'https://my-cosmos-endpoint.cosmos.fabric.microsoft.com:443/'
COSMOS_DATABASE_NAME = 'my-cosmos-artifact'
COSMOS_CONTAINER_NAME = 'SampleVectorData'
```

## 📖 Notebook Walkthrough

### Cell 1: Introduction and Overview

Markdown cell explaining vector search concepts and sample features.

### Cell 2: Package Installation

```python
%pip install azure-cosmos
%pip install openai
```

Installs required Azure Cosmos DB and OpenAI Python SDKs.

### Cell 3: Imports and Configuration

Sets up imports and connection variables for your Cosmos DB instance and OpenAI integration.

### Cell 4: Authentication Setup

Implements `FabricTokenCredential` for seamless authentication in Microsoft Fabric.

### Cell 5: Database and Container Connection

Establishes connection to your Cosmos DB database and container.

### Cell 6: Embedding Generation Function

Demonstrates how to generate vector embeddings using Fabric's built-in OpenAI model.

### Cell 7: Vector Search Function

Core function showing VectorDistance query with similarity filtering and ranking.

### Cell 8: Execute Vector Search

Runs semantic search with configurable parameters and displays results.

## 💡 Key Concepts Demonstrated

### 1. Fabric OpenAI Integration

```python
def generate_embeddings(text):
    response = openai.embeddings.create(
        input=text,
        model="text-embedding-ada-002"
    )
    return response.data[0].embedding
```

### 2. VectorDistance Query

```sql
SELECT TOP @limit 
    VectorDistance(c.vectors, @embeddings) AS SimilarityScore,
    c.name, c.description, c.categoryName
FROM c 
WHERE 
    c.docType = @docType AND
    VectorDistance(c.vectors, @embeddings) >= @similarity
ORDER BY 
    VectorDistance(c.vectors, @embeddings)
```

### 3. Similarity Threshold Filtering

- **0.9+** - Extremely similar (nearly identical)
- **0.8+** - Very similar (recommended starting point)
- **0.7+** - Moderately similar 
- **0.6+** - Somewhat similar (may include noise)

## 🔧 Troubleshooting

### Common Issues

#### No Results Returned

- Lower the similarity threshold (try 0.7 instead of 0.8)
- Verify SampleVectorData was loaded correctly
- Check that search text is descriptive enough

#### OpenAI API Errors

- Ensure you're running in Microsoft Fabric (uses built-in OpenAI)
- Verify the embedding model name is correct
- Check network connectivity in Fabric environment

#### Vector Query Errors

- Confirm your container has documents with `vectors` property
- Verify vector dimensions match (should be 1536 for Ada-002)

## 🎯 Experiment and Learn

### Try Different Search Queries

```python
# Technology focused
products = await search_products("gaming laptop", similarity=0.8, limit=5)

# Feature focused  
products = await search_products("high performance graphics", similarity=0.80, limit=10)

# Use case focused
products = await search_products("work from home setup", similarity=0.7, limit=10)
```

### Adjust Parameters

- **similarity**: Try values between 0.6 and 0.9 to see quality vs quantity trade-offs
- **limit**: Experiment with different result set sizes
- **search_text**: Test various natural language queries

## 🔄 Next Steps

After completing this sample, explore:

- **Advanced Vector Search** - Enterprise-grade vector search with Azure OpenAI deployment and Key Vault
- **Management Operations** - Container management and production patterns

## 📚 Additional Resources

- [What is a Vector database](https://learn.microsoft.com/azure/cosmos-db/vector-database)
- [Why use Cosmos DB for your AI apps?](https://docs.microsoft.com/azure/cosmos-db/gen-ai/why-cosmos-ai)
- [Azure OpenAI Embeddings Guide](https://docs.microsoft.com/azure/cognitive-services/openai/how-to/embeddings)
- [Index vector data using Cosmos DB in Fabric](https://docs.microsoft.com/fabric/database/cosmos-db/index-vector-data)
- [Hybrid search in Cosmos DB in Fabric](https://docs.microsoft.com/fabric/database/cosmos-db/hybrid-search)

## 🤝 Contributing

Found an issue or have suggestions for improving this vector search sample? Please open an issue in the main repository or submit a pull request with enhancements.
