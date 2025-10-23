# 📊 Sample Datasets

Welcome to the **Cosmos DB in Fabric sample datasets**! These carefully curated datasets provide realistic data for exploring Cosmos DB features, from basic queries to advanced AI-powered vector search scenarios.

## 🗂️ Dataset Overview

| Dataset | Type | Size | Use Case | Vector Support |
|---------|------|------|----------|----------------|
| [fabricSampleData.json](#-fabricsampledatajson) | Product Catalog | ~50 items | Basic queries & operations | ❌ |
| [fabricSampleDataVectors-ada-002-1536.json](#-fabricsampledatavectors-ada-002-1536json) | Product Catalog + Vectors | ~50 items | Vector search with Ada-002 | ✅ (1536-dim) |
| [fabricSampleDataVectors-3-large-512.json](#-fabricsampledatavectors-3-large-512json) | Product Catalog + Vectors | ~50 items | Advanced vector scenarios | ✅ (512-dim) |

---

## 📦 fabricSampleData.json

**Basic product catalog with customer reviews** - Perfect for getting started with Cosmos DB in Fabric.

### 🎯 **Best For:**
- Learning basic CRUD operations
- Understanding document structure
- Practicing SQL queries
- Exploring co-located data patterns

### 🏗️ **Data Structure:**
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

### 🚀 **How to Use:**
1. Load via **Cosmos Data Explorer** → Click "SampleData"
2. Available immediately in Fabric portal
3. No additional setup required

---

## 🤖 fabricSampleDataVectors-ada-002-1536.json

**Enhanced dataset with AI embeddings** - Same product catalog enhanced with OpenAI Ada-002 vector embeddings.

### 🎯 **Best For:**
- Semantic search scenarios
- Similarity matching
- RAG (Retrieval-Augmented Generation) patterns
- Vector database demonstrations

### 📐 **Vector Details:**
- **Model:** `text-embedding-ada-002`
- **Dimensions:** 1536
- **Generated from:** Product names and descriptions
- **Format:** Float32 arrays

### 🏗️ **Enhanced Structure:**
```json
{
  "docType": "product",
  "productId": "77be013f-4036-4311-9b5a-dab0c3d022be",
  "categoryName": "Computers, Laptops",
  "name": "Adventure Works Laptop15",
  "description": "Adventure Works Laptop15, 4GB RAM",
  "currentPrice": 1200.99,
  "contentVector": [0.0123, -0.0456, 0.0789, ...], // 1536 dimensions
  // ... other fields
}
```

### 🚀 **How to Use:**
1. **Download** this file from the repository
2. **Import** into your Cosmos DB container using Data Explorer
3. **Configure vector indexing** for optimal search performance

---

## 🔬 fabricSampleDataVectors-3-large-512.json

**Advanced vector dataset** - Optimized vectors using the latest text-embedding-3-large model with reduced dimensions.

### 🎯 **Best For:**
- Production-ready vector scenarios
- Advanced AI applications
- Performance-optimized vector search
- Integration with Azure OpenAI

### 📐 **Vector Details:**
- **Model:** `text-embedding-3-large`
- **Dimensions:** 512 (optimized)
- **Quality:** Higher precision than Ada-002
- **Performance:** Faster search with reduced dimensions

### 🏗️ **Enhanced Structure:**
```json
{
  "docType": "product",
  "productId": "77be013f-4036-4311-9b5a-dab0c3d022be",
  "categoryName": "Computers, Laptops",
  "name": "Adventure Works Laptop15",
  "description": "Adventure Works Laptop15, 4GB RAM",
  "currentPrice": 1200.99,
  "contentVector": [0.0234, -0.0567, 0.0891, ...], // 512 dimensions
  // ... other fields
}
```

### ⚙️ **Prerequisites:**
- **Azure OpenAI account** with deployed model
- **Key Vault** for secure credential storage
- **Advanced vector search** sample implementation

### 🚀 **How to Use:**
1. **Download** this file from the repository
2. **Configure Azure OpenAI** integration
3. **Set up Key Vault** for credentials
4. **Import** and configure vector indexing

---

## 💡 Choosing the Right Dataset

### 🟢 **New to Cosmos DB?**
Start with **fabricSampleData.json**
- Simple structure, easy to understand
- Available directly in Fabric portal
- Perfect for learning fundamentals

### 🟡 **Ready for AI Features?**
Use **fabricSampleDataVectors-ada-002-1536.json**
- Includes vector embeddings
- Good balance of features and complexity
- Standard OpenAI model compatibility

### 🔴 **Building Production AI Apps?**
Choose **fabricSampleDataVectors-3-large-512.json**
- Latest embedding model
- Optimized performance
- Enterprise-ready setup

## 🔗 Related Samples

- [Simple Query Samples](../Simple%20Query%20Samples/) - Use with `fabricSampleData.json`
- Vector Search Samples *(coming soon)* - Use with vector-enabled datasets
- Performance Optimization *(coming soon)* - Compare dataset performance

## 📚 Additional Resources

- [Cosmos DB Vector Search Documentation](https://docs.microsoft.com/azure/cosmos-db/vector-search)
- [Azure OpenAI Embeddings Guide](https://docs.microsoft.com/azure/cognitive-services/openai/how-to/embeddings)
- [Vector Indexing Best Practices](https://docs.microsoft.com/azure/cosmos-db/index-overview)
