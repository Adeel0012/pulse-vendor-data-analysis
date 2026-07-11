import os
import sys
import logging
import numpy as np
import pandas as pd
from sqlalchemy import text
from sqlalchemy.types import Integer, String, Numeric

# Route path headers for modular execution
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config.settings import LOG_FILE, LOGS_DIR, TARGET_ANALYTICS_TABLE
from src.connector import get_db_engine

def setup_logging():
    if not os.path.exists(LOGS_DIR):
        os.makedirs(LOGS_DIR)
    for handler in logging.root.handlers[:]:
        logging.root.removeHandler(handler)
        
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[logging.FileHandler(LOG_FILE, encoding='utf-8'), logging.StreamHandler()]
    )
    logging.info("--- Modular ETL Pipeline Execution Started ---")

def extract(engine):
    logging.info("Extracting transactional staging components from database...")
    cte_query = """
    WITH FreightSummary AS (
        SELECT "VendorNumber", SUM("Freight") AS "FreightCost" FROM vendor_invoice GROUP BY "VendorNumber"
    ),
    PurchaseSummary AS (
        SELECT p."VendorNumber", p."VendorName", p."Brand", p."Description", p."PurchasePrice",
               pp."Price" AS "ActualPrice", pp."Volume",
               SUM(p."Quantity") AS "TotalPurchaseQuantity", SUM(p."Dollars") AS "TotalPurchaseDollars"
        FROM purchases p JOIN purchase_prices pp ON p."Brand" = pp."Brand" WHERE p."PurchasePrice" > 0
        GROUP BY p."VendorNumber", p."VendorName", p."Brand", p."Description", p."PurchasePrice", pp."Price", pp."Volume"
    ),
    SalesSummary AS (
        SELECT "VendorNo", "Brand", SUM("SalesQuantity") AS "TotalSalesQuantity",
               SUM("SalesDollars") AS "TotalSalesDollars", SUM("SalesPrice") AS "TotalSalesPrice", SUM("ExciseTax") AS "TotalExciseTax"
        FROM sales GROUP BY "VendorNo", "Brand"
    )
    SELECT ps.*, ss."TotalSalesQuantity", ss."TotalSalesDollars", ss."TotalSalesPrice", ss."TotalExciseTax", fs."FreightCost"
    FROM PurchaseSummary ps
    LEFT JOIN SalesSummary ss ON ps."VendorNumber" = ss."VendorNo" AND ps."Brand" = ss."Brand"
    LEFT JOIN FreightSummary fs ON ps."VendorNumber" = fs."VendorNumber"
    """
    return pd.read_sql_query(text(cte_query), engine)

def transform(df):
    logging.info("Transforming operational metrics and calculating custom KPIs...")
    df_clean = df.copy()
    df_clean['Volume'] = df_clean['Volume'].astype('float64')
    df_clean['VendorName'] = df_clean['VendorName'].str.strip().fillna("Unknown")
    df_clean.fillna(0, inplace=True)
    
    df_clean['GrossProfit'] = df_clean['TotalSalesDollars'] - df_clean['TotalPurchaseDollars']
    df_clean['ProfitMargin'] = (df_clean['GrossProfit'] / df_clean['TotalSalesDollars'].replace(0, np.nan)).fillna(0) * 100
    df_clean['StockTurnover'] = (df_clean['TotalSalesQuantity'] / df_clean['TotalPurchaseQuantity'].replace(0, np.nan)).fillna(0)
    df_clean['SalestoPurchaseRatio'] = (df_clean['TotalSalesDollars'] / df_clean['TotalPurchaseDollars'].replace(0, np.nan)).fillna(0)
    return df_clean

def load(df, engine):
    logging.info(f"Loading analytics-ready dataset into database table: '{TARGET_ANALYTICS_TABLE}'...")
    pg_schema = {
        "VendorNumber": Integer(), "VendorName": String(100), "Brand": Integer(), "Description": String(100),
        "PurchasePrice": Numeric(10, 2), "ActualPrice": Numeric(10, 2), "Volume": Numeric(10, 2),
        "TotalPurchaseQuantity": Integer(), "TotalPurchaseDollars": Numeric(15, 2),
        "TotalSalesQuantity": Integer(), "TotalSalesDollars": Numeric(15, 2),
        "TotalSalesPrice": Numeric(15, 2), "TotalExciseTax": Numeric(15, 2), "FreightCost": Numeric(15, 2),
        "GrossProfit": Numeric(15, 2), "ProfitMargin": Numeric(15, 2), "StockTurnover": Numeric(15, 2), "SalestoPurchaseRatio": Numeric(15, 2)
    }
    df.to_sql(name=TARGET_ANALYTICS_TABLE, con=engine, if_exists='replace', index=False, dtype=pg_schema)
    
    logging.with_engine = engine
    with engine.begin() as connection:
        connection.execute(text(f'ALTER TABLE {TARGET_ANALYTICS_TABLE} ADD PRIMARY KEY ("VendorNumber", "Brand");'))
    logging.info("Composite primary key applied successfully.")

def run():
    setup_logging()
    try:
        engine = get_db_engine()
        raw_data = extract(engine)
        transformed_data = transform(raw_data)
        load(transformed_data, engine)
        logging.info("--- ETL Pipeline Runs Concluded Successfully! ---")
        print("\n✅ Execution Finished successfully! Logs updated.")
    except Exception as e:
        logging.critical(f"Pipeline Execution Aborted: {str(e)}")
        print(f"\n❌ Pipeline failed. Check your logs.")

if __name__ == "__main__":
    run()
