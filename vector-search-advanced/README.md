<!--
---
page_type: sample
languages:
- python
products:
- fabric
name: "Advanced Vector Search"
description: "Enterprise-grade vector search with Azure OpenAI deployment, Key Vault integration, and custom embedding models for Cosmos DB in Fabric"
urlFragment: "vector-search-advanced"
---
-->

# 🚀 Advanced Vector Search

**Enterprise-grade vector search implementation with Azure OpenAI deployment and Azure Key Vault integration**

This advanced sample demonstrates how to build a production-ready vector search solution using Cosmos DB in Fabric with custom Azure OpenAI deployments, secure secret management through Azure Key Vault, and optimized embedding strategies.

## 🎯 What You'll Learn

This sample covers advanced concepts for building enterprise vector search solutions:

### 🔐 **Security & Authentication**

- **Azure Key Vault integration** for secure secret management
- **Workspace Identity authentication** with Azure RBAC policies
- **Azure OpenAI authentication** using managed secrets

### 🤖 **AI & Vector search**

- **Custom Azure OpenAI deployment** with text-embedding-3-large and gpt-4.1-mini models
- **Optimized embedding dimensions** demonstrates using custom dimensions sizes for performance

### ⚡ **Performance & Optimization**

- **Reduced embedding dimensions** for faster queries and lower storage
- **Container configuration** with vector indexing policies
- **Query optimization** techniques for vector search
- **Error handling** and retry patterns

### 🏗️ **Infrastructure & Deployment**

- **AZD resource provisioning** (Azure OpenAI + Azure Key Vault)
- **RBAC policy configuration** for service-to-service permissions

## 📋 Prerequisites

⚠️ **Important**: This is an advanced sample requiring significant Azure permissions

### **Required Permissions**

- **Azure Subscription Owner** rights (for resource deployment and Role Assignments)
- **Microsoft Fabric workspace** with admin access
- **Workspace Identity** configured for your Fabric workspace

### **Technical Requirements**

- Python 3.11+ with Jupyter notebook support
- Azure CLI (for initial setup)
- Azure Developer CLI (AZD for deployment)
- Git (for cloning the deployment repository)

### **Azure Services**

This sample automatically provisions:

- Azure OpenAI Service with text-embedding-3-large and gpt-4.1-mini models
- Azure Key Vault
- Role Assignments using User identity and Fabric Workspace Identity

## 🚀 Getting Started

### Step 1: Deploy Azure Infrastructure

