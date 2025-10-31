<!--
page_type: sample
languages:
- python
products:
- fabric
name: "Fabric User Data Functions for Cosmos DB"
description: "Complete collection of Cosmos DB operations using Fabric User Data Functions - create, read, update, query, and vector search"
urlFragment: "user-data-functions"
---
-->

# 🚀 Fabric User Data Functions for Cosmos DB

**Complete collection of Cosmos DB operations using Microsoft Fabric User Data Functions**

This collection demonstrates how to use **Fabric User Data Functions** to perform all essential Cosmos DB operations. User Data Functions provide a powerful platform to host custom logic that can be reused across Fabric items and integrated with external applications via REST endpoints.

> **🎯 Key Innovation**: These samples showcase how to encapsulate Cosmos DB operations as reusable functions that can be invoked from Fabric Pipelines, Notebooks, Power BI, and external applications.

## 🎯 What You'll Learn

### **📈 User Data Functions Concepts**

- **Reusable business logic** for Cosmos DB operations
- **Function encapsulation** with proper error handling
- **External connectivity** via REST endpoints
- **Fabric integration patterns** across different workloads

### **🔗 Cosmos DB Operations**

- **CRUD operations** (Create, Read, Update, Delete)
- **Advanced querying** with parameterized queries
- **Vector search** with Azure OpenAI integration
- **Performance optimization** using partition keys

### **🛠️ Development Patterns**

- **Connection management** using Fabric connections
- **Error handling** for Cosmos DB exceptions
- **Type safety** with Python type hints
- **Security best practices** for external integrations

## 📋 Prerequisites

### **Required Services**

- **Microsoft Fabric workspace** with User Data Functions enabled
- **Cosmos DB artifact** in Fabric with sample data
- **Azure OpenAI** (for vector search sample)
- **Python 3.11.9** runtime knowledge

### **Required Libraries**

- **azure-cosmos** (version 4.14.0 or later)
- **openai** (version 2.3.0 or later, for vector search)
- **fabric.functions** (built-in Fabric library)

### **Sample Data**

- **SampleData container** - for basic CRUD operations
- **SampleVectorData container** - for vector search operations

## 🚀 Getting Started

### Step 1: Set Up Cosmos DB Sample Data

1. **Create or use Cosmos DB artifact** in your Microsoft Fabric workspace
2. **Load sample data**:
   - Click **"SampleData"** on Cosmos Home screen for basic operations
   - Click **"SampleVectorData"** for vector search operations
3. **Get connection details**:
   - Go to **Settings** (gear icon) → **Connection** tab
   - Copy the **URI** for your functions
   - Note the **artifact name** as your database name

### Step 2: Create User Data Functions

1. **Navigate to Data Engineering** experience in Fabric
2. **Create new User Data Functions** item
3. **Copy function code** from the samples below
4. **Update configuration variables** with your Cosmos DB details
5. **Install required libraries** in Library Management

### Step 3: Configure and Test

1. **Update connection variables** in each function:
   ```python
   COSMOS_DB_URI = "{your-cosmos-artifact-uri}"
   DB_NAME = "{your-cosmos-artifact-name}"
   CONTAINER_NAME = "SampleData"  # or "SampleVectorData"
   ```

2. **Test functions** using the built-in test interface
3. **Deploy and use** from other Fabric items or external applications

## 📚 Function Samples

