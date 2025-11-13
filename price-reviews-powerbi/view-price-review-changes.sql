-- ============================================================================
-- CREATE VIEW: Price and Review Score Changes Over Time for Power BI
-- ============================================================================
-- Purpose: Create a SQL view in your Fabric Lakehouse SQL Analytics Endpoint
-- that tracks changes in product prices and review scores over time. This view
-- serves as the data source for visualizing the relationship between pricing
-- decisions and customer satisfaction trends.
--
-- Use Cases:
-- • Visualize price changes and review score trends on the same timeline
-- • Study individual product performance when deciding on price adjustments
-- • Analyze correlation between price changes and review score changes
-- • Optimize revenue by understanding price-satisfaction relationships
-- • Identify products where price changes impacted customer ratings
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
-- 8. Repeat for all SQL view files in this folder (view-correlation.sql, view-products.sql, etc.)
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
IF OBJECT_ID('{SCHEMA_NAME}.vw_PriceReviewChanges', 'V') IS NOT NULL
    DROP VIEW {SCHEMA_NAME}.vw_PriceReviewChanges;
GO

-- Create the view in the same schema as your data
CREATE OR ALTER VIEW {SCHEMA_NAME}.vw_PriceReviewChanges AS
WITH PriceRaw AS (
    SELECT
        p.id AS ProductID,
        CAST(
            COALESCE(
                TRY_CAST(ph.[date] AS datetime2),
                TRY_CAST(SWITCHOFFSET(TRY_CAST(ph.[date] AS datetimeoffset), '+00:00') AS datetime2)
            ) AS date
        ) AS EventDate,
        TRY_CAST(ph.[price] AS decimal(18,2)) AS Price
    FROM {SCHEMA_NAME}.{TABLE_NAME} AS p
    CROSS APPLY OPENJSON(p.priceHistory)
    WITH (
        [price] decimal(38,10) '$.price',
        [date]  nvarchar(64)   '$.date'
    ) AS ph
    WHERE p.docType = 'product'
      AND ph.[date]  IS NOT NULL
      AND ph.[price] IS NOT NULL
),
PriceDaily AS (
    SELECT ProductID, EventDate, AVG(Price) AS Price
    FROM PriceRaw
    GROUP BY ProductID, EventDate
),
PriceChanges AS (
    SELECT
        ProductID,
        EventDate,
        Price,
        CASE
            WHEN LAG(Price) OVER (PARTITION BY ProductID ORDER BY EventDate) IS NULL
                 OR Price <> LAG(Price) OVER (PARTITION BY ProductID ORDER BY EventDate)
            THEN 1 ELSE 0
        END AS IsPriceChange
    FROM PriceDaily
),
ReviewsRaw AS (
    SELECT
        r.productId AS ProductID,
        CAST(
            COALESCE(
                TRY_CAST(r.reviewDate AS datetime2),
                TRY_CAST(SWITCHOFFSET(TRY_CAST(r.reviewDate AS datetimeoffset), '+00:00') AS datetime2)
            ) AS date
        ) AS EventDate,
        TRY_CAST(r.stars AS decimal(9,2)) AS Stars
    FROM {SCHEMA_NAME}.{TABLE_NAME} AS r
    WHERE r.docType = 'review'
      AND r.reviewDate IS NOT NULL
      AND r.stars      IS NOT NULL
),
ReviewsDaily AS (
    SELECT
        ProductID,
        EventDate,
        SUM(Stars) AS SumStars,
        COUNT(*)   AS CntReviews
    FROM ReviewsRaw
    GROUP BY ProductID, EventDate
),
ReviewsCum AS (
    SELECT
        ProductID,
        EventDate,
        SUM(SumStars)  OVER (PARTITION BY ProductID ORDER BY EventDate
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumSumStars,
        SUM(CntReviews) OVER (PARTITION BY ProductID ORDER BY EventDate
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumCntReviews
    FROM ReviewsDaily
),
EventsFromPrice AS (
    SELECT
        pc.ProductID,
        pc.EventDate,
        CAST(1.0 * rc.CumSumStars / rc.CumCntReviews AS decimal(9,4)) AS Stars,
        CAST(pc.Price AS decimal(18,2)) AS Price
    FROM PriceChanges pc
    CROSS APPLY (
        SELECT TOP (1) rc.CumSumStars, rc.CumCntReviews
        FROM ReviewsCum rc
        WHERE rc.ProductID = pc.ProductID
          AND rc.EventDate <= pc.EventDate
          AND rc.CumCntReviews > 0
        ORDER BY rc.EventDate DESC
    ) rc
    WHERE pc.IsPriceChange = 1
),
EventsFromStars AS (
    SELECT
        rc.ProductID,
        rc.EventDate,
        CAST(1.0 * rc.CumSumStars / rc.CumCntReviews AS decimal(9,4)) AS Stars,
        CAST(pd.Price AS decimal(18,2)) AS Price
    FROM (
        SELECT
            ProductID, EventDate, CumSumStars, CumCntReviews,
            CASE
                WHEN LAG(CumSumStars * 1.0 / NULLIF(CumCntReviews,0))
                     OVER (PARTITION BY ProductID ORDER BY EventDate)
                     <> (CumSumStars * 1.0 / NULLIF(CumCntReviews,0))
                THEN 1
                ELSE CASE WHEN LAG(CumCntReviews) OVER (PARTITION BY ProductID ORDER BY EventDate) IS NULL THEN 1 ELSE 0 END
            END AS IsStarsChange
        FROM ReviewsCum
        WHERE CumCntReviews > 0
    ) rc
    CROSS APPLY (
        SELECT TOP (1) pd.Price
        FROM PriceDaily pd
        WHERE pd.ProductID = rc.ProductID
          AND pd.EventDate <= rc.EventDate
        ORDER BY pd.EventDate DESC
    ) pd
    WHERE rc.IsStarsChange = 1
)
SELECT ProductID, EventDate AS [Date], Stars, Price
FROM EventsFromPrice
UNION
SELECT ProductID, EventDate AS [Date], Stars, Price
FROM EventsFromStars;
GO

-- ============================================================================
-- VERIFICATION: Test the view after creation
-- ============================================================================
-- Run this query to verify the view was created successfully:
SELECT TOP 10 * FROM {SCHEMA_NAME}.vw_PriceReviewChanges ORDER BY ProductID, [Date];
GO

-- Check row count:
SELECT COUNT(*) as TotalRows FROM {SCHEMA_NAME}.vw_PriceReviewChanges;
GO

-- Check products with changes:
SELECT ProductID, COUNT(*) as ChangeCount 
FROM {SCHEMA_NAME}.vw_PriceReviewChanges 
GROUP BY ProductID 
ORDER BY ChangeCount DESC;
GO