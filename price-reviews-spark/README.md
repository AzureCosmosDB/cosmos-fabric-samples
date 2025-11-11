<!--
---
page_type: sample
languages:
- python
products:
- fabric
- fabric-database-cosmos-db
name: |
    Lakehouse Analytics with Python Spark
urlFragment: price-reviews-spark
description: Analyze price-review correlations using Spark SQL from Cosmos DB data via lakehouse shortcuts.
---
-->

# 📊 Price-Review Correlation Analysis with Python Spark

**Analyze product pricing and customer satisfaction correlations using Cosmos DB data via lakehouse shortcuts and Spark SQL**

This sample demonstrates how to analyze Cosmos DB data in Microsoft Fabric using **Python, Spark SQL, and interactive visualizations**. You'll discover correlations between product pricing and customer review ratings across different categories using **category-relative price analysis** - avoiding the common mistake of comparing laptop prices to accessory prices by using statistical positioning within each product category.

> **🎯 Key Innovation**: This sample uses **category-relative pricing analysis** instead of static price bands, ensuring meaningful comparisons by positioning products within their specific categories rather than using arbitrary price thresholds.

## 🎯 What You'll Learn

### 📈 **Data Analytics Concepts**

- **Price-review correlation analysis** across product categories
- **Statistical analysis** using SQL aggregation functions  
- **Category-relative price analysis** avoiding arbitrary price band comparisons
- **Trend analysis** over time periods and price positions within categories
- **Interactive visualizations** with Plotly for exploratory data analysis

### 🔗 **Fabric Integration Patterns**

- **Cosmos DB shortcuts** to lakehouse for data access
- **Spark SQL** for querying Cosmos DB data through shortcuts
- **Python data analysis** with pandas and numpy
- **Cross-service data workflows** in Microsoft Fabric

### 📊 **Python Analytics**

- **Correlation coefficient calculations** using pandas
- **Statistical significance testing** for business insights
- **Interactive charts** with Plotly (scatter plots, bar charts, heatmaps)
- **Data transformation** and aggregation techniques

## 📋 Prerequisites

### **Required Services**

- **Microsoft Fabric workspace** with appropriate permissions
- **Cosmos DB artifact** in Fabric with sample data
- **Lakehouse** in your Fabric workspace for shortcuts

### **Data Requirements**

- **fabricSampleData.json** loaded in your Cosmos DB container
- **Lakehouse shortcuts** configured to your Cosmos DB container
- **Sample data** with product and review documents

### **Skills**

- Basic SQL query knowledge
- Basic Python familiarity
- Understanding of data correlation concepts

## 🚀 Getting Started

### Step 1: Create Cosmos DB Container

1. **Create a new Cosmos DB artifact** in your Microsoft Fabric workspace:
   - In your workspace, create a **new Cosmos DB artifact**
   - Name your artifact `CosmosSampleDatabase`

2. **Create a container** using one of these methods:

   **Option A: Quick Create from Home Tab**
   - From the **Home tab**, click on the **SampleData** card
   - This creates a new Cosmos DB container called `SampleData` and uploads the sample dataset used in the sample.

   **Option B: Manual Create from Data Explorer**
   - Open **Cosmos DB Data Explorer**
   - Click **New Container**
   - Container name: `SampleData`
   - Partition key: `/categoryName`
   - Click **Create**
   - **Upload sample data**:
     - In Data Explorer, select your `SampleData` container
     - Click **Items**
     - Click **Upload** button
     - Navigate to `datasets/fabricSampleData.json` from this repository
     - Verify all documents are loaded successfully

### Step 2: Create Lakehouse and Shortcuts

1. **Create a new Lakehouse** in your Fabric workspace
   - Give it a clear name like `CosmosSampleLakehouse`
2. **Create a shortcut to your Cosmos DB**:
   - In your lakehouse, select **Tables** from Explorer
   - Click **New schma shortcut**
   - Select **Microsoft OneLake**
   - Choose your Cosmos DB database you previously created
   - Click **Create**
3. **Note your names** for configuration in the notebook

### Step 3: Import and Run the Analysis Notebook

> **🚨 IMPORTANT**: The notebook MUST be run in Microsoft Fabric - it cannot be executed locally due to Fabric-specific Spark SQL syntax and authentication.

1. **Download the notebook**:
   - Navigate to this folder
   - Download `price-reviews-spark.ipynb`

2. **Import into Fabric**:
   - In your Fabric workspace, select **Import → Notebook**
   - Upload `price-reviews-spark.ipynb`

