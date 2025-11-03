<!--
---
page_type: sample
languages:
- sql
- python
products:
- fabric
- fabric-database-cosmos-db
name: "Spark Analytics and Power BI Dashboard"
description: "Analyze price-review correlations using Spark SQL and create Power BI dashboards from Cosmos DB data via lakehouse shortcuts"
urlFragment: "spark-analytics-powerbi"
---
-->

# 📊 Spark Analytics and Power BI Dashboard

**Analyze product pricing and customer satisfaction correlations using Cosmos DB shortcuts and Spark SQL with Power BI visualization**

This sample demonstrates how to analyze Cosmos DB data in Microsoft Fabric using **lakehouse shortcuts** and create compelling **Power BI dashboards**. You'll discover correlations between product pricing and customer review ratings across different categories using **category-relative price analysis** - avoiding the common mistake of comparing laptop prices to accessory prices by using statistical positioning within each product category.

> **🎯 Key Innovation**: This sample uses **category-relative pricing analysis** instead of static price bands, ensuring meaningful comparisons by positioning products within their specific categories rather than using arbitrary price thresholds.

## 🎯 What You'll Learn

### 📈 **Data Analytics Concepts**

- **Price-review correlation analysis** across product categories
- **Statistical analysis** using SQL aggregation functions  
- **Category-relative price analysis** avoiding arbitrary price band comparisons
- **Trend analysis** over time periods and price positions within categories

### 🔗 **Fabric Integration Patterns**

- **Cosmos DB shortcuts** to lakehouse for data access
- **Spark SQL** for querying Cosmos DB data through shortcuts
- **Power BI integration** with lakehouse data sources
- **Cross-service data workflows** in Microsoft Fabric

### 📊 **Business Intelligence**

- **Interactive dashboards** showing price-satisfaction relationships
- **Category-based insights** for different product types
- **Performance metrics** and KPIs visualization
- **Real-time analytics** on live mirrored data

## 📋 Prerequisites

### **Required Services**

- **Microsoft Fabric workspace** with appropriate permissions
- **Cosmos DB artifact** in Fabric with sample data
- **Lakehouse** in your Fabric workspace for shortcuts
- **Power BI** access in your Fabric workspace

### **Data Requirements**

- **fabricSampleData.json** loaded in your Cosmos DB container
- **Lakehouse shortcuts** configured to your Cosmos DB container
- **Sample data** with product and review documents

### **Skills**

- Basic SQL query knowledge
- Familiarity with Power BI (helpful but not required)
- Understanding of data correlation concepts

## 🚀 Getting Started

### Step 1: Create Cosmos DB Container

1. **Create or use Cosmos DB artifact** in your Microsoft Fabric workspace:
   - From the **Home tab**, create a **new Cosmos DB artifact** (or use an existing one)
   - Name your artifact (e.g., `cosmos-sample-db`)
2. **Open Cosmos DB Data Explorer** for your artifact
3. **Create a new container** with these settings:
   - Database name: `CosmosSampleDatabase` (or your preferred name)
   - Container name: `SampleData` (or your preferred name)  
   - Partition key: `/categoryName`
4. **Upload sample data**: Use the **Upload** button in Data Explorer
5. **Select the file**: Navigate to `datasets/fabricSampleData.json` from this repository
6. **Verify upload**: Confirm all documents are loaded successfully

### Step 2: Create Lakehouse and Shortcuts

1. **Create a new Lakehouse** in your Fabric workspace
   - Give it a clear name like `cosmos_sample_lakehouse`
2. **Create a shortcut to your Cosmos DB**:
   - In your lakehouse, go to **Files** or **Tables** section
   - Click **New shortcut**
   - Select **Microsoft OneLake** → **Cosmos DB**
   - Choose your Cosmos DB account and database
   - Select the container you created in Step 1
3. **Note your names** for configuration in the notebook

### Step 3: Import and Configure the Analysis Notebook

> **🚨 IMPORTANT**: The notebook MUST be run in Microsoft Fabric - it cannot be executed locally due to Fabric-specific Spark SQL syntax and authentication.

