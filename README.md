# Pulse Vendor Data Analysis & Executive Dashboard

## 📊 Project Overview
This project delivers a robust, end-to-end data science and engineering pipeline designed to evaluate vendor performance, track core commercial metrics, and optimize supply-chain distribution layers. By establishing a fully programmatic data flow using **Python (Pandas & SQLAlchemy)**, staging and processing structural layers in **PostgreSQL**, and engineering a high-fidelity interactive dashboard in **Power BI**, this solution transforms raw operational logs into highly actionable executive summaries.



https://github.com/user-attachments/assets/3a455717-e384-4ef1-8f79-028c139a5ffb


## ⚙️ Data Pipeline Architecture & Engineering

The project infrastructure coordinates data across a complete ETL (Extract, Transform, Load) cycle to guarantee data integrity, relational consistency, and optimized reporting speeds:

1. **Extraction & Relational Database Design (`SQL`):** 
   Raw staging layers (`sales`, `purchases`, `purchase_prices`, and `vendor_invoice`) are generated and structured natively with optimized indexing to accelerate connection queries. A production-level analytical view utilizes **Common Table Expressions (CTEs)** to aggregate separate transaction frameworks into a unified summary profile.
   * *View source schemas and indexing in the [`sql/queries.sql`](sql/queries.sql) file.*
2. **Transformation and KPI Fabrication (`Python`):** 
   Using Pandas, data types are cleanly cast, trailing white spaces are stripped, missing features are handled natively, and programmatic safety checks are instituted to completely neutralize zero-division calculation crashes. Custom pipeline logic computes multi-source performance metrics (`ProfitMargin`, `StockTurnover`, and `SalestoPurchaseRatio`).
   * *View source pipeline architecture in the [`scripts/etl_pipeline.py`](scripts/etl_pipeline.py) file.*
3. **Loading and Constraints Application (`PostgreSQL`):** 
   The refined analytics dataframe is written directly back into a production database table (`public_vendor_sales_summary`) using explicit SQLAlchemy strict type mapping (`Numeric`, `Integer`, `String`). Upon write completion, an automated statement applies a unified **Composite Primary Key** (`VendorNumber`, `Brand`) to enforce database constraint rules and relational durability.

## 🛠️ Key Features & Technical Implementations
* **Multi-Tool Integration:** Cleaned and structured transactional data using Python and PostgreSQL before importing it into Power BI for presentation.
* **Dynamic KPI Tracking:** Engineered custom DAX measures to ensure mathematically sound calculations across total revenue, total costs, and profit margins.
* **Top-N Performance Analysis:** Implemented optimized visual-level filters to highlight the **Top 5 Sold Items** and **Top 5 Vendors** by revenue generation dynamically.
* **Interactive Slicing & Contextual Filtering:** Configured multi-level dropdown slicers (`Brand`, `Description`, `VendorName`) allowing stakeholders to instantly isolate performance vectors.

## 🧮 Custom DAX Calculations Used
To maintain exact calculation fidelity across visual filters, explicit DAX measures were built rather than relying on implicit column aggregates.

📈 Business Insights Delivered
Product Optimization: Instantly isolates the highest-velocity items by unit quantity to prevent stockouts on top-tier inventory.

Vendor Analysis: Identifies the top 5 revenue-driving vendors to strengthen supplier relationships and negotiate better bulk pricing.

Data-Driven Slicing: Empowers regional and product managers to filter by specific brands or items to evaluate localized inventory performance.
