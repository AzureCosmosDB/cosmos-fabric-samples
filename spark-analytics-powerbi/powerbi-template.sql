-- Power BI Custom SQL Query Template for Price-Review Correlation Analysis
-- Based on SQL Analytics Notebook: Price-Review Correlation Analysis in Cosmos DB
-- 
-- Purpose: Create comprehensive Power BI dashboards showing how product pricing 
-- correlates with customer review ratings across different product categories.
-- This template aligns with the correlation patterns discovered in our analysis.
--
-- Expected Correlation Patterns (based on data analysis):
-- • Accessories: Strong POSITIVE correlation (r > 0.6) - higher prices = better ratings
-- • Devices: Strong NEGATIVE correlation (r < -0.3) - higher prices = lower ratings  
-- • Peripherals: Moderate POSITIVE correlation (0.3 ≤ r ≤ 0.6) - some price-quality relationship
-- • Computers: Weak/No correlation (|r| < 0.2) - price doesn't predict ratings
--
-- Connection Steps for Microsoft Fabric:
-- 1. Open Power BI Desktop
-- 2. Get Data → More → Microsoft Fabric → Warehouse (or SQL analytics endpoint)
-- 3. Enter your Fabric workspace URL or SQL analytics endpoint
-- 4. Select your lakehouse or warehouse
-- 5. Choose "Advanced options" and paste this query in "SQL statement" (optional)
-- 6. Use your Microsoft Account (same as your Fabric account)
--
-- Alternative Direct Connection (Recommended):
-- 1. Open Power BI Desktop  
-- 2. Get Data → More → Microsoft Fabric → Lakehouse
-- 3. Select your workspace and lakehouse
-- 4. Navigate to Tables and select your mirrored table
-- 5. Use Transform Data to apply filters if needed
--
-- For Custom SQL Analysis (Advanced):
-- 1. Use the Fabric SQL analytics endpoint connection
-- 2. Paste this query for advanced correlation analysis
-- 3. The query includes all calculated fields for dashboard creation

-- CONFIGURATION: Update with your actual Fabric lakehouse and database names
-- Replace these placeholders with your actual names:
-- {LAKEHOUSE_NAME} - Your Fabric lakehouse name (e.g., "cosmos_sample_lakehouse")
-- {DATABASE_NAME} - Your mirrored database name (e.g., "cosmos-sample-database") 
-- {TABLE_NAME} - Your table/container name (e.g., "SampleData")
-- 
-- Full table reference format: {LAKEHOUSE_NAME}.`{DATABASE_NAME}`.{TABLE_NAME}
-- Example: cosmos_sample_lakehouse.`cosmos-sample-database`.SampleData
-- Note: Backticks around database name handle special characters like hyphens