1. **Download the notebook**:
   - Navigate to the `spark-analytics-powerbi` folder
   - Download `spark-analytics-powerbi.ipynb`

2. **Import into Fabric**:
   - In your Fabric workspace, select **Import → Notebook**
   - Upload `spark-analytics-powerbi.ipynb`

3. **Configure the notebook**:
   - Update cell 4 with your actual lakehouse and database names
   - Follow the detailed setup instructions within the notebook

## 📊 Data Structure Analysis

The `fabricSampleData.json` contains two types of documents:

### **Product Documents**

```json
{
  "id": "product-id",
  "docType": "product",
  "name": "Product Name",
  "categoryName": "Product Category",
  "currentPrice": 1299.99,
  "inventory": 150
}
```

### **Review Documents**

```json
{
  "id": "review-id", 
  "docType": "review",
  "productId": "product-id",
  "categoryName": "Product Category",
  "stars": 4,
  "reviewText": "Customer review..."
}
```

## 🔍 Key Analytics Queries

### **1. Price-Review Correlation by Category**

```sql
-- Calculate average price and rating by category using Spark SQL
SELECT 
    p.categoryName,
    AVG(p.currentPrice) as avg_price,
    AVG(CAST(r.stars as DOUBLE)) as avg_rating,
    COUNT(r.id) as review_count,
    COUNT(DISTINCT p.id) as product_count
FROM {FULL_TABLE_NAME} p
JOIN {FULL_TABLE_NAME} r ON p.id = r.productId
WHERE p.docType = 'product' AND r.docType = 'review'
GROUP BY p.categoryName
ORDER BY avg_price DESC;
```

### **2. Category-Relative Price Analysis**

```sql
-- Analyze ratings by price position within each category (not static bands)
WITH ProductReviews AS (
    SELECT 
        p.categoryName,
        p.currentPrice,
        CAST(r.stars as DOUBLE) as rating,
        -- Calculate relative price position within category (0-1 scale)
        (p.currentPrice - MIN(p.currentPrice) OVER (PARTITION BY p.categoryName)) / 
        NULLIF(MAX(p.currentPrice) OVER (PARTITION BY p.categoryName) - MIN(p.currentPrice) OVER (PARTITION BY p.categoryName), 0) as relative_price_position,
        -- Calculate price percentile within category
        PERCENT_RANK() OVER (PARTITION BY p.categoryName ORDER BY p.currentPrice) as price_percentile
    FROM {FULL_TABLE_NAME} p
    INNER JOIN {FULL_TABLE_NAME} r ON p.id = r.productId
    WHERE p.docType = 'product' 
      AND r.docType = 'review'
      AND p.currentPrice IS NOT NULL
      AND r.stars IS NOT NULL
),
PricePositions AS (
    SELECT *,
        CASE 
            WHEN price_percentile < 0.25 THEN 'Bottom 25% (Lowest Price)'
            WHEN price_percentile < 0.50 THEN '25-50% (Below Average)'
            WHEN price_percentile < 0.75 THEN '50-75% (Above Average)'
            ELSE 'Top 25% (Highest Price)'
        END as price_position_category
    FROM ProductReviews
)
SELECT 
    categoryName,
    price_position_category,
    AVG(rating) as avg_rating,
    COUNT(*) as review_count,
    AVG(relative_price_position) as avg_relative_position
FROM PricePositions
GROUP BY categoryName, price_position_category
ORDER BY categoryName, avg_relative_position;
```

### **3. Category Deep Dive**

```sql
-- Detailed analysis for specific categories using Spark SQL
SELECT 
    p.name as product_name,
    p.currentPrice,
    AVG(CAST(r.stars as DOUBLE)) as avg_rating,
    COUNT(r.id) as review_count,
    MAX(r.stars) as highest_rating,
    MIN(r.stars) as lowest_rating
FROM {FULL_TABLE_NAME} p
INNER JOIN {FULL_TABLE_NAME} r ON p.id = r.productId
WHERE p.docType = 'product' 
  AND r.docType = 'review'
  AND p.categoryName = 'Computers, Laptops'
GROUP BY p.id, p.name, p.currentPrice
HAVING COUNT(r.id) >= 2  -- Products with at least 2 reviews
ORDER BY avg_rating DESC, p.currentPrice ASC;
```

