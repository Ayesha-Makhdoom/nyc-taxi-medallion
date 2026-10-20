"""Central configuration for the NYC Taxi Medallion pipeline."""

import os
from pathlib import Path

# --- Paths ---
PROJECT_ROOT = Path(__file__).resolve().parent
DATA_DIR = PROJECT_ROOT / "data"
PARQUET_FILE = DATA_DIR / "yellow_tripdata_2026-01.parquet"

# --- Database ---
# NEVER hardcode credentials. Use environment variables.
DB_USER = os.getenv("MYSQL_USER", "root")
DB_PASS = os.getenv("MYSQL_PASSWORD", "")
DB_HOST = os.getenv("MYSQL_HOST", "localhost")
DB_PORT = os.getenv("MYSQL_PORT", "3306")
DB_NAME = os.getenv("MYSQL_DB", "nyc_taxi_analytics")

DB_URL = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# --- Tables ---
BRONZE_TABLE = "bronze"
SILVER_TABLE = "silver"
GOLD_TABLE   = "gold"

# --- Pipeline tuning ---
TARGET_ROWS = 1_000_000
CHUNK_SIZE  = 50_000