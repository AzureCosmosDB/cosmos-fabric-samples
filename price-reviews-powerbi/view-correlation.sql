-- ============================================================================
-- CREATE VIEW: Price-Review Correlation Analysis for Power BI
-- ============================================================================
-- Purpose: Create a SQL view in your Fabric Lakehouse SQL Analytics Endpoint
-- that performs the correlation analysis between product prices and customer
-- review ratings. This view calculates all components needed for computing
-- Pearson correlation coefficients in Power BI.
--
-- This is one of three SQL views for the Power BI dashboard:
-- • view-correlation.sql (THIS FILE) - Correlation analysis with category-relative pricing
-- • view-products.sql - Product dimension table for slicers and filtering
-- • view-price-review-changes.sql - Price and review changes over time for trend analysis
--
-- CORRELATION COEFFICIENT EXPLANATION:
-- The Pearson correlation coefficient (r) measures the linear relationship
-- between two variables. In this analysis, we're measuring how price relates
-- to customer ratings within each product category.
--
-- r = Σ[(Xi - X̄)(Yi - Ȳ)] / √[Σ(Xi - X̄)² × Σ(Yi - Ȳ)²]
--
-- Where:
-- • Xi = Individual product price
-- • X̄ = Average price in category
-- • Yi = Individual review rating
-- • Ȳ = Average rating in category
-- • (Xi - X̄) = PriceDeviation (calculated in this view)
-- • (Yi - Ȳ) = RatingDeviation (calculated in this view)
--
-- This view provides the building blocks (deviations, standard deviations,
-- means) that Power BI DAX measures will use to calculate the final
-- correlation coefficient for each category.
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
-- See the companion Power BI guide (README.md) for detailed instructions

-- Drop the view if it already exists
IF OBJECT_ID('{SCHEMA_NAME}.vw_PriceReviewCorrelation', 'V') IS NOT NULL
    DROP VIEW {SCHEMA_NAME}.vw_PriceReviewCorrelation;
GO

-- Create the view in the same schema as your data
CREATE VIEW {SCHEMA_NAME}.vw_PriceReviewCorrelation AS