## 📈 Power BI Dashboard Creation

### **Step 1: Connect Power BI to Lakehouse**

1. **Open Power BI Desktop**
2. **Get Data** → **More** → **Microsoft Fabric** → **Lakehouse**
3. **Enter connection details**:
   - **Workspace**: Your Fabric workspace
   - **Lakehouse**: Your lakehouse name
   - **Authentication**: Microsoft Account (same as Fabric)

### **Step 2: Use the Power BI Template SQL File**

This sample includes a **`powerbi-template.sql`** file with optimized queries for Power BI:

1. **Copy the SQL queries** from `powerbi-template.sql`
2. **In Power BI**, use **Transform Data** → **Advanced Editor**  
3. **Replace the default M query** with the provided SQL templates
4. **Update the connection parameters** to match your lakehouse and table names

The template includes:

- **Main correlation dataset** with category-relative price analysis
- **Optimized DAX measures** for correlation calculations
- **Pre-built visualization guidance**
- **Proper Fabric lakehouse connection syntax**

### **Step 3: Create Visualizations**

**📊 Recommended Visuals:**

1. **Scatter Plot**: Price vs Average Rating by Category (with correlation trend lines)
2. **Column Chart**: Average Rating by Price Position Within Category
3. **Line Chart**: Rating Trends Over Time by Category
4. **Heat Map**: Category vs Price Position correlation matrix
5. **Cards**: Key Metrics (Total Products, Avg Price, Avg Rating, Correlation Strength)
6. **Slicer**: Category Filter for Interactive Analysis
7. **Gauge**: Price-to-Average Ratio by Category

### **Step 4: Dashboard Design**

**🎨 Layout Structure:**

```text
┌─────────────────────────────────────────────────────┐
│ KPI Cards: Avg Price | Avg Rating | Correlation     │
├─────────────────────────────────────────────────────┤
│ Category Slicer                                     │
├──────────────────────┬──────────────────────────────┤
│ Price vs Rating      │ Rating by Price Position     │
│ Scatter Plot         │ (Category-Relative)          │
│ (with trend lines)   │ Column Chart                 │
├──────────────────────┼──────────────────────────────┤
│ Price Position       │ Value Assessment             │
│ Heat Map             │ Distribution                 │
└──────────────────────┴──────────────────────────────┘
```

## 🔍 Key Insights to Discover

### **Expected Correlations**

- **Electronics**: Higher prices may correlate with better ratings due to quality within each category
- **Fashion**: Price-rating correlation might be weaker due to subjective preferences, but position within category still matters
- **Home & Garden**: Mid-tier products within each category might show optimal satisfaction
- **Sports**: Premium equipment within each category often justifies higher ratings

### **Analysis Questions**

1. **Which categories show the strongest price-position correlation within their range?**
2. **Do higher-priced products within a category consistently rate better?**
3. **What relative price position offers the best value (high rating, reasonable category position)?**
4. **How do seasonal trends affect ratings across price positions within categories?**

## 🛠️ Advanced Analytics

### **Statistical Correlation Calculation using Spark SQL**

```sql
-- Calculate Pearson correlation coefficient using Spark SQL
WITH ProductReviews AS (
    SELECT 
        p.categoryName,
        p.currentPrice,
        CAST(r.stars as DOUBLE) as rating
    FROM {FULL_TABLE_NAME} p
    INNER JOIN {FULL_TABLE_NAME} r ON p.id = r.productId
    WHERE p.docType = 'product' 
      AND r.docType = 'review'
      AND p.currentPrice IS NOT NULL
      AND r.stars IS NOT NULL
),
CorrelationCalc AS (
    SELECT 
        categoryName,
        CORR(currentPrice, rating) as correlation_coefficient,
        COUNT(*) as sample_size,
        AVG(currentPrice) as avg_price,
        AVG(rating) as avg_rating,
        STDDEV(currentPrice) as price_std,
        STDDEV(rating) as rating_std
    FROM ProductReviews
    GROUP BY categoryName
    HAVING COUNT(*) >= 10  -- Ensure statistical significance
)
SELECT 
    categoryName,
    correlation_coefficient,
    sample_size,
    avg_price,
    avg_rating,
    CASE 
        WHEN ABS(correlation_coefficient) >= 0.7 THEN 'Strong'
        WHEN ABS(correlation_coefficient) >= 0.4 THEN 'Moderate'
        WHEN ABS(correlation_coefficient) >= 0.2 THEN 'Weak'
        ELSE 'Very weak/None'
    END as correlation_strength
FROM CorrelationCalc
ORDER BY ABS(correlation_coefficient) DESC;
```