This sample uses the [Fabric, KeyVault & OpenAI Sample](https://github.com/AzureCosmosDB/fabric-keyvault-openai-secrets) for automated provisioning.

1. **Clone the deployment repository**:

   ```bash

   git clone https://github.com/AzureCosmosDB/fabric-keyvault-openai-secrets.git
   cd fabric-keyvault-openai-secrets
   ```

2. **Follow the deployment instructions** in that repository
3. **Copy the output values** (Key Vault URI, secret names, etc.)

### Step 2: Prepare Your Fabric Workspace

1. **Create a Cosmos DB artifact** in your Fabric workspace
2. **Configure Workspace Identity** (required for Azure authentication)
3. **Import the notebook**:
   - Navigate to your Fabric workspace
   - Select **Import → Notebook**
   - Upload `vector-search-advanced.ipynb`

### Step 3: Configure the Sample

**Update the configuration cell** with values from your Azure deployment:

```python
# Values from your Azure deployment output
KEYVAULT_URI = "https://your-keyvault.vault.azure.net/"
KEYVAULT_OPENAI_ENDPOINT = "openai-endpoint"
KEYVAULT_OPENAI_API_KEY = "openai-api-key"

COSMOS_ENDPOINT = 'https://my-cosmos-endpoint.cosmos.fabric.microsoft.com:443/'
COSMOS_DATABASE_NAME = 'cosmos-sample-database'
COSMOS_CONTAINER_NAME = 'SampleVectorData-text3'
```

## 📖 Notebook Walkthrough

### 🔧 **Setup & Authentication** (Cells 1-4)

- Package installation (`azure-cosmos`, `openai`)
- Azure Key Vault credential retrieval
- Fabric token credential implementation
- Azure OpenAI client initialization

### 📊 **Container Setup** (Cells 5-6)

- Vector embedding policy configuration (512 dimensions)
- Container creation with optimized indexing
- Sample data loading with text-embedding-3-large vectors

### 🔍 **Vector Search Implementation** (Cells 7-9)

- Embedding generation with custom Azure OpenAI model
- Advanced similarity search with configurable thresholds
- Production-ready error handling and logging

### 🎯 **Query Execution** (Cell 10)

- Interactive vector search demonstration
- Similarity score analysis and filtering
- Result visualization and interpretation

## 🗂️ Sample Data

This sample uses the **optimized vector dataset**:

- **Dataset**: `fabricSampleDataVectors-3-large-512.json`
- **Model**: text-embedding-3-large (Azure OpenAI)
- **Dimensions**: 512 (reduced from 1536 for performance)
- **Benefits**: 67% smaller storage, faster queries, but with some accuracy loss

### **Performance Comparison**

| Model | Dimensions | Storage Size | Query Speed | Accuracy |
|-------|------------|--------------|-------------|----------|
| ada-002 | 1536 | 100% | Baseline | High |
| text-3-large | 512 | 33% | 3x faster | High (-2%) |

## 🔍 Key Code Examples

### **Secure Azure OpenAI Authentication**

```python
# Retrieve secrets from Azure Key Vault using Workspace Identity
OPENAI_ENDPOINT = notebookutils.credentials.getSecret(KEYVAULT_URI, KEYVAULT_OPENAI_ENDPOINT)
OPENAI_KEY = notebookutils.credentials.getSecret(KEYVAULT_URI, KEYVAULT_OPENAI_API_KEY)

# Initialize Azure OpenAI client
OPENAI_CLIENT = AsyncAzureOpenAI(
    azure_endpoint=OPENAI_ENDPOINT,
    api_key=OPENAI_KEY,
    api_version=OPENAI_API_VERSION
)
```

### **Optimized Vector Search Query**

```python
query = """
    SELECT TOP @limit 
        VectorDistance(c.vectors, @embeddings) AS SimilarityScore,
        c.name, c.description, c.categoryName,
        c.currentPrice, c.inventory
    FROM c
    WHERE VectorDistance(c.vectors, @embeddings) > @similarity
    ORDER BY VectorDistance(c.vectors, @embeddings)
"""
```

### **Advanced Container Configuration**

```python
vector_embedding_policy = {
    "vectorEmbeddings": [{
        "path": "/vectors",
        "dataType": "float32",
        "distanceFunction": "cosine",
        "dimensions": 512  # Optimized dimension count
    }]
}
```

## 🏗️ Architecture

```
📱 Fabric Workspace
├── 🔐 Workspace Identity
│   ├── Azure OpenAI RBAC
│   └── Key Vault RBAC
├── 📊 Cosmos DB Container
│   ├── Vector Indexing (512D)
│   └── Sample Data
└── 📔 Jupyter Notebook

☁️ Azure Resources
├── 🤖 Azure OpenAI Service
│   ├── text-embedding-3-large
│   └── Custom deployment
├── 🔑 Azure Key Vault
│   ├── OpenAI endpoint
│   └── API keys
└── 🛡️ RBAC Policies
```

## 🚨 Troubleshooting

### **Authentication Issues**

- **Workspace Identity not configured**: Follow [Workspace Identity](https://docs.microsoft.com/fabric/security/workspace-identity)
- **Key Vault access denied**: Verify RBAC policies in the deployment script
- **OpenAI authentication failed**: Check secret names match deployment output

### **Data Issues**

- **Container not found**: Ensure container creation cell executed successfully
- **No search results**: Lower similarity threshold (try 0.6 instead of 0.8)
- **Vector dimension mismatch**: Verify embedding model matches container policy

## 📚 Related Samples

| Sample | Description | Difficulty |
|--------|-------------|------------|
| [Vector Search](../vector-search/) | Basic vector search with Fabric OpenAI | Intermediate |
| [Management Operations](../management/) | Container management and retry patterns | Advanced |
| [Simple Query](../simple-query/) | Fundamental Cosmos DB operations | Beginner |

## 🔗 Additional Resources

- [🤖 Azure OpenAI Service Documentation](https://docs.microsoft.com/azure/ai-services/openai/)
- [🔑 Azure Key Vault Integration](https://docs.microsoft.com/azure/key-vault/)
- [📊 Vector Search in Cosmos DB](https://docs.microsoft.com/azure/cosmos-db/nosql/vector-search)
- [🛡️ Workspace Identity in Fabric](https://docs.microsoft.com/fabric/security/workspace-identity)
- [⚡ Sharded DiskANN Performance Optimization Guide](https://docs.microsoft.com/azure/cosmos-db/gen-ai/sharded-diskann)

## ⚡ Performance Tips

1. **Use custom dimension sizes** for faster queries and reduced storage overhead, incurs some accuracy loss
2. **Set appropriate similarity thresholds** (0.6-0.8 for most use cases)
3. **Limit result sets** using TOP clause to improve response times
4. **Exclude vector properties from Index** to reduce storage overhead
5. **Implement caching** for frequently searched embeddings

## 🎯 Next Steps

- **Experiment with different similarity thresholds** to optimize results
- **Try different embedding models** (text-embedding-3-small for cost optimization)
- **Implement hybrid search** combining vector and traditional queries
- **Add real-time embedding generation** for new content
- **Scale to production** with Azure Container Apps or Azure Functions

---

*This sample demonstrates enterprise-grade patterns for vector search in production environments. For simpler scenarios, start with the [basic vector search](../vector-search/).*
