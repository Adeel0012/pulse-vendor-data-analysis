-- ====================================================================
-- Pulse Vendor Data Analysis - Full Database Schema & Materialization
-- Tool: PostgreSQL
-- Purpose: Creating core tables, indexing, and calculating metrics
-- ====================================================================

-- 1. Structural Staging Layer: Sales Records
CREATE TABLE IF NOT EXISTS sales (
    "VendorNo" INT,
    "Brand" INT,
    "SalesQuantity" INT,
    "SalesDollars" NUMERIC(15,2),
    "SalesPrice" NUMERIC(15,2),
    "ExciseTax" NUMERIC(15,2)
);

CREATE INDEX IF NOT EXISTS idx_sales_composite ON sales("VendorNo", "Brand");

-- 2. Structural Staging Layer: Purchase Logs
CREATE TABLE IF NOT EXISTS purchases (
    "VendorNumber" INT,
    "VendorName" VARCHAR(150),
    "Brand" INT,
    "Description" VARCHAR(255),
    "PurchasePrice" NUMERIC(10,2),
    "Quantity" INT,
    "Dollars" NUMERIC(15,2)
);

CREATE INDEX IF NOT EXISTS idx_purchases_composite ON purchases("VendorNumber", "Brand");

-- 3. Structural Staging Layer: Purchase Prices Catalog
CREATE TABLE IF NOT EXISTS purchase_prices (
    "Brand" INT PRIMARY KEY,
    "Price" NUMERIC(10,2),
    "Volume" NUMERIC(10,2)
);

-- 4. Structural Staging Layer: Vendor Invoices & Freight
CREATE TABLE IF NOT EXISTS vendor_invoice (
    "VendorNumber" INT,
    "InvoiceNumber" VARCHAR(50),
    "InvoiceDate" DATE,
    "Freight" NUMERIC(10,2),
    "Taxes" NUMERIC(10,2)
);

CREATE INDEX IF NOT EXISTS idx_vendor_invoice_num ON vendor_invoice("VendorNumber");

-- ====================================================================
-- 5. Production Materialization Pipeline
-- ====================================================================
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

-- Apply Primary Key constraint for structural integrity
ALTER TABLE public_vendor_sales_summary ADD PRIMARY KEY ("VendorNumber", "Brand");