3. **Configure the notebook**:
   - Update cell 4 with your actual lakehouse and database names
   - Follow the detailed setup instructions within the notebook

4. **Run the analysis**:
   - Execute all cells sequentially
   - Review the interactive visualizations generated in each section
   - Explore the correlation insights and business recommendations

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

## ️ Advanced Analytics

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

The `price-reviews-spark.ipynb` notebook includes:

### **🔧 Setup and Configuration** (Cells 1-4)

- Package installation for Fabric environment (plotly)
- Library imports (pandas, plotly, numpy)
- Lakehouse and database configuration
- Connection validation with sample data preview

### **📊 Data Exploration and Validation** (Cells 5-7)

- Complete dataset loading with Spark SQL
- Data structure analysis and category breakdown
- **Interactive visualization**: Price range distribution across categories (Plotly bar chart)
- Category statistics summary

### **🔍 Advanced Correlation Analysis** (Cells 8-10)

- Category-relative price position analysis
- **Price-review correlation calculations** using individual data points (avoiding aggregation bias)
- **Interactive visualization**: Correlation coefficient strength by category (Plotly bar chart with color coding)
- Statistical significance testing and proper correlation interpretation

### **📈 Visualization and Insights** (Cells 11-13)

- Product performance analysis (best/worst performers within categories)
- **Interactive visualization**: Price vs Rating scatter plot with category coloring
- **Interactive visualization**: Heatmap showing rating distribution across price positions
- **Interactive visualization**: Multi-chart dashboard combining key metrics
- Actionable business insights and strategic recommendations

### **💡 Business Intelligence Output** (Cell 14)

- Category-specific correlation insights
- Strategic pricing recommendations based on data
- Value opportunity identification (sweet spots in price-quality relationship)
- Data-driven conclusions for business strategy

## 🚨 Troubleshooting

### **Lakehouse and Shortcut Issues**

- **Data not appearing**: Verify shortcuts are created correctly and pointing to the right Cosmos DB container
- **Query errors**: Check lakehouse and table names match your configuration in cell 4
- **Permission issues**: Ensure you have access to both the Cosmos DB artifact and lakehouse

### **Notebook Execution**

- **Import errors**: Run the package installation cell (cell 1) in Fabric environment first
- **Configuration errors**: Update cell 4 with your actual lakehouse and database names
- **No correlations found**: Verify adequate data volume and proper data relationships
- **Visualizations not displaying**: Ensure plotly is installed correctly (re-run cell 1 if needed)

### **Data Quality**

- **Unexpected correlation values**: Check for data quality issues (missing prices, invalid ratings)
- **Empty categories**: Some categories may have insufficient data for meaningful analysis
- **Outliers affecting results**: Review price ranges and consider filtering extreme values

## 🔄 Next Steps

After completing this sample, explore:

- **Advanced Analytics** - Machine learning predictions for pricing optimization using scikit-learn
- **Real-time Analytics** - Integrate streaming data with Event Streams in Fabric
- **Custom Visualizations** - Create additional Plotly charts for deeper insights
- **Multi-source Integration** - Combine with other Fabric data sources in your analysis
- **Export Insights** - Save processed data back to lakehouse for downstream consumption

## 📚 Additional Resources

- [📊 Fabric Lakehouse Documentation](https://docs.microsoft.com/fabric/data-engineering/lakehouse-overview)
- [🔗 Cosmos DB in Fabric Documentation](https://docs.microsoft.com/fabric/database/cosmos-db/)
- [🐍 Choosing between Python and PySpark Notebooks in Microsoft Fabric](https://docs.microsoft.com/fabric//data-engineering/fabric-notebook-selection-guide)
- [📈 Plotly Python Graphing Library](https://plotly.com/python/)
- [🔬 Pandas Correlation Analysis](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.corr.html)

## 🎯 Key Takeaways

1. **Cosmos DB shortcuts** provide seamless access to operational data in lakehouses
2. **Price-review correlations** reveal valuable business insights using category-relative analysis
3. **Spark SQL** offers powerful analytics capabilities for querying large datasets
4. **Python visualizations** with Plotly enable interactive exploratory data analysis  
5. **Category-relative pricing** provides more meaningful insights than static price bands
6. **Statistical analysis** within notebooks enables rapid iteration and insight discovery

---

*This sample demonstrates modern Python-based data analytics patterns in Microsoft Fabric, bridging operational Cosmos DB data with advanced correlation analysis and interactive visualizations.*