WITH ProductReviews AS (
    -- =========================================================================
    -- CTE 1: Join Products with Reviews and Calculate Category-Relative Metrics
    -- =========================================================================
    -- This CTE combines product data with review data, creating one row per
    -- product-review combination. It calculates several category-relative
    -- price metrics that are essential for understanding price positioning
    -- and correlation analysis.
    --
    -- WHY THIS MATTERS FOR CORRELATION:
    -- - Correlation is calculated WITHIN each category to ensure fair comparison
    -- - A $1000 laptop shouldn't be compared to a $20 mouse
    -- - Category-relative metrics allow Power BI to show how price position
    --   within a category relates to customer satisfaction
    -- =========================================================================
    
    SELECT 
        -- =================================================================
        -- Product Identification
        -- =================================================================
        p.id as product_id,
        p.name as product_name,
        p.categoryName,
        p.currentPrice,
        p.inventory,
        
        -- =================================================================
        -- Review Identification
        -- =================================================================
        r.id as review_id,
        CAST(r.stars as FLOAT) as stars,
        r.customerName,
        r.reviewDate,
        YEAR(r.reviewDate) as review_year,
        MONTH(r.reviewDate) as review_month,
        DATENAME(MONTH, r.reviewDate) as review_month_name,
        
        -- =================================================================
        -- CORRELATION METRIC 1: Relative Price Position (0-1 Normalized Scale)
        -- =================================================================
        -- PURPOSE: Normalize prices within each category to 0-1 scale where:
        --   0 = Cheapest product in category
        --   1 = Most expensive product in category
        --   0.5 = Product at midpoint of category price range
        --
        -- FORMULA: (Price - CategoryMin) / (CategoryMax - CategoryMin)
        --
        -- WHY THIS IS CRITICAL FOR CORRELATION:
        -- - Enables comparison across categories with different price ranges
        -- - A product at 0.8 position in Computers vs 0.8 in Accessories
        --   both represent "expensive within their category"
        -- - Used in Power BI scatter plots to show price-rating relationship
        -- - NULLIF prevents division by zero for single-product categories
        --
        -- POWER BI USAGE: Tooltip showing "This product is priced at the 75th
        --                 percentile within its category"
        -- =================================================================
        (p.currentPrice - MIN(p.currentPrice) OVER (PARTITION BY p.categoryName)) / 
        NULLIF(MAX(p.currentPrice) OVER (PARTITION BY p.categoryName) - 
               MIN(p.currentPrice) OVER (PARTITION BY p.categoryName), 0) as RelativePricePosition,
        
        -- =================================================================
        -- CORRELATION METRIC 2: Price-to-Average Ratio
        -- =================================================================
        -- PURPOSE: Express each product's price as a ratio to category average
        --
        -- EXAMPLES:
        --   1.0 = Exactly average price
        --   1.5 = 50% more expensive than category average
        --   0.7 = 30% cheaper than category average
        --
        -- WHY THIS IS CRITICAL FOR CORRELATION:
        -- - Intuitive measure of price premium/discount
        -- - Used in Power BI tooltips: "This product costs 1.3x the category average"
        -- - Helps identify premium vs budget products
        -- - Independent of absolute price ranges
        --
        -- POWER BI USAGE: Conditional formatting to highlight products with
        --                 high price ratios but low ratings (poor value)
        -- =================================================================
        p.currentPrice / NULLIF(AVG(p.currentPrice) OVER (PARTITION BY p.categoryName), 0) as PriceToAvgRatio,
        
        -- =================================================================
        -- CORRELATION METRIC 3: Category Price Percentile (Statistical Rank)
        -- =================================================================
        -- PURPOSE: Statistical percentile rank of product price within category
        --
        -- RETURNS: 0.0 to 1.0 where:
        --   0.0 = Lowest priced product (0th percentile)
        --   0.25 = 25% of products are cheaper
        --   0.50 = Median price (50th percentile)
        --   0.75 = 75% of products are cheaper (upper quartile)
        --   1.0 = Highest priced product (100th percentile)
        --
        -- WHY THIS IS CRITICAL FOR CORRELATION:
        -- - More accurate than simple min-max normalization
        -- - Handles outliers better (extreme prices don't skew the scale)
        -- - Used to create quartile-based groupings in Power BI
        -- - Essential for binning products into price tiers
        --
        -- DIFFERENCE FROM RelativePricePosition:
        -- - RelativePricePosition uses actual price range (linear scale)
        -- - CategoryPricePercentile uses statistical ranking (handles outliers)
        --
        -- POWER BI USAGE: Create quartile slicers (Q1: Budget, Q2-Q3: Mid-range, Q4: Premium)
        -- =================================================================
        PERCENT_RANK() OVER (PARTITION BY p.categoryName ORDER BY p.currentPrice) as CategoryPricePercentile,
        
        -- =================================================================
        -- DESCRIPTIVE CATEGORIZATION: Satisfaction Level
        -- =================================================================
        -- PURPOSE: Classify customer satisfaction into actionable categories
        --
        -- BUSINESS SIGNIFICANCE:
        -- - 4-5 stars: Satisfied customers (likely to recommend)
        -- - 3 stars: Neutral (at-risk customers)
        -- - 1-2 stars: Dissatisfied (churn risk, negative word-of-mouth)
        --
        -- WHY NO ASSUMPTIONS:
        -- - Uses actual star values without predicting correlation
        -- - Categories are descriptive, not prescriptive
        -- - Power BI can aggregate reviews by satisfaction level
        --
        -- POWER BI USAGE: Filter visuals by satisfaction level to analyze
        --                 how pricing affects each customer segment
        -- =================================================================
        CASE 
            WHEN r.stars >= 4 THEN 'Satisfied (4-5 stars)'
            WHEN r.stars = 3 THEN 'Neutral (3 stars)'
            WHEN r.stars <= 2 THEN 'Dissatisfied (1-2 stars)'
            ELSE 'Unknown'
        END as SatisfactionLevel,
        
        -- =================================================================
        -- DESCRIPTIVE CATEGORIZATION: Price Position Category (Quartiles)
        -- =================================================================
        -- PURPOSE: Group products into 4 price tiers based on statistical quartiles
        --
        -- QUARTILE BREAKDOWN:
        -- - Bottom 25%: Budget tier (0-25th percentile)
        -- - 25-50%: Below average tier (25th-50th percentile)
        -- - 50-75%: Above average tier (50th-75th percentile)
        -- - Top 25%: Premium tier (75th-100th percentile)
        --
        -- WHY THIS IS CRITICAL FOR CORRELATION:
        -- - Allows analysis of correlation within price tiers
        -- - Question: "Do premium products get better reviews than budget?"
        -- - Used in Power BI grouped bar charts
        -- - Provides binned data for clearer trend visualization
        --
        -- POWER BI USAGE: Create a clustered column chart showing average
        --                 rating by price tier to visually identify correlation
        -- =================================================================
        CASE 
            WHEN PERCENT_RANK() OVER (PARTITION BY p.categoryName ORDER BY p.currentPrice) < 0.25 
                THEN 'Bottom 25% (Lowest Price)'
            WHEN PERCENT_RANK() OVER (PARTITION BY p.categoryName ORDER BY p.currentPrice) < 0.50 
                THEN '25-50% (Below Average)'
            WHEN PERCENT_RANK() OVER (PARTITION BY p.categoryName ORDER BY p.currentPrice) < 0.75 
                THEN '50-75% (Above Average)'
            ELSE 'Top 25% (Highest Price)'
        END as PricePositionCategory,
        
        -- =================================================================
        -- DESCRIPTIVE CATEGORIZATION: Value Assessment
        -- =================================================================
        -- PURPOSE: Classify products based on price-quality relationship
        --
        -- QUADRANT ANALYSIS:
        -- - Great Value: Above-average rating + Below-average price
        -- - Premium Quality: Above-average rating + Above-average price
        -- - Budget Option: Below-average rating + Below-average price
        -- - Poor Value: Below-average rating + Above-average price
        --
        -- WHY NO ASSUMPTIONS:
        -- - Uses actual data (not predicted correlation)
        -- - Compares each product to its category's averages
        -- - Helps identify outliers for investigation
        --
        -- BUSINESS SIGNIFICANCE:
        -- - Great Value products: Promote heavily, high customer satisfaction
        -- - Poor Value products: Investigate why (quality issues? overpriced?)
        -- - Premium Quality: Justify price through marketing
        -- - Budget Option: Expected trade-off, manage expectations
        --
        -- POWER BI USAGE: Conditional formatting to highlight "Poor Value"
        --                 products for pricing review
        -- =================================================================
        CASE 
            WHEN r.stars > AVG(CAST(r.stars as FLOAT)) OVER (PARTITION BY p.categoryName) 
                 AND p.currentPrice <= AVG(p.currentPrice) OVER (PARTITION BY p.categoryName) 
                THEN 'Great Value'
            WHEN r.stars > AVG(CAST(r.stars as FLOAT)) OVER (PARTITION BY p.categoryName)
                 AND p.currentPrice > AVG(p.currentPrice) OVER (PARTITION BY p.categoryName) 
                THEN 'Premium Quality'
            WHEN r.stars <= AVG(CAST(r.stars as FLOAT)) OVER (PARTITION BY p.categoryName)
                 AND p.currentPrice <= AVG(p.currentPrice) OVER (PARTITION BY p.categoryName) 
                THEN 'Budget Option'
            WHEN r.stars <= AVG(CAST(r.stars as FLOAT)) OVER (PARTITION BY p.categoryName)
                 AND p.currentPrice > AVG(p.currentPrice) OVER (PARTITION BY p.categoryName) 
                THEN 'Poor Value'
            ELSE 'Unclassified'
        END as ValueCategory,
        
        -- =================================================================
        -- STATISTICAL FOUNDATION: Category Aggregates for Correlation
        -- =================================================================
        -- These window functions calculate category-level statistics that are
        -- the building blocks for Pearson correlation coefficient calculation.
        --
        -- CRITICAL FOR CORRELATION FORMULA:
        -- These values feed into the correlation coefficient formula in Power BI:
        --   r = Σ[(Price - AvgPrice)(Rating - AvgRating)] / 
        --       √[Σ(Price - AvgPrice)² × Σ(Rating - AvgRating)²]
        -- =================================================================
        
        -- Average price within category (X̄ in correlation formula)
        AVG(p.currentPrice) OVER (PARTITION BY p.categoryName) as CategoryAvgPrice,
        
        -- Price range boundaries (used for normalization and outlier detection)
        MIN(p.currentPrice) OVER (PARTITION BY p.categoryName) as CategoryMinPrice,
        MAX(p.currentPrice) OVER (PARTITION BY p.categoryName) as CategoryMaxPrice,
        
        -- Average rating within category (Ȳ in correlation formula)
        AVG(CAST(r.stars as FLOAT)) OVER (PARTITION BY p.categoryName) as CategoryAvgRating,
        
        -- =================================================================
        -- STANDARD DEVIATIONS: Measure of Spread for Correlation
        -- =================================================================
        -- Standard deviation measures how spread out the data is from the mean.
        --
        -- WHY CRITICAL FOR CORRELATION:
        -- - Used in denominator of Pearson correlation formula
        -- - Low StdDev = Data clustered near average (less variation)
        -- - High StdDev = Data widely spread (more variation)
        -- - If StdDev = 0, correlation is undefined (all values identical)
        --
        -- POWER BI USAGE:
        -- - Categories with high PriceStdDev have wide price ranges
        -- - Categories with low RatingStdDev have consistent ratings
        -- - Used in DAX to calculate correlation coefficient
        -- =================================================================
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
    -- =========================================================================
    -- CTE 2: Calculate Deviations for Correlation Coefficient
    -- =========================================================================
    -- This CTE calculates the deviations from mean for both price and rating.
    -- These deviations are the core components of the Pearson correlation
    -- coefficient numerator.
    --
    -- CORRELATION FORMULA BREAKDOWN:
    -- The numerator of the Pearson r formula is:
    --   Σ[(Xi - X̄)(Yi - Ȳ)]
    --
    -- This CTE provides:
    --   (Xi - X̄) = PriceDeviation
    --   (Yi - Ȳ) = RatingDeviation
    --
    -- Power BI DAX will multiply these and sum them to get the numerator.
    --
    -- INTERPRETATION OF DEVIATIONS:
    -- - Positive PriceDeviation: Product is more expensive than category average
    -- - Negative PriceDeviation: Product is cheaper than category average
    -- - Positive RatingDeviation: Review is better than category average rating
    -- - Negative RatingDeviation: Review is worse than category average rating
    --
    -- CORRELATION SIGN INTERPRETATION:
    -- - If (PriceDeviation × RatingDeviation) is mostly positive:
    --   → Positive correlation (higher prices → higher ratings)
    -- - If (PriceDeviation × RatingDeviation) is mostly negative:
    --   → Negative correlation (higher prices → lower ratings)
    -- - If mixed (equal positive/negative products):
    --   → Near-zero correlation (no linear relationship)
    --
    -- POWER BI DAX MEASURE EXAMPLE:
    -- CorrelationCoefficient = 
    --   SUMX(
    --       vw_PriceReviewCorrelation,
    --       [PriceDeviation] * [RatingDeviation]
    --   ) / 
    --   SQRT(
    --       SUMX(vw_PriceReviewCorrelation, [PriceDeviation] ^ 2) *
    --       SUMX(vw_PriceReviewCorrelation, [RatingDeviation] ^ 2)
    --   )
    -- =========================================================================
    
    SELECT 
        *,
        -- =================================================================
        -- CORRELATION COMPONENT: Price Deviation from Category Mean
        -- =================================================================
        -- How much this product's price differs from the category average
        -- Positive = More expensive, Negative = Cheaper
        -- =================================================================
        (currentPrice - CategoryAvgPrice) as PriceDeviation,
        
        -- =================================================================
        -- CORRELATION COMPONENT: Rating Deviation from Category Mean
        -- =================================================================
        -- How much this review's rating differs from the category average
        -- Positive = Better rating, Negative = Worse rating
        -- =================================================================
        (stars - CategoryAvgRating) as RatingDeviation
    FROM ProductReviews
)
-- =============================================================================
-- FINAL SELECT: Output All Fields for Power BI
-- =============================================================================
-- This final SELECT statement outputs all calculated fields in a structure
-- optimized for Power BI consumption. Field names are user-friendly and
-- grouped logically for ease of use in the semantic model.
-- =============================================================================
SELECT 
    -- =========================================================================
    -- Product Dimension
    -- =========================================================================
    product_id as ProductID,
    product_name as ProductName,
    categoryName as Category,
    currentPrice as Price,
    inventory as Inventory,
    
    -- =========================================================================
    -- Review Dimension
    -- =========================================================================
    review_id as ReviewID,
    stars as Rating,
    customerName as Customer,
    reviewDate as ReviewDate,
    
    -- =========================================================================
    -- Time Dimension (for temporal analysis)
    -- =========================================================================
    review_year as ReviewYear,
    review_month as ReviewMonth,
    review_month_name as ReviewMonthName,
    
    -- =========================================================================
    -- KEY CORRELATION ANALYSIS FIELDS
    -- =========================================================================
    -- These are the primary metrics used in Power BI visuals and DAX measures
    -- to calculate and display correlation between price and ratings
    -- =========================================================================
    RelativePricePosition,          -- 0-1 normalized price within category
    PriceToAvgRatio,               -- Price as multiple of category average
    CategoryPricePercentile,       -- Statistical percentile (0-1)
    
    -- =========================================================================
    -- Category Statistics (Building Blocks for Correlation Formula)
    -- =========================================================================
    -- These aggregate values are repeated on every row to enable row-level
    -- calculations in Power BI without requiring separate aggregation tables
    -- =========================================================================
    CategoryAvgPrice,              -- X̄ (mean price in correlation formula)
    CategoryMinPrice,              -- Minimum price in category
    CategoryMaxPrice,              -- Maximum price in category
    CategoryAvgRating,             -- Ȳ (mean rating in correlation formula)
    CategoryPriceStdDev,           -- σx (price std dev in correlation formula)
    CategoryRatingStdDev,          -- σy (rating std dev in correlation formula)
    
    -- =========================================================================
    -- CORRELATION DEVIATIONS (Direct Inputs to Pearson r Formula)
    -- =========================================================================
    -- These are the most critical fields for correlation calculation in Power BI
    -- DAX measures will use these to compute the correlation coefficient
    -- =========================================================================
    PriceDeviation,                -- (Xi - X̄) - Price deviation from category mean
    RatingDeviation,               -- (Yi - Ȳ) - Rating deviation from category mean
    
    -- =========================================================================
    -- Descriptive Categories (For Filtering and Visual Grouping)
    -- =========================================================================
    SatisfactionLevel,             -- Satisfied / Neutral / Dissatisfied
    PricePositionCategory,         -- Quartile-based price tier
    ValueCategory                  -- Great Value / Premium / Budget / Poor Value

FROM CorrelationBase;
GO

-- ============================================================================
-- VERIFICATION: Test the view after creation
-- ============================================================================
-- Run these queries to verify the view was created successfully and contains
-- valid data for correlation analysis

-- Test 1: Sample data from each category
SELECT TOP 10 * FROM {SCHEMA_NAME}.vw_PriceReviewCorrelation 
ORDER BY Category, Price;
GO

-- Test 2: Verify row count and category distribution
SELECT 
    Category,
    COUNT(*) as ReviewCount,
    COUNT(DISTINCT ProductID) as ProductCount,
    MIN(Price) as MinPrice,
    MAX(Price) as MaxPrice,
    AVG(CAST(Rating as FLOAT)) as AvgRating
FROM {SCHEMA_NAME}.vw_PriceReviewCorrelation 
GROUP BY Category
ORDER BY Category;
GO

-- Test 3: Verify correlation components are calculated correctly
-- Check that deviations sum to approximately zero within each category
-- (mathematical property of deviations from mean)
SELECT 
    Category,
    SUM(PriceDeviation) as SumPriceDeviation,     -- Should be ~0
    SUM(RatingDeviation) as SumRatingDeviation,   -- Should be ~0
    AVG(CategoryPriceStdDev) as PriceStdDev,
    AVG(CategoryRatingStdDev) as RatingStdDev
FROM {SCHEMA_NAME}.vw_PriceReviewCorrelation 
GROUP BY Category
ORDER BY Category;
GO

-- Test 4: Sample calculation of correlation coefficient for one category
-- This demonstrates how Power BI DAX will calculate the final correlation
SELECT TOP 1
    Category,
    -- Numerator: Σ[(Xi - X̄)(Yi - Ȳ)]
    SUM(PriceDeviation * RatingDeviation) as Numerator,
    -- Denominator: √[Σ(Xi - X̄)² × Σ(Yi - Ȳ)²]
    SQRT(
        SUM(PriceDeviation * PriceDeviation) * 
        SUM(RatingDeviation * RatingDeviation)
    ) as Denominator,
    -- Correlation coefficient: r = Numerator / Denominator
    SUM(PriceDeviation * RatingDeviation) / 
    NULLIF(
        SQRT(
            SUM(PriceDeviation * PriceDeviation) * 
            SUM(RatingDeviation * RatingDeviation)
        ),
        0
    ) as CorrelationCoefficient
FROM {SCHEMA_NAME}.vw_PriceReviewCorrelation
GROUP BY Category
ORDER BY Category;
GO
