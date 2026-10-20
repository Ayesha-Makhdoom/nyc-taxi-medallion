"""
Silver Layer Transformation
===========================
Reads from `bronze`, applies data-quality validation, and writes
only CLEAN rows into `silver`.

Medallion layer: SILVER (validated, conformed).
"""

import logging

import pandas as pd
from sqlalchemy import create_engine, text

from config import (
    DB_URL, BRONZE_TABLE, SILVER_TABLE, CHUNK_SIZE,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s",
)
log = logging.getLogger(__name__)

INT_COLS = [
    "VendorID", "RatecodeID", "passenger_count",
    "PULocationID", "DOLocationID", "payment_type",
]
DECIMAL_COLS = [
    "trip_distance", "fare_amount", "extra", "mta_tax", "tip_amount",
    "tolls_amount", "improvement_surcharge", "total_amount",
    "congestion_surcharge", "Airport_fee", "cbd_congestion_fee",
]
RENAME_MAP = {
    "VendorID": "vendor_id",
    "tpep_pickup_datetime": "pickup_datetime",
    "tpep_dropoff_datetime": "dropoff_datetime",
    "RatecodeID": "rate_code_id",
    "PULocationID": "pickup_location_id",
    "DOLocationID": "dropoff_location_id",
    "Airport_fee": "airport_fee",
    "id": "_bronze_source_id",
}
FINAL_COLS = [
    "vendor_id", "pickup_datetime", "dropoff_datetime",
    "passenger_count", "trip_distance", "rate_code_id", "store_and_fwd_flag",
    "pickup_location_id", "dropoff_location_id", "payment_type",
    "fare_amount", "extra", "mta_tax", "tip_amount", "tolls_amount",
    "improvement_surcharge", "total_amount", "congestion_surcharge",
    "airport_fee", "cbd_congestion_fee",
    "is_valid", "validation_errors", "quality_score", "_bronze_source_id",
]


def _clean_chunk(chunk: pd.DataFrame) -> pd.DataFrame:
    """Fill nulls and drop rows that fail business validation."""
    for col in INT_COLS:
        chunk[col] = chunk[col].fillna(0).astype(int)
    chunk["store_and_fwd_flag"] = chunk["store_and_fwd_flag"].fillna("N")
    for col in DECIMAL_COLS:
        chunk[col] = chunk[col].fillna(0).astype(float)

    bad = (
        (chunk["fare_amount"] < 0)
        | (chunk["trip_distance"] <= 0)
        | (chunk["passenger_count"] <= 0)
        | (chunk["tpep_dropoff_datetime"] < chunk["tpep_pickup_datetime"])
        | (chunk["total_amount"] <= 0)
    )
    clean = chunk[~bad].copy()
    clean["is_valid"] = True
    clean["quality_score"] = 100
    clean["validation_errors"] = ""
    return clean


def run() -> None:
    engine = create_engine(DB_URL)

    with engine.connect() as conn:
        log.info("Truncating %s ...", SILVER_TABLE)
        conn.execute(text(f"TRUNCATE TABLE {SILVER_TABLE}"))
        conn.commit()

    log.info("Streaming from %s in chunks of %s ...", BRONZE_TABLE, f"{CHUNK_SIZE:,}")
    reader = pd.read_sql(f"SELECT * FROM {BRONZE_TABLE}", engine, chunksize=CHUNK_SIZE)

    kept, dropped = 0, 0
    for chunk in reader:
        clean = _clean_chunk(chunk)
        dropped += len(chunk) - len(clean)
        if clean.empty:
            continue
        clean = clean.rename(columns=RENAME_MAP)[FINAL_COLS]
        clean.to_sql(SILVER_TABLE, engine, if_exists="append", index=False)
        kept += len(clean)
        log.info("Silver rows: %s kept | %s dropped", f"{kept:,}", f"{dropped:,}")

    log.info("Silver complete: %s clean, %s dropped.", f"{kept:,}", f"{dropped:,}")


if __name__ == "__main__":
    run()