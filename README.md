# 🚖 NYC Taxi Analytics: Medallion Data Pipeline

## Overview
This project implements an end-to-end data pipeline using the **Medallion Architecture** (Bronze, Silver, Gold) to process NYC Yellow Taxi trip data. The pipeline ingests raw Parquet data into MySQL, cleanses and validates it, and prepares it for downstream analytical modeling.

## The Medallion Architecture: What Problem Does It Solve?
In traditional data engineering, raw data is often transformed all at once before being loaded into a warehouse (ETL). This approach frequently leads to **"spaghetti architecture"** a tangled mess of scripts where a failure at any single step breaks the entire pipeline. 

The Medallion Architecture solves this by introducing **incremental data quality layers**. It establishes a single source of truth by progressively improving data quality as it moves through three distinct stages:

1. **Resilience & Recoverability:** If a transformation logic changes, you don't need to re-download or re-parse the original files. You simply re-run the transformation from the Bronze layer.
2. **Data Governance & Trust:** Data analysts know exactly what they are getting. They can trust that the **Gold** layer contains validated, high-quality data.
3. **Separation of Concerns:** Data Engineers focus on ingestion and cleansing (Bronze/Silver), while Data Analysts and Data Scientists focus on business aggregations and ML (Gold).
4. **Auditability:** The Bronze layer acts as a permanent historical archive. If a bug is found later, you have the raw data to trace it back.

## 🥉 🥈 🥇 The Layers in This Project

### 1. Bronze Layer (Raw Ingestion)
* **Purpose:** Ingests raw data exactly as it is received from the source, with zero transformations.
* **Implementation:** Reads NYC Taxi Parquet files and streams them into the `bronze` MySQL table. 
* **Key Feature:** Automatically appends metadata columns (`_ingest_timestamp`, `_source_file`, `_row_hash`) for full lineage and auditability.

### 2. Silver Layer (Cleansed & Validated)
* **Purpose:** Creates a trusted, "single source of truth" for the data. 
* **Implementation:** Reads from the `bronze` table in chunks, applies data quality rules, and writes clean data to the `silver` table.
* **Data Quality Rules Applied:**
  * Drops records with negative fares or zero/negative trip distances.
  * Drops records with invalid timestamps (dropoff before pickup).
  * Standardizes null values (converts to `0` or `'N'` where appropriate).
  * Renames columns to standard `snake_case` (e.g., `VendorID` → `vendor_id`).

### 3. Gold Layer (Business Aggregations)
* **Purpose:** Curated, business-ready data for BI dashboards and reporting.
* **Implementation:** *(Coming Soon)* Aggregates Silver data into performance metrics (e.g., daily revenue, trip averages by location).

---

## 🛠️ Tech Stack
* **Language:** Python 3.x
* **Data Processing:** Pandas, PyArrow
* **Database:** MySQL
* **ORM / DB Toolkit:** SQLAlchemy, PyMySQL

---

## 📁 Repository Structure

```text
nyc-taxi-medallion/
│
├── config.py                 # Centralized configuration & environment variables
├── requirements.txt          # Python dependencies
├── README.md                 # Project documentation
│
├── sql/
│   └── schema.sql            # DDL for Bronze, Silver, and Gold tables
│
├── src/                      # Core pipeline scripts
│   ├── __init__.py
│   ├── bronze_ingest.py      # Loads Parquet into Bronze
│   └── silver_transform.py   # Cleans Bronze and loads into Silver
│
└── scripts/                  
    └── explore_data.py       # Interactive EDA and profiling

    
🚀 Getting Started
1. Prerequisites
Ensure you have MySQL installed and running locally.

2. Installation
Clone the repository and install the required packages:

bash
git clone https://github.com/yourusername/nyc-taxi-medallion.git
cd nyc-taxi-medallion
pip install -r requirements.txt
3. Database Setup
Execute the schema script to create the tables:

bash
mysql -u root -p < sql/schema.sql
4. Environment Variables
This project uses environment variables to keep credentials secure. Set them in your terminal before running the scripts:

Windows (Command Prompt):

cmd
set MYSQL_USER=root
set MYSQL_PASSWORD=your_password
set MYSQL_DB=nyc_taxi_analytics
Mac/Linux:

bash
export MYSQL_USER=root
export MYSQL_PASSWORD=your_password
export MYSQL_DB=nyc_taxi_analytics
5. Run the Pipeline
Execute the ingestion and transformation scripts sequentially:

bash
# 1. Load raw data into Bronze
python -m src.bronze_ingest

# 2. Cleanse data into Silver
python -m src.silver_transform
Disclaimer: This project uses publicly available data from the NYC TLC Trip Record Data.

