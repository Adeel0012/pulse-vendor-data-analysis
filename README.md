# pulse-vendor-data-analysis
End-to-end data analysis pipeline evaluating vendor performance and sales metrics. Features an interactive Power BI executive dashboard built on data processed via Python and PostgreSQL to deliver actionable commercial insights.

# Pulse Vendor Data Analysis & Executive Dashboard

## 📊 Project Overview
This project delivers an end-to-end data analysis pipeline designed to track core commercial metrics, evaluate vendor performance, and optimize inventory distribution. By leveraging Python and PostgreSQL for data handling and Power BI for visualization, this solution transforms raw logistics and transaction records into actionable executive insights.



https://github.com/user-attachments/assets/e64d1bcb-eca1-4dda-ae94-6b12e4df0328


## 🛠️ Key Features & Technical Implementations
* **Multi-Tool Integration:** Cleaned and structured transactional data using Python and PostgreSQL before importing it into Power BI for presentation.
* **Dynamic KPI Tracking:** Engineered custom DAX measures to ensure mathematically sound calculations across total revenue, total costs, and profit margins.
* **Top-N Performance Analysis:** Implemented optimized visual-level filters to highlight the **Top 5 Sold Items** and **Top 5 Vendors** by revenue generation dynamically.
* **Interactive Slicing & Contextual Filtering:** Configured multi-level dropdown slicers (`Brand`, `Description`, `VendorName`) allowing stakeholders to instantly isolate performance vectors.

## 🧮 Custom DAX Calculations Used
To maintain exact calculation fidelity across visual filters, explicit DAX measures were built rather than relying on implicit column aggregates:

📈 Business Insights Delivered
Product Optimization: Instantly isolates the highest-velocity items by unit quantity to prevent stockouts on top-tier inventory.

Vendor Analysis: Identifies the top 5 revenue-driving vendors to strengthen supplier relationships and negotiate better bulk pricing.

Data-Driven Slicing: Empowers regional and product managers to filter by specific brands or items to evaluate localized inventory performance.