| Function | File | Description | Prerequisites | Complexity |
|----------|------|-------------|---------------|------------|
| [Create Item](#-create-item) | [`create_item.py`](./create_item.py) | Insert a new product document into Cosmos DB container | SampleData container | Beginner |
| [Read Item](#-read-item) | [`read_item.py`](./read_item.py) | Retrieve a single document by ID and partition key | SampleData container with existing data | Beginner |
| [Update Item](#-update-item) | [`update_item.py`](./update_item.py) | Update product price and price history | SampleData container with existing data | Intermediate |
| [Query Items](#-query-items) | [`query_items.py`](./query_items.py) | Query multiple documents with SQL-like syntax | SampleData container | Intermediate |
| [Vector Search](#-vector-search) | [`vector_query_items.py`](./vector_query_items.py) | AI-powered semantic search using vector embeddings | SampleVectorData container, Azure OpenAI | Advanced |

## 📖 Detailed Function Documentation

### 🆕 Create Item

**File**: [`create_item.py`](./create_item.py)

**Purpose**: Demonstrates how to insert a new document into a Cosmos DB container using User Data Functions.

**Key Features**:
- Document creation with proper structure
- Error handling for duplicate items
- ISO8601 timestamp generation
- Structured product data model

**Function Signature**:
```python
@udf.function()
def insert_product(cosmosDb: fn.FabricItem) -> list[dict[str, Any]]
```

**Usage Example**:
```python
# The function creates a predefined product
# Modify the product data within the function for different items
result = insert_product(cosmosDb_connection)
```

**Learning Points**:
- Basic Cosmos DB document structure
- Error handling patterns
- Using Fabric connections
- Document ID and partition key relationships

---

### 📖 Read Item

**File**: [`read_item.py`](./read_item.py)

**Purpose**: Shows how to retrieve a specific document using its ID and partition key.

**Key Features**:
- Point read operation (most efficient)
- Partition key usage for performance
- Error handling for missing items
- Type-safe return values

**Function Signature**:
```python
@udf.function()
def get_product(cosmosDb: fn.FabricItem, categoryName: str, productId: str) -> list[dict[str, Any]]
```

**Usage Example**:
```python
# Example values
categoryName = "Computers, Laptops"
productId = "77be013f-4036-4311-9b5a-dab0c3d022be"

product = get_product(cosmosDb_connection, categoryName, productId)
```

**Learning Points**:
- Point read vs. query operations
- Partition key importance
- Error handling for not found scenarios
- Function parameters and types

---

### ✏️ Update Item

**File**: [`update_item.py`](./update_item.py)

**Purpose**: Demonstrates reading, modifying, and updating a document in Cosmos DB.

**Key Features**:
- Read-modify-write pattern
- Price history tracking
- Timestamp generation
- Optimistic concurrency (via replace_item)

**Function Signature**:
```python
@udf.function()
def update_product(cosmosDb: fn.FabricItem, categoryName: str, productId: str, newPrice: float) -> list[dict[str, Any]]
```

**Usage Example**:
```python
# Update product price
categoryName = "Computers, Laptops"
productId = "77be013f-4036-4311-9b5a-dab0c3d022be"
newPrice = 2899.99

updated_product = update_product(cosmosDb_connection, categoryName, productId, newPrice)
```

**Learning Points**:
- Read-modify-write operations
- Array manipulation (price history)
- Document replacement patterns
- Business logic encapsulation

---

### 🔍 Query Items

**File**: [`query_items.py`](./query_items.py)

**Purpose**: Shows how to query multiple documents using SQL-like syntax with parameters.

**Key Features**:
- Parameterized queries for security
- Cross-partition query handling
- Result filtering and ordering
- Performance optimization with partition keys

**Function Signature**:
```python
@udf.function()
def query_products(cosmosDb: fn.FabricItem, categoryName: str, productId: str, newPrice: float) -> list[dict[str, Any]]
```

**Usage Example**:
```python
# Query products in a category
categoryName = "Computers, Laptops"

products = query_products(cosmosDb_connection, categoryName)
```

**Learning Points**:
- SQL query syntax in Cosmos DB
- Parameterized queries
- Performance considerations
- Result set handling

---

### 🔍 Vector Search

**File**: [`vector_query_items.py`](./vector_query_items.py)

**Purpose**: Demonstrates AI-powered semantic search using vector embeddings and Azure OpenAI.

**Key Features**:
- Vector similarity search
- Azure OpenAI integration
- Embedding generation
- Cross-partition vector queries

**Function Signature**:
```python
@udf.function()
def product_vector_search(cosmosDb: fn.FabricItem, searchtext: str, similarity: float, limit: int) -> list[dict[str, Any]]
```

**Usage Example**:
```python
# Semantic search for products
searchText = "gaming pc"
similarity = 0.824  # Minimum similarity threshold
limit = 5          # Maximum results

results = product_vector_search(cosmosDb_connection, searchText, similarity, limit)
```

**Additional Setup Required**:
1. **Deploy Azure OpenAI** with text-embedding-ada-002 model
2. **Update OpenAI configuration**:
   ```python
   OPENAI_URI = "{your-azure-openai-endpoint}"
   OPENAI_KEY = "{your-azure-openai-key}"
   ```

**Learning Points**:
- Vector embeddings and similarity search
- Azure OpenAI integration
- Performance with vector queries
- AI-powered search patterns

## 🛠️ Configuration Guide

### **Required Variables**

Each function requires these configuration variables:

```python
# Cosmos DB Configuration
COSMOS_DB_URI = "{my-cosmos-artifact-uri}"        # From Cosmos Settings → Connection
DB_NAME = "{my-cosmos-artifact-name}"             # Your Cosmos artifact name
CONTAINER_NAME = "SampleData"                     # Or "SampleVectorData"

# Azure OpenAI Configuration (for vector search only)
OPENAI_URI = "{my-azure-openai-endpoint}"         # Your Azure OpenAI endpoint
OPENAI_KEY = "{my-azure-openai-key}"              # Your Azure OpenAI key
OPENAI_API_VERSION = "2023-05-15"                 # API version
OPENAI_EMBEDDING_MODEL = "text-embedding-ada-002" # Embedding model
```

### **Finding Your Configuration Values**

1. **Cosmos DB URI and Name**:
   - Open your Cosmos DB artifact in Fabric
   - Go to **Settings** (gear icon) → **Connection** tab
   - Copy the **URI** and note the **artifact name**

2. **Container Names**:
   - **SampleData**: Created when you click "SampleData" on Cosmos Home
   - **SampleVectorData**: Created when you click "SampleVectorData" on Cosmos Home

3. **Azure OpenAI Details**:
   - Deploy text-embedding-ada-002 model in Azure OpenAI
   - Get endpoint and key from Azure portal
   - Verify API version in AI Foundry portal

## 🔗 Integration Patterns

### **Fabric Pipelines**

Use User Data Functions in Data Factory pipelines:

```python
# Activity: User Data Functions
# Function: get_product
# Parameters: 
#   categoryName: "Computers, Laptops"
#   productId: "77be013f-4036-4311-9b5a-dab0c3d022be"
```

### **Fabric Notebooks**

Call functions from Spark notebooks:

```python
import requests

# Call User Data Function via REST endpoint
function_endpoint = "https://your-fabric-workspace/userDataFunctions/get_product"
response = requests.post(function_endpoint, json={
    "categoryName": "Computers, Laptops",
    "productId": "77be013f-4036-4311-9b5a-dab0c3d022be"
})
```

### **Power BI Integration**

Create translytical apps connecting Power BI with User Data Functions for real-time data operations.

### **External Applications**

Access via REST endpoints for integration with external systems:

```bash
# REST API call
curl -X POST "https://your-function-endpoint" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"categoryName": "Computers, Laptops", "productId": "77be013f-4036-4311-9b5a-dab0c3d022be"}'
```

## 🚨 Troubleshooting

### **Library Management Issues**

- **Missing azure-cosmos**: Go to Library Management → Add **azure-cosmos** version 4.14.0+
- **Missing openai**: Add **openai** version 2.3.0+ (for vector search)
- **Import errors**: Restart the User Data Functions runtime

### **Connection Issues**

- **Invalid URI**: Verify Cosmos DB URI from Settings → Connection tab
- **Database not found**: Check artifact name matches `DB_NAME` variable
- **Container not found**: Ensure SampleData/SampleVectorData containers exist

### **Function Execution Issues**

- **Authentication errors**: Verify Fabric connection permissions
- **Timeout errors**: Check query performance and add appropriate filters
- **Type errors**: Ensure parameter types match function signatures

### **Vector Search Specific**

- **OpenAI connection failed**: Verify Azure OpenAI endpoint and key
- **Embedding model errors**: Ensure text-embedding-ada-002 is deployed
- **No vector results**: Check similarity threshold and embedding quality

## 🎯 Best Practices

### **Performance Optimization**

1. **Use partition keys** in queries whenever possible
2. **Limit result sets** with TOP clause and appropriate filters
3. **Cache embeddings** for repeated vector searches
4. **Use point reads** instead of queries when possible

### **Error Handling**

1. **Implement proper exception handling** for all Cosmos operations
2. **Log errors appropriately** for debugging
3. **Return meaningful error messages** to callers
4. **Handle rate limiting** and retry logic

### **Security**

1. **Use Fabric connections** instead of hardcoded credentials
2. **Validate input parameters** before processing
3. **Sanitize query parameters** to prevent injection
4. **Implement appropriate authorization** for REST endpoints

### **Code Organization**

1. **Separate configuration** from business logic
2. **Use type hints** for better code clarity
3. **Document function purposes** and parameters
4. **Follow consistent naming conventions**

## 🔄 Next Steps

After exploring these samples:

- **Create custom functions** for your specific business logic
- **Integrate with Fabric Pipelines** for data processing workflows
- **Build Power BI dashboards** with real-time data operations
- **Develop external applications** using REST endpoints
- **Implement advanced patterns** like caching and batch operations

## 📚 Additional Resources

- [📖 User Data Functions Overview](https://learn.microsoft.com/en-us/fabric/data-engineering/user-data-functions/user-data-functions-overview)
- [🚀 Create User Data Functions](https://learn.microsoft.com/en-us/fabric/data-engineering/user-data-functions/create-user-data-functions-portal)
- [🔗 Connect to Data Sources](https://learn.microsoft.com/en-us/fabric/data-engineering/user-data-functions/connect-to-data-sources)
- [📊 Python Programming Model](https://learn.microsoft.com/en-us/fabric/data-engineering/user-data-functions/python-programming-model)
- [🔧 Cosmos DB Python SDK](https://docs.microsoft.com/azure/cosmos-db/nosql/sdk-python)
- [🤖 Azure OpenAI Embeddings](https://docs.microsoft.com/azure/cognitive-services/openai/how-to/embeddings)

## 🎯 Key Takeaways

1. **User Data Functions** provide reusable, encapsulated business logic for Cosmos DB operations
2. **Fabric integration** enables seamless connectivity across the platform
3. **External REST endpoints** allow integration with external applications
4. **Vector search capabilities** unlock AI-powered semantic search scenarios
5. **Proper error handling** and performance optimization are essential for production use

---

*This collection demonstrates the power of Fabric User Data Functions for creating reusable, scalable Cosmos DB operations that integrate seamlessly across the Microsoft Fabric ecosystem.*