WITH ProductReviews AS (
    SELECT 
        p.id as product_id,
        p.name as product_name,
        p.categoryName,
        p.currentPrice,
        p.inventory,
        r.id as review_id,
        CAST(r.stars as FLOAT) as stars,
        r.customerName,
        r.reviewDate,
        YEAR(r.reviewDate) as review_year,
        MONTH(r.reviewDate) as review_month,
        DATENAME(MONTH, r.reviewDate) as review_month_name,
        
        -- Category-relative price analysis (matching notebook analysis)
        (p.currentPrice - MIN(p.currentPrice) OVER (PARTITION BY p.categoryName)) / 
        NULLIF(MAX(p.currentPrice) OVER (PARTITION BY p.categoryName) - MIN(p.currentPrice) OVER (PARTITION BY p.categoryName), 0) as RelativePricePosition,
        
        p.currentPrice / AVG(p.currentPrice) OVER (PARTITION BY p.categoryName) as PriceToAvgRatio,
        
        PERCENT_RANK() OVER (PARTITION BY p.categoryName ORDER BY p.currentPrice) as CategoryPricePercentile,
        
        -- Expected correlation type based on category patterns discovered in analysis
        CASE 
            WHEN p.categoryName LIKE 'Computers%' THEN 'None (|r| < 0.2)'
            WHEN p.categoryName LIKE 'Devices%' THEN 'Inverse (r < -0.3)' 
            WHEN p.categoryName LIKE 'Accessories%' THEN 'Strong Positive (r > 0.6)'
            WHEN p.categoryName LIKE 'Peripherals%' THEN 'Moderate Positive (0.3 ≤ r ≤ 0.6)'
            ELSE 'Unknown'
        END as ExpectedCorrelationType,
        
        -- Rating satisfaction levels
        CASE 
            WHEN r.stars >= 4 THEN 'Satisfied (4-5 stars)'
            WHEN r.stars = 3 THEN 'Neutral (3 stars)'
            ELSE 'Dissatisfied (1-2 stars)'
        END as SatisfactionLevel,
        
        -- Price position categories (matching notebook analysis)
        CASE 
            WHEN PERCENT_RANK() OVER (PARTITION BY p.categoryName ORDER BY p.currentPrice) < 0.25 THEN 'Bottom 25% (Lowest Price)'
            WHEN PERCENT_RANK() OVER (PARTITION BY p.categoryName ORDER BY p.currentPrice) < 0.50 THEN '25-50% (Below Average)'
            WHEN PERCENT_RANK() OVER (PARTITION BY p.categoryName ORDER BY p.currentPrice) < 0.75 THEN '50-75% (Above Average)'
            ELSE 'Top 25% (Highest Price)'
        END as PricePositionCategory,
        
        -- Value assessment (matching notebook's detailed product analysis)
        CASE 
            WHEN r.stars > AVG(CAST(r.stars as FLOAT)) OVER (PARTITION BY p.categoryName) 
                 AND p.currentPrice <= AVG(p.currentPrice) OVER (PARTITION BY p.categoryName) THEN 'Great Value'
            WHEN r.stars > AVG(CAST(r.stars as FLOAT)) OVER (PARTITION BY p.categoryName)
                 AND p.currentPrice > AVG(p.currentPrice) OVER (PARTITION BY p.categoryName) THEN 'Premium Quality'
            WHEN r.stars <= AVG(CAST(r.stars as FLOAT)) OVER (PARTITION BY p.categoryName)
                 AND p.currentPrice <= AVG(p.currentPrice) OVER (PARTITION BY p.categoryName) THEN 'Budget Option'
            ELSE 'Poor Value'
        END as ValueCategory,
        
        -- Statistical measures for correlation analysis
        AVG(p.currentPrice) OVER (PARTITION BY p.categoryName) as CategoryAvgPrice,
        MIN(p.currentPrice) OVER (PARTITION BY p.categoryName) as CategoryMinPrice,
        MAX(p.currentPrice) OVER (PARTITION BY p.categoryName) as CategoryMaxPrice,
        AVG(CAST(r.stars as FLOAT)) OVER (PARTITION BY p.categoryName) as CategoryAvgRating,
        STDEV(p.currentPrice) OVER (PARTITION BY p.categoryName) as CategoryPriceStdDev,
        STDEV(CAST(r.stars as FLOAT)) OVER (PARTITION BY p.categoryName) as CategoryRatingStdDev

    FROM {LAKEHOUSE_NAME}.`{DATABASE_NAME}`.{TABLE_NAME} p
    INNER JOIN {LAKEHOUSE_NAME}.`{DATABASE_NAME}`.{TABLE_NAME} r ON p.id = r.productId
    WHERE p.docType = 'product' 
      AND r.docType = 'review'
      AND p.currentPrice IS NOT NULL
      AND r.stars IS NOT NULL
      AND r.reviewDate IS NOT NULL
),
CorrelationBase AS (
    SELECT 
        *,
        -- Price vs rating deviation for correlation calculation
        (currentPrice - CategoryAvgPrice) as PriceDeviation,
        (stars - CategoryAvgRating) as RatingDeviation
    FROM ProductReviews
)
SELECT 
    -- Product Information
    product_id as ProductID,
    product_name as ProductName,
    categoryName as Category,
    currentPrice as Price,
    inventory as Inventory,
    
    -- Review Information  
    review_id as ReviewID,
    stars as Rating,
    customerName as Customer,
    reviewDate as ReviewDate,
    
    -- Time Analysis
    review_year as ReviewYear,
    review_month as ReviewMonth,
    review_month_name as ReviewMonthName,
    
    -- KEY CORRELATION ANALYSIS FIELDS (matching notebook analysis)
    RelativePricePosition,          -- 0-1 scale within each category
    PriceToAvgRatio,               -- Ratio to category average (1.5 = 50% above average)
    CategoryPricePercentile,       -- Percentile rank within category (0-1)
    ExpectedCorrelationType,       -- Expected correlation pattern based on category
    
    -- Category Statistics for Correlation Calculation
    CategoryAvgPrice,
    CategoryMinPrice,
    CategoryMaxPrice,
    CategoryAvgRating,
    CategoryPriceStdDev,
    CategoryRatingStdDev,
    
    -- Price-Rating Deviations for Correlation
    PriceDeviation,
    RatingDeviation,
    
    -- Analysis Categories (matching notebook's classification)
    SatisfactionLevel,
    PricePositionCategory,         -- Matches notebook's 4-tier price positioning
    ValueCategory                  -- Matches notebook's value assessment

FROM CorrelationBase
ORDER BY categoryName, currentPrice;

-- ============================================================================
-- POWER BI DASHBOARD CREATION GUIDE
-- ============================================================================
-- After importing this data into Power BI, create these visualizations to 
-- showcase the price-review correlation patterns discovered in our analysis:

-- 📊 ESSENTIAL CORRELATION VISUALIZATIONS:

-- 1. 🎯 CORRELATION STRENGTH BY CATEGORY (Key Insight Chart)
--    Visual: Clustered Bar Chart
--    X-axis: Category
--    Y-axis: Correlation Coefficient (create measure below)
--    Color: ExpectedCorrelationType
--    Purpose: Shows which categories have strong price-quality relationships

-- 2. 📈 PRICE VS RATING SCATTER (Core Analysis)
--    Visual: Scatter Chart with Small Multiples
--    X-axis: Price
--    Y-axis: Rating  
--    Small Multiples: Category
--    Trend Line: Enabled
--    Purpose: Visualizes the actual correlation patterns within each category

-- 3. 🔄 CATEGORY-RELATIVE PRICE POSITION ANALYSIS
--    Visual: Line Chart
--    X-axis: PricePositionCategory (Bottom 25%, 25-50%, 50-75%, Top 25%)
--    Y-axis: Average Rating
--    Legend: Category
--    Purpose: Shows how ratings change by relative price position

-- 4. 💎 VALUE CATEGORY DISTRIBUTION
--    Visual: Stacked Bar Chart
--    X-axis: Category
--    Y-axis: Count of Reviews
--    Legend: ValueCategory (Great Value, Premium Quality, Budget Option, Poor Value)
--    Purpose: Identifies value opportunities and problem areas

-- 5. 🎨 CORRELATION HEATMAP
--    Visual: Matrix
--    Rows: Category
--    Columns: PricePositionCategory
--    Values: Average Rating
--    Color: Conditional formatting (Green=High, Red=Low)
--    Purpose: Quick visual of performance across price tiers

-- 📈 SUPPORTING ANALYSIS VISUALS:

-- 6. 📊 PRICE DISTRIBUTION BY CATEGORY
--    Visual: Box and Whisker Plot (if available) or Violin Chart
--    Category: Category
--    Values: Price
--    Purpose: Shows price range and distribution differences between categories

-- 7. 🏆 TOP/BOTTOM PERFORMERS
--    Visual: Table
--    Columns: ProductName, Category, Price, Rating, ValueCategory
--    Filters: Top 10 by Rating, Bottom 10 by Rating
--    Purpose: Identifies specific products that break correlation patterns

-- 8. 📅 TEMPORAL CORRELATION TRENDS
--    Visual: Line Chart
--    X-axis: ReviewDate (by Month/Quarter)
--    Y-axis: Average Rating
--    Legend: PricePositionCategory
--    Slicer: Category
--    Purpose: Shows if price-quality relationships change over time

-- 🎛️ INTERACTIVE FILTERS AND SLICERS:

-- 9. Category Slicer (Multi-select)
-- 10. ExpectedCorrelationType Slicer  
-- 11. ReviewYear Slicer
-- 12. PricePositionCategory Slicer
-- 13. SatisfactionLevel Slicer

-- 📏 CRITICAL DAX MEASURES TO CREATE:

-- Correlation Coefficient by Category:
-- CorrelationCoeff = 
-- VAR CurrentCategory = SELECTEDVALUE(Data[Category])
-- VAR CategoryData = FILTER(Data, Data[Category] = CurrentCategory)
-- VAR SumXY = SUMX(CategoryData, [PriceDeviation] * [RatingDeviation])
-- VAR SumX2 = SUMX(CategoryData, [PriceDeviation] * [PriceDeviation])
-- VAR SumY2 = SUMX(CategoryData, [RatingDeviation] * [RatingDeviation])
-- VAR N = COUNTROWS(CategoryData)
-- RETURN 
-- IF(SumX2 = 0 || SumY2 = 0, BLANK(), SumXY / SQRT(SumX2 * SumY2))

-- Correlation Strength Classification:
-- CorrelationStrength = 
-- VAR Corr = [CorrelationCoeff]
-- RETURN 
-- IF(ISBLANK(Corr), "No Data",
--    IF(ABS(Corr) >= 0.7, "Strong",
--       IF(ABS(Corr) >= 0.4, "Moderate", 
--          IF(ABS(Corr) >= 0.2, "Weak", "Very Weak/None"))))

-- Price Premium Indicator:
-- PricePremium = 
-- IF([PriceToAvgRatio] > 1.2, "Premium (+20%)",
--    IF([PriceToAvgRatio] > 1.1, "Above Average (+10%)",
--       IF([PriceToAvgRatio] < 0.8, "Budget (-20%)",
--          IF([PriceToAvgRatio] < 0.9, "Below Average (-10%)", "Average"))))

-- Rating Performance vs Price:
-- RatingVsPrice = 
-- IF([Rating] >= 4 && [PriceToAvgRatio] > 1.1, "High Rating, High Price",
--    IF([Rating] >= 4 && [PriceToAvgRatio] < 0.9, "High Rating, Low Price",
--       IF([Rating] <= 2 && [PriceToAvgRatio] > 1.1, "Low Rating, High Price",
--          IF([Rating] <= 2 && [PriceToAvgRatio] < 0.9, "Low Rating, Low Price", "Mixed"))))

-- Category Performance Score:
-- CategoryPerformanceScore = 
-- VAR AvgRating = AVERAGE(Data[Rating])
-- VAR CorrelationScore = IF(ABS([CorrelationCoeff]) >= 0.6, 3, IF(ABS([CorrelationCoeff]) >= 0.3, 2, 1))
-- VAR RatingScore = IF(AvgRating >= 4, 3, IF(AvgRating >= 3, 2, 1))
-- RETURN CorrelationScore + RatingScore

-- 🎯 DASHBOARD LAYOUT RECOMMENDATIONS:

-- PAGE 1: CORRELATION OVERVIEW
-- • Title: "Price-Review Correlation Analysis Dashboard"
-- • Top Row: Correlation Coefficient by Category (Bar Chart) + Key Metrics Cards
-- • Middle: Price vs Rating Scatter (Small Multiples by Category)
-- • Bottom: Category filters and ExpectedCorrelationType breakdown

-- PAGE 2: CATEGORY DEEP-DIVE
-- • Category slicer at top
-- • Price Position Analysis (Line Chart)
-- • Value Category Distribution (Stacked Bar)
-- • Top/Bottom Performers (Table)

-- PAGE 3: TEMPORAL ANALYSIS
-- • Time-based correlation trends
-- • Month/Quarter filters
-- • Rating trends over time by price tier

-- 💡 ANALYSIS INSIGHTS TO HIGHLIGHT:
-- • Accessories show strong positive correlation - premium pricing justified
-- • Devices show inverse correlation - higher prices hurt satisfaction
-- • Computers show weak correlation - price isn't a quality indicator
-- • Peripherals show moderate correlation - some price-quality relationship

-- 🚨 IMPORTANT CONFIGURATION NOTES:
-- 1. Replace {LAKEHOUSE_NAME}, {DATABASE_NAME}, {TABLE_NAME} with your actual values
-- 2. Ensure date formats are properly configured for temporal analysis
-- 3. Set up proper relationships if using multiple queries
-- 4. Configure conditional formatting colors to match correlation strength
-- 5. Test all DAX measures with your actual data structure