-- ============================================================================
-- CREATE VIEW: Price-Review Correlation Analysis for Power BI
-- ============================================================================
-- Purpose: Create a SQL view in your Fabric Lakehouse SQL Analytics Endpoint
-- that performs the correlation analysis, then use this view as a data source
-- in Power BI for building dashboards.
--
-- This is one of three SQL views for the Power BI dashboard:
-- • view-correlation.sql (THIS FILE) - Correlation analysis with category-relative pricing
-- • view-products.sql - Product dimension table for slicers and filtering
-- • view-price-review-changes.sql - Price and review changes over time for trend analysis
--
-- Expected Correlation Patterns (based on data analysis):
-- • Accessories: Strong POSITIVE correlation (r > 0.6) - higher prices = better ratings
-- • Devices: Strong NEGATIVE correlation (r < -0.3) - higher prices = lower ratings  
-- • Peripherals: Moderate POSITIVE correlation (0.3 ≤ r ≤ 0.6) - some price-quality relationship
-- • Computers: Weak/No correlation (|r| < 0.2) - price doesn't predict ratings
-- ============================================================================
-- -------------------------------------------------------------------------
-- STEP 1: Execute this SQL in your Lakehouse SQL Analytics Endpoint
-- -------------------------------------------------------------------------
-- 1. Open your Fabric workspace in the browser
-- 2. Navigate to your Lakehouse
-- 3. Click "SQL analytics endpoint" in the top-right corner
-- 4. Click "New SQL query" button
-- 5. Replace the placeholders throughout this script:
--    • {SCHEMA_NAME} - Your schema name (e.g., "CosmosSampleDatabase")
--    • {TABLE_NAME} - Your table/container name (e.g., "SampleData")
-- 6. Paste the modified script and click "Run"
-- 7. Verify the view was created successfully
-- 8. Repeat for all SQL view files: view-products.sql, view-price-review-changes.sql
--
-- STEP 2: Create Semantic Model from Lakehouse
-- -------------------------------------------------------------------------
-- 1. In your Fabric workspace, navigate to your Lakehouse
-- 2. In the Lakehouse, click "New semantic model" button
-- 3. Select all three views: vw_PriceReviewCorrelation, vw_Products, vw_PriceReviewChanges
-- 4. Click "Confirm" to create the semantic model
-- 5. Open the semantic model to build relationships between views
-- 6. Create DAX measures for your analysis in Power BI
--
-- See the companion Power BI guide (powerbi-dax-guide.md) for detailed instructions

-- Drop the view if it already exists
IF OBJECT_ID('{SCHEMA_NAME}.vw_PriceReviewCorrelation', 'V') IS NOT NULL
    DROP VIEW {SCHEMA_NAME}.vw_PriceReviewCorrelation;
GO

-- Create the view in the same schema as your data
CREATE VIEW {SCHEMA_NAME}.vw_PriceReviewCorrelation AS

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

    FROM {SCHEMA_NAME}.{TABLE_NAME} p
    INNER JOIN {SCHEMA_NAME}.{TABLE_NAME} r ON p.id = r.productId
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

FROM CorrelationBase;
GO

-- ============================================================================
-- VERIFICATION: Test the view after creation
-- ============================================================================
-- Run this query to verify the view was created successfully:
SELECT TOP 10 * FROM {SCHEMA_NAME}.vw_PriceReviewCorrelation ORDER BY Category, Price;
GO

-- Check row count:
SELECT COUNT(*) as TotalRows FROM {SCHEMA_NAME}.vw_PriceReviewCorrelation;
GO

-- Check categories:
SELECT Category, COUNT(*) as ReviewCount 
FROM {SCHEMA_NAME}.vw_PriceReviewCorrelation 
GROUP BY Category 
ORDER BY Category;
GO
