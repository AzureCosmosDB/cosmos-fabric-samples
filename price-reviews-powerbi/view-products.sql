-- ============================================================================
-- CREATE VIEW: Product List for Power BI Semantic Model
-- ============================================================================
-- Purpose: Create a SQL view in your Fabric Lakehouse SQL Analytics Endpoint
-- that provides a clean list of products for use in the Power BI semantic model
-- and report. This view serves as the source for product filtering and individual
-- product details within the dashboard.
--
-- This is one of three SQL views for the Power BI dashboard:
-- • view-correlation.sql - Correlation analysis with category-relative pricing
-- • view-products.sql (THIS FILE) - Product dimension table for slicers and filtering
-- • view-price-review-changes.sql - Price and review changes over time for trend analysis
--
-- Use Cases:
-- • Product dimension table in semantic model relationships
-- • Slicer/filter source for product selection in reports
-- • Product detail cards and tooltips
-- • Product-level drill-through pages
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
-- 8. Repeat for all SQL view files: view-correlation.sql, view-price-review-changes.sql
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
IF OBJECT_ID('{SCHEMA_NAME}.vw_Products', 'V') IS NOT NULL
    DROP VIEW {SCHEMA_NAME}.vw_Products;
GO

-- Create the view in the same schema as your data
CREATE VIEW {SCHEMA_NAME}.vw_Products AS

    SELECT 
        p.id as ProductID,
        p.name as ProductName,
        p.categoryName as Category
    FROM 
        {SCHEMA_NAME}.{TABLE_NAME} p
    WHERE
        p.docType = 'product';
GO

-- ============================================================================
-- VERIFICATION: Test the view after creation
-- ============================================================================
-- Run this query to verify the view was created successfully:
SELECT TOP 10 * FROM {SCHEMA_NAME}.vw_Products;
GO

-- Check row count:
SELECT COUNT(*) as TotalRows FROM {SCHEMA_NAME}.vw_Products;
GO