## 📚 Notebook Walkthrough

The `spark-analytics-powerbi.ipynb` notebook includes:

### **🔧 Setup and Configuration** (Cells 1-4)

- Package installation for Fabric environment
- Library imports (pandas, plotly)
- Lakehouse and database configuration
- Connection validation with sample data preview

### **📊 Data Exploration and Validation** (Cells 5-7)

- Complete dataset loading with Spark SQL
- Data structure analysis and category breakdown
- Price range analysis across categories with visualizations

### **🔍 Advanced Correlation Analysis** (Cells 8-10)

- Category-relative price position analysis
- Price-review correlation calculations using individual data points
- Statistical significance testing and proper correlation interpretation

### **📈 Visualization and Insights** (Cells 11-13)

- Product performance analysis (best/worst performers)
- Comprehensive dashboard with multiple chart types
- Actionable business insights and strategic recommendations

### **💡 Business Intelligence Output** (Cell 14)

- Category-specific correlation insights
- Strategic pricing recommendations
- Value opportunity identification

## 🚨 Troubleshooting

### **Lakehouse and Shortcut Issues**

- **Data not appearing**: Verify shortcuts are created correctly and pointing to the right Cosmos DB container
- **Query errors**: Check lakehouse and table names match your configuration
- **Permission issues**: Ensure you have access to both the Cosmos DB artifact and lakehouse

### **Power BI Connection**

- **Authentication failed**: Ensure same account used for Fabric and Power BI
- **Lakehouse not found**: Verify lakehouse name and workspace access
- **Query timeout**: Optimize SQL queries or add filters for large datasets

### **Notebook Execution**

- **Import errors**: Run the package installation cell in Fabric environment
- **Configuration errors**: Update cell 4 with your actual lakehouse and database names
- **No correlations found**: Verify adequate data volume and proper data relationships

## 🔄 Next Steps

After completing this sample, explore:

- **Advanced Analytics** - Machine learning predictions for pricing optimization
- **Real-time Dashboards** - Live streaming analytics with Event Streams
- **Custom Metrics** - Create calculated columns and measures in Power BI
- **Multi-source Integration** - Combine with other Fabric data sources
- **Automated Refresh** - Schedule data refresh in Power BI from lakehouse

## 📚 Additional Resources

- [📊 Fabric Lakehouse Documentation](https://docs.microsoft.com/fabric/data-engineering/lakehouse-overview)
- [🔗 Cosmos DB in Fabric Guide](https://docs.microsoft.com/fabric/database/cosmos-db/)
- [📈 Power BI in Fabric](https://docs.microsoft.com/fabric/power-bi/)
- [� Spark SQL Reference](https://docs.microsoft.com/fabric/data-engineering/spark-sql-overview)

## 🎯 Key Takeaways

1. **Cosmos DB shortcuts** provide seamless access to operational data in lakehouses
2. **Price-review correlations** reveal valuable business insights using category-relative analysis
3. **Power BI integration** with lakehouse enables rich, interactive dashboard experiences  
4. **Spark SQL** offers powerful analytics capabilities for correlation analysis
5. **Category-relative pricing** provides more meaningful insights than static price bands

---

*This sample demonstrates modern data analytics patterns in Microsoft Fabric, bridging operational Cosmos DB data with advanced correlation analysis and business intelligence.*
