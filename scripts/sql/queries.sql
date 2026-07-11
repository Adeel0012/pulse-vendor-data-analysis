-- ====================================================================
-- Pulse Vendor Data Analysis - Database Schema & Aggregation Views
-- Tool: PostgreSQL
-- Purpose: Staging and materializing analytical views for Power BI
-- ====================================================================

-- 1. Create staging table for raw invoice metrics to handle freight overhead
CREATE TABLE IF NOT EXISTS vendor_invoice (
    "VendorNumber" INT,
    "InvoiceNumber" VARCHAR(50),
    "InvoiceDate" DATE,
    "Freight" NUMERIC(10,2),
    "Taxes" NUMERIC(10,2)
);

-- 2. Create optimized index to accelerate ETL extraction join performance
CREATE INDEX IF NOT EXISTS idx_vendor_invoice_num 
ON vendor_invoice("VendorNumber");

-- 3. Materialize the final analytical table for the pipeline
-- This drops the old table if it exists and creates the clean "public_vendor_sales_summary" table
DROP TABLE IF EXISTS public_vendor_sales_summary;

CREATE TABLE public_vendor_sales_summary AS
WITH FreightSummary AS (
    SELECT 
        "VendorNumber", 
        SUM("Freight") AS "FreightCost" 
    FROM vendor_invoice 
    GROUP BY "VendorNumber"
),
PurchaseSummary AS (
    SELECT 
        p."VendorNumber", 
        p."VendorName", 
        p."Brand", 
        p."Description", 
        p."PurchasePrice",
        pp."Price" AS "ActualPrice", 
        pp."Volume",
        SUM(p."Quantity") AS "TotalPurchaseQuantity", 
        SUM(p."Dollars") AS "TotalPurchaseDollars"
    FROM purchases p 
    JOIN purchase_prices pp ON p."Brand" = pp."Brand" 
    WHERE p."PurchasePrice" > 0
    GROUP BY 
        p."VendorNumber", p."VendorName", p."Brand", p."Description", 
        p."PurchasePrice", pp."Price", pp."Volume"
),
SalesSummary AS (
    SELECT 
        "VendorNo", 
        "Brand", 
        SUM("SalesQuantity") AS "TotalSalesQuantity",
        SUM("SalesDollars") AS "TotalSalesDollars", 
        SUM("SalesPrice") AS "TotalSalesPrice", 
        SUM("ExciseTax") AS "TotalExciseTax"
    FROM sales 
    GROUP BY "VendorNo", "Brand"
)
SELECT 
    ps.*, 
    ss."TotalSalesQuantity", 
    ss."TotalSalesDollars", 
    ss."TotalSalesPrice", 
    ss."TotalExciseTax", 
    fs."FreightCost"
FROM PurchaseSummary ps
LEFT JOIN SalesSummary ss ON ps."VendorNumber" = ss."VendorNo" AND ps."Brand" = ss."Brand"
LEFT JOIN FreightSummary fs ON ps."VendorNumber" = fs."VendorNumber";

-- 4. Apply Primary Key constraint for structural integrity
ALTER TABLE public_vendor_sales_summary ADD PRIMARY KEY ("VendorNumber", "Brand");